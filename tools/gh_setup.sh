#!/usr/bin/env bash
# ============================================================================
# gh_setup.sh — one-shot GitHub configuration for Neon Dash.
#
# Requires the GitHub CLI (https://cli.github.com) to be installed and
# authenticated:  gh auth login
#
# Safe to re-run: creation steps are idempotent where the CLI allows it.
# This script never stores secrets; the Android keystore secrets must be added
# separately (see docs/RELEASE.md).
# ============================================================================
set -euo pipefail

REPO_NAME="${REPO_NAME:-neon-dash}"
VISIBILITY="${VISIBILITY:-public}"           # public | private
DESCRIPTION="A production-ready, 100% offline endless runner for Android, built with Godot 4."
TOPICS="godot,godot4,gdscript,android,endless-runner,game,mobile-game,offline,ci-cd"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: GitHub CLI (gh) is not installed. See https://cli.github.com" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

echo "==> Creating repository '$REPO_NAME' ($VISIBILITY) and pushing 'main'..."
git branch -M main
gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --push \
  --description "$DESCRIPTION" || echo "  (repo may already exist; continuing)"

echo "==> Setting description & topics..."
gh repo edit --description "$DESCRIPTION" --add-topic "${TOPICS//,/ --add-topic }" || true

echo "==> Creating milestones..."
create_milestone() {
  local title="$1" desc="$2"
  gh api "repos/{owner}/{repo}/milestones" -f title="$title" -f description="$desc" \
    >/dev/null 2>&1 && echo "  + $title" || echo "  = $title (exists)"
}
create_milestone "v0.2.0 — Content & Feel" "Art/audio pass, more power-ups, biomes, onboarding."
create_milestone "v0.3.0 — Progression Depth" "Abilities, weekly missions, cosmetics, ghosts."
create_milestone "v0.4.0 — Polish & Accessibility" "Colorblind palettes, reduced motion, profiling."
create_milestone "v1.0.0 — Play Store Launch" "Store assets, ratings, staged rollout."

echo "==> Syncing labels from .github/labels.yml..."
if command -v yq >/dev/null 2>&1; then
  yq -r '.[] | [.name, .color, .description] | @tsv' .github/labels.yml |
  while IFS=$'\t' read -r name color desc; do
    gh label create "$name" --color "$color" --description "$desc" 2>/dev/null \
      && echo "  + $name" \
      || gh label edit "$name" --color "$color" --description "$desc" 2>/dev/null || true
  done
else
  echo "  (install 'yq' to sync labels here, or rely on the Sync labels workflow)"
fi

echo "==> Enabling branch protection on 'main' (requires admin)..."
gh api -X PUT "repos/{owner}/{repo}/branches/main/protection" \
  -H "Accept: application/vnd.github+json" \
  -f "required_status_checks[strict]=true" \
  -F "required_status_checks[contexts][]=Lint (gdtoolkit)" \
  -F "required_status_checks[contexts][]=Unit / Integration / Performance tests" \
  -F "enforce_admins=false" \
  -F "required_pull_request_reviews[required_approving_review_count]=1" \
  -F "restrictions=" >/dev/null 2>&1 \
  && echo "  branch protection enabled" \
  || echo "  (could not set branch protection — needs admin permission)"

echo "==> Done. Remember to add Android signing secrets (see docs/RELEASE.md):"
echo "    gh secret set ANDROID_KEYSTORE_BASE64 < keystore.b64"
echo "    gh secret set ANDROID_KEYSTORE_PASSWORD"
echo "    gh secret set ANDROID_KEY_ALIAS"
echo "    gh secret set ANDROID_KEY_ALIAS_PASSWORD"
