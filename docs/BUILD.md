# Build Guide

How to build Neon Dash locally and in CI.

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Godot | 4.3 (standard, not .NET) | Editor for dev; headless binary for CI. |
| Godot export templates | 4.3 | Must match the editor version exactly. |
| Android SDK | API 34 build-tools, platform 34 | Only for Android exports. |
| JDK | 17+ | Required by the Android build toolchain. |
| Git | any recent | Version control. |

> This repository was scaffolded in an environment **without** the Godot binary
> installed. All source (scenes, scripts, resources) is authored in Godot's
> text formats so it builds from source; run the editor once to let Godot import
> assets and generate the `.godot/` cache.

## First-time setup

```bash
# Import assets and generate the resource cache (headless is fine).
godot --headless --path . --import
```

## Running in the editor

```bash
godot --path . --editor
```

The main scene is `scenes/boot/Splash.tscn`. The game is fully playable with
primitive-mesh placeholder art; no external assets are required to run.

## Running the game headless (smoke)

```bash
godot --headless --path . --quit-after 300
```

## Building Android artifacts

Configure the Android SDK path in the Godot editor (Editor → Editor Settings →
Export → Android) or via environment variables in CI. Export presets live in
`export_presets.cfg` (see [Android export](#android-export-presets)).

```bash
# Debug APK (installable, unsigned/debug-signed)
godot --headless --path . --export-debug "Android" export/neon-dash-debug.apk

# Release APK
godot --headless --path . --export-release "Android" export/neon-dash-release.apk

# Release AAB (for Google Play upload)
godot --headless --path . --export-release "Android" export/neon-dash-release.aab
```

Release exports require a signing keystore. See [RELEASE.md](RELEASE.md). The
keystore is supplied at build time and is **never committed**.

## Android export presets

`export_presets.cfg` defines the `Android` preset:

- Package: `com.neondash.game`
- Min SDK 26 (Android 8.0), Target SDK 34
- Architectures: `arm64-v8a` (+ `armeabi-v7a` for wide device support)
- Gradle build enabled for custom signing and AAB output

Secrets (keystore path/passwords) are injected via environment variables in CI,
not stored in the preset.

## CI builds

- `.github/workflows/ci.yml` — lint (gdtoolkit) + GUT tests + scene/import
  validation on every push/PR.
- `.github/workflows/android.yml` — **debug** APK build for toolchain
  validation (manual `workflow_dispatch`, and PRs that touch the export config).
- `.github/workflows/android-release.yml` — **production signed release** on
  `v*` tags: tests → version stamp → decode keystore → signed APK + AAB →
  checksums → GitHub Release. Enforces signing (fails on `v*` tags if the
  signing secrets are missing rather than publishing unsigned). See
  [RELEASE.md](RELEASE.md).

## Local signed release build (optional)

Signing values come from environment variables — never hardcode them:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$PWD/neon-dash-release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="neondash"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="********"   # from your vault
godot --headless --path . --install-android-build-template \
  --export-release "Android" export/neon-dash-release.apk
godot --headless --path . --export-release "Android" export/neon-dash-release.aab
```

## Troubleshooting

- **"Cannot open file .translation"** — none is used; translations load from
  `localization/translations.csv` at runtime.
- **Missing audio/art** — expected in a fresh clone; the game degrades to
  placeholders and no-op audio. Drop assets into `assets/` to enable them.
- **Export template mismatch** — the templates must be the exact same version as
  the editor/headless binary.
