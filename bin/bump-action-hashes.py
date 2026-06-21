#!/usr/bin/env python3

"""Refresh SHA-pinned GitHub Actions in .github/workflows/*.

For every `uses: owner/repo@<40-hex> # vX.Y.Z` pin, look up the newest release
on the SAME major line as the comment, resolve its commit SHA, and rewrite the
pin in place. Major-version jumps are reported but never applied automatically,
so an intentional hold (e.g. a stale v1 line) is preserved and a human decides
when to cross a major.

Stdlib only. Honours $GITHUB_TOKEN/$GH_TOKEN to dodge the API rate limit.

Previews by default; pass --apply to write. Review `git diff` and commit
yourself.

Usage:
  bin/bump-action-hashes.py [--apply] [workflow-dir]   (default dir: .github/workflows)
"""

import json
import os
import re
import sys
import urllib.request
from pathlib import Path

PIN_RE = re.compile(
    r"(?P<prefix>uses:\s*)(?P<repo>[\w.-]+/[\w.-]+)@(?P<sha>[0-9a-f]{40})"
    r"\s*#\s*v?(?P<ver>\d+\.\d+\.\d+)"
)
SEMVER_TAG_RE = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")


def fetch(url):
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "bump-action-hashes"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=30) as r:
        return json.load(r)


def semver_tags(repo):
    """Return [(version_tuple, tag_name, commit_sha)] for the repo's semver tags."""
    out = []
    for page in (1, 2):
        items = fetch(f"https://api.github.com/repos/{repo}/tags?per_page=100&page={page}")
        for tag in items:
            match = SEMVER_TAG_RE.match(tag["name"])
            if match:
                out.append((tuple(int(g) for g in match.groups()), tag["name"], tag["commit"]["sha"]))
        if len(items) < 100:
            break
    return out


def main():
    args = list(sys.argv[1:])
    apply = "--apply" in args
    args = [a for a in args if a != "--apply"]
    workflow_dir = Path(args[0] if args else ".github/workflows")

    files = sorted(workflow_dir.glob("*.yml")) + sorted(workflow_dir.glob("*.yaml"))
    if not files:
        sys.exit(f"No workflow files under {workflow_dir}")

    tag_cache = {}
    applied, held, current = {}, {}, {}  # keyed by repo so each appears once

    for path in files:
        text = path.read_text()
        changed = False

        def replace(m):
            nonlocal changed
            repo, sha, ver = m["repo"], m["sha"], m["ver"]
            cur = tuple(int(p) for p in ver.split("."))
            if repo not in tag_cache:
                tag_cache[repo] = semver_tags(repo)
            tags = tag_cache[repo]
            if not tags:
                current[repo] = f"{repo}: no semver tags found, left at v{ver}"
                return m[0]

            same_major = [t for t in tags if t[0][0] == cur[0]]
            newest_overall = max(tags)
            if newest_overall[0][0] > cur[0]:
                held[repo] = f"{repo}: v{ver} -> {newest_overall[1]} available (major jump, NOT applied)"

            if not same_major:
                current[repo] = f"{repo}: v{ver}"
                return m[0]
            newest = max(same_major)
            if newest[2] == sha:
                current[repo] = f"{repo}: v{ver} (already newest {cur[0]}.x)"
                return m[0]

            changed = True
            applied[repo] = f"{repo}: v{ver} -> {newest[1]}"
            return f"{m['prefix']}{repo}@{newest[2]} # {newest[1]}"

        new_text = PIN_RE.sub(replace, text)
        if changed and apply:
            path.write_text(new_text)

    def section(title, rows):
        print(title)
        for row in sorted(rows.values()) or ["  (none)"]:
            print(f"  {row}")
        print()

    print(f"\n{'APPLYING' if apply else 'DRY RUN (use --apply to write)'}: action pin refresh\n")
    section("Updated:", applied)
    section("Held back (major upgrade available):", held)
    section("Already current:", current)


if __name__ == "__main__":
    main()
