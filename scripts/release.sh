#!/bin/bash
set -euo pipefail

# Release script for markviewz
# Usage: ./scripts/release.sh [patch|minor|major]
#
# Steps:
#   1. Verify clean working tree on main
#   2. Bump version (package.json, plugin.json, marketplace.json, install.sh, Info.plist, CHANGELOG.md)
#   3. Verify package contents
#   4. Commit version bump
#   5. Git tag
#   6. Publish to npm
#   7. Push to GitHub (only after successful publish)
#   8. Update aggregated marketplace (daveremy/claude-plugins)

BUMP="${1:-patch}"

if [[ "$BUMP" != "patch" && "$BUMP" != "minor" && "$BUMP" != "major" ]]; then
  echo "Usage: $0 [patch|minor|major]"
  exit 1
fi

# 1. Must be on main with a clean working tree
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "Error: must be on 'main' branch to release (current: $CURRENT_BRANCH)."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is not clean. Commit or stash changes first."
  exit 1
fi

# 2. Bump version
OLD_VERSION=$(node -p "require('./package.json').version")
npm version "$BUMP" --no-git-tag-version --no-commit-hooks > /dev/null
NEW_VERSION=$(node -p "require('./package.json').version")
echo "Version: $OLD_VERSION → $NEW_VERSION"

# Sync plugin.json
node -e "
const fs = require('fs');
const f = '.claude-plugin/plugin.json';
const j = JSON.parse(fs.readFileSync(f, 'utf8'));
j.version = '$NEW_VERSION';
fs.writeFileSync(f, JSON.stringify(j, null, 2) + '\n');
"

# Sync marketplace.json
node -e "
const fs = require('fs');
const f = '.claude-plugin/marketplace.json';
const j = JSON.parse(fs.readFileSync(f, 'utf8'));
j.plugins[0].version = '$NEW_VERSION';
fs.writeFileSync(f, JSON.stringify(j, null, 2) + '\n');
"

# Sync install.sh VERSION
node -e "
const fs = require('fs');
const f = 'install.sh';
fs.writeFileSync(f, fs.readFileSync(f, 'utf8').replace(/^VERSION=\"[^\"]*\"/m, 'VERSION=\"$NEW_VERSION\"'));
"

# Sync Info.plist (both CFBundleVersion and CFBundleShortVersionString)
node -e "
const fs = require('fs');
const f = 'Info.plist';
let content = fs.readFileSync(f, 'utf8');
// Replace the version string that follows CFBundleVersion
content = content.replace(
  /(<key>CFBundleVersion<\/key>\s*<string>)[^<]*(<\/string>)/,
  '\$1$NEW_VERSION\$2'
);
// Replace the version string that follows CFBundleShortVersionString
content = content.replace(
  /(<key>CFBundleShortVersionString<\/key>\s*<string>)[^<]*(<\/string>)/,
  '\$1$NEW_VERSION\$2'
);
fs.writeFileSync(f, content);
"

# Sync CHANGELOG.md — rename [Unreleased] to new version with date
TODAY=$(date +%Y-%m-%d)
node -e "
const fs = require('fs');
const f = 'CHANGELOG.md';
let content = fs.readFileSync(f, 'utf8');
content = content.replace(
  '## [Unreleased]',
  '## [Unreleased]\n\n## [$NEW_VERSION] - $TODAY'
);
// Update compare links
content = content.replace(
  /\[Unreleased\]: (.*\/)v[^.]*\.\.\./,
  '[Unreleased]: \$1v$NEW_VERSION...'
);
// Add new version link before the last version link
const lastVersionLink = content.match(/\[[0-9]+\.[0-9]+\.[0-9]+\]: /);
if (lastVersionLink) {
  content = content.replace(
    lastVersionLink[0],
    '[$NEW_VERSION]: https://github.com/daveremy/Markviewz/compare/v$OLD_VERSION...v$NEW_VERSION\n' + lastVersionLink[0]
  );
}
fs.writeFileSync(f, content);
"

# 3. Verify package contents
echo ""
echo "Package contents:"
npm pack --dry-run 2>&1 | tail -10
echo ""

# 4. Commit
git add package.json .claude-plugin/plugin.json .claude-plugin/marketplace.json install.sh Info.plist CHANGELOG.md
git commit -m "$NEW_VERSION"

# 5. Tag
git tag "v$NEW_VERSION"

# 6. Publish (before push — if this fails, no tag/commit escapes to remote)
echo "Publishing to npm..."
npm publish --access public

# 7. Push (only after successful publish)
echo "Pushing to GitHub..."
git push origin main
git push origin "v$NEW_VERSION"

# 8. Update aggregated marketplace
MARKETPLACE_DIR="$HOME/code/claude-plugins"
MARKETPLACE_FILE="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"
PLUGIN_NAME="markviewz"

if [[ -d "$MARKETPLACE_DIR" ]]; then
  echo "Updating aggregated marketplace..."
  (
    cd "$MARKETPLACE_DIR"
    git pull --rebase origin main
    node -e "
const fs = require('fs');
const f = '$MARKETPLACE_FILE';
const m = JSON.parse(fs.readFileSync(f, 'utf8'));
const plugin = m.plugins.find(p => p.name === '$PLUGIN_NAME');
if (plugin) {
  plugin.version = '$NEW_VERSION';
  fs.writeFileSync(f, JSON.stringify(m, null, 2) + '\n');
} else {
  console.error('Warning: $PLUGIN_NAME not found in marketplace.json');
  process.exit(1);
}
"
    git add .claude-plugin/marketplace.json
    git commit -m "Bump $PLUGIN_NAME to v$NEW_VERSION"
    git push origin main
  )
  echo "Marketplace updated."
else
  echo "Warning: $MARKETPLACE_DIR not found — update marketplace manually."
fi

echo ""
echo "Released markviewz@$NEW_VERSION"
echo "  npm: https://www.npmjs.com/package/markviewz"
echo "  tag: https://github.com/daveremy/Markviewz/releases/tag/v$NEW_VERSION"
