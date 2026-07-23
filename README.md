<div align="center">

# ⚡ Neon Dash

**A production-ready, 100% offline endless runner for Android — built with Godot 4 and GDScript.**

[![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)](.github/workflows/ci.yml)
[![Engine](https://img.shields.io/badge/Godot-4.3-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-Android_8%2B-3DDC84?logo=android&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## Overview

Neon Dash is a three-lane endless runner. Dodge obstacles, grab coins and gems,
chain power-ups, and chase a new high score — all with no internet, no login,
and no backend. It targets a smooth **60 FPS** on Android 8.0+ from low-end to
flagship devices, using object pooling and chunk streaming to keep frame times
stable and memory low.

The entire project is engineered to be developed, tested, built and released
with **maximum automation**: unit/integration tests run in CI, and Android APK
and AAB artifacts are produced and attached to GitHub Releases automatically.

## Features

- 🏃 Endless, procedurally generated world with infinite chunk streaming
- 🕹️ Responsive movement: lane switching, **double jump**, slide and a
  cooldown **dash** with i-frames
- 🚧 Dynamic obstacle spawning with fair, always-solvable lane layouts
- 🪙 Coin and 💎 gem economy with a persistent, corruption-safe local save
- ⚡ Power-ups: Magnet, Shield, Double Coins, Speed Boost, Slow Motion, Invincibility
- 🏆 Achievements, 📆 offline daily rewards, 🎯 rotating daily missions
- 👤 Unlockable characters and 🎨 skins via an in-game store (soft currency only)
- 📊 Lifetime statistics tracking
- 🎚️ Full settings: audio mixing, vibration, screen shake, control scheme, language
- 🌍 Localization in 6 languages (EN, ES, FR, DE, PT, HI)
- 📱 Touch controls (swipe + optional on-screen buttons), landscape-first
- 🎬 Camera shake, particle juice, and audio with music cross-fade

## Quick start

```bash
# 1. Install Godot 4.3 (standard build) — https://godotengine.org/download
# 2. Open the project
godot --path . --editor          # or open project.godot from the Project Manager

# 3. Run the game
godot --path .
```

The game runs out of the box with primitive-mesh placeholder art, so there are
no missing-asset blockers. Drop real art/audio into `assets/` to skin it.

## Running tests

Tests use the [GUT](https://github.com/bitwes/Gut) framework (installed into
`addons/gut/`; CI does this automatically):

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

See [docs/TESTING.md](docs/TESTING.md) for details.

## Building for Android

Full instructions in [docs/BUILD.md](docs/BUILD.md). In short: install the Godot
Android export templates and Android SDK, then:

```bash
godot --headless --path . --export-debug "Android" export/neon-dash-debug.apk
godot --headless --path . --export-release "Android" export/neon-dash-release.aab
```

Release builds require a signing keystore — see [docs/RELEASE.md](docs/RELEASE.md).
**No keystore or secret is ever committed to this repository.**

### One-command release

With the signing secrets configured in GitHub, cut a fully automated, signed
release (APK + AAB + checksums + GitHub Release) with:

```bash
./scripts/release.sh patch    # or: minor | major
```

This bumps the version, updates the CHANGELOG, tags, and triggers the
`android-release.yml` pipeline.

## Documentation

| Document | Purpose |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | High-level system architecture |
| [docs/TECHNICAL_DESIGN.md](docs/TECHNICAL_DESIGN.md) | Detailed technical decisions |
| [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) | Gameplay, balance and progression |
| [docs/BUILD.md](docs/BUILD.md) | Building locally and in CI |
| [docs/RELEASE.md](docs/RELEASE.md) | Versioning and release process |
| [docs/TESTING.md](docs/TESTING.md) | Test strategy and how to run tests |
| [ROADMAP.md](ROADMAP.md) | Planned milestones |
| [CHANGELOG.md](CHANGELOG.md) | Release history |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [AGENTS.md](AGENTS.md) | Conventions for AI/automation agents |

## Project layout

```
scripts/     GDScript source (autoload/, gameplay/, world/, ui/, data/, ...)
scenes/      Godot scenes (.tscn) grouped by domain
assets/      Art, audio, fonts, themes (placeholders included)
localization/ CSV translations loaded at runtime
resources/   Data resources (characters, skins, chunks)
tests/       GUT tests (unit/, integration/, performance/)
docs/        Documentation
.github/     CI/CD workflows, issue/PR templates
export/      Build output (git-ignored)
```

## License

Released under the [MIT License](LICENSE). Asset attributions live in
[docs/CREDITS.md](docs/CREDITS.md).
