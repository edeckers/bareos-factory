#!/usr/bin/env bash

set -euo pipefail

# Publish an older-major Bareos bump as a branch + tracking issue, NOT a PR.
# The mainline branch ships a different major, so this must never merge into it.
# Commits whatever is in the working tree (run bump.sh first) onto branch
# bump/bareos-<version>, pushes it, and opens an issue linking it so a human can
# tag the release from that branch. Idempotent: if an open issue for this
# version already exists, does nothing.
#
# Usage: open-bump-issue.sh <version>
#
# Needs git and the `gh` CLI (authenticated; in CI export GH_TOKEN).

function cd_to_repo_root () {
  cd "$(dirname "${0}")/.."
}

cd_to_repo_root

VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  echo "Usage: ${0} <version>" >&2
  exit 1
fi

BRANCH="bump/bareos-${VERSION}"
TITLE="Release Bareos ${VERSION}"

# Already tracked? Nothing to do.
if gh issue list --state open --search "${TITLE} in:title" --json title --jq '.[].title' \
    | grep -qxF "${TITLE}"; then
  echo "Issue \"${TITLE}\" already open; nothing to do."
  exit 0
fi

# CI checkouts have no committer identity; a human running this keeps theirs.
if ! git config user.email >/dev/null; then
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
fi

git switch -C "${BRANCH}"

if git diff --quiet; then
  echo "Nothing to change for ${VERSION}, skipping."
  exit 0
fi

git commit -am "chore(deps): bump Bareos to ${VERSION}"

if git ls-remote --exit-code --heads origin "${BRANCH}" >/dev/null 2>&1; then
  git fetch origin "${BRANCH}"
  git push --force-with-lease origin "${BRANCH}"
else
  git push origin "${BRANCH}"
fi

REPO_URL="$(gh repo view --json url --jq '.url')"
gh issue create \
  --title "${TITLE}" \
  --body "Bareos ${VERSION} is available on an older major line we track, so it is shipped as a branch, not a develop PR.

Branch with the bump applied: ${REPO_URL}/tree/${BRANCH}

To release: review the branch, then push tag \`${VERSION}\` from it. That triggers the build-and-release workflow, which deletes the branch once the release is published. Do **not** merge this into develop."
