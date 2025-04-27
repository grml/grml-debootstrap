#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Run previously built VM image in qemu and check if it boots.
# Requires virtiofs support in VM.

set -eu -o pipefail

if [ "$#" -ne 3 ]; then
  echo "$0: Invalid arguments" >&2
  echo "Expect: $0 VM_IMAGE VM_HOSTNAME RASPI" >&2
  exit 1
fi
set -x

VM_IMAGE="$1"
VM_HOSTNAME="$2"
RASPI="$3"

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

  sudo rm -rf "${TEST_TMPDIR}"

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
echo "INSIDE_VM \$0 running \$(date -R)"
mkdir results

# Collect information from VM first
cat /etc/os-release > results/os-release.txt
dpkg -l > results/dpkg-l.txt
uname -a > results/uname-a.txt
systemctl list-units > results/systemctl_list-units.txt
systemctl status > results/systemctl_status.txt
fdisk -l > results/fdisk-l.txt
hostname -f > results/hostname-f.txt 2>&1
journalctl -b > results/journalctl-b.txt

# Run tests
echo "INSIDE_VM starting goss \$(date -R)"
./goss --gossfile goss.yaml validate --format tap > results/goss.tap 2> results/goss.err
# Detection of testrunner success hinges on goss.exitcode file.
echo \$? > results/goss.exitcode

echo "INSIDE_VM \$0 finished \$(date -R)"
EOT
chmod a+rx "$TEST_TMPDIR"/testrunner

cd "$TEST_TMPDIR"

MOUNT_TAG=host0
declare -a qemu_command

DPKG_ARCHITECTURE=$(dpkg --print-architecture)
if [ "${DPKG_ARCHITECTURE}" = "amd64" ]; then
  qemu_command=( qemu-system-x86_64 )
  qemu_command+=( -machine q35 )
elif [ "${DPKG_ARCHITECTURE}" = "arm64" ]; then
  if [ "$RASPI" = 'yes' ]; then
    if ! rpi_bootdata="$(sudo "$TEST_PWD"/tests/extract-rpi-bootdata.sh "$VM_IMAGE")"; then
      echo "E: could not extract RPi boot data"
      exit 1
    fi
    IFS='|' read rpi_kern rpi_initrd rpi_kerncmd <<< "$rpi_bootdata"
    qemu_command=( qemu-system-aarch64 )
    qemu_command+=( -machine "type=virt,gic-version=max,accel=kvm:tcg,highmem=off" )
    qemu_command+=( -kernel "$rpi_kern" )
    qemu_command+=( -initrd "$rpi_initrd" )
    qemu_command+=( -append "$rpi_kerncmd" )
  else
    cp /usr/share/AAVMF/AAVMF_VARS.fd efi_vars.fd
    qemu_command=( qemu-system-aarch64 )
    qemu_command+=( -machine "type=virt,gic-version=max,accel=kvm:tcg" )
    qemu_command+=( -drive "if=pflash,format=raw,unit=0,file.filename=/usr/share/AAVMF/AAVMF_CODE.no-secboot.fd,file.locking=off,readonly=on" )
    qemu_command+=( -drive "if=pflash,format=raw,unit=1,file=efi_vars.fd" )
  fi
else
  echo "E: unsupported ${DPKG_ARCHITECTURE}"
  exit 1
fi
qemu_command+=( -cpu max )
qemu_command+=( -smp 2 )
qemu_command+=( -m 2048 )
qemu_command+=( -drive "file=${VM_IMAGE},format=raw,index=0,media=disk" )
qemu_command+=( -virtfs "local,path=${TEST_TMPDIR},mount_tag=${MOUNT_TAG},security_model=none,id=host0" )
qemu_command+=( -nographic )
qemu_command+=( -display none )
qemu_command+=( -vnc :0 )
qemu_command+=( -monitor "unix:qemu-monitor-socket,server,nowait" )
qemu_command+=( -serial pty )
"${qemu_command[@]}" &>qemu.log &
QEMU_PID="$!"

RC=0
"$TEST_PWD"/tests/serial-console-connection \
  --tries 180 \
  --screenshot "$TEST_PWD/tests/screenshot.jpg" \
  --qemu-log qemu.log \
  --hostname "$VM_HOSTNAME" \
  --poweroff \
  "mount -t 9p -o trans=virtio,version=9p2000.L,msize=512000,rw $MOUNT_TAG /mnt && cd /mnt && ./testrunner" || RC=$?

if [ ! -d results ] || [ ! -f ./results/goss.tap ] || [ ! -f ./results/goss.exitcode ]; then
  echo "Running tests inside VM failed for unknown reason" >&2
  RC=1
  cat results/goss.err || true
else
  RC=$(cat results/goss.exitcode)
  echo "goss exitcode: $RC"

  cat results/goss.tap
fi

# in case of errors we might have captured a screenshot via VNC
if [ -r "${TEST_PWD}"/tests/screenshot.jpg ] ; then
  cp "${TEST_PWD}"/tests/screenshot.jpg "${TESTS_RESULTSDIR}"
fi

if [ -d results ] ; then
  mv results/* "$TESTS_RESULTSDIR/"
fi

bailout "$RC"

# EOF
