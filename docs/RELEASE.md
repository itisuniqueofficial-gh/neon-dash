# Release Process

Neon Dash follows **Semantic Versioning** (`MAJOR.MINOR.PATCH`) and ships
production Android builds through a fully automated, secure GitHub Actions
pipeline (`.github/workflows/android-release.yml`).

```
git tag v1.0.0  →  git push origin v1.0.0
      ↓
GitHub Actions (Android Release)
      ↓  tests → version stamp → decode keystore → sign
Signed APK + Signed AAB + checksums.txt
      ↓
GitHub Release (APK + AAB + checksums attached)
```

## Release policy (important)

This is a Play-Store-oriented title, so **tag releases enforce signing**. If the
signing secrets are absent when a `v*` tag is pushed, the workflow builds a
debug APK for diagnostics, uploads it as an artifact, and then **fails on
purpose** — it will **never publish an unsigned "release."** Configure the
secrets below before tagging.

## Versioning

- `MAJOR` — breaking changes to save format or a major gameplay overhaul.
- `MINOR` — new backward-safe features.
- `PATCH` — bug fixes and balance tweaks.

The workflow derives the version **from the Git tag** and stamps it into the
project automatically:

- `project.godot` → `config/version` = `MAJOR.MINOR.PATCH`
- `export_presets.cfg` → `version/name` and an auto-computed integer
  `version/code = MAJOR*10000 + MINOR*100 + PATCH` (monotonically increasing,
  required by Google Play).

You do not need to hand-edit versions for a release; just tag.

## One-time: create a production keystore

A keystore signs every build of the app. **You must reuse the same keystore for
every future update** — losing it means you can never update the app on Google
Play under the same listing.

```bash
keytool -genkey -v \
  -keystore neon-dash-release.keystore \
  -alias neondash \
  -keyalg RSA -keysize 2048 -validity 10000
```

You will be prompted for a **keystore password** and a **key (alias) password**.
Record them in a password manager. Keep the `.keystore` file **out of the repo**
(`.gitignore` already excludes `*.keystore`, `*.jks`, `*.base64`, etc.).

### Back up the keystore securely

- Store the `.keystore` file and both passwords in a secrets manager / vault
  (e.g., 1Password, Bitwarden, cloud KMS) — **never** in the repository.
- Keep at least one offline encrypted backup.
- Treat the passwords as production credentials.

## One-time: add the GitHub Actions secrets

The pipeline reads four encrypted repository secrets (GitHub masks them in
logs automatically; the workflow never prints their values):

| Secret | Contents |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 of the `.keystore` file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore (store) password |
| `ANDROID_KEY_ALIAS` | Signing key alias (e.g., `neondash`) |
| `ANDROID_KEY_ALIAS_PASSWORD` | Key (alias) password |

Base64-encode the keystore into a git-ignored file:

```bash
base64 -w0 neon-dash-release.keystore > keystore.base64   # Linux
# macOS: base64 -i neon-dash-release.keystore -o keystore.base64
```

Add the secrets with the GitHub CLI. Reading from a file / interactive prompt
keeps passwords **out of your shell history**:

```bash
# Check first — do not overwrite existing secrets unknowingly.
gh secret list -R itisuniqueofficial-gh/neon-dash

gh secret set ANDROID_KEYSTORE_BASE64 -R itisuniqueofficial-gh/neon-dash < keystore.base64
gh secret set ANDROID_KEYSTORE_PASSWORD   -R itisuniqueofficial-gh/neon-dash   # prompts (hidden)
gh secret set ANDROID_KEY_ALIAS           -R itisuniqueofficial-gh/neon-dash   # prompts (hidden)
gh secret set ANDROID_KEY_ALIAS_PASSWORD  -R itisuniqueofficial-gh/neon-dash   # prompts (hidden)

# Clean up the local encoded copy.
shred -u keystore.base64 2>/dev/null || rm -f keystore.base64
```

**UI alternative:** Repo → Settings → Secrets and variables → Actions →
*New repository secret*, and paste each value.

## Cut a release

Use the release script — it is the source of truth for versioning:

