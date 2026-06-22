# Tracking upstream Bareos releases

Bareos ships new releases on its own schedule, and this project rebuilds its images from those releases. To avoid checking the Bareos repository by hand, a GitHub Action compares what Bareos has published against what we have released and, for every version we are missing on the major lines we track, either opens a pull request (mainline) or files a tracking issue with a ready-to-tag branch (older majors).

This document explains how that works and how to steer it.

## The promise

We track the **latest two major lines** Bareos maintains (currently 24 and 25). When Bareos starts a new major, the set rolls forward automatically: the newest two are tracked and the oldest drops off, with no edit to the workflow.

## The version file

[`.bareos-version`](../.bareos-version) at the repository root holds the Bareos version we ship, and is the single source of truth. `bump.sh` reads it to know what to replace, the release workflow reads it to know what to build, and the bump rewrites it in passing. Nothing else hardcodes the version. Crucially the **git tag is a separate thing** from this file: the file is the Bareos *source* version, the tag is the image *release* version, and the two are allowed to diverge (see [Releasing and divergence](#releasing-and-divergence)).

## The pipeline

The mechanism is a few small scripts in [`bin/`](../bin), each doing one thing so they can be run by hand: two standard-library Python scripts that pipe together to decide what is missing, then shell scripts that apply a version and publish it.

```
check-upstream.py | filter-releases.py  ->  per version:  bump.sh <v>  ->  create-pr.sh (mainline)  |  open-bump-issue.sh (older major)
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
- **Catches lagging lines.** If we are on `24.0.10` but Bareos has also published `24.0.9` and `24.0.10`, both are proposed even though they are older than `24.0.10`. A simple "newest release" check would miss them.
- **New majors start at the head.** A major we have no release for at all (a brand-new line) is proposed at upstream's current head only, as a single item, rather than its entire back catalogue.

### 3. `bump.sh`: apply

Rewrites the repository to ship one given version, replacing the version we currently ship everywhere it appears (Dockerfile `ARG`s, `build.sh`, the example compose tags, the README, the issue template) and advancing `.bareos-version`. It reads the current version from `.bareos-version`, so there is no hardcoded constant. It deliberately skips `.github/workflows/`: the bot's token cannot push workflow changes, and the version there is read from the file rather than hardcoded, so there is nothing to bump. This is the same trivial script you run by hand for a manual bump; the workflow just calls it once per missing version.

### 4. publish: `create-pr.sh` or `open-bump-issue.sh`

Both take whatever `bump.sh` left in the working tree, commit it onto `bump/bareos-<version>`, and push, using the `gh` CLI rather than a third-party action so the flow stays self-contained. They differ in what they open, and which one runs depends on the major (see below):

- `create-pr.sh` opens a **pull request** into the mainline branch. Idempotent: if a PR for that branch is already open it leaves it untouched.
- `open-bump-issue.sh` opens a **tracking issue** that links the branch, and opens no PR. Idempotent: if an issue for that version is already open it does nothing.

## Mainline versus older majors

The mainline branch (`develop`) ships exactly one major line, and `bump.sh` rewrites a single version string everywhere. So a bump only makes sense to *merge* for the major that mainline already tracks. A `24.x` bump merged into a `25.x` mainline would downgrade every version string, junk.

So the propose step reads the mainline major from `.bareos-version` (before the bump rewrites it) and routes per version:

- **Mainline major** (same major as `.bareos-version`): `create-pr.sh`, a PR into `develop`. Merging it advances the mainline, which is why develop always reflects the latest.
- **Older tracked major**: `open-bump-issue.sh`, a branch plus a tracking issue, never merged. You tag the release straight off that branch.

This is also why a back-major release needs no merge: the build reads the version from the file on the tagged commit, not from develop, so tagging an older-major branch builds that version while develop stays put.

## Releasing and divergence

Merging a PR or reviewing an issue branch records the bump. **Pushing the tag `X.Y.Z` is what triggers the [build and release workflow](../.github/workflows/release.yaml).** The bump and the release are deliberately separate, so a human decides when a version ships.

At release time the workflow reads `.bareos-version` (on the tagged commit) for the Bareos checkout and the source-code link, while the git tag drives the image tags and the GitHub release name. Because those are separate, you can ship a rebuild under a divergent tag: tag `24.0.10-supply-chain-fix-1` while the file still says `24.0.10`, and it builds Bareos `24.0.10` and ships it under your fix tag.

Bump branches clean themselves up. Merged mainline PR branches are removed by the repo's "automatically delete head branches" setting; older-major branches are deleted by the release workflow once their tag is published.

## The skip list

Some releases should never be proposed: a version that turned out broken, or one superseded within a day. List those in [`.bareos-skip-releases`](../.bareos-skip-releases) at the repository root, one `X.Y.Z` per line (blank lines and `#` comments are ignored). Without it, the check would re-open a request for that version on every run.

## The workflow

[`.github/workflows/check-upstream.yaml`](../.github/workflows/check-upstream.yaml) runs on demand (**Run workflow**), and on a daily schedule once the commented-out `schedule:` trigger is re-enabled:

1. The `detect` job runs `check-upstream.py | filter-releases.py --have <our tags> --latest-majors 2 --skip-file .bareos-skip-releases` to produce the list of missing versions.
2. The `propose-bumps` job fans out one run per version, each calling `bump.sh` then routing to `create-pr.sh` or `open-bump-issue.sh` by major.

### One-time setup

In the repository settings:

- **Settings → Actions → General → Workflow permissions** → enable **"Allow GitHub Actions to create and approve pull requests."** Without it the bot cannot open the mainline PRs.
- **Settings → General** → enable **"Automatically delete head branches"** so merged mainline bump branches are cleaned up.

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
