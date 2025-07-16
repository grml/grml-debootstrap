#!/usr/bin/env bats

mountpoint="/srv/debian"

@test "ensure no grub configuration is present" {
  run ls "${mountpoint}"/boot/grub/grub.cfg
  [ "$status" -ne 0 ]
}

@test "kernel is absent" {
  run ls "${mountpoint}"/boot/vmlinuz-*
  [ "$status" -ne 0 ]
}

@test "ensure eatmydata package is present" {
  run chroot "${mountpath}" dpkg --list eatmydata
  [ "$status" -eq 0 ]
}

@test "debian_version exists and is valid version" {
  run cat "${mountpoint}/etc/debian_version"
  [ "$status" -eq 0 ]
  [[ "$output" == [0-9].[0-9]* ]] || [[ "$output" == 'trixie/sid' ]]
}
