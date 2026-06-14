# SPDX-License-Identifier: AGPL-3.0-or-later

BUILD_DIR := build
BINARY := $(BUILD_DIR)/dastan
DUMP_TREE := $(BUILD_DIR)/dump-tree
FONTS_CONF := $(abspath $(BUILD_DIR)/dastan-fonts.conf)
CMARK_GFM_DIR := external/cmark-gfm

MESON ?= meson

.DEFAULT_GOAL := help

.PHONY: help init all build setup install run debug tree clean distclean reconfigure

help: ## Show available targets
	@echo "MarkViewer — build targets"
	@echo ""
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

all: build ## Build MarkViewer

init: ## Initialize submodules and context reference clones
	git submodule update --init --recursive
	@test -f $(CMARK_GFM_DIR)/src/cmark.c || (echo "dastan: $(CMARK_GFM_DIR) submodule empty — use: git clone --recurse-submodules …" >&2; exit 1)
	./scripts/fetch-context.sh

setup: init ## Configure the Meson build directory
	$(MESON) setup $(BUILD_DIR) .

build: init ## Compile MarkViewer
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
	FONTCONFIG_FILE=$(FONTS_CONF) $(BINARY) $(FILE)

debug: build ## Run with GTK Inspector (usage: make debug FILE=notes.md)
ifndef FILE
	$(error FILE is required. Example: make debug FILE=README.md)
endif
	FONTCONFIG_FILE=$(FONTS_CONF) GTK_DEBUG=inspector $(BINARY) $(FILE)

tree: build ## Dump AST with direction to YAML (usage: make tree FILE=notes.md [OUT=tree.yml])
ifndef FILE
	$(error FILE is required. Example: make tree FILE=README.md OUT=README-tree.yml)
endif
ifdef OUT
	$(DUMP_TREE) $(FILE) $(OUT)
else
	$(DUMP_TREE) $(FILE)
endif

reconfigure: ## Reconfigure the build directory from scratch
	$(MESON) setup $(BUILD_DIR) . --wipe
	$(MESON) compile -C $(BUILD_DIR)

clean: ## Remove compiled objects (keeps build configuration)
	@if [ ! -f $(BUILD_DIR)/build.ninja ]; then \
		echo "dastan: nothing to clean ($(BUILD_DIR) not configured)"; \
	else \
		$(MESON) compile -C $(BUILD_DIR) --clean; \
	fi

distclean: ## Delete the build directory
	rm -rf $(BUILD_DIR)