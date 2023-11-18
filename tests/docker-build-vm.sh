#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Use an already installed grml-debootstrap to build a VM image, then
# run it in qemu. Installs goss inside the VM.

set -eu -o pipefail

if [ "$#" -ne 3 ]; then
  echo "$0: Invalid arguments" >&2
  echo "Expect: $0 HOST_UID TARGET RELEASE" >&2
  exit 1
fi
HOST_UID="$1"
TARGET="$2"
RELEASE="$3"

if [ -n "${DEBOOTSTRAP:-}" ] && [ "${DEBOOTSTRAP:-}" != "debootstrap" ]; then
  apt-get install -y "${DEBOOTSTRAP}"
fi

set -x

case "${RELEASE:-}" in
  stretch)
    MIRROR='http://archive.debian.org/debian'
    EXTRAOPT=--debopt=--no-check-gpg
  ;;
  *)
    MIRROR='http://deb.debian.org/debian'
    EXTRAOPT=''
  ;;
esac


echo " ****************************************************************** "
echo " * Running grml-debootstrap"

grml-debootstrap \
  --force \
  --vmfile \
  --vmsize 3G \
  --target "$TARGET" \
  --bootappend "console=ttyS0,115200 console=tty0 vga=791" \
  --password grml \
  --release  "$RELEASE" \
  --hostname "$RELEASE" \
  --mirror "$MIRROR" \
  $EXTRAOPT

chown "$HOST_UID" "$TARGET"
