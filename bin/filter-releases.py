#!/usr/bin/env python3

"""Filter the JSON Lines stream from check-upstream.py down to the Bareos
versions we are missing, and print them one per line, sorted.

This is where release-selection policy lives. A release qualifies when it is:
  * not a draft and not a pre-release,
  * tagged Release/X.Y.Z,
  * on a major line we track, and
  * newer than the highest version we already ship on that same major line
    (the per-major floor), and not on the skip list.

Major lines come from one of:
  --majors 24,25     explicit set
  --latest-majors N  the N highest majors present upstream
  (neither)          all majors

The per-major floor is what keeps this honest. We do not back-fill: if we shipped
24.0.0 then jumped to 24.0.8, the floor is 24.0.8 and 24.0.1..24.0.7 are never
proposed. A major we have no release for at all is treated as new and starts at
upstream's current head (one PR), not its whole history.

  --have 24.0.8,25.0.3   versions we already ship (our git tags)
  --skip-file PATH       versions to never propose (one X.Y.Z per line; blank
                         lines and # comments ignored)

    check-upstream.py | filter-releases.py --have "$(git tag | paste -sd,)" \\
        --latest-majors 2 --skip-file .bareos-skip-releases

Stdlib only, reads stdin, writes stdout.
"""

import argparse
import json
import re
import sys
from pathlib import Path

RELEASE_RE = re.compile(r"^Release/(\d+\.\d+\.\d+)$")
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")


def version_key(version):
    return tuple(int(part) for part in version.split("."))


def major(version):
    return version_key(version)[0]


def parse_versions(value):
    return {part.strip() for part in (value or "").split(",") if part.strip()}


def read_skip(path):
    if not path:
        return set()
    skip = set()
    for line in Path(path).read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            skip.add(line)
    return skip


def selected_majors(args, upstream):
    if args.majors is not None:
        return {int(part) for part in args.majors.split(",") if part.strip()}
    majors = {major(v) for v in upstream}
    if args.latest_majors is not None:
        return set(sorted(majors, reverse=True)[: args.latest_majors])
    return majors


def missing(upstream, have, skip, majors):
    result = set()
    for line in majors:
        on_line = sorted((v for v in upstream if major(v) == line), key=version_key)
        if not on_line:
            continue
        have_on_line = [v for v in have if major(v) == line]
        if have_on_line:
            floor = max(have_on_line, key=version_key)
            candidates = [v for v in on_line if version_key(v) > version_key(floor)]
        else:
            candidates = [on_line[-1]]  # new major: start at upstream head
        result.update(v for v in candidates if v not in have and v not in skip)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--have",
        metavar="X.Y.Z,...",
        help="versions we already ship; sets the per-major floor",
    )
    parser.add_argument(
        "--skip-file",
        metavar="PATH",
        help="file of versions to never propose (one X.Y.Z per line, # comments)",
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--majors", metavar="N,N", help="explicit major lines to keep")
    group.add_argument(
        "--latest-majors",
        type=int,
        metavar="N",
        help="keep the N highest major lines present upstream",
    )
    args = parser.parse_args()

    upstream = set()
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        release = json.loads(line)
        if release["draft"] or release["pre"]:
            continue
        match = RELEASE_RE.match(release["tag"] or "")
        if match:
            upstream.add(match.group(1))

    have = parse_versions(args.have)
    skip = read_skip(args.skip_file)
    majors = selected_majors(args, upstream)

    for version in sorted(missing(upstream, have, skip, majors), key=version_key):
        print(version)


if __name__ == "__main__":
    main()
