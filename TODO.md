# TODO

Living task list. Completed foundation items are in [CHANGELOG.md](CHANGELOG.md);
longer-term direction is in [ROADMAP.md](ROADMAP.md).

## Blocked (needs external credentials/tools)

- [ ] **Create the GitHub repository** — requires the GitHub CLI (`gh`) to be
      installed and authenticated, or manual creation in the GitHub UI. Steps
      are documented in the "Publishing to GitHub" section below.
- [ ] **Sign release builds** — requires an Android keystore provided as CI
      secrets (see [docs/RELEASE.md](docs/RELEASE.md)). Never committed.
- [ ] **Install Godot 4.3 + export templates** in the dev/CI environment to run
      the game, run tests locally, and produce Android artifacts.

## Engineering

- [ ] Add real art and audio assets under `assets/` (placeholders in use).
- [ ] Add a Godot project theme (`assets/themes/`) for consistent UI styling.
- [ ] Wire selected character/skin colour into the Player mesh material.
- [ ] Implement the "tilt" control scheme (currently swipe/buttons only).
- [ ] Add revive/continue flow UI on the Game Over screen.
- [ ] Persist and display mission progress on the Main Menu.

## Quality

- [ ] Increase test coverage for `MissionManager` and `PowerUpController`.
- [ ] Add a headless "play N seconds" stress test in CI.
- [ ] Profile on a low-end reference device and record a baseline.

## Publishing to GitHub (manual, until `gh` is available)

```bash
# 1. Create an empty repo on GitHub (UI) named "neon-dash".
# 2. Point this local repo at it and push:
git remote add origin https://github.com/<you>/neon-dash.git
git branch -M main
git push -u origin main

# With the GitHub CLI installed & authenticated, this is fully automatic:
gh auth login
gh repo create neon-dash --public --source=. --remote=origin --push
```

CI workflows, issue/PR templates and labels are already in `.github/` and will
activate automatically once the repo is on GitHub.
