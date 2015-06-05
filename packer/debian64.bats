#!/usr/bin/env bats

# config
mountpath="/mnt"
device="/dev/sda"
disk="${device}1"

setup() {
  mountpoint "$mountpath" &>/dev/null || mount "$disk" "$mountpath"
}

teardown() {
  mountpoint "$mountpath" &>/dev/null && umount "$mountpath"
}

# tests
@test "debian_version exists and is valid version" {
  run cat "${mountpath}/etc/debian_version"
  [ "$status" -eq 0 ]
  [[ "$output" == [0-9].[0-9]* ]] || [[ "$output" == 'stretch/sid' ]]
}

@test "kernel exists" {
  run ls "${mountpath}"/boot/vmlinuz-*
  [ "$status" -eq 0 ]
  [[ "$output" =~ ${mountpath}/boot/vmlinuz-* ]]
}

@test "initrd exists" {
  run ls "${mountpath}"/boot/initrd.img-*
  [ "$status" -eq 0 ]
  [[ "$output" =~ ${mountpath}/boot/initrd.img-* ]]
}

@test "grub-pc installed" {
  run chroot $mountpath dpkg-query --show --showformat='${Status}' grub-pc
  [ "$status" -eq 0 ]
  [[ "$output" == "install ok installed" ]]
}

@test "ext3/ext4 filesystem" {
  fstype=$(blkid -o udev ${disk} | grep '^ID_FS_TYPE=')
  run echo $fstype
  [ "$status" -eq 0 ]
  [[ $output =~ ID_FS_TYPE=ext[34] ]]
}

@test "partition table" {
  table_info=$(parted -s ${device} 'unit s print' | grep -A1 '^Number.*Start.*End' | tail -1)
  regex='1 2048s.*primary ext[34] boot'
  run echo $table_info
  echo "debug: table_info = $table_info"
  echo "debug: output     = $output"
  [[ $output =~ $regex ]]
}

@test "tune2fs mount count setting" {
  mount_count=$(tune2fs -l "$disk" | grep "^Maximum mount count:")
  run echo "$mount_count"
  [[ "$output" == "Maximum mount count:      -1" ]]
}

@test "kernel entry in grub config" {
  run grep "Debian GNU/Linux" "${mountpath}/boot/grub/grub.cfg"
  [ "$status" -eq 0 ]
}

@test "vim package is installed" {
  run chroot "$mountpath" dpkg --list vim
  [ "$status" -eq 0 ]
}

@test "home directory for user vagrant" {
  run ls -d "$mountpath"/home/vagrant
  [ "$status" -eq 0 ]
}

@test "home directory for user vagrant" {
  run grep -q ssh-rsa "$mountpath"/home/vagrant/.ssh/authorized_keys
  [ "$status" -eq 0 ]
}

@test "sudo setup for user vagrant" {
  run grep -q '^vagrant ALL=(ALL) NOPASSWD: ALL' "${mountpath}/etc/sudoers.d/vagrant" "${mountpath}/etc/sudoers"
  [ "$status" -eq 0 ]
}

@test "check for GRUB in MBR" {
  # note: ^00000170 for lenny
  # note: ^00000180 for >=wheezy
  regex='^000001[78]0.*GRUB.*'
  grub_string=$(dd if=${device} bs=512 count=1 2>/dev/null | hexdump -C | egrep "$regex")
  run echo "$grub_string"
  echo "debug: grub_string = $grub_string"
  echo "debug: output      = $output"
  [[ $output =~ $regex ]]
}
