#!/usr/bin/env bats

mountpath="/mnt"
image="/srv/debian.img"

setup() {
  if ! mountpoint "${mountpath}" &>/dev/null ; then
    partition="$(kpartx -asv ${image} | awk '/add/ {print $3}')"
    mount "/dev/mapper/${partition}" "${mountpath}"
  fi
}

teardown() {
  if mountpoint "${mountpath}" &>/dev/null ; then
    umount "${mountpath}"
    kpartx -vd "${image}"
  fi
}

@test "ensure grub configuration is present" {
  run ls "${mountpath}"/boot/grub/grub.cfg
  [ "$status" -eq 0 ]
}

@test "ensure eatmydata package is present" {
  run chroot "${mountpath}" dpkg --list eatmydata
  [ "$status" -eq 0 ]
}

@test "kernel is present" {
  run ls "${mountpath}"/boot/vmlinuz-*
  [ "$status" -eq 0 ]
}

@test "debian_version exists and is valid version" {
  run cat "${mountpath}/etc/debian_version"
  [ "$status" -eq 0 ]
  [[ "$output" == [0-9].[0-9]* ]] || [[ "$output" == 'buster/sid' ]]
}
