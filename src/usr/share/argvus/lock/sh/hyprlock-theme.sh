#!/usr/bin/env sh
# Rebuild the active Hyprlock config from its theme template.
# Usage: hyprlock-theme.sh [--invalidate]
# shellcheck disable=SC1091

set -eu

ARGVUS_BOOTSTRAP="${ARGVUS_BOOTSTRAP:-${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/session/sh/bootstrap.sh}"
. "$ARGVUS_BOOTSTRAP"
ARGVUS_MUTABLE_CONFIG=1
# shellcheck source=/usr/share/argvus/lib/i18n.sh
. /usr/share/argvus/lib/i18n.sh

STATE_DIR="${ARGVUS_CONFIG_HOME}/argvus"
ACTIVE_FILE="${STATE_DIR}/.active-theme"
ACCENT_FILE="${STATE_DIR}/.accent-color"
TARGET_FILE="$(paths_config lock/config/hyprlock.conf)"
SYSTEM_CONFIG="${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}"
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
  if [ -s "$_file" ]; then
    sed -n '1p' "$_file"
  else
    printf '%s\n' "$_fallback"
  fi
}

font_state_value() {
  _key="$1"
  _fallback="$2"
  _fonts_file="${ARGVUS_CONFIG_HOME}/argvus/fonts.conf"

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

THEME="$(read_state "$ACTIVE_FILE" argvus-dark-aether)"
case "$THEME" in
  argvus-dark-aether|argvus-dark-aether-float) DEFAULT_ACCENT="3590bd" ;;
  argvus-dark-silver|argvus-dark-silver-float) DEFAULT_ACCENT="595959" ;;
  argvus-light-veil|argvus-light-veil-float) DEFAULT_ACCENT="181818" ;;
  argvus-dark-slate|argvus-dark-slate-float) DEFAULT_ACCENT="7391a5" ;;
  argvus-dark-universe|argvus-dark-universe-float) DEFAULT_ACCENT="eeeeee" ;;
  *)
    printf '%s\n' "$(argvus_tr lock invalid_active_theme theme="$THEME")" >&2
    exit 1
    ;;
esac

THEME_FILE="$(paths_config "lock/config/themes/${THEME}/hyprlock.conf")"
if [ ! -f "$THEME_FILE" ]; then
  THEME_FILE="$SYSTEM_CONFIG/lock/config/themes/${THEME}/hyprlock.conf"
fi
if [ ! -f "$THEME_FILE" ]; then
  printf '%s\n' "$(argvus_tr lock theme_not_found theme="$THEME")" >&2
  exit 1
fi

ACCENT="$(read_state "$ACCENT_FILE" "#$DEFAULT_ACCENT" | tr 'A-F' 'a-f' | sed 's/^#//')"
case "$ACCENT" in
  ??????)
    case "$ACCENT" in
      *[!0-9a-f]*) ACCENT="$DEFAULT_ACCENT" ;;
    esac
    ;;
  *) ACCENT="$DEFAULT_ACCENT" ;;
esac

mkdir -p "${TARGET_FILE%/*}"
mkdir -p "${LOCK_WALLPAPER%/*}"
TEMP_FILE="${TARGET_FILE}.theme.$$"
cp "$THEME_FILE" "$TEMP_FILE"
sed -i "s|^[[:space:]]*path = .*hyprlock-wallpaper-blur.png|  path = ${LOCK_WALLPAPER}|" "$TEMP_FILE"
sed -i "s|^[[:space:]]*outer_color = .*|  outer_color = rgb(${ACCENT})|" "$TEMP_FILE"
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
