# -*- shell-script -*-
# Filename:      cmdlineopts.clp
# Purpose:       shell script command line parameter-processing for grml-debootstrap
# Authors:       grml-team (grml.org), Tong Sun <suntong@cpan.org>
# Bug-Reports:   see http://grml.org/bugs/
# License:       This file is licensed under the GPL v2 or any later version.
################################################################################
# @WARNING: Do NOT modify this file without prior contacting the author.
# This script is use for the command line *logic* processing. It should be
# as dumb as possible. I.e., it should NOT be more complicated than
# copy-paste-and-rename from existing code. All *business-logic* processing
# should be handled in the main script, where it belongs.
################################################################################

CMDLINE_OPTS=mirror:,iso:,release:,target:,mntpoint:,debopt:,defaultinterfaces,interactive,nodebootstrap,nointerfaces,nokernel,nopackages,filesystem:,config:,confdir:,packages:,chroot-scripts:,scripts:,pre-scripts:,debconf:,vmfile,vmsize:,keep_src_list,hostname:,password:,nopassword,grmlrepos,backportrepos,bootappend:,grub:,arch:,insecure,verbose,help,version,force,debug

_opt_temp=`getopt --name grml-debootstrap -o +m:i:r:t:p:c:d:vhV --long \
    $CMDLINE_OPTS -- "$@"`

if [ $? != 0 ]; then
  eerror "Try 'grml-debootstrap --help' for more information."; eend 1; exit 1
fi
eval set -- "$_opt_temp"

while :; do
  case "$1" in

  # == Bootstrap options
  --mirror|-m)         # Mirror which should be used for apt-get/aptitude
    shift; _opt_mirror="$1"
    ;;
  --iso|-i)            # Mountpoint where a Debian ISO is mounted to
    shift; _opt_iso="$1"
    ;;
  --release|-r)        # Release of new Debian system
    shift; _opt_release="$1"
    ;;
  --target|-t)         # Target partition (/dev/...) or directory
    shift; _opt_target="$1"
    ;;
  --vmfile)           # Virtual machine file
    _opt_vmfile="T"
    ;;
  --vmsize)           # size of Virtual machine file
    shift; _opt_vmsize="$1"
    ;;
  --mntpoint|-p)       # Mountpoint used for mounting the target system
    shift; _opt_mntpoint="$1"
    ;;
  --debopt)            # Extra parameters passed to the debootstrap command
    shift; _opt_debopt="$1"
    ;;
  --filesystem)        # Filesystem that should be used
    shift; _opt_filesystem="$1"
    ;;
  --interactive)       # Use interactive mode (frontend)
    _opt_interactive=T
    ;;
  --nodebootstrap)     # Skip debootstrap, only do configuration to the target
    _opt_nodebootstrap=T
    ;;
  --nopackages)        # Skip installation of packages defined in /etc/debootstrap/packages
    _opt_nopackages=T
    ;;
  --arch)              # Target architecutre
    shift; _opt_arch="$1"
    ;;
  # just for backwards compatibility
  --insecure)
    _opt_insecure=T
    ;;
  #

  # == Configuration options
  --config|-c)         # Use specified configuration file, defaults to /etc/debootstrap
    shift; _opt_config="$1"
    ;;
  --confdir|-d)        # Place of config files for debootstrap, defaults to /etc/debootstrap
    shift; _opt_confdir="$1"
    ;;
  --packages)          # Install packages defined in specified file
    shift; _opt_packages="$1"
    _opt_packages_set=T
    ;;
  --debconf)           # Pre-seed packages using specified file
    shift; _opt_debconf="$1"
    _opt_debconf_set=T
    ;;
  --pre-scripts)       # Execute scripts from specified directory (before chroot-scripts).
    shift; _opt_pre_scripts="$1"
    _opt_pre_scripts_set=T
    ;;
  --scripts)           # Execute scripts from specified directory
    shift; _opt_scripts="$1"
    _opt_scripts_set=T
    ;;
  --chroot-scripts)   # Execute chroot scripts from specified directory
    shift; _opt_chroot_scripts="$1"
    _opt_chroot_scripts_set=T
    ;;
  --keep_src_list)     # Do not overwrite user provided apt sources.list
    _opt_keep_src_list=T
    ;;
  --hostname)          # Hostname of Debian system
    shift; _opt_hostname="$1"
    ;;
  --password)          # Use specified password as password for user root
    shift; _opt_password="$1"
    ;;
  --defaultinterfaces) # Install default /etc/network/interfaces
    _opt_defaultinterfaces=T
    ;;
  --nointerfaces)      # Skip installation of /etc/network/interfaces
    _opt_nointerfaces=T
    ;;
  --nokernel)          # Skip installation of default kernel images
    _opt_nokernel=T
    ;;
  --nopassword)        # Skip password dialog
    _opt_nopassword=T
    ;;
  --grmlrepos)         # Enable Grml repository
    _opt_grmlrepos=T
    ;;
  --backportrepos)     # Enable Debian backports repository
    _opt_backportrepos=T
    ;;
  --bootappend)        # Add specified appendline to kernel whilst booting
    shift; _opt_bootappend="$1"
    ;;
  --grub)              # Target for grub installation. Use grub syntax for specifying
    shift; _opt_grub="$1"
    ;;

  # == Other options
  --verbose|-v)        # Increase verbosity
    if [ "$_opt_verbose" ]; then _opt_verbose=`expr $_opt_verbose + 1`
    else _opt_verbose=1; fi
    ;;
  --debug)             # Execute in debug mode
    _opt_debug=T
    ;;
  --help|-h)           # Print usage information and exit
    _opt_help=T
    ;;
  --version|-V)        # Show version information and exit
    _opt_version=T
    ;;
  --force)             # Do not prompt for user input
    _opt_force=T
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

## END OF FILE #################################################################
