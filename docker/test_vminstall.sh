#!/bin/bash

set -e
set -u

# MOUNTPATH="/mnt"

#bailout() {
#  [ -n "${LOOP_DEVICE:-}" ] || exit 1
#  [ -n "${1:-}" ] || EXIT_CODE=1
#  umount "${MOUNTPATH}"
#  kpartx -vd "${LOOP_DEVICE}"
#  losetup -d "${LOOP_DEVICE}"
#  exit $EXIT_CODE
#}
#
#trap "bailout 1" ERR HUP INT QUIT TERM

if ! [ -r /.dockerenv ] ; then
  echo "This doesn't look like a docker container, exiting to avoid data damage." >&2
  exit 1
fi

echo eatmydata >> /etc/debootstrap/packages
eatmydata grml-debootstrap --vmfile --target /srv/debian.img --password grml --hostname docker --force

# get access to inner file system
#LOOP_DEVICE="$(losetup -fv /srv/debian.img)"
#PARTITION="$(kpartx -asv ${LOOP_DEVICE} | awk '/add/ {print $3}')"
#mount "${PARTITION}" "${MOUNTPATH}"

bats /srv/test_vminstall.bats

# cleanup
#bailout 0
