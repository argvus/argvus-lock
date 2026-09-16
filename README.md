<!-- ARGVUS Arch Linux package repository. -->

# argvus-lock

Hyprlock configuration, lock-screen theme templates, and the theme-application
helper for the ARGVUS desktop environment.

This repository owns the files installed below `/usr/share/argvus/lock/`:

- `config/hyprlock.conf`;
- `config/themes/*/hyprlock.conf`; and
- `sh/hyprlock-theme.sh`.

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
makepkg -p packaging/arch/ci/PKGBUILD --printsrcinfo
```

See [packaging/arch/README.md](packaging/arch/README.md) for the local and CI
packaging layout.

## License

SPDX: `GPL-3.0-only`. See [LICENSE](LICENSE).
