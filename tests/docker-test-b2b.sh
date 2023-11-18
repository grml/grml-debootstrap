#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Diff two built VM images for unaccounted differences.

set -eu -o pipefail

if [ "$#" -ne 2 ]; then
  echo "$0: Invalid arguments" >&2
  echo "Expect: $0 IMG1 IMG2" >&2
  exit 1
fi
IMG1="$1"
IMG2="$2"

set -x

MNTDIR1=$(mktemp -d)
MNTDIR2=$(mktemp -d)

# Assumes root partition is at 4MB offset.
mount -oloop,offset=4194304 "$IMG1" "$MNTDIR1"
mount -oloop,offset=4194304 "$IMG2" "$MNTDIR2"

set +x

while read -r pattern; do
  if [ -n "$pattern" ]; then
    echo "Removing known difference before diffing: $pattern"
    rm -rfv "$MNTDIR1"$pattern "$MNTDIR2"$pattern
  fi
done < <(grep -v '^#' ./tests/b2b-known-differences)

set -x
exec diff -Nru \
  --no-dereference \
  "$MNTDIR1" "$MNTDIR2" | tee diff.txt
