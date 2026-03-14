#!/bin/bash
# npm postinstall hook — builds and installs Markviewz.app from source.
# Runs automatically when Claude Code installs the plugin via npx.
set -e

# macOS only
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Markviewz is macOS-only. Skipping binary install."
  exit 0
fi

# Requires git and Swift toolchain
if ! command -v git &>/dev/null; then
  echo "Error: git is required to install Markviewz."
  exit 1
fi

if ! command -v swift &>/dev/null; then
  echo "Error: Swift is required to build Markviewz."
  echo "Install Xcode from the App Store or the Swift toolchain from https://swift.org"
  exit 1
fi

REPO_URL="https://github.com/daveremy/Markviewz.git"
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Installing Markviewz..."
git clone --depth 1 "$REPO_URL" "$BUILD_DIR"

cd "$BUILD_DIR"
./install.sh
