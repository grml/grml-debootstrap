#!/bin/bash

set -eu -o pipefail

RELEASE="${RELEASE:-stretch}"
export RELEASE

# run shellcheck tests
docker run koalaman/shellcheck:stable --version
docker run -v "$(pwd)":/code koalaman/shellcheck:stable -e SC2181 /code/chroot-script /code/grml-debootstrap

# build Debian package
wget -O- https://travis.debian.net/script.sh | sh -

if ! [ "${TRAVIS_DEBIAN_DISTRIBUTION:-}" = "unstable" ] ; then
  echo "TRAVIS_DEBIAN_DISTRIBUTION is $TRAVIS_DEBIAN_DISTRIBUTION and not unstable, skipping VM build tests."
  exit 0
fi

# copy only the binary from the TRAVIS_DEBIAN_INCREMENT_VERSION_NUMBER=true build
cp ../grml-debootstrap_*travis*deb .

# we need to run in privileged mode to be able to use loop devices
docker run --privileged -v "$(pwd)":/code --rm -i -t debian:stretch /code/travis/build-vm.sh

[ -x ./goss ] || curl -fsSL https://goss.rocks/install | GOSS_DST="$(pwd)" sh

sudo apt-get update
sudo apt-get -y install qemu-system-x86

# sudo timeout --preserve-status --foreground 120 qemu-system-x86_64 -hda qemu.img -serial stdio -display none | tee -a qemu.log
sudo qemu-system-x86_64 -hda qemu.img -serial stdio -display none | tee -a qemu.log &

timeout=120
success=0
while [ "$timeout" -gt 0 ]; do
  ((timeout--))
  if ./goss --gossfile ./travis/goss.yaml validate --format nagios ; then
    success=1
    sleep 1
    break
  else
    echo "Tests didn't pass YET, will retry again [$timeout retries left]"
    sleep 1
  fi
done

if [ "$success" = "1" ] ; then
  echo "All tests passed! (◕‿◕)"
else
  echo "Reached timeout after $timeout seconds with failing tests. ¯\(º o)/¯ ☂" >&2
  echo "Latest test run results:"
  ./goss --gossfile ./travis/goss.yaml validate
  exit 1
fi
