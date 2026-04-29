#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Use an already installed grml-debootstrap to build a VM image, then
# run it in qemu. Installs goss inside the VM.

set -eu -o pipefail

if [ "$#" -ne 4 ]; then
  echo "$0: Invalid arguments" >&2
  echo "Expect: $0 HOST_UID TARGET_FILE RELEASE TARGET" >&2
  exit 1
fi
HOST_UID="$1"
TARGET_FILE="$2"
RELEASE="$3"
TARGET="$4"

set -x

MIRROR='https://deb.debian.org/debian'


echo " ****************************************************************** "
echo " * Running grml-debootstrap"

if [ "$TARGET" = 'RPI' ]; then
  extra_buildopts=(--rpifile --non-free)
else
  extra_buildopts=(--vmfile)
fi

# arm64 'virt' machines expose a pl011 UART as ttyAMA0 with no VGA console;
# amd64 has the traditional 8250 UART at ttyS0 plus a VGA tty0.
DPKG_ARCHITECTURE="$(dpkg --print-architecture)"
if [ "$DPKG_ARCHITECTURE" = 'arm64' ]; then
  bootappend="console=ttyAMA0,115200 console=tty0"
else
  bootappend="console=ttyS0,115200 console=tty0 vga=791"
fi

grml-debootstrap \
  --debug \
  --force \
  "${extra_buildopts[@]}" \
  --imagesize 3G \
  --target "$TARGET_FILE" \
  --bootappend "$bootappend" \
  --password grml \
  --release  "$RELEASE" \
  --hostname "$RELEASE" \
  --mirror "$MIRROR"

chown "$HOST_UID" "$TARGET_FILE"
