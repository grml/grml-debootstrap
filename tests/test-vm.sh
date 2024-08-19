#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Run previously built VM image in qemu and check if it boots.
# Requires virtiofs support in VM.

set -eu -o pipefail

if [ "$#" -ne 2 ]; then
  echo "$0: Invalid arguments" >&2
  echo "Expect: $0 VM_IMAGE VM_HOSTNAME" >&2
  exit 1
fi
set -x

VM_IMAGE="$1"
VM_HOSTNAME="$2"

TEST_PWD="$PWD"
TEST_TMPDIR=$(mktemp -d)
TESTS_RESULTSDIR="$PWD/tests/results"
echo "Working in $TEST_TMPDIR, writing results to $TESTS_RESULTSDIR"
mkdir -p "$TESTS_RESULTSDIR"

bailout() {
  if [ -n "${QEMU_PID:-}" ] ; then
    # shellcheck disable=SC2009
    ps --pid="${QEMU_PID}" -o pid= | grep -q '.' && kill "${QEMU_PID:-}"
  fi

  rm -rf "${TEST_TMPDIR}"

  [ -n "${1:-}" ] && EXIT_CODE="$1" || EXIT_CODE=1
  exit "$EXIT_CODE"
}
trap bailout 1 2 3 6 14 15

# Setup test runner
cp ./tests/goss "$TEST_TMPDIR"/
cp ./tests/goss.yaml "$TEST_TMPDIR"/
cat <<EOT > "$TEST_TMPDIR"/testrunner
#!/bin/bash
# Do not set -eu, we want to continue even if individual commands fail.
set -x
echo "INSIDE_VM $0 running"
mkdir results

# Collect information from VM first
lsb_release -a > results/lsb_release.txt
uname -a > results/uname-a.txt
systemctl list-units > results/systemctl_list-units.txt
systemctl status > results/systemctl_status.txt
fdisk -l > results/fdisk-l.txt
hostname -f > results/hostname-f.txt 2>&1
journalctl -b > results/journalctl-b.txt
dpkg -l > results/dpkg-l.txt

# Run tests
./goss --gossfile goss.yaml validate --format tap > results/goss.tap
# Detection of testrunner success hinges on goss.exitcode file.
echo \$? > results/goss.exitcode

echo "INSIDE_VM $0 finished"
EOT
chmod a+rx "$TEST_TMPDIR"/testrunner

cd "$TEST_TMPDIR"

MOUNT_TAG=host0
qemu-system-x86_64 -hda "${VM_IMAGE}" -m 2048 \
                   -display none -vnc :0 \
                   -virtfs local,path="$TEST_TMPDIR",mount_tag="$MOUNT_TAG",security_model=none,id=host0 \
                   -serial pty &>qemu.log &
QEMU_PID="$!"

timeout=30
success=0
while [ "$timeout" -gt 0 ] ; do
  ((timeout--))
  if grep -q 'char device redirected to ' qemu.log ; then
    success=1
    sleep 1
    break
  else
    echo "No serial console from Qemu found yet [$timeout retries left]"
    sleep 1
  fi
done

if [ "$success" = "1" ] ; then
  serial_port=$(awk '/char device redirected/ {print $5}' qemu.log)
else
  echo "Error: Failed to identify serial console port." >&2
  cat qemu.log
  exit 1
fi

timeout=30
success=0
while [ "$timeout" -gt 0 ] ; do
  ((timeout--))
  if [ -c "$serial_port" ] ; then
    success=1
    sleep 1
    break
  else
    echo "No block device for serial console found yet [$timeout retries left]"
    sleep 1
  fi
done

if [ "$success" = "0" ] ; then
  echo "Error: can't access serial console block device." >&2
  exit 1
fi

RC=0
"$TEST_PWD"/tests/serial-console-connection \
  --tries 180 \
  --screenshot "$TEST_PWD/tests/screenshot.jpg" \
  --port "$serial_port" \
  --hostname "$VM_HOSTNAME" \
  --poweroff \
  "mount -t 9p -o trans=virtio,version=9p2000.L,rw $MOUNT_TAG /mnt && cd /mnt && ./testrunner" || RC=$?

if [ ! -d results ] || [ ! -f ./results/goss.tap ] || [ ! -f ./results/goss.exitcode ]; then
  echo "Running tests inside VM failed for unknown reason" >&2
  RC=1
else
  RC=$(cat results/goss.exitcode)
  echo "goss exitcode: $RC"

  cat results/goss.tap
fi

echo "Finished serial console connection [timeout=${timeout}]."

# in case of errors we might have captured a screenshot via VNC
if [ -r "${TEST_PWD}"/tests/screenshot.jpg ] ; then
  cp "${TEST_PWD}"/tests/screenshot.jpg "${TESTS_RESULTSDIR}"
fi

if [ -d results ] ; then
  mv results/* "$TESTS_RESULTSDIR/"
fi

bailout "$RC"

# EOF
