Creating Vagrant baseboxes and testing grml-debootstrap
=======================================================

Purpose
-------

This directory provides configurations and scripts to

* test grml-debootstrap
* generate base.box for Virtualbox usage with Vagrant

Required software
-----------------

* [Packer](https://packer.io/) binary in $PATH
* [Vagrant](https://vagrantup.com/)
* [Virtualbox](https://www.virtualbox.org/)

Usage instructions
------------------

To create a Debian base box for usage with Vagrant
(and while at it run the grml-debootstrap tests):

    % cd grml-debootstrap.git
    % make testrun

Start resulting Debian system via Vagrant:

    % vagrant up
