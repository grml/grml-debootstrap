#!/bin/bash

set -e
set -u

if ! [ -r /.dockerenv ] ; then
  echo "This doesn't look like a docker container, exiting to avoid data damage." >&2
  exit 1
fi

echo eatmydata >> /etc/debootstrap/packages

eatmydata grml-debootstrap --target /srv/debian --password grml --hostname docker --nokernel --force

bats /srv/test_dirinstall.bats
