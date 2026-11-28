# Callisto. A thin layer over scripts/, so that CI and people run the same things.

# What `make iso` builds. ISO=path boots another one (vm, run, smoke).
BUILT := callisto-amd64.hybrid.iso
PAGE ?=
NAME ?= shot
SHELL_SCRIPTS = scripts/*.sh bin/callisto-clip-store bin/callisto-greeter bin/callisto-settings bin/start-callisto \
	configs/installer/install-* configs/installer/callisto-install \
	configs/installer/live/setxkbmap configs/installer/live/callisto-install-hint \
	live-build/auto/config live-build/config/hooks/live/010-callisto-setup.hook.chroot \
	live-build/config/hooks/normal/9100-callisto-boot-menu.hook.binary

.DEFAULT_GOAL := help
.PHONY: help check lint tokens iso sync shell shell-watch shell-window shell-test \
	vm vm-push vm-watch vm-shot vm-gpu vm-perf vm-down run run-sw smoke down images clean clean-all

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-13s\033[0m %s\n", $$1, $$2}'

check: lint ## Everything that needs no VM or container: lint, tokens, contrast, tests
	python3 scripts/lint-literals.py
	python3 scripts/generate-theme.py --check
	python3 scripts/check-contrast.py
	python3 scripts/test-settingsd.py

lint: ## Check shell scripts and Python
	shellcheck -S warning $(SHELL_SCRIPTS)
	python3 -c 'import ast, sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]' bin/callisto-apply bin/callisto-settingsd bin/callisto-clip bin/callisto-shot scripts/*.py containers/*.py

tokens: ## Regenerate the theme from design/tokens.json
	python3 scripts/generate-theme.py

iso: ## Build the live ISO (rootless podman)
	scripts/build-iso.sh

sync: ## Stage the repository into live-build's includes.chroot
	scripts/sync-configs.sh

# --- The shell, in a container -----------------------------------------------
shell: ## Load the shell, or PAGE=power; screenshots in .out/shell/
	scripts/shell.py $(or $(PAGE),shell)

shell-watch: ## The same again on every save: PAGE=power
	scripts/shell.py --watch $(or $(PAGE),shell)

shell-window: ## Live in a window on your desktop: PAGE=power
	scripts/shell.py --window $(or $(PAGE),shell)

shell-test: ## Every entry point and gallery page
	scripts/shell.py

# --- The virtual machine -----------------------------------------------------
vm: ## Boot the ISO headless with 3D and put the working tree on it
	scripts/vm.py up

vm-push: ## Put the working tree on the running machine
	scripts/vm.py push

vm-watch: ## Push on every save
	scripts/vm.py push --watch

vm-shot: ## Screenshot to .out/vm/shot.png, or NAME=launcher
	scripts/vm.py shot $(NAME)

vm-gpu: ## Check that the guest's graphics are accelerated
	scripts/vm.py gpu

vm-perf: ## Measure the shell: startup, memory, idle cpu
	scripts/vm.py perf

vm-down: ## Stop the machine
	scripts/vm.py down

run: ## Boot the ISO as shipped, in a window
	scripts/vm.py up --fresh --window --as-shipped

run-sw: ## The same with software rendering
	scripts/vm.py up --fresh --window --as-shipped --gpu sw

smoke: ## Boot the ISO as shipped, headless, and check it (CI)
	scripts/vm.py smoke

# --- Housekeeping ------------------------------------------------------------
down: ## Stop the machine and the shell's container
	scripts/vm.py down
	scripts/shell.py --down

images: ## Rebuild the container images from fresh bases
	podman build --pull=newer -f containers/builder.Dockerfile -t callisto-iso-builder .
	python3 -B -c 'import sys; sys.path.insert(0, "scripts"); import shell, vm; shell.image(True); vm.vm_image(True)'

clean: down ## Remove build outputs, keep package caches
	podman run --rm --privileged -v $(CURDIR):/work:z callisto-iso-builder -c 'cd /work/live-build && lb clean'
	rm -rf $(BUILT) SHA256SUMS .out

clean-all: clean ## Remove the caches too (the next build starts from nothing)
	podman unshare rm -rf live-build/cache live-build/chroot live-build/binary live-build/.build
