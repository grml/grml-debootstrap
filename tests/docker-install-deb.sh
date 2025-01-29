#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Install an already built grml-debootstrap.deb.
# Wrapper around apt-get install for usage inside docker.

set -eu -o pipefail

if [ "$#" -ne 1 ]; then
  echo "$0: Invalid arguments" >&2
  echo "Expect: $0 DEB_NAME" >&2
  exit 1
fi
DEB_NAME="$1"

apt-get update
# docker images can be relatively old, especially for unstable.
apt-get upgrade -qq -y
apt-get install -qq -y "$DEB_NAME"
