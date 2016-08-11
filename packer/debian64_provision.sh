#!/bin/bash

set -e
set -o pipefail
set -o errtrace
set -o functrace

# defaults
GRML_DEBOOTSTRAP='grml-debootstrap'
TARGET='/mnt'
INSTALL_TARGET='/dev/sda1'
GRUB_TARGET='/dev/sda'

## validation / checks
[ -f /etc/grml_cd ] || { echo "File /etc/grml_cd doesn't exist, not executing script to avoid data loss." >&2 ; exit 1 ; }

if [ -z "$DEBIAN_VERSION" ] ; then
  echo "* Error: DEBIAN_VERSION environment variable is undefined. Exiting." >&2
  exit 1
fi

## debugging
# if we notice an error then do NOT immediately return but provide
# user a chance to debug the VM
bailout() {
  echo "* Noticed problem during execution (line ${1}, exit code ${2}), sleeping for 9999 seconds to provide debugging option"
  sleep 9999
  echo "* Finally exiting with return code 1"
  exit "$2"
}
trap 'bailout ${LINENO} $?' ERR

## helper functions
virtualbox_setup() {
  case "$DEBIAN_VERSION" in
    lenny)
      echo "* Debian lenny doesn't support Virtualbox Guest Additions, skipping."
      return 0
      ;;
  esac

  if ! mountpoint "${TARGET}" &>/dev/null ; then
    echo "* Mounting target system"
    mount "${INSTALL_TARGET}" "${TARGET}"
  fi

  echo "* Installing packages for Virtualbox Guest Additions"
  chroot ${TARGET} apt-get -y install make gcc dkms

  echo "* Installing Virtualbox Guest Additions"
  isofile="${HOME}/VBoxGuestAdditions.iso"

  KERNELHEADERS=$(basename $(find $TARGET/usr/src/ -maxdepth 1 -name linux-headers\* ! -name \*common) | sort -u -r -V | head -1)
  if [ -z "$KERNELHEADERS" ] ; then
    echo "Error: no kernel headers found for building the VirtualBox Guest Additions kernel module." >&2
    exit 1
  fi

  KERNELVERSION=${KERNELHEADERS##linux-headers-}
  if [ -z "$KERNELVERSION" ] ; then
    echo "Error: no kernel version could be identified." >&2
    exit 1
  fi

  cp /tmp/fake-uname.so "${TARGET}/tmp/fake-uname.so"
  mkdir -p "${TARGET}/media/cdrom"
  mountpoint "${TARGET}/media/cdrom" >/dev/null && umount "${TARGET}/media/cdrom"
  mount -t iso9660 $isofile "${TARGET}/media/cdrom/"
  UTS_RELEASE=$KERNELVERSION LD_PRELOAD=/tmp/fake-uname.so grml-chroot "$TARGET" /media/cdrom/VBoxLinuxAdditions.run --nox11 || true
  tail -10 "${TARGET}/var/log/VBoxGuestAdditions.log"
  umount "${TARGET}/media/cdrom/"

  # work around bug in VirtualBox 4.3.18 which leaves process behind,
  # causing unmount of "$TARGET" to fail
  grml-chroot "$TARGET" /etc/init.d/vboxadd-service stop || true
  # left behind by VBoxService
  umount "$TARGET"/dev || true

  # work around regression in virtualbox-guest-additions-iso 4.3.10
  if [ -d ${TARGET}/opt/VBoxGuestAdditions-4.3.10 ] ; then
    ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions ${TARGET}/usr/lib/VBoxGuestAdditions
  fi

  if mountpoint "${TARGET}" &>/dev/null ; then
    echo "* Unmounting target system"
    umount "${TARGET}"
  fi
}

