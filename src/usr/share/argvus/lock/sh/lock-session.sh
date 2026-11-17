#!/usr/bin/env sh

# shellcheck disable=SC1090,SC1091
ARGVUS_BOOTSTRAP="${ARGVUS_BOOTSTRAP:-${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/session/sh/bootstrap.sh}"
. "$ARGVUS_BOOTSTRAP"

# Wallpaper paths belong to appearance and are not loaded by bootstrap.
. "${ARGVUS_SYSTEM_CONFIG}/appearance/sh/hypr.sh"
sh "$(paths_config lock/sh/hyprlock-theme.sh)" >/dev/null || exit 1
HYPRLOCK_PATH="$(
  sed -n \
    -e "s|^[[:space:]]*path[[:space:]]*=[[:space:]]*~|$HOME|p" \
    -e "s|^[[:space:]]*path[[:space:]]*=[[:space:]]*\\(/.*\\)|\\1|p" \
    "$(paths_config lock/config/hyprlock.conf)" |
    head -n1
)"
[ -n "$WALLPAPER_PATH" ] && [ -f "$WALLPAPER_PATH" ] || exit 1
[ -n "$HYPRLOCK_PATH" ] || exit 1
mkdir -p "${HYPRLOCK_PATH%/*}" || exit 1
if [ ! -f "$HYPRLOCK_PATH" ] || [ "$WALLPAPER_PATH" -nt "$HYPRLOCK_PATH" ]; then
  magick "$WALLPAPER_PATH" \
    -blur 0x2 \
    -fill black -colorize 20% \
    "$HYPRLOCK_PATH"
fi
dpms_helper="$(paths_config power/sh/lock-dpms-toggle.sh)"
if [ -r "$dpms_helper" ] && [ "$(sh "$dpms_helper" status)" = "enabled" ]; then
  (sleep 1; argvus config hyprland dpms off) &
fi
exec hyprlock -c "$(paths_config lock/config/hyprlock.conf)"
