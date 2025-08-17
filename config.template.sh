#!/usr/bin/env bash

# Absolute path to the root of the Wine installation.
# This directory should contain "bin", "include", "lib" and "share".
CFG_WINE_ROOT="/opt/wine-devel"

# Absolute path to the git clone root of the Wine source
CFG_SRC_DIR="/my/clone/of/wine"

# Absolute path to the root of the build output
# After a make/build command, this directory should contain "dlls"
# If the binaries are built in-tree: Same as $CFG_SRC_DIR
CFG_BUILD_DIR="$CFG_SRC_DIR"

# The WINEPREFIX that shall be used by this script
# Set to empty to use the global default (environment variable or ~/.wine)
CFG_ENV_WINEPREFIX=""

# Default WINEDEBUG channels
# https://gitlab.winehq.org/wine/wine/-/wikis/Debug-Channels#useful-channels
# Channels provided by the WINEDEBUG environment variable are appended.
CFG_ENV_WINEDEBUG=+timestamp
