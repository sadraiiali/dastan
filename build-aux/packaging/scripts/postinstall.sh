#!/bin/sh
set -e

if [ -d /usr/share/glib-2.0/schemas ]; then
  glib-compile-schemas /usr/share/glib-2.0/schemas
fi