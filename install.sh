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

# Create CLI wrapper script (uses `open -a` to reuse running instance)
echo "Installing CLI tool..."
CLI_SCRIPT='#!/bin/bash
if [ $# -eq 0 ]; then
    open -a Markviewz
else
    open -a Markviewz "$@"
fi'

if [ -w /usr/local/bin ]; then
    rm -f /usr/local/bin/markviewz
    echo "$CLI_SCRIPT" > /usr/local/bin/markviewz
    chmod +x /usr/local/bin/markviewz
    CLI_PATH="/usr/local/bin/markviewz"
else
    mkdir -p "$HOME/.local/bin"
    rm -f "$HOME/.local/bin/markviewz"
    echo "$CLI_SCRIPT" > "$HOME/.local/bin/markviewz"
    chmod +x "$HOME/.local/bin/markviewz"
    CLI_PATH="$HOME/.local/bin/markviewz"
    echo "  (Add ~/.local/bin to your PATH if not already there)"
fi

echo ""
echo "Done! Markviewz installed to:"
echo "  App:  $APP_DIR"
echo "  CLI:  $CLI_PATH"
echo ""
echo "Usage:"
echo "  open -a Markviewz file.md"
echo "  markviewz file.md"
