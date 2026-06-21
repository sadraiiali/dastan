#!/usr/bin/env bash

rm -f io.github.markviewer.flatpak
rm -rf _build ; mkdir _build
rm -rf _repo ; mkdir _repo

STATE_DIR=~/.cache/dastan/flatpak-builder
BRANCH=main

flatpak-builder \
    --ccache --force-clean \
    --repo=_repo --state-dir=$STATE_DIR \
    --default-branch=$BRANCH \
    _build io.github.markviewer.json

flatpak build-bundle \
    _repo io.github.markviewer.flatpak io.github.markviewer $BRANCH