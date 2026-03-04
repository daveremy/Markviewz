#!/bin/bash
set -e

echo "Building Markviewz..."
swift build -c release 2>&1

APP_DIR="/Applications/Markviewz.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS"

cp .build/release/Markviewz "$MACOS/Markviewz"
cp Info.plist "$CONTENTS/Info.plist"

# Create CLI symlink — try /usr/local/bin, fall back to ~/bin
echo "Installing CLI tool..."
if [ -w /usr/local/bin ] && ln -sf "$MACOS/Markviewz" /usr/local/bin/markviewz 2>/dev/null; then
    CLI_PATH="/usr/local/bin/markviewz"
else
    mkdir -p "$HOME/bin"
    ln -sf "$MACOS/Markviewz" "$HOME/bin/markviewz"
    CLI_PATH="$HOME/bin/markviewz"
    echo "  (Add ~/bin to your PATH if not already there)"
fi

echo ""
echo "Done! Markviewz installed to:"
echo "  App:  $APP_DIR"
echo "  CLI:  $CLI_PATH"
echo ""
echo "Usage:"
echo "  open -a Markviewz file.md"
echo "  markviewz file.md"
