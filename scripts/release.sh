#!/bin/bash
set -euo pipefail

# Release script for markviewz
# Usage: ./scripts/release.sh [patch|minor|major]
#
# Steps:
#   1. Verify clean working tree on main
#   2. Bump version in all files
#   3. Verify package contents
#   4. Commit, tag, publish to npm
#   5. Push to GitHub (only after successful publish)
#   6. Update aggregated marketplace (daveremy/claude-plugins)

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

# Sync version across all files in a single node invocation
TODAY=$(date +%Y-%m-%d)
NEW_VERSION="$NEW_VERSION" OLD_VERSION="$OLD_VERSION" TODAY="$TODAY" node -e "
const fs = require('fs');
const v = process.env.NEW_VERSION;
const oldV = process.env.OLD_VERSION;
const today = process.env.TODAY;

// plugin.json
const pf = '.claude-plugin/plugin.json';
const pj = JSON.parse(fs.readFileSync(pf, 'utf8'));
pj.version = v;
fs.writeFileSync(pf, JSON.stringify(pj, null, 2) + '\n');

// marketplace.json
const mf = '.claude-plugin/marketplace.json';
const mj = JSON.parse(fs.readFileSync(mf, 'utf8'));
const mp = mj.plugins.find(p => p.name === 'markviewz');
if (mp) mp.version = v;
fs.writeFileSync(mf, JSON.stringify(mj, null, 2) + '\n');

// install.sh VERSION
const isf = 'install.sh';
fs.writeFileSync(isf, fs.readFileSync(isf, 'utf8').replace(/^VERSION=\"[^\"]*\"/m, 'VERSION=\"' + v + '\"'));

// Info.plist (CFBundleVersion and CFBundleShortVersionString)
const ipf = 'Info.plist';
let plist = fs.readFileSync(ipf, 'utf8');
plist = plist.replace(
  /(<key>CFBundleVersion<\/key>\s*<string>)[^<]*(<\/string>)/,
  '\$1' + v + '\$2'
);
plist = plist.replace(
  /(<key>CFBundleShortVersionString<\/key>\s*<string>)[^<]*(<\/string>)/,
  '\$1' + v + '\$2'
);
fs.writeFileSync(ipf, plist);

// CHANGELOG.md — add new version heading, update links
const cf = 'CHANGELOG.md';
let cl = fs.readFileSync(cf, 'utf8');
cl = cl.replace(
  '## [Unreleased]',
  '## [Unreleased]\n\n## [' + v + '] - ' + today
);
cl = cl.replace(
  /(\[Unreleased\]: .*\/)v[\d.]+\.\.\./,
  '\$1v' + v + '...'
);
// Insert new version comparison link right after [Unreleased] link
cl = cl.replace(
  /(\[Unreleased\]:.*\n)/,
  '\$1[' + v + ']: https://github.com/daveremy/Markviewz/compare/v' + oldV + '...v' + v + '\n'
);
fs.writeFileSync(cf, cl);
"

# 3. Verify package contents
echo ""
echo "Package contents:"
npm pack --dry-run 2>&1 | tail -10
echo ""

# 4. Commit, tag, publish
git add package.json .claude-plugin/plugin.json .claude-plugin/marketplace.json install.sh Info.plist CHANGELOG.md
git commit -m "$NEW_VERSION"
git tag "v$NEW_VERSION"

echo "Publishing to npm..."
npm publish --access public

# 5. Push (only after successful publish)
echo "Pushing to GitHub..."
git push origin main "v$NEW_VERSION"

# 6. Update aggregated marketplace
MARKETPLACE_DIR="${CLAUDE_PLUGINS_DIR:-$HOME/code/claude-plugins}"
MARKETPLACE_FILE="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"
PLUGIN_NAME="markviewz"

if [[ -d "$MARKETPLACE_DIR" ]]; then
  echo "Updating aggregated marketplace..."
  (
    cd "$MARKETPLACE_DIR"
    git pull --rebase origin main
    NEW_VERSION="$NEW_VERSION" PLUGIN_NAME="$PLUGIN_NAME" node -e "
const fs = require('fs');
const f = process.cwd() + '/.claude-plugin/marketplace.json';
const v = process.env.NEW_VERSION;
const name = process.env.PLUGIN_NAME;
const m = JSON.parse(fs.readFileSync(f, 'utf8'));
const plugin = m.plugins.find(p => p.name === name);
if (plugin) {
  plugin.version = v;
  fs.writeFileSync(f, JSON.stringify(m, null, 2) + '\n');
} else {
  console.error('Warning: ' + name + ' not found in marketplace.json');
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
