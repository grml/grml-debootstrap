# grml-debootstrap

[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-purple?logo=github)](https://github.com/sponsors/grml)
[![GitHub release](https://img.shields.io/github/v/release/grml/grml-debootstrap)](https://github.com/grml/grml-debootstrap/releases)
[![Debian package](https://img.shields.io/debian/v/grml-debootstrap/trixie?label=debian)](https://packages.debian.org/trixie/grml-debootstrap)
[![Ubuntu package](https://img.shields.io/ubuntu/v/grml-debootstrap)](https://packages.ubuntu.com/search?keywords=grml-debootstrap)

Install a pure [Debian](https://debian.org/) system from a Grml Live or another Debian-style system.

## Purpose

This tool eases a "debootstrap"-style installation process of pure [Debian](https://debian.org/), as favored by many advanced users over the traditional Debian Installer.
Configuration can be done on the command line, in a dialog frontend or in /etc/debootstrap/config.
You will get a pure Debian system installed on the specified device or directory, or directly into an image file suitable for Virtual Machine use.

## Installation

### From Debian repositories

```bash
sudo apt install grml-debootstrap
```

### From GitHub releases

Download the latest release from [GitHub Releases](https://github.com/grml/grml-debootstrap/releases), and then:

```bash
# Download and install .deb package
sudo apt install ./grml-debootstrap_*.deb
```

## Documentation

For detailed usage instructions and all available options, visit: https://grml.org/grml-debootstrap/ and read [grml-debootstrap.8.adoc](grml-debootstrap.8.adoc).

## License

This project is licensed under the GPL v2+.

## Contributing

- **Source code**: https://github.com/grml/grml-debootstrap
- **Issues**: https://github.com/grml/grml-debootstrap/issues
- **Releases**: https://github.com/grml/grml-debootstrap/releases
- **Grml Live Linux**: https://grml.org
