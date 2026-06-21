# Tracking upstream Bareos releases

Bareos ships new releases on its own schedule, and this project rebuilds its images from those releases. To avoid checking the Bareos repository by hand, a scheduled GitHub Action compares what Bareos has published against what we have released and opens a pull request for every version we are missing on the major lines we track.

This document explains how that works and how to steer it.

## The promise

We track the **latest two major lines** Bareos maintains (currently 24 and 25). When Bareos starts a new major, the set rolls forward automatically: the newest two are tracked and the oldest drops off, with no edit to the workflow.

## The pipeline

The mechanism is a few small scripts in [`bin/`](../bin), each doing one thing so they can be run by hand: two standard-library Python scripts that pipe together to decide what is missing, then two shell scripts that apply a version and publish a pull request for it.

```
check-upstream.py | filter-releases.py   ->   for each version:  bump.sh <version>  ->  create-pr.sh <version>
```

### 1. `check-upstream.py`: fetch

Fetches the Bareos releases from the GitHub API and prints them as JSON Lines, one `{tag, date, draft, pre}` object per line. Pure I/O, no policy. It honours `GITHUB_TOKEN`/`GH_TOKEN` if present (only to dodge the unauthenticated rate limit) and works without one.

### 2. `filter-releases.py`: decide

Reads that stream and prints the versions we are missing, one per line. This is where all selection policy lives. A release qualifies when it is:

- not a draft and not a pre-release (so `WIP/*-pre` tags are ignored),
- tagged `Release/X.Y.Z`,
- on a tracked major line, and
- above the **per-major floor**, and not on the skip list.

Major lines come from `--latest-majors N` (the N highest majors upstream) or an explicit `--majors 24,25`. The versions we already ship are passed with `--have` (our git tags).

#### The per-major floor

For each tracked major, the floor is the highest version we already ship on that line; only upstream releases above it are proposed. This is what keeps the comparison honest:

- **No back-fill.** If we shipped `24.0.0` then jumped to `24.0.8`, the floor on the 24 line is `24.0.8`, so `24.0.1`..`24.0.7` are never proposed. We do not resurrect versions we deliberately skipped.
- **Catches lagging lines.** If we are on `25.0.3` but Bareos has also published `24.0.9` and `24.0.10`, both are proposed even though they are older than `25.0.3`. A simple "newest release" check would miss them.
- **New majors start at the head.** A major we have no release for at all (a brand-new line) is proposed at upstream's current head only, as a single pull request, rather than its entire back catalogue.

### 3. `bump.sh`: apply

Rewrites the repository to ship one given version, replacing the version we currently ship everywhere it appears (Dockerfile `ARG`s, `build.sh`, the example compose tags, the README, the issue template, the release notes). This is the same trivial script you run by hand for a manual bump; the workflow just calls it once per missing version.

### 4. `create-pr.sh`: publish

Takes whatever `bump.sh` left in the working tree, commits it onto branch `bump/bareos-<version>`, pushes, and opens a pull request, unless one is already open for that branch (in which case the push just updates it). It is the only step that talks to GitHub for writes, using the `gh` CLI rather than a third-party action, so the whole flow stays self-contained. Run `bump.sh` before it.

## The skip list

Some releases should never be proposed: a version that turned out broken, or one superseded within a day. List those in [`.bareos-skip-releases`](../.bareos-skip-releases) at the repository root, one `X.Y.Z` per line (blank lines and `#` comments are ignored). Without it, the daily check would re-open a pull request for that version on every run.

## The workflow

[`.github/workflows/check-upstream.yaml`](../.github/workflows/check-upstream.yaml) runs the pipeline daily (and on demand via **Run workflow**):

1. `check-upstream.py | filter-releases.py --have <our tags> --latest-majors 2 --skip-file .bareos-skip-releases` produces the list of missing versions.
2. A matrix fans out one job per version, each running `bump.sh <version>` then `create-pr.sh <version>` to open (or update) a pull request on branch `bump/bareos-X.Y.Z`.

Merging a pull request records the bump. **Pushing the tag `X.Y.Z` is what actually triggers the [build and release workflow](../.github/workflows/release.yaml).** The bump PR and the release are deliberately separate steps, so a human decides when a version actually ships.

### One-time setup

For the Action to open pull requests, enable **Settings → Actions → General → Workflow permissions → "Allow GitHub Actions to create and approve pull requests."**

## Running it by hand

```bash
# What are we missing on the two latest majors?
bin/check-upstream.py \
  | bin/filter-releases.py \
      --have "$(git tag | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | paste -sd,)" \
      --latest-majors 2 \
      --skip-file .bareos-skip-releases

# Apply a specific version to the working tree
bin/bump.sh 25.0.4
```