```bash
./scripts/release.sh patch     # 0.2.0 -> 0.2.1
./scripts/release.sh minor     # 0.2.1 -> 0.3.0
./scripts/release.sh major     # 0.3.0 -> 1.0.0
./scripts/release.sh patch --yes   # non-interactive (CI/automation)
./scripts/release.sh 1.4.2         # explicit version
```

The script validates the working tree and branch, computes the next semantic
version from `project.godot`, syncs it into `project.godot` and
`export_presets.cfg` (name + an always-increasing Android `versionCode`), rolls
the CHANGELOG `Unreleased` section into a dated version section, commits, creates
an annotated `vX.Y.Z` tag, and pushes both. It refuses to overwrite an existing
tag.

Manual equivalent (if you prefer):

```bash
# bump versions + CHANGELOG yourself, then:
git commit -am "chore(release): v1.0.0"
git tag -a v1.0.0 -m "v1.0.0"
git push origin main && git push origin v1.0.0
```

Pushing the tag triggers **Android Release**, which runs the tests, stamps the
version, decodes the keystore to a protected temp path (`$RUNNER_TEMP`), builds
the **signed APK and AAB**, **verifies both signatures** (`apksigner` for the
APK, `jarsigner -verify` for the AAB), generates checksums and release notes,
publishes a GitHub Release (marked *pre-release* for `v0.x`, *stable* for
`v1.0.0+`), and deletes the keystore.

Output assets attached to the release:

```
EndlessRunner-v1.0.0-release.apk    # direct install / testing
EndlessRunner-v1.0.0-release.aab    # Google Play distribution (primary)
EndlessRunner-v1.0.0-checksums.txt  # SHA-256 of both
```

If a Release for the tag already exists, the publish action updates it rather
than creating a duplicate.

## Test the pipeline WITHOUT publishing

Use the manual dry run (no tag, no Release is published):

```bash
gh workflow run "Android Release" -R itisuniqueofficial-gh/neon-dash -f dry_run=true
gh run watch -R itisuniqueofficial-gh/neon-dash
```

A dry run builds/validates only; the publish step is skipped because it requires
a real tag push.

## Rotating signing credentials

You generally should **not** rotate the app signing key (it must stay stable for
Play updates). If you must (e.g., password compromise) and are **not** using Play
App Signing, this is effectively a new app identity. Recommended instead:

- Enroll in **Google Play App Signing** so Google holds the app signing key and
  you rotate only the *upload* key. To rotate the upload key, generate a new
  keystore, update the four GitHub secrets, and register the new upload
  certificate in the Play Console.
- After updating secrets, run a dry run to confirm signing still succeeds.

## Google Play submission

1. Download the signed `.aab` from the GitHub Release.
2. Upload to the Play Console (internal testing track first).
3. Complete the listing, content rating and data-safety form. This game collects
   **no** user data and requests **no** internet permission (only vibration).
4. Promote through testing tracks to production.

## Rollback

If a release regresses, roll forward with a PATCH or halt the staged rollout in
the Play Console. Saves are versioned and forward-migrated, so downgrading the
app is safe for existing players.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Release job fails at "Detect signing configuration" enforcement | One or more of the four secrets is missing/empty. Re-add them (see above) and re-run. |
| `versionCode is set to 0` | Only happens with no tags on a manual run; the workflow now falls back to the project version and clamps `versionCode >= 1`. Tagged releases are always correct. |
| `apksigner: not found` | The Android build-tools weren't installed; the workflow installs `build-tools;34.0.0`. Re-run if a transient SDK install failed. |
| "AAB is not correctly signed" | The keystore/alias/password secrets don't match the keystore. Verify the four secrets correspond to the same keystore. |
| Duplicate release | The publish action updates an existing release for the tag; it does not duplicate. Delete the tag/release only if you intend to re-cut. |
| Tag already exists | `release.sh` refuses to overwrite. Bump to a new version instead. |

To exercise the pipeline without publishing, use the dry run:

```bash
gh workflow run "Android Release" -R itisuniqueofficial-gh/neon-dash -f dry_run=true
```
