#!/bin/bash

set -eu -o pipefail

TARGET="${TARGET:-/code/qemu.img}"
RELEASE="${RELEASE:-stretch}"

cd "$(dirname "$TARGET")"
apt update
apt -y install ./grml-debootstrap*.deb

grml-debootstrap \
  --force \
  --vmfile \
  --vmsize 3G \
  --target "$TARGET" \
  --bootappend "console=ttyS0,115200 console=tty0 vga=791" \
  --password grml \
  --release  "$RELEASE" \
  --hostname "$RELEASE" \
  # EOF
