# Release Process

Neon Dash follows **Semantic Versioning** (`MAJOR.MINOR.PATCH`) and automates
releases through GitHub Actions.

## Versioning

- `MAJOR` — breaking changes to save format or a major gameplay overhaul.
- `MINOR` — new features (characters, power-ups, modes) that are backward-safe.
- `PATCH` — bug fixes and balance tweaks.

The version lives in two places and must stay in sync:
- `project.godot` → `config/version`
- `export_presets.cfg` → `version/name` and integer `version/code`

The `version/code` (Android versionCode) must **strictly increase** on every
Play Store upload.

## Cutting a release

1. Update `CHANGELOG.md` — move items from *Unreleased* into a new version
   heading with the date.
2. Bump the version in `project.godot` and `export_presets.cfg` (increment the
   Android `version/code`).
3. Commit: `chore(release): v0.2.0`.
4. Tag: `git tag -a v0.2.0 -m "v0.2.0"` and push the tag.
5. The **Android release workflow** triggers on the tag: it builds the release
   APK + AAB, generates release notes, creates the GitHub Release, and attaches
   the artifacts.

## Signing (required for release)

Release builds must be signed. The keystore and its credentials are provided to
CI as **GitHub Actions secrets** and are never committed:

| Secret | Purpose |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 of the `.keystore` file. |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password. |
| `ANDROID_KEY_ALIAS` | Signing key alias. |
| `ANDROID_KEY_ALIAS_PASSWORD` | Key alias password. |

The workflow decodes the keystore to a temp path, exports, then deletes it.

### Generating a keystore (once, locally)

```bash
keytool -genkey -v -keystore neon-dash.keystore \
  -alias neondash -keyalg RSA -keysize 2048 -validity 10000
```

Store this file safely **outside** the repo (a password manager or secrets
vault). Losing it means you can never update the Play Store listing.

## Google Play submission

1. Download the signed `.aab` from the GitHub Release.
2. Upload to the Play Console (internal testing track first).
3. Complete the store listing, content rating and data-safety form (this game
   collects **no** user data and requires **no** permissions beyond vibration).
4. Promote through testing tracks to production.

## Rollback

If a release regresses, either roll forward with a PATCH or halt the staged
rollout in the Play Console. Because saves are versioned and forward-migrated,
downgrading the app is safe for existing players.
