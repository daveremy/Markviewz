#!/bin/bash
# Install Markviewz binary and CLI wrapper.
# Clones the latest source and builds from scratch.
set -e

REPO_URL="https://github.com/daveremy/Markviewz.git"
BUILD_DIR="/tmp/Markviewz"

echo "Downloading Markviewz..."
rm -rf "$BUILD_DIR"
git clone --depth 1 "$REPO_URL" "$BUILD_DIR"

cd "$BUILD_DIR"
exec ./install.sh
