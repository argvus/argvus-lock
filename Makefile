PREFIX ?= /usr
DESTDIR ?=
INSTALL ?= install
RM ?= rm -f

.DEFAULT_GOAL := help

.PHONY: help install uninstall validate release-archive clean

help:
	@echo "Available targets:"
	@echo "  make build"
	@echo "  make install"
	@echo "  make uninstall"
	@echo "  make validate"
	@echo "  make release-archive"

install:
	$(INSTALL) -dm755 "$(DESTDIR)$(PREFIX)/share/argvus/lock"
	cp -a src/usr/share/argvus/lock/. "$(DESTDIR)$(PREFIX)/share/argvus/lock/"
	find "$(DESTDIR)$(PREFIX)/share/argvus/lock/sh" -type f -name '*.sh' -exec chmod 755 {} \; 2>/dev/null || true
	$(INSTALL) -Dm644 LICENSE \
		"$(DESTDIR)$(PREFIX)/share/licenses/argvus-lock/LICENSE"

uninstall:
	rm -rf "$(DESTDIR)$(PREFIX)/share/argvus/lock"
	$(RM) "$(DESTDIR)$(PREFIX)/share/licenses/argvus-lock/LICENSE"

validate:
	@set -eu; \
	scripts=$$(find src -type f -name '*.sh' | sort); \
	if [ -n "$$scripts" ]; then \
		for script in $$scripts; do sh -n "$$script"; done; \
		if command -v shellcheck >/dev/null 2>&1; then \
			for script in $$scripts; do shellcheck -e SC1090 -e SC2034 "$$script"; done; \
		else \
			echo "shellcheck not found; skipped"; \
		fi; \
	fi; \
	configs=$$(find src/usr/share/argvus/lock/config -type f -name 'hyprlock.conf' | sort); \
	test -n "$$configs"; \
	for conf in $$configs; do \
		grep -q '^background {' "$$conf"; \
		grep -q '^input-field {' "$$conf"; \
		grep -q '^label {' "$$conf"; \
		grep -q 'hyprlock-wallpaper-blur.png' "$$conf"; \
	done; \
	count=$$(find src/usr/share/argvus/lock/config/themes -mindepth 2 -maxdepth 2 -type f -name 'hyprlock.conf' | wc -l); \
	if [ "$$count" -ne 10 ]; then \
		echo "expected 10 lock theme templates, found $$count" >&2; \
		exit 1; \
	fi
	@echo "argvus-lock validation ok"

release-archive:
	mkdir -p .release
	git archive --format=tar.gz --prefix="argvus-lock-$$(git rev-parse --short HEAD)/" \
		--output=".release/argvus-lock-$$(git rev-parse --short HEAD).tar.gz" HEAD

.PHONY: build

build:
	@tools/build-local-package.sh

clean:
	rm -rf dist
	rm -f packaging/arch/*.zst packaging/arch/*.tar.gz