vagrant_setup() {
  if ! mountpoint "${TARGET}" &>/dev/null ; then
    echo "* Mounting target system"
    mount "${INSTALL_TARGET}" "${TARGET}"
  fi

  echo "* Setting password for user root to 'vagrant'"
  echo root:vagrant | chroot ${TARGET} chpasswd

  echo "* Installing sudo package"
  chroot ${TARGET} apt-get -y install sudo

  echo "* Adding Vagrant user"
  chroot ${TARGET} useradd -d /home/vagrant -m -u 1000 vagrant -s /bin/bash

  echo "* Installing Vagrant ssh key"
  mkdir -m 0700 -p ${TARGET}/home/vagrant/.ssh
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" >> ${TARGET}/home/vagrant/.ssh/authorized_keys
  chmod 0600 ${TARGET}/home/vagrant/.ssh/authorized_keys
  chroot ${TARGET} chown vagrant:vagrant /home/vagrant/.ssh /home/vagrant/.ssh/authorized_keys

  echo "* Setting up sudo configuration for user vagrant"
  if ! [ -d "${TARGET}/etc/sudoers.d" ] ; then # lenny:
    echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> "${TARGET}/etc/sudoers"
  else # wheezy and newer:
    echo "vagrant ALL=(ALL) NOPASSWD: ALL" > "${TARGET}/etc/sudoers.d/vagrant"
    chmod 0440 "${TARGET}/etc/sudoers.d/vagrant"
  fi

  host="$(cat ${TARGET}/etc/hostname)"
  if ! grep -q "${host}$" "${TARGET}"/etc/hosts ; then
    echo "* Setting up localhost entry for hostname $host in /etc/hosts"
    cat >> "${TARGET}"/etc/hosts << EOF
# Added by grml-debootstrap/provision to make sure host is resolvable for sudo:
127.0.0.2 ${host}.local $host

EOF
  fi

  echo "* Setting up stdin/tty workaround in /root/.profile"
  sed -i "s;^mesg n$;# modified via grml-debootstrap/provision script to work around stdin/tty issue:\ntty -s \&\& mesg n;g" "${TARGET}"/root/.profile

  if [ -f ${TARGET}/etc/ssh/sshd_config ] && ! grep -q '^UseDNS' ${TARGET}/etc/ssh/sshd_config ; then
    echo "* Disabling UseDNS in sshd config"
    echo "UseDNS no" >> ${TARGET}/etc/ssh/sshd_config
  fi

  if mountpoint "${TARGET}" &>/dev/null ; then
    echo "* Unmounting target system"
    umount "${TARGET}"
  fi
}

partition_setup() {
  echo "* Executing automated partition setup"
  cat > /tmp/partition_setup.txt << EOF
disk_config sda disklabel:msdos bootable:1
primary / 800M- ext4 rw
EOF

  export LOGDIR='/tmp/setup-storage'
  mkdir -p $LOGDIR

  export disklist=$(/usr/lib/fai/fai-disk-info | sort)
  PATH=/usr/lib/fai:${PATH} setup-storage -f /tmp/partition_setup.txt -X
}

sources_list_setup() {
  # This is ugly because it's 'testing' no matter what ISO we're using, but otherwise we're running into
  # W: Failed to fetch http://snapshot.debian.org/archive/debian/20141114/dists/testing/main/binary-amd64/Packages  404  Not Found [IP: 193.62.202.30 80]
  echo "* Setting up /etc/apt/sources.list.d/debian.list to avoid snapshot.debian.org usage causing possible failures"
  cat > /etc/apt/sources.list.d/debian.list << EOF
deb http://ftp.debian.org/debian testing main
EOF
}

grml_debootstrap_setup() {
  echo "* grml-debootstrap setup"
  if [ "$GRML_DEBOOTSTRAP_VERSION" = "latest" ] ; then
    echo "** GRML_DEBOOTSTRAP_VERSION is set to '$GRML_DEBOOTSTRAP_VERSION'"
    echo "** Setting up grml-debootstrap from CI repository from jenkins.grml.org"
    cat > /etc/apt/sources.list.d/grml-debootstrap.list << EOF
deb     http://jenkins.grml.org/debian grml-debootstrap main
EOF
    wget -O - http://jenkins.grml.org/debian/C525F56752D4A654.asc | apt-key add -
    apt-get update
    apt-get -y install grml-debootstrap
  elif [ "$GRML_DEBOOTSTRAP_VERSION" = "stable" ] ; then
    echo "** GRML_DEBOOTSTRAP_VERSION is set to '$GRML_DEBOOTSTRAP_VERSION'"
    echo "** Using latest stable grml-debootstrap version"
    apt-get update
    apt-get -y install grml-debootstrap
  elif [ "$GRML_DEBOOTSTRAP_VERSION" = "git" ] ; then
    echo "** GRML_DEBOOTSTRAP_VERSION is set to '$GRML_DEBOOTSTRAP_VERSION'"
    echo "** Using grml-debootstrap from Git repository"
    git clone git://git.grml.org/grml-debootstrap.git
    cd grml-debootstrap
    GRML_DEBOOTSTRAP="CONFFILES=$(pwd) $(pwd)/grml-debootstrap"
  elif [ "$GRML_DEBOOTSTRAP_VERSION" = "local" ] ; then
    echo "** GRML_DEBOOTSTRAP_VERSION is set to '$GRML_DEBOOTSTRAP_VERSION'"
    echo "** Using /tmp/grml-debootstrap derived from local system"
    cd /tmp/grml-debootstrap
    export CONFFILES=$(pwd)/etc/debootstrap
    GRML_DEBOOTSTRAP="bash $(pwd)/usr/sbin/grml-debootstrap"
  elif [ "$GRML_DEBOOTSTRAP_VERSION" = "iso" ] ; then
    echo "** GRML_DEBOOTSTRAP_VERSION is set to '$GRML_DEBOOTSTRAP_VERSION'"
    echo "** Using grml-debootstrap as provided on ISO"
  fi
}

