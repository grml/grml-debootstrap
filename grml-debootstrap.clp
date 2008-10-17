# -*- shell-script -*-

#
# shell script command line parameter-processing for:
#
# grml-debootstrap - wrapper around debootstrap for installing plain Debian via
# grml
#
# @Author:  Tong SUN
# @Release: $Revision: $, under the BSD license
# @HomeURL: http://xpt.sourceforge.net/
#


eval set -- `getopt \
  -o +m:i:r:t:p:c:hv --long \
    mirror:,iso:,release:,target:,mntpoint:,debopt:,interactive,config:,packages::,debconf::,keep_src_list,hostname:,password:,bootappend:,groot:,grub:,help,version \
  -- "$@"`

while :; do
  case "$1" in

  # == Bootstrap options
  --mirror|-m)         # Mirror which should be used for apt-get/aptitude.
    shift; _opt_mirror="$1"
    ;;
  --iso|-i)            # Mountpoint where a Debian ISO is mounted to, for use instead
    shift; _opt_iso="$1"
    ;;
  --release|-r)        # Release of new Debian system (default: stable).
    shift; _opt_release="$1"
    ;;
  --target|-t)         # Target partition (/dev/...) or directory.
    shift; _opt_target="$1"
    ;;
  --mntpoint|-p)       # Mountpoint used for mounting the target system.
    shift; _opt_mntpoint="$1"
    ;;
  --debopt)            # Extra parameters passed to the debootstrap.
    shift; _opt_debopt="$1"
    ;;
  --interactive)       # Use interactive mode (frontend).
    _opt_interactive=T
    ;;
  #

  # == Configuration options
  --config|-c)         # Use specified configuration file, defaults to /etc/debootstr
    shift; _opt_config="$1"
    ;;
  --packages)          # Install packages defined in /etc/debootstrap/packages. Optio
    shift; _opt_packages="$1"
    _opt_packages_set=T
    ;;
  --debconf)           # Pre-seed packages using /etc/debootstrap/debconf-selections.
    shift; _opt_debconf="$1"
    _opt_debconf_set=T
    ;;
  --keep_src_list)     # Do not overwrite user provided apt sources.list.
    _opt_keep_src_list=T
    ;;
  --hostname)          # Hostname of Debian system.
    shift; _opt_hostname="$1"
    ;;
  --password)          # Use specified password as password for user root.
    shift; _opt_password="$1"
    ;;
  #
  --bootappend)        # Add specified appendline to kernel whilst booting.
    shift; _opt_bootappend="$1"
    ;;
  --groot)             # Root device for usage in grub, corresponds with $TARGET in g
    shift; _opt_groot="$1"
    ;;
  --grub)              # Target for grub installation. Use grub syntax for specifying
    shift; _opt_grub="$1"
    ;;

  # == Other options
  --help|-h)           # Print this usage information and exit.
    _opt_help=T
    ;;
  --version|-v)        # Show summary of options and exit.
    _opt_version=T
    ;;
  --)
    shift; break
    ;;
  *)
    eerror "Internal getopt error!"; eend 1 ; exit 1
    ;;
  esac
  shift
done


[ "$_opt_debug" ] && {
  echo "[grml-debootstrap] debug: _opt_mirror=$_opt_mirror"
  echo "[grml-debootstrap] debug: _opt_iso=$_opt_iso"
  echo "[grml-debootstrap] debug: _opt_release=$_opt_release"
  echo "[grml-debootstrap] debug: _opt_target=$_opt_target"
  echo "[grml-debootstrap] debug: _opt_mntpoint=$_opt_mntpoint"
  echo "[grml-debootstrap] debug: _opt_debopt=$_opt_debopt"
  echo "[grml-debootstrap] debug: _opt_interactive=$_opt_interactive"
  echo "[grml-debootstrap] debug: _opt_config=$_opt_config"
  echo "[grml-debootstrap] debug: _opt_packages=$_opt_packages"
  echo "[grml-debootstrap] debug: _opt_debconf=$_opt_debconf"
  echo "[grml-debootstrap] debug: _opt_keep_src_list=$_opt_keep_src_list"
  echo "[grml-debootstrap] debug: _opt_hostname=$_opt_hostname"
  echo "[grml-debootstrap] debug: _opt_password=$_opt_password"
  echo "[grml-debootstrap] debug: _opt_bootappend=$_opt_bootappend"
  echo "[grml-debootstrap] debug: _opt_groot=$_opt_groot"
  echo "[grml-debootstrap] debug: _opt_grub=$_opt_grub"
  echo "[grml-debootstrap] debug: _opt_help=$_opt_help"
  echo "[grml-debootstrap] debug: _opt_version=$_opt_version"
}

if [ "$_opt_check_failed" ]; then
  eerror "Not all mandatory options are set."; eend 1 ; exit 1
fi

# End
