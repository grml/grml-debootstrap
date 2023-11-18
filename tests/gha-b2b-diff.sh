#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Install an already built grml-debootstrap.deb in docker and use it to
# build two test VM images, with the same configuration. Then diff the
# two images for unaccounted differences.

set -eu -o pipefail

usage() {
  echo "Usage: $0 run"
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

# Debian version to install using grml-debootstrap
RELEASE="${RELEASE:-bookworm}"
HOST_RELEASE="${HOST_RELEASE:-unstable}"

# debootstrap to use, default empty (let grml-debootstrap decide)
DEBOOTSTRAP="${DEBOOTSTRAP:-}"

build_image() {
  # we need to run in privileged mode to be able to use loop devices
  docker run --privileged --rm -i \
    -v "$(pwd)":/code \
    -e TERM="$TERM" \
    -e DEBOOTSTRAP="$DEBOOTSTRAP" \
    -w /code \
    debian:"$HOST_RELEASE" \
    bash -c './tests/docker-install-deb.sh '"$DEB_NAME"' && ./tests/docker-build-vm.sh '"$(id -u)"' '"/code/$1"' '"$RELEASE"
}

if [ "$1" == "run" ]; then
  # Debian version on which grml-debootstrap will *run*
  HOST_RELEASE="${HOST_RELEASE:-bookworm}"

  DEB_NAME=$(ls ./grml-debootstrap*.deb || true)
  if [ -z "$DEB_NAME" ]; then
    echo "$0: No grml-debootstrap*.deb found, aborting" >&2
    exit 1
  fi

  build_image qemu-1.img
  build_image qemu-2.img

elif [ "$1" == "test" ]; then
  exec docker run --privileged --rm -i \
    -v "$(pwd)":/code \
    -e TERM="$TERM" \
    -e DEBOOTSTRAP="$DEBOOTSTRAP" \
    -w /code \
    debian:"$HOST_RELEASE" \
    ./tests/docker-test-b2b.sh qemu-1.img qemu-2.img

else
  echo "$0: unknown parameters, see --help" >&2
  exit 1
fi

# EOF