verify_debootstrap_version() {
  local required_version=1.0.65
  local present_version=$(dpkg-query --show --showformat='${Version}' debootstrap)

  if dpkg --compare-versions $present_version lt $required_version ; then
    echo "** debootstrap version $present_version is older than minimum required version $required_version - upgrading."
    apt-get update
    apt-get -y install debootstrap
  fi
}

grml_debootstrap_execution() {
  echo "* Installing Debian"

  # release specific stuff
  case "$DEBIAN_VERSION" in
    lenny)
      GRML_DEB_OPTIONS="--mirror http://archive.debian.org/debian/ --filesystem ext3"
      ;;
    stretch)
      verify_debootstrap_version
      ;;
  esac

  echo "** Executing: $GRML_DEBOOTSTRAP --hostname $DEBIAN_VERSION --release $DEBIAN_VERSION --target ${INSTALL_TARGET} --grub ${GRUB_TARGET} --password grml --force $GRML_DEB_OPTIONS" | tee -a /tmp/grml-debootstrap.log
  $GRML_DEBOOTSTRAP --hostname "${DEBIAN_VERSION}" --release "${DEBIAN_VERSION}" --target "${INSTALL_TARGET}" --grub "${GRUB_TARGET}" --password grml --force $GRML_DEB_OPTIONS 2>&1 | tee -a /tmp/grml-debootstrap.log
}

log_system_information() {
  if ! mountpoint "${TARGET}" &>/dev/null ; then
    echo "* Mounting target system"
    mount "${INSTALL_TARGET}" "${TARGET}"
  fi

  local debian_version="$(cat ${TARGET}/etc/debian_version)"
  echo "* Installed Debian version $debian_version"

  echo "* Logging build information to /etc/grml_debootstrap.info"
  echo "Debian $debian_version installed by grml-debootstrap/provision on $(date)" > ${TARGET}/etc/grml_debootstrap.info
  $GRML_DEBOOTSTRAP --version | head -1 >> ${TARGET}/etc/grml_debootstrap.info || true

  if mountpoint "${TARGET}" &>/dev/null ; then
    echo "* Unmounting target system"
    umount "${TARGET}"
  fi
}

clean_apt_files() {
  if ! mountpoint "${TARGET}" &>/dev/null ; then
    echo "* Mounting target system"
    mount "${INSTALL_TARGET}" "${TARGET}"
  fi

  echo "* Cleaning up apt stuff"
  chroot ${TARGET} apt-get clean
  rm -f ${TARGET}/var/lib/apt/lists/*Packages \
    ${TARGET}/var/lib/apt/lists/*Release \
    ${TARGET}/var/lib/apt/lists/*Sources \
    ${TARGET}/var/lib/apt/lists/*Index* \
    ${TARGET}/var/lib/apt/lists/*Translation* \
    ${TARGET}/var/lib/apt/lists/*.gpg \
    ${TARGET}/var/cache/apt-show-versions/* \
    ${TARGET}/var/cache/debconf/*.dat-old \
    ${TARGET}/var/cache/apt/*.bin \
    ${TARGET}/var/lib/aptitude/pkgstates.old

  if mountpoint "${TARGET}" &>/dev/null ; then
    echo "* Unmounting target system"
    umount "${TARGET}"
  fi
}

automated_tests() {
  echo "* Checking for bats"
  if dpkg --list bats >/dev/null 2>&1 ; then
    echo "* bats is already present, nothing to do."
  else
    echo "* Installing bats"
    apt-get update
    apt-get -y install bats
  fi

  echo "* Running tests to verify grml-debootstrap system"
  bats /tmp/debian64.bats -t
}

## main execution
sources_list_setup
partition_setup
grml_debootstrap_setup
grml_debootstrap_execution
virtualbox_setup
vagrant_setup
log_system_information
clean_apt_files
automated_tests

echo "* Finished execution of $0"
