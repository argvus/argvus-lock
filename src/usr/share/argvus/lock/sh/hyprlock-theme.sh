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

canonical_theme_id() {
  case "$1" in
    argvus-catppuccin-latte|argvus-light-catppuccin-latte) printf '%s\n' "catppuccin-latte" ;;
    argvus-catppuccin-latte-float|argvus-light-catppuccin-latte-float) printf '%s\n' "catppuccin-latte-float" ;;
    *) printf '%s\n' "$1" ;;
  esac
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

THEME="$(canonical_theme_id "$(read_state "$ACTIVE_FILE" argvus-dark)")"
TRANSPARENCY_STATE="$(read_state "$STATE_DIR/state/transparency" "")"
[ -n "$TRANSPARENCY_STATE" ] || TRANSPARENCY_STATE="$(read_state "$STATE_DIR/state/effects" enabled)"
case "$THEME" in
  dracula|dracula-float) DEFAULT_ACCENT="BD93F9"; BACKGROUND="282A36" ;;
  one-dark|one-dark-float) DEFAULT_ACCENT="61AFEF"; BACKGROUND="282C34" ;;
  argvus-dark|argvus-dark-float) DEFAULT_ACCENT="3590bd"; BACKGROUND="111316" ;;
  silver-dark|silver-dark-float) DEFAULT_ACCENT="595959"; BACKGROUND="111316" ;;
  argvus-light|argvus-light-float) DEFAULT_ACCENT="181818"; BACKGROUND="f7f7f7" ;;
  github-light|github-light-float) DEFAULT_ACCENT="0969DA"; BACKGROUND="FFFFFF" ;;
  one-light|one-light-float) DEFAULT_ACCENT="4078F2"; BACKGROUND="FAFAFA" ;;
  everforest-light|everforest-light-float) DEFAULT_ACCENT="3A94C5"; BACKGROUND="FDF6E3" ;;
  solarized-light|solarized-light-float) DEFAULT_ACCENT="268BD2"; BACKGROUND="FDF6E3" ;;
  frost|frost-float) DEFAULT_ACCENT="0969DA"; BACKGROUND="F6F8FA" ;;
  catppuccin-latte|catppuccin-latte-float) DEFAULT_ACCENT="1E66F5"; BACKGROUND="EFF1F5" ;;
  gruvbox-light|gruvbox-light-float) DEFAULT_ACCENT="458588"; BACKGROUND="FBF1C7" ;;
  slate-dark|slate-dark-float) DEFAULT_ACCENT="7391a5"; BACKGROUND="2f3541" ;;
  universe|universe-float) DEFAULT_ACCENT="eeeeee"; BACKGROUND="000000" ;;
  gruvbox-high-dark|gruvbox-high-dark-float) DEFAULT_ACCENT="D79921"; BACKGROUND="282828" ;;
  gruvbox-dark|gruvbox-dark-float) DEFAULT_ACCENT="D4BE98"; BACKGROUND="282828" ;;
  rose-pine|rose-pine-float) DEFAULT_ACCENT="C4A7E7"; BACKGROUND="191724" ;;
  tokyo-night|tokyo-night-float) DEFAULT_ACCENT="7AA2F7"; BACKGROUND="1A1B26" ;;
  solitude|solitude-float) DEFAULT_ACCENT="798186"; BACKGROUND="101315" ;;
  sunset|sunset-float) DEFAULT_ACCENT="E2BE8A"; BACKGROUND="0F0F0F" ;;
  hackerman|hackerman-float) DEFAULT_ACCENT="82FB9C"; BACKGROUND="0B0C16" ;;
  monokai-dark|monokai-dark-float) DEFAULT_ACCENT="78DCE8"; BACKGROUND="2D2A2E" ;;
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
if [ "$TRANSPARENCY_STATE" = "disabled" ]; then
  sed -i '/^[[:space:]]*path[[:space:]]*=/d; /^[[:space:]]*blur_size[[:space:]]*=/d; /^[[:space:]]*blur_passes[[:space:]]*=/d; /^[[:space:]]*brightness[[:space:]]*=/d' "$TEMP_FILE"
  _solid_file="${TEMP_FILE}.solid"
  awk -v background="$BACKGROUND" '
    /^[[:space:]]*background[[:space:]]*\{/ { print; print "  color = rgb(" background ")"; next }
    { print }
  ' "$TEMP_FILE" > "$_solid_file" && mv "$_solid_file" "$TEMP_FILE"
fi
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
