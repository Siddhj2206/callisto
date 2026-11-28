# Callisto. A thin layer over scripts/, so that CI and people run the same things.

ISO := callisto-amd64.hybrid.iso
SHELL_SCRIPTS = scripts/*.sh containers/*.sh bin/callisto-clip-store bin/callisto-greeter bin/callisto-settings bin/start-callisto \
	configs/installer/install-* configs/installer/callisto-install \
	configs/installer/live/setxkbmap configs/installer/live/callisto-install-hint \
	live-build/auto/config live-build/config/hooks/live/010-callisto-setup.hook.chroot \
	live-build/config/hooks/normal/9100-callisto-boot-menu.hook.binary

.DEFAULT_GOAL := help
.PHONY: help check lint tokens iso run run-sw smoke sync shell-test images clean clean-all

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

check: lint ## Everything that needs no VM or container: lint, tokens, contrast, tests
	python3 scripts/lint-literals.py
	python3 scripts/generate-theme.py --check
	python3 scripts/check-contrast.py
	python3 scripts/test-settingsd.py

lint: ## Check shell scripts and Python
	shellcheck -S warning $(SHELL_SCRIPTS)
	python3 -c 'import ast, sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]' bin/callisto-apply bin/callisto-settingsd bin/callisto-clip bin/callisto-shot scripts/*.py

tokens: ## Regenerate the theme from design/tokens.json
	python3 scripts/generate-theme.py

iso: ## Build the live ISO (rootless podman)
	scripts/build-iso.sh

run: ## Boot the built ISO in QEMU
	scripts/run-qemu.sh

run-sw: ## Boot it with software rendering
	scripts/run-qemu.sh --sw

smoke: ## Boot it headless and keep screenshots in .out/iso/
	scripts/test-iso.sh

sync: ## Stage the repository into live-build's includes.chroot
	scripts/sync-configs.sh

shell-test: ## Load every entry point and gallery page in a container
	scripts/test-shell-all.sh

images: ## (Re)build the two container images
	podman build -f containers/builder.Dockerfile -t callisto-iso-builder .
	podman build -f containers/shelltest.Dockerfile -t callisto-shelltest .

clean: ## Remove build outputs, keep package caches
	podman run --rm --privileged -v $(CURDIR):/work:z callisto-iso-builder -c 'cd /work/live-build && lb clean'
	rm -rf $(ISO) SHA256SUMS .out

clean-all: clean ## Remove the caches too (the next build starts from nothing)
	podman unshare rm -rf live-build/cache live-build/chroot live-build/binary live-build/.build
