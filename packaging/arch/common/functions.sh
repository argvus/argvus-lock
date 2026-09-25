#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2154
# srcdir, pkgdir, pkgname, and pkgver are supplied by makepkg.

# GitHub source archives use <repository>-v<version> as their top-level
# directory, while the local builder creates <pkgname>-<pkgver>. Normalize
# both forms before check() and package() run.
arch_normalize_source_tree() {
	local expected="${srcdir}/${pkgname}-${pkgver}"
	local -a roots=()

	while IFS= read -r -d '' root; do
		roots+=("$root")
	done < <(find "$srcdir" -mindepth 1 -maxdepth 1 -type d -print0)

	if (( ${#roots[@]} != 1 )); then
		printf 'error: expected exactly one extracted source directory in %s\n' "$srcdir" >&2
		return 1
	fi

	if [[ "${roots[0]}" != "$expected" ]]; then
		[[ ! -e "$expected" ]] || {
			printf 'error: source destination already exists: %s\n' "$expected" >&2
			return 1
		}
		mv -- "${roots[0]}" "$expected"
	fi
}

arch_check_lock_payload() {
	local source_root="${srcdir}/${pkgname}-${pkgver}"
	local themes_root="${source_root}/src/usr/share/argvus/lock/config/themes"
	local theme_directories
	local theme_configs

	test -f "${source_root}/src/usr/share/argvus/lock/config/hyprlock.conf"
	test -x "${source_root}/src/usr/share/argvus/lock/sh/hyprlock-theme.sh"
	theme_directories="$(find "$themes_root" -mindepth 1 -maxdepth 1 -type d | wc -l)"
	theme_configs="$(find "$themes_root" -mindepth 2 -maxdepth 2 -type f -name hyprlock.conf | wc -l)"
	test "$theme_directories" -gt 0
	test "$theme_configs" -eq "$theme_directories"
}

arch_package_lock_payload() {
	local source_root="${srcdir}/${pkgname}-${pkgver}"

	cp -a --no-preserve=ownership "${source_root}/src/." "${pkgdir}/"
	find "${pkgdir}" -type f -name '*.sh' -exec chmod 755 {} +
	install -Dm644 "${source_root}/LICENSE" \
		"${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
