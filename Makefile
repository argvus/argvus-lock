.PHONY: help build package install install-package clean validate lint lint-shell spellcheck changelog

.DEFAULT_GOAL := help

help:
	@echo "Available targets:"
	@echo "  make build           - build the package into build/"
	@echo "  make package         - alias for make build"
	@echo "  make install         - install the single local package (sudo pacman -U)"
	@echo "  make clean           - remove build/ outputs"
	@echo "  make validate        - run required repository and PKGBUILD checks"
	@echo "  make lint            - run local static checks"
	@echo "  make spellcheck      - run cspell (if installed)"
	@echo "  make changelog       - regenerate CHANGELOG.md with git-cliff"

build:
	@tools/sh/pkgbuild_local.sh

package: build

install:
	@set -e; \
	package="$$(find build/dist -maxdepth 1 -type f -name '*.pkg.tar.zst' -print | sort | head -n 1)"; \
	count="$$(find build/dist -maxdepth 1 -type f -name '*.pkg.tar.zst' -print | wc -l)"; \
	if [ "$$count" -ne 1 ] || [ -z "$$package" ]; then \
		echo "Expected exactly one package in build/dist; run 'make clean && make build'." >&2; \
		exit 1; \
	fi; \
	sudo pacman -U "$$package"

install-package: install

validate:
	@tools/sh/validate.sh

lint-shell:
	@for root in tools packaging/arch/common src; do \
		if [ -d "$$root" ]; then \
			find "$$root" -type f -name '*.sh' -exec shellcheck -e SC1090 -e SC2034 -e SC2154 {} +; \
		fi; \
	done
	@for root in tools packaging/arch/common src; do \
		if [ -d "$$root" ]; then \
			find "$$root" -type f -name '*.sh' -exec bash -n {} +; \
		fi; \
	done
	@git diff --check
	@echo "Lint Shell OK"

lint: lint-shell

spellcheck:
	@if command -v cspell >/dev/null 2>&1; then \
		cspell --config cspell.json .; \
	else \
		echo "cspell is not installed; skipping (CI runs it)." >&2; \
	fi

changelog:
	@git-cliff -o CHANGELOG.md

clean:
	rm -rf -- build/
