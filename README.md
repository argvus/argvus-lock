<!-- ARGVUS Arch Linux package repository. -->

# argvus-lock

<div align="center">

[![CI](https://github.com/argvus/argvus-lock/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/argvus/argvus-lock/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/argvus/argvus-lock)](./LICENSE)
[![Language: Shell](https://img.shields.io/badge/Shell-POSIX-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform: Arch Linux | Wayland](https://img.shields.io/badge/platform-Arch%20Linux%20%7C%20Wayland-1793D1?logo=archlinux&logoColor=white)](https://archlinux.org/)
[![Pull requests](https://img.shields.io/github/issues-pr/argvus/argvus-lock)](https://github.com/argvus/argvus-lock/pulls)
[![Issues](https://img.shields.io/github/issues/argvus/argvus-lock)](https://github.com/argvus/argvus-lock/issues)
[![Last commit](https://img.shields.io/github/last-commit/argvus/argvus-lock)](https://github.com/argvus/argvus-lock/commits/main)
[![Docs](https://img.shields.io/badge/docs-project-blue)](./docs/)

</div>

Hyprlock configuration, lock-screen theme templates, and the theme-application
helper for the ARGVUS desktop environment.

This repository owns the files installed below `/usr/share/argvus/lock/`:

- `config/hyprlock.conf`;
- `theme-template/hyprlock.conf`, the lock screen template every theme is
  rendered through (registered in `/usr/share/argvus/theme/consumers.d/lock.toml`); and
- `sh/hyprlock-theme.sh`, which assembles the active lock screen from the theme build.

`argvus-appearance` owns shared visual inputs such as wallpaper, active-theme,
and accent-color state. `argvus-power` owns idle timeout, lock-menu, suspend,
and DPMS policy and calls this package's helper before invoking `hyprlock`.

## Build and install

On Arch Linux or a compatible distribution:

```sh
sudo pacman -S --needed base-devel git shellcheck
make validate
make build
make install
```

`make build` creates a deterministic local source archive in
`build/artifacts/` and a package in `build/dist/`. `make install` requires
`sudo` and installs the single package found there.

For package metadata only:

```sh
make validate
makepkg -p packaging/arch/remote/PKGBUILD --printsrcinfo
```

See [packaging/arch/README.md](packaging/arch/README.md) for the local and CI
packaging layout.

## Contributing and policies

- [CONTRIBUTING.md](https://github.com/argvus/.github/blob/main/CONTRIBUTING.md) — contribution workflow
- [SECURITY.md](https://github.com/argvus/.github/blob/main/SECURITY.md) — private vulnerability reports
- [Code of Conduct](https://github.com/argvus/.github/blob/main/policies/CODE_OF_CONDUCT.md) — community standards
- [AI usage policy](https://github.com/argvus/.github/blob/main/policies/IA_USAGE.md) — rules for AI-assisted contributions

## License

SPDX: `GPL-3.0-only`. See [LICENSE](LICENSE).
