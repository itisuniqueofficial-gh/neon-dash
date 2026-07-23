# Security Policy

## Scope

Neon Dash is a fully offline, single-player game. It has **no backend, no
network calls, no accounts, and collects no personal data**. As such the attack
surface is small, but we still take the following seriously.

## Supported versions

Security fixes are applied to the latest released version and the `main` branch.

## Reporting a vulnerability

If you discover a security issue (for example, a save-file parsing bug that
could crash the game, or a supply-chain concern in a dependency), please report
it privately:

1. **Do not** open a public issue for a sensitive vulnerability.
2. Use GitHub's **"Report a vulnerability"** (Security Advisories) on the repo,
   or contact the maintainers listed in the repository profile.
3. Include reproduction steps and the affected version.

We aim to acknowledge reports within 5 business days and to ship a fix or
mitigation as promptly as the severity warrants.

## Handling of secrets

- **No secrets are ever committed** to this repository. Signing keystores,
  passwords, API keys and certificates are provided at build time via CI
  secrets and are excluded by `.gitignore`.
- The Android signing keystore is stored only as a GitHub Actions secret
  (`ANDROID_KEYSTORE_BASE64`) and is decoded to a temporary file during the
  build, then deleted.

## Data & permissions

- The app persists only local gameplay data under Godot's `user://` directory.
- The only device capability used is **vibration** (haptics), which the player
  can disable in Settings.
- No analytics, no ads, no tracking.

## Dependency hygiene

- Runtime dependencies are limited to the Godot engine.
- The only development dependency is the GUT test framework, pinned to a known
  version in CI.
