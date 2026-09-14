# argvus-lock

Hyprlock configuration, lock screen theme templates and lock-theme apply
helpers for the ARGVUS Desktop Environment.

Read the ecosystem plan first:

```text
/home/boss/Projects/github/organizations/argvus/argvus-session/tmp/AGENT_PLAN.md
```

## Ownership

This package owns:

- `/usr/share/argvus/lock/config/hyprlock.conf`
- `/usr/share/argvus/lock/config/themes/*/hyprlock.conf`
- `/usr/share/argvus/lock/sh/hyprlock-theme.sh`

`argvus-appearance` owns shared visual inputs such as wallpapers, active theme
state and accent color state. `argvus-lock` reads those inputs through the
existing ARGVUS path/bootstrap helpers and rebuilds the generated Hyprlock
config at `~/.config/argvus/hypr/hyprlock.conf`.

`argvus-power` owns idle timeout, lock menu, suspend flow and DPMS policy. It
should call `hyprlock-theme.sh` before invoking `hyprlock`, preserving the
current lock screen rendering without duplicating idle behavior here.

## Installation

```sh
make install
```

Use `DESTDIR` for packaging:

```sh
make DESTDIR="$pkgdir" PREFIX=/usr install
```

## Validation

```sh
make validate
```

Validation checks shell syntax, runs ShellCheck when available, and verifies
that the default Hyprlock config plus all extracted theme templates contain the
expected lock-screen sections.
