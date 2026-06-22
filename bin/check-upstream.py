#!/usr/bin/env python3

"""Fetch upstream Bareos releases from the GitHub API and print them as JSON
Lines, one {"tag", "date", "draft", "pre"} object per line.

Pure I/O: every "which of these do we want" decision (stable only, which major
lines, newer than what we ship) lives in filter-releases.py, so this stays a
dumb fetch you can eyeball or pipe elsewhere:

    check-upstream.py | filter-releases.py --since 24.0.9 --latest-majors 2

Stdlib only. Honours $GITHUB_TOKEN/$GH_TOKEN if set (just to dodge the
unauthenticated API rate limit); runs fine without one.
"""

import json
import os
import sys
import urllib.request

UPSTREAM_REPO = os.environ.get("BF_UPSTREAM_REPO", "bareos/bareos")


def fetch(url):
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "bareos-factory-check-upstream",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def main():
    releases = fetch(f"https://api.github.com/repos/{UPSTREAM_REPO}/releases?per_page=100")
    for release in releases:
        json.dump(
            {
                "tag": release["tag_name"],
                "date": release["published_at"],
                "draft": release["draft"],
                "pre": release["prerelease"],
            },
            sys.stdout,
        )
        sys.stdout.write("\n")


if __name__ == "__main__":
    main()
