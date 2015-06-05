compile: fake-uname.so

GRML_DEBOOTSTRAP_VERSION=latest

fake-uname.so:
	gcc -shared -fPIC -ldl fake-uname.c -o fake-uname.so

# Debian 9
stretch: fake-uname.so
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) debian64.json

# Debian 8
jessie: fake-uname.so
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) debian64.json

# Debian 7
wheezy: fake-uname.so
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) debian64.json

# Debian 6.0
squeeze: fake-uname.so
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) debian64.json

# Debian 5.0
lenny: fake-uname.so
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) debian64.json

.PHONY: compile stretch jessie wheezy squeeze lenny
