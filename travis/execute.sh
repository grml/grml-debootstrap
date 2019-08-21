#!/bin/bash

set -eu -o pipefail
set -x

if [ -z "${TRAVIS:-}" ] ; then
  echo "Running outside of Travis."

  if [ "$#" -ne 1 ] ; then
    echo "Usage: $(basename "$0") ./grml-debootstrap*.deb" >&2
    exit 1
  else
    GRML_DEBOOTSTRAP_DEB="$1"
    if [ "$(dirname "$(realpath "$GRML_DEBOOTSTRAP_DEB")")" != "$(pwd)" ] ; then
      echo "Error: the grml-debootstrap*.deb needs to be inside $(pwd) to be shared with docker container." >&2
      exit 1
    fi
  fi
fi

RELEASE="${RELEASE:-stretch}"
export RELEASE

TARGET="${TARGET:-qemu.img}"

bailout() {
  if [ -n "${QEMU_PID:-}" ] ; then
    # shellcheck disable=SC2009
    ps --pid="${QEMU_PID}" -o pid= | grep -q '.' && kill "${QEMU_PID:-}"
  fi

  if [ -f "${TARGET:-}" ] ; then
    sudo kpartx -dv "$(realpath "${TARGET}")"
  fi

  if [ -n "${LOOP_DISK:-}" ] ; then
    if sudo dmsetup ls | grep -q "${LOOP_DISK}"; then
      sudo kpartx -d "/dev/${LOOP_DISK}"
    fi
  fi

  local loopmount
  loopmount="$(sudo losetup -a | grep "$(realpath "${TARGET}")" | cut -f1 -d: || true)"

  if [ -n "${loopmount:-}" ] ; then
    sudo losetup -d "${loopmount}"
  fi

  [ -n "${1:-}" ] && EXIT_CODE="$1" || EXIT_CODE=1
  exit "$EXIT_CODE"
}
trap bailout 1 2 3 6 14 15

# run shellcheck tests
docker run koalaman/shellcheck:stable --version
docker run --rm -v "$(pwd)":/code koalaman/shellcheck:stable -e SC2181 -e SC2001 /code/chroot-script /code/grml-debootstrap

# build Debian package
if [ -z "${TRAVIS:-}" ] ; then
  echo "Not running under Travis, installing local grml-debootstrap package ${GRML_DEBOOTSTRAP_DEB}."
else
  if ! [ "${TRAVIS_DEBIAN_DISTRIBUTION:-}" = "unstable" ] ; then
    echo "TRAVIS_DEBIAN_DISTRIBUTION is $TRAVIS_DEBIAN_DISTRIBUTION and not unstable, skipping VM build tests."
    exit 0
  fi
  wget -O- https://travis.debian.net/script.sh | sh -
  # copy only the binary from the TRAVIS_DEBIAN_INCREMENT_VERSION_NUMBER=true build
  cp ../grml-debootstrap_*travis*deb .
fi

# we need to run in privileged mode to be able to use loop devices
docker run --privileged -v "$(pwd)":/code --rm -i -t debian:stretch /code/travis/build-vm.sh

[ -x ./goss ] || curl -fsSL https://goss.rocks/install | GOSS_DST="$(pwd)" sh

# Ubuntu trusty (14.04LTS) doesn't have realpath in coreutils yet
if ! command -v realpath &>/dev/null ; then
  REALPATH_PACKAGE=realpath
fi

sudo apt-get update
sudo apt-get -y install qemu-system-x86 kpartx python-pexpect python-serial ${REALPATH_PACKAGE:-}

# run tests from inside Debian system
DEVINFO=$(sudo kpartx -asv "${TARGET}")
LOOP_PART="${DEVINFO##add map }"
LOOP_PART="${LOOP_PART// */}"
LOOP_DISK="${LOOP_PART%p*}"
IMG_FILE="/dev/mapper/$LOOP_PART"

MNTPOINT="$(mktemp -d)"
sudo mount "$IMG_FILE" "${MNTPOINT}"

sudo cp ./goss "${MNTPOINT}"/usr/local/bin/goss
sudo cp ./travis/goss.yaml "${MNTPOINT}"/root/goss.yaml

sudo umount "${MNTPOINT}"
sudo kpartx -dv "$(realpath "${TARGET}")"
if sudo dmsetup ls | grep -q "${LOOP_DISK}"; then
  sudo kpartx -d "/dev/${LOOP_DISK}"
fi

rmdir "$MNTPOINT"

sudo chown "$(id -un)" qemu.img
rm -f ./serial0
mkfifo ./serial0
qemu-system-x86_64 -hda qemu.img -display none -vnc :0 \
                   -device virtio-serial-pci \
                   -chardev pipe,id=ch0,path=./serial0 \
                   -device virtserialport,chardev=ch0,name=serial0 \
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

sudo chown "$(id -un)" "$serial_port"
./travis/serial-console-connection --port "$serial_port" --hostname "$RELEASE" --pipefile "serial0" --vmoutput "vm-output.txt"

cat vm-output.txt

RC=0
if grep -q '^failure_exit' vm-output.txt ; then
  echo "We noticed failing tests."
  RC=1
else
  echo "All tests passed."
fi

echo "Finished serial console connection [timeout=${timeout}]."

bailout $RC

# EOF
