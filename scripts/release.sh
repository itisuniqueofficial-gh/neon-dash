#!/usr/bin/env bash
# ============================================================================
# release.sh — cut a semantic-version release for Neon Dash.
#
# Usage:
#   ./scripts/release.sh patch          # 0.2.0 -> 0.2.1
#   ./scripts/release.sh minor          # 0.2.1 -> 0.3.0
#   ./scripts/release.sh major          # 0.3.0 -> 1.0.0
#   ./scripts/release.sh patch --yes    # non-interactive (no confirmation)
#   ./scripts/release.sh 1.4.2          # explicit version
#
# It reads the authoritative version from project.godot, computes the next
# version, syncs it into project.godot + export_presets.cfg (name + an
# always-increasing Android versionCode), rolls the CHANGELOG "Unreleased"
# section into a dated version section, commits, creates an annotated tag,
# and pushes both. Pushing the tag triggers the signed Android release
# workflow (.github/workflows/android-release.yml).
#
# It never handles signing secrets — those live only in GitHub Actions.
# ============================================================================
set -euo pipefail

RELEASE_BRANCH="main"
PROJECT_FILE="project.godot"
PRESET_FILE="export_presets.cfg"
CHANGELOG="CHANGELOG.md"
REPO_SLUG="itisuniqueofficial-gh/neon-dash"

die() { echo "error: $*" >&2; exit 1; }

# --- Parse arguments --------------------------------------------------------
BUMP=""
ASSUME_YES="false"
for arg in "$@"; do
	case "$arg" in
		patch|minor|major) BUMP="$arg" ;;
		--yes|-y) ASSUME_YES="true" ;;
		[0-9]*.[0-9]*.[0-9]*) BUMP="explicit"; EXPLICIT_VERSION="$arg" ;;
		*) die "unknown argument '$arg' (expected patch|minor|major|X.Y.Z [--yes])" ;;
	esac
done
[[ -n "$BUMP" ]] || die "specify a release type: patch | minor | major | X.Y.Z"

cd "$(git rev-parse --show-toplevel)"

# --- Pre-flight checks ------------------------------------------------------
command -v git >/dev/null || die "git is required"
[[ -f "$PROJECT_FILE" ]] || die "$PROJECT_FILE not found (run from the repo)"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[[ "$CURRENT_BRANCH" == "$RELEASE_BRANCH" ]] \
	|| die "must release from '$RELEASE_BRANCH' (on '$CURRENT_BRANCH')"

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
	die "working tree has uncommitted changes; commit or stash first"
fi

echo "==> Syncing with origin/$RELEASE_BRANCH..."
git pull --ff-only origin "$RELEASE_BRANCH" || die "could not fast-forward; resolve manually"

# --- Compute versions -------------------------------------------------------
CURRENT="$(sed -nE 's|^config/version="(.*)"|\1|p' "$PROJECT_FILE" | head -n1)"
[[ "$CURRENT" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "current version '$CURRENT' is not semver"
IFS='.' read -r MAJ MIN PAT <<< "$CURRENT"

case "$BUMP" in
	patch) NEW="${MAJ}.${MIN}.$((PAT + 1))" ;;
	minor) NEW="${MAJ}.$((MIN + 1)).0" ;;
	major) NEW="$((MAJ + 1)).0.0" ;;
	explicit) NEW="$EXPLICIT_VERSION" ;;
esac
[[ "$NEW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "computed version '$NEW' is not semver"

IFS='.' read -r NMAJ NMIN NPAT <<< "$NEW"
NEW_CODE=$(( NMAJ * 10000 + NMIN * 100 + NPAT ))
TAG="v${NEW}"

git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null \
	&& die "tag ${TAG} already exists — never overwrite a release"

echo "==> Current version : ${CURRENT}"
echo "==> New version     : ${NEW}  (tag ${TAG}, Android versionCode ${NEW_CODE})"

if [[ "$ASSUME_YES" != "true" ]]; then
	read -r -p "Create and push release ${TAG}? [y/N] " reply
	[[ "$reply" =~ ^[Yy]$ ]] || { echo "aborted."; exit 0; }
fi

# --- Apply version to project files ----------------------------------------
sed -i -E "s|^config/version=\".*\"|config/version=\"${NEW}\"|" "$PROJECT_FILE"
sed -i -E "s|^version/name=\".*\"|version/name=\"${NEW}\"|" "$PRESET_FILE"
sed -i -E "s|^version/code=[0-9]+|version/code=${NEW_CODE}|" "$PRESET_FILE"

# --- Roll the CHANGELOG -----------------------------------------------------
# Rename "## [Unreleased]" to the new dated version and add a fresh Unreleased.
if [[ -f "$CHANGELOG" ]] && grep -q '## \[Unreleased\]' "$CHANGELOG"; then
	DATE="$(date +%Y-%m-%d)"
	python3 - "$CHANGELOG" "$NEW" "$DATE" "$CURRENT" <<'PY'
import sys, re
path, new, date, prev = sys.argv[1:5]
text = open(path, encoding="utf-8").read()
text = text.replace(
    "## [Unreleased]",
    f"## [Unreleased]\n\n## [{new}] - {date}",
    1,
)
# Add compare links if a link-reference section is present.
if f"[{new}]:" not in text:
    link = f"[{new}]: https://github.com/itisuniqueofficial-gh/neon-dash/compare/v{prev}...v{new}\n"
    m = re.search(r"\n\[Unreleased\]:.*\n", text)
    if m:
        text = text[:m.start()] + f"\n[Unreleased]: https://github.com/itisuniqueofficial-gh/neon-dash/compare/v{new}...HEAD\n" + link + text[m.end():]
open(path, "w", encoding="utf-8").write(text)
print(f"CHANGELOG: rolled Unreleased -> [{new}] - {date}")
PY
else
	echo "warning: no '## [Unreleased]' section found; skipping CHANGELOG roll" >&2
fi

# --- Commit, tag, push ------------------------------------------------------
git add "$PROJECT_FILE" "$PRESET_FILE" "$CHANGELOG"
git commit -m "chore(release): ${TAG}"
git tag -a "${TAG}" -m "Neon Dash ${TAG}"

echo "==> Pushing commit and tag..."
git push origin "$RELEASE_BRANCH"
git push origin "${TAG}"

echo ""
echo "Release ${TAG} pushed. The signed Android release workflow is now running:"
echo "  https://github.com/${REPO_SLUG}/actions/workflows/android-release.yml"
echo "Track it with:"
echo "  gh run watch -R ${REPO_SLUG}"
