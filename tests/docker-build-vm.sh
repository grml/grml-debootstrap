#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Use an already installed grml-debootstrap to build a VM image, then
# run it in qemu. Installs goss inside the VM.

set -eu -o pipefail

if [ "$#" -ne 4 ]; then
  echo "$0: Invalid arguments" >&2
  echo "Expect: $0 HOST_UID TARGET RELEASE RASPI" >&2
  exit 1
fi
HOST_UID="$1"
TARGET="$2"
RELEASE="$3"
RASPI="$4"

set -x

MIRROR='https://deb.debian.org/debian'


echo " ****************************************************************** "
echo " * Running grml-debootstrap"

if [ "$RASPI" = 'yes' ]; then
  extra_buildopts='--rpifile --non-free'
else
  extra_buildopts='--vmfile'
fi

grml-debootstrap \
  --debug \
  --force \
  ${extra_buildopts} \
  --imagesize 3G \
  --target "$TARGET" \
  --bootappend "console=ttyS0,115200 console=tty0 vga=791" \
  --password grml \
  --release  "$RELEASE" \
  --hostname "$RELEASE" \
  --mirror "$MIRROR"

chown "$HOST_UID" "$TARGET"
