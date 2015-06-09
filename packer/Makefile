GRML_DEBOOTSTRAP_VERSION=latest
GRML_DEBOOTSTRAP_LOCAL_PATH=$(shell pwd)/local_dir

compile: fake-uname.so

install:
	cd .. && make DESTDIR=packer/local_dir install

clean:
	rm -rf local_dir

fake-uname.so:
	gcc -shared -fPIC -ldl fake-uname.c -o fake-uname.so

# Debian 9
stretch: fake-uname.so clean install
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) -var grml_debootstrap_local_path=$(GRML_DEBOOTSTRAP_LOCAL_PATH) debian64.json

# Debian 8
jessie: fake-uname.so clean install
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) -var grml_debootstrap_local_path=$(GRML_DEBOOTSTRAP_LOCAL_PATH) debian64.json

# Debian 7
wheezy: fake-uname.so clean install
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) -var grml_debootstrap_local_path=$(GRML_DEBOOTSTRAP_LOCAL_PATH) debian64.json

# Debian 6.0
squeeze: fake-uname.so clean install
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) -var grml_debootstrap_local_path=$(GRML_DEBOOTSTRAP_LOCAL_PATH) debian64.json

# Debian 5.0
lenny: fake-uname.so clean install
	packer build -var debian_version=$@ -var grml_debootstrap_version=$(GRML_DEBOOTSTRAP_VERSION) -var grml_debootstrap_local_path=$(GRML_DEBOOTSTRAP_LOCAL_PATH) debian64.json

.PHONY: compile stretch jessie wheezy squeeze lenny
