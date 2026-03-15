#!/bin/bash
set -e

VERSION="0.1.0"

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

write_cli_script() {
    cat << 'WRAPPER_EOF'
#!/bin/bash
MARKVIEWZ_VERSION="__VERSION__"

if [ $# -eq 1 ]; then
    case "$1" in
        --version|-v)
            echo "markviewz $MARKVIEWZ_VERSION"
            exit 0
            ;;
        --help|-h)
            echo "Usage: markviewz [file.md]"
            echo "       markviewz --version"
            echo "       markviewz update"
            exit 0
            ;;
        update)
            echo "Updating Markviewz..."
            rm -rf /tmp/Markviewz
            git clone --depth 1 https://github.com/daveremy/Markviewz.git /tmp/Markviewz && \
                cd /tmp/Markviewz && exec ./install.sh
            echo "Error: Failed to clone repository." >&2
            exit 1
            ;;
    esac
fi

if [ $# -eq 0 ]; then
    open -a Markviewz
else
    open -a Markviewz "$@"
fi
WRAPPER_EOF
}

if [ -w /usr/local/bin ]; then
    rm -f /usr/local/bin/markviewz
    write_cli_script | sed "s/__VERSION__/$VERSION/" > /usr/local/bin/markviewz
    chmod +x /usr/local/bin/markviewz
    CLI_PATH="/usr/local/bin/markviewz"
else
    mkdir -p "$HOME/.local/bin"
    rm -f "$HOME/.local/bin/markviewz"
    write_cli_script | sed "s/__VERSION__/$VERSION/" > "$HOME/.local/bin/markviewz"
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
