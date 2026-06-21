#!/usr/bin/env bash

set -e

# Single source of truth for the Bareos version. The blanket replace below
# rewrites this file too (it holds exactly CURRENT_VERSION), so it advances
# along with everything else.
VERSION_FILE=".bareos-version"
if [ ! -s "$VERSION_FILE" ]; then
    echo "Error: $VERSION_FILE is missing or empty" >&2
    exit 1
fi
CURRENT_VERSION="$(cat "$VERSION_FILE")"

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <new_version>"
    echo "Example: $0 25.0.3"
    echo ""
    echo "Current version: $CURRENT_VERSION"
    exit 1
fi

NEW_VERSION="$1"

# Validate version format (basic check for X.Y.Z)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 25.0.3)"
    exit 1
fi

echo "Current version: $CURRENT_VERSION"
echo "New version: $NEW_VERSION"
echo ""

echo "Updating all files in repository..."

# Skip .github/workflows: the bot's token can't push workflow changes, and the
# version there is read from .bareos-version, not hardcoded, so nothing to bump.
# Use different sed syntax for macOS vs Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    find . -type f -not -path "./.git/*" -not -path "./.github/workflows/*" -exec sed -i '' "s/$CURRENT_VERSION/$NEW_VERSION/g" {} +
else
    # Linux
    find . -type f -not -path "./.git/*" -not -path "./.github/workflows/*" -exec sed -i "s/$CURRENT_VERSION/$NEW_VERSION/g" {} +
fi

echo ""
echo "✅ Version bumped from $CURRENT_VERSION to $NEW_VERSION"
echo ""
echo "Changed files:"
git diff

echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit changes: git commit -am 'Bump version to $NEW_VERSION'"
echo "  3. Create tag: git tag $NEW_VERSION"
echo "  4. Push: git push && git push --tags"

