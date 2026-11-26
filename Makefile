# Callisto — top-level build orchestration.
#
# The Makefile is a thin convenience layer over scripts/. All real logic
# lives there so CI can invoke the same commands without make.

.PHONY: iso run run-sw run-headless sync clean clean-all builder lint help

ISO := callisto-amd64.hybrid.iso

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

iso: ## Build the Callisto live ISO inside the builder container
	scripts/build-iso.sh

run: iso ## Boot the ISO in QEMU (GPU accelerated)
	scripts/run-qemu.sh

run-sw: iso ## Boot the ISO in QEMU (software rendering fallback)
	scripts/run-qemu.sh --sw

run-headless: iso ## Boot the ISO headless with serial output (CI smoke test)
	scripts/run-qemu.sh --headless

sync: ## Sync shell/ and configs/ into live-build includes.chroot
	scripts/sync-configs.sh

builder: ## (Re)build the containerized build environment
	sudo podman build -f Dockerfile.builder -t callisto-iso-builder .

lint: ## Run static checks on shell scripts and configs
	shellcheck scripts/*.sh live-build/auto/config live-build/config/hooks/live/* 2>/dev/null || echo "shellcheck not installed — skipping"

clean: ## Remove build artifacts, keep caches (fast rebuild)
	sudo podman run --rm --privileged -v $(CURDIR):/work:z callisto-iso-builder -c 'cd /work/live-build && lb clean' || true
	rm -f $(ISO) SHA256SUMS

clean-all: clean ## Remove build artifacts AND caches (full bootstrap on next build)
	rm -rf live-build/cache live-build/chroot live-build/binary live-build/.build
