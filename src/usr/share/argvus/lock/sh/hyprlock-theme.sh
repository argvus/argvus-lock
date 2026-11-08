#!/usr/bin/env sh
# Rebuild the active Hyprlock config from its theme template.
# Usage: hyprlock-theme.sh [--invalidate]
# shellcheck disable=SC1090,SC1091,SC2034

set -eu

ARGVUS_BOOTSTRAP="${ARGVUS_BOOTSTRAP:-${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/session/sh/bootstrap.sh}"
. "$ARGVUS_BOOTSTRAP"
ARGVUS_MUTABLE_CONFIG=1
# shellcheck source=/usr/share/argvus/lib/i18n.sh
. /usr/share/argvus/lib/i18n.sh

STATE_DIR="${ARGVUS_CONFIG_HOME}/argvus/data"
ACTIVE_FILE="${STATE_DIR}/.active-theme"
TARGET_FILE="$(paths_config lock/config/hyprlock.conf)"
LOCK_WALLPAPER="$(paths_cache hypr)/hyprlock-wallpaper-blur.png"

case "${1:-}" in
  ''|--invalidate) ;;
  *)
    printf '%s\n' "$(argvus_tr lock usage)" >&2
    exit 1
    ;;
esac

read_state() {
  _file="$1"
  _fallback="$2"
  # The effects state migrated from a legacy file to the generated
  # state/effects/ directory. Only regular files are readable state values;
  # directories must fall through to the supplied default instead of making
  # this set -e projection fail.
  if [ -f "$_file" ] && [ -s "$_file" ]; then
    sed -n '1p' "$_file"
  else
    printf '%s\n' "$_fallback"
  fi
}

canonical_theme_id() {
  case "$1" in *-float) set -- "${1%-float}-spaced" ;; esac
  case "$1" in
    argvus-catppuccin-latte|argvus-light-catppuccin-latte) printf '%s\n' "catppuccin-latte" ;;
    argvus-catppuccin-latte-spaced|argvus-light-catppuccin-latte-spaced) printf '%s\n' "catppuccin-latte-spaced" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

font_state_value() {
  _key="$1"
  _fallback="$2"
  _fonts_file="${ARGVUS_CONFIG_HOME}/argvus/data/generated/fonts.conf"

  if [ -f "$_fonts_file" ]; then
    awk -F= -v key="$_key" '
      $1 == key {
        sub(/^[^=]*=/, "")
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
        print
        found = 1
        exit
      }
      END { exit found ? 0 : 1 }
    ' "$_fonts_file" 2>/dev/null && return 0
  fi

  printf '%s\n' "$_fallback"
}

THEME="$(canonical_theme_id "$(read_state "$ACTIVE_FILE" argvus-dark)")"
# The lock screen follows the canonical taskbar transparency switch in
# argvus-config. Without a readable value it keeps the enabled default.
case "$(argvus config get /effects/transparency_taskbar_enabled --effective --raw 2>/dev/null || true)" in
  true|enabled) TRANSPARENCY_STATE=enabled ;;
  false|disabled) TRANSPARENCY_STATE=disabled ;;
  *) TRANSPARENCY_STATE=enabled ;;
esac
# The theme build renders the lock screen of the active theme, layout and
# accent; its build.toml has the accent and the background colour.
if ! THEME_FILE="$(paths_theme_build_file "$THEME" lock/hyprlock.conf)"; then
  printf '%s\n' "$(argvus_tr lock theme_not_found theme="$THEME")" >&2
  exit 1
fi
BUILD_MANIFEST="${THEME_FILE%/lock/hyprlock.conf}/build.toml"
build_color() {
  sed -n "s/^$1 = \"#\([0-9A-Fa-f]\{6\}\)\"\$/\1/p" "$BUILD_MANIFEST" | head -n 1
}
ACCENT="$(build_color accent)"
BACKGROUND="$(build_color background)"
if [ -z "$ACCENT" ] || [ -z "$BACKGROUND" ]; then
  printf '%s\n' "$(argvus_tr lock invalid_active_theme theme="$THEME")" >&2
  exit 1
fi

mkdir -p "${TARGET_FILE%/*}"
mkdir -p "${LOCK_WALLPAPER%/*}"
TEMP_FILE="${TARGET_FILE}.theme.$$"
cp "$THEME_FILE" "$TEMP_FILE"
sed -i "s|^[[:space:]]*path = .*hyprlock-wallpaper-blur.png|  path = ${LOCK_WALLPAPER}|" "$TEMP_FILE"
if [ "$TRANSPARENCY_STATE" = "disabled" ]; then
  sed -i '/^[[:space:]]*path[[:space:]]*=/d; /^[[:space:]]*blur_size[[:space:]]*=/d; /^[[:space:]]*blur_passes[[:space:]]*=/d; /^[[:space:]]*brightness[[:space:]]*=/d' "$TEMP_FILE"
  _solid_file="${TEMP_FILE}.solid"
  awk -v background="$BACKGROUND" '
    /^[[:space:]]*background[[:space:]]*\{/ { print; print "  color = rgb(" background ")"; next }
    { print }
  ' "$TEMP_FILE" > "$_solid_file" && mv "$_solid_file" "$TEMP_FILE"
fi
PASSWORD_PLACEHOLDER="$(argvus_tr lock password_placeholder)"
sed -i "s|__ARGVUS_LOCK_PASSWORD__|${PASSWORD_PLACEHOLDER}|g" "$TEMP_FILE"
LOCK_FONT="$(font_state_value system_name "$(font_state_value default_name "IBM Plex Mono")")"
TEMP_FONT_FILE="${TARGET_FILE}.font.$$"
awk -v font="$LOCK_FONT" '
  /^[[:space:]]*font_family[[:space:]]*=/ {
    sub(/=.*/, "= " font)
    print
    next
  }
  { print }
' "$TEMP_FILE" >"$TEMP_FONT_FILE" && mv "$TEMP_FONT_FILE" "$TEMP_FILE"
rm -f "$TEMP_FONT_FILE"
mv "$TEMP_FILE" "$TARGET_FILE"

if [ "${1:-}" = "--invalidate" ]; then
  _lock_wallpaper=$(
    sed -n "s|^[[:space:]]*path[[:space:]]*=[[:space:]]*~|$HOME|p" "$TARGET_FILE" |
      sed -n "1p"
  )
  if [ -z "$_lock_wallpaper" ]; then
    _lock_wallpaper=$(
      sed -n "s|^[[:space:]]*path[[:space:]]*=[[:space:]]*\\(/.*\\)|\\1|p" "$TARGET_FILE" |
        head -n1
    )
  fi
  [ -n "$_lock_wallpaper" ] && rm -f "$_lock_wallpaper"
fi

printf '%s\n' "$(argvus_tr lock theme_applied theme="$THEME" accent="$ACCENT")"
