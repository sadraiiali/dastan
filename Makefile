# SPDX-License-Identifier: AGPL-3.0-or-later

BUILD_DIR := build
BINARY := $(BUILD_DIR)/src/dastan
DUMP_TREE := $(BUILD_DIR)/src/dump-tree
FONTS_CONF := $(abspath $(BUILD_DIR)/data/dastan-fonts.conf)
CMARK_GFM_DIR := external/cmark-gfm

MESON ?= meson

.DEFAULT_GOAL := help

.PHONY: help init init-build all build setup install run debug tree test clean dist distclean reconfigure

help: ## Show available targets
	@echo "MarkViewer — build targets"
	@echo ""
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

all: build ## Build MarkViewer

LASEM_DIR := external/lasem

init-build: ## Initialize the cmark-gfm and lasem submodules (required to compile)
	git submodule update --init --recursive external/cmark-gfm external/lasem
	@chmod +x external/lasem-meson/patch-lasem.sh
	@./external/lasem-meson/patch-lasem.sh external/lasem
	@test -f $(CMARK_GFM_DIR)/src/cmark.c || (echo "dastan: $(CMARK_GFM_DIR) submodule empty — use: git clone --recurse-submodules …" >&2; exit 1)
	@test -f $(LASEM_DIR)/src/lsm.c || (echo "dastan: $(LASEM_DIR) submodule empty — use: git clone --recurse-submodules …" >&2; exit 1)
	@ln -sfn ../lasem-meson/generated external/lasem/generated
	@test -f external/lasem-meson/generated/lsmdomenumtypes.c || (echo "dastan: missing vendored Lasem enum files — run: python3 external/lasem-meson/generate-enums.py (requires glib2-devel)" >&2; exit 1)

init: init-build ## Initialize submodules and context reference clones
	./build-aux/scripts/fetch-context.sh

setup: init ## Configure the Meson build directory
	$(MESON) setup $(BUILD_DIR) .

build: init-build ## Compile MarkViewer
	@if [ ! -f $(BUILD_DIR)/build.ninja ]; then \
		$(MESON) setup $(BUILD_DIR) .; \
	fi
	$(MESON) compile -C $(BUILD_DIR)

install: build ## Install dastan (usage: make install [DESTDIR=...])
	$(MESON) install -C $(BUILD_DIR) $(if $(DESTDIR),--destdir $(DESTDIR),)

run: build ## Run MarkViewer (usage: make run FILE=notes.md)
ifndef FILE
	$(error FILE is required. Example: make run FILE=README.md)
endif
	FONTCONFIG_FILE=$(FONTS_CONF) GSETTINGS_SCHEMA_DIR=$(abspath $(BUILD_DIR)/data/gsettings) $(BINARY) $(FILE)

debug: build ## Run with GTK Inspector (usage: make debug FILE=notes.md)
ifndef FILE
	$(error FILE is required. Example: make debug FILE=README.md)
endif
	FONTCONFIG_FILE=$(FONTS_CONF) GSETTINGS_SCHEMA_DIR=$(abspath $(BUILD_DIR)/data/gsettings) GTK_DEBUG=inspector $(BINARY) $(FILE)

tree: build ## Dump AST with direction to YAML (usage: make tree FILE=notes.md [OUT=tree.yml])
ifndef FILE
	$(error FILE is required. Example: make tree FILE=README.md OUT=README-tree.yml)
endif
ifdef OUT
	$(DUMP_TREE) $(FILE) $(OUT)
else
	$(DUMP_TREE) $(FILE)
endif

test: build ## Run unit tests (usage: make test)
	xvfb-run -a $(MESON) test -C $(BUILD_DIR) --print-errorlogs

reconfigure: ## Reconfigure the build directory from scratch
	$(MESON) setup $(BUILD_DIR) . --wipe
	$(MESON) compile -C $(BUILD_DIR)

dist: init-build ## Build .deb, .rpm, Arch, and AppImage packages in dist/
	@chmod +x build-aux/scripts/dist.sh build-aux/packaging/scripts/postinstall.sh build-aux/packaging/scripts/postremove.sh
	@./build-aux/scripts/dist.sh

clean: ## Remove compiled objects (keeps build configuration)
	@if [ ! -f $(BUILD_DIR)/build.ninja ]; then \
		echo "dastan: nothing to clean ($(BUILD_DIR) not configured)"; \
	else \
		$(MESON) compile -C $(BUILD_DIR) --clean; \
	fi

distclean: ## Delete the build directory
	rm -rf $(BUILD_DIR)