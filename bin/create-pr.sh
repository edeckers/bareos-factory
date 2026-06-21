#!/usr/bin/env bash

set -euo pipefail

# Open a pull request for a Bareos version bump. Commits whatever is already in
# the working tree (run bump.sh first) onto branch bump/bareos-<version>, pushes,
# and opens a PR. Idempotent: if a PR is already open for that branch it leaves
# everything untouched and exits.
#
# Usage: create-pr.sh <version> [base-branch]
#
# Needs git and the `gh` CLI (authenticated; in CI export GH_TOKEN). The base
# branch defaults to $BF_BASE_BRANCH, else the current branch.

function cd_to_repo_root () {
  cd "$(dirname "${0}")/.."
}

cd_to_repo_root

VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  echo "Usage: ${0} <version> [base-branch]" >&2
  exit 1
fi

BASE="${2:-${BF_BASE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}}"
BRANCH="bump/bareos-${VERSION}"

# Already have an open PR for this version? Nothing to do.
STATE="$(gh pr view "${BRANCH}" --json state --jq '.state' 2>/dev/null || true)"
if [[ "${STATE}" == "OPEN" ]]; then
  echo "PR for ${BRANCH} already open; leaving it untouched."
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
  # Stale branch left by a previously closed PR. Refresh it, but lease-guard so a
  # concurrent push is never silently clobbered.
  git fetch origin "${BRANCH}"
  git push --force-with-lease origin "${BRANCH}"
else
  git push origin "${BRANCH}"
fi

gh pr create --base "${BASE}" --head "${BRANCH}" \
  --title "chore(deps): bump Bareos to ${VERSION}" \
  --body "Automated bump to Bareos ${VERSION}.

Upstream release: https://github.com/bareos/bareos/releases/tag/Release/${VERSION}

Merging records the bump. Pushing tag \`${VERSION}\` is what triggers the build-and-release workflow."
