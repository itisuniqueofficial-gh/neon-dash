# Contributing to Neon Dash

Thanks for your interest in improving Neon Dash! This guide covers the
conventions that keep the project consistent and production-ready.

## Getting started

1. Install **Godot 4.3** (standard build).
2. Fork and clone the repo.
3. Run `godot --headless --path . --import` to generate the resource cache.
4. Open the project and run `scenes/boot/Splash.tscn`.

## Development workflow

1. Create a branch: `feat/short-description` or `fix/short-description`.
2. Make focused changes with clear commits (see below).
3. Add or update tests under `tests/`.
4. Run the test suite locally (see [docs/TESTING.md](docs/TESTING.md)).
5. Update docs when behaviour changes (README/CHANGELOG/relevant design doc).
6. Open a pull request using the PR template.

## Commit conventions

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(player): add double-jump
fix(save): recover from truncated backup file
refactor(audio): pool sfx voices
docs(readme): clarify Android build steps
test(pool): add leak guard
chore(release): v0.2.0
```

Scopes commonly used: `player`, `world`, `save`, `audio`, `ui`, `store`,
`achievements`, `ci`, `build`, `docs`.

## Code style

- **GDScript, statically typed.** Annotate variables, parameters and returns.
- **One class per file**, with a top-of-file `##` doc comment describing its
  responsibility. Add `class_name` when the type is referenced elsewhere.
- **No magic numbers** in gameplay code — put tunables in `scripts/autoload/Constants.gd`.
- **Communicate via `EventBus`** across system boundaries; avoid hard
  cross-references between managers and gameplay nodes.
- **Pool** anything spawned frequently; never allocate per-frame in gameplay.
- Keep functions small and single-purpose (SOLID where it applies).
- Document every public method.

## Tests

- New features and bug fixes should come with tests.
- Prefer deterministic logic tests over physics-dependent ones.
- Keep global state isolated with `before_each` / `after_each`.

## Reporting issues

Use the issue templates (bug report / feature request). Include your platform,
Godot version, and reproduction steps.

## Code of Conduct

Participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md).
