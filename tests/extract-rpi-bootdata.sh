#!/bin/bash
VM_IMAGE="$1"
WORK_DIR="${WORK_DIR:-./rpi-work}"
KERN_DIR="${KERN_DIR:-./rpi-kernel}"

bail_noremove() {
  echo "$1" >&2
  exit 1
}

cleanup() {
  if mountpoint "$WORK_DIR" 2>/dev/null >/dev/null; then
    umount "$WORK_DIR" 2>/dev/null >/dev/null
  fi
  rmdir "$WORK_DIR" 2>/dev/null >/dev/null
  kpartx -d -s -v "$VM_IMAGE" 2>/dev/null >/dev/null
}

bail() {
  cleanup
  bail_noremove "$1"
}

mkdir --parents "$WORK_DIR" || bail_noremove "Could not create work dir!"
mkdir --parents "$KERN_DIR" || bail_noremove "Could not create kernel dir!"
[ "$(cd "$WORK_DIR"; find '.')" = '.' ] || bail_noremove "Work dir is not empty!"
[ "$(cd "$KERN_DIR"; find '.')" = '.' ] || bail_noremove "Kernel dir is not empty!"

kpartx_info="$(kpartx -a -s -v "$VM_IMAGE")"
readarray -t kpartx_part_list < <(awk '{ print $3 }' <<< "$kpartx_info")
[ "${#kpartx_part_list[@]}" = '2' ] || bail "VM image has wrong number of partitions!"
mount /dev/mapper/"${kpartx_part_list[0]}" "$WORK_DIR"
config_txt_cont="$(cat "${WORK_DIR}/config.txt")"
kernel_name="$(grep '^kernel=' <<< "$config_txt_cont" | cut -d'=' -f2 | head -n1)"
[ -z "$kernel_name" ] && bail 'Could not detect kernel name!'
initramfs_name="$(grep '^initramfs ' <<< "$config_txt_cont" | cut -d' ' -f2 | head -n1)"
[ -z "$initramfs_name" ] && bail 'Could not detect initramfs name!'
cp "${WORK_DIR}/${kernel_name}" "$KERN_DIR"/
cp "${WORK_DIR}/${initramfs_name}" "$KERN_DIR"/
umount "$WORK_DIR"
root_part_uuid="$(grep "${kpartx_part_list[1]}" < <(lsblk -f) | awk '{ print $4 }')"
cleanup
echo "${KERN_DIR}/${kernel_name}|${KERN_DIR}/${initramfs_name}|root=UUID=${root_part_uuid} rw"
