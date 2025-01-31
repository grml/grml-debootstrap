#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Install an already built grml-debootstrap.deb in docker and use it to
# build a test VM image. Then run this VM image in qemu and check if it
# boots.

set -eu -o pipefail

usage() {
  echo "Usage: $0 setup"
  echo " then: $0 run"
  echo " then: $0 test"
  echo "WARNING: $0 is potentially dangerous and may destroy the host system and/or any data."
  exit 0
}

if [ "${1:-}" == "--help" ] || [ "${1:-}" == "help" ]; then
  usage
fi

if [ -z "${1:-}" ]; then
  echo "$0: unknown parameters, see --help" >&2
  exit 1
fi

set -x

if [ ! -d ./tests ]; then
  echo "$0: Started from incorrect working directory" >&2
  exit 1
fi

if [ "$1" == "setup" ]; then
  sudo apt-get update
  sudo apt-get -qq -y install curl qemu-system-x86 kpartx python3-pexpect python3-serial
  # vncsnapshot might not be available, though we don't want to abort execution then
  sudo apt-get -qq -y install vncsnapshot || true
  [ -x ./tests/goss ] || curl -fsSL https://goss.rocks/install | GOSS_DST="$(pwd)/tests" sh
  # TODO: docker.io
  exit 0
fi

# Debian version to install using grml-debootstrap
RELEASE="${RELEASE:-trixie}"

TARGET="${TARGET:-qemu.img}"

if [ "$1" == "run" ]; then
  # Debian version on which grml-debootstrap will *run*
  HOST_RELEASE="${HOST_RELEASE:-trixie}"

  DEB_NAME=$(ls ./grml-debootstrap*.deb || true)
  if [ -z "$DEB_NAME" ]; then
    echo "$0: No grml-debootstrap*.deb found, aborting" >&2
    exit 1
  fi

  # we need to run in privileged mode to be able to use loop devices
  exec docker run --privileged --rm -i \
    -v "$(pwd)":/code \
    -e TERM="$TERM" \
    -w /code \
    debian:"$HOST_RELEASE" \
    bash -c './tests/docker-install-deb.sh '"$DEB_NAME"' && ./tests/docker-build-vm.sh '"$(id -u)"' '"/code/$TARGET"' '"$RELEASE"

elif [ "$1" == "test" ]; then
  # run tests from inside Debian system
  exec ./tests/test-vm.sh "$PWD/$TARGET" "$RELEASE"

else
  echo "$0: unknown parameters, see --help" >&2
  exit 1
fi

# EOF
