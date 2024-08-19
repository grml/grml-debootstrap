# Tests

The `tests` directory provides scripts and configuration files which are used within [grml-debootstrap's GitHub actions](https://github.com/grml/grml-debootstrap/actions).

> [!CAUTION]
> executing the scripts is potentially dangerous and may destroy the host system and/or any data. Run the tests only on throw-away systems and at your own risk.

The scripts are **not** designed to be executed manually, though it's possible to run them inside a local Debian throw-away VM.

> [!NOTE]
> make sure to have at least 8GB disk space and 2GB memory available on your VM.

Execute the following steps to build a Debian VM image (`qemu.img`) and run the tests against it:

```
sudo apt install git docker.io
git clone https://github.com/grml/grml-debootstrap
cd grml-debootstrap
sudo ./tests/docker-build-deb.sh --autobuild 01
sudo ./tests/build-vm-and-test.sh setup
sudo ./tests/build-vm-and-test.sh run
sudo ./tests/build-vm-and-test.sh test
```
