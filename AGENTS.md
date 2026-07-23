# AGENTS.md

Conventions for AI/automation agents (and humans) working in this repository.
Following these keeps automated changes safe, consistent and reviewable.

## Project shape

- **Engine:** Godot 4.3, GDScript, Forward+/Mobile renderer.
- **Type:** offline Android endless runner. No networking, accounts or backend.
- **Entry scene:** `scenes/boot/Splash.tscn`.
- **Autoloads:** see `[autoload]` in `project.godot` and the table in
  `docs/ARCHITECTURE.md`.

## Golden rules

1. **Never commit secrets.** Keystores, passwords, tokens and certificates are
   provided via CI secrets only. Respect `.gitignore`.
2. **No per-frame allocations in gameplay.** Use `PoolManager` for anything
   spawned repeatedly.
3. **Tunables go in `Constants.gd`.** Do not hardcode gameplay numbers elsewhere.
4. **Cross-system communication uses `EventBus`.** Do not add hard references
   between managers and gameplay nodes.
5. **Every script is documented** with a top-of-file `##` comment; public
   methods get doc comments.
6. **Statically typed GDScript** everywhere.

## Where things live

```
scripts/autoload/     Singletons (managers, EventBus, Constants, Localization)
scripts/gameplay/     Player, GameController, CameraRig, TouchInput
scripts/world/        Chunk, ChunkManager
scripts/collectibles/ Collectible (coin/gem)
scripts/obstacles/    Obstacle
scripts/powerups/     PowerUpPickup, PowerUpController
scripts/ui/           Screen controllers (one per UI scene)
scripts/data/         Catalog, UnlockService, data resources
scenes/               .tscn files mirroring the scripts/ domains
tests/                GUT tests (unit/integration/performance)
localization/         translations.csv (loaded at runtime)
docs/                 Documentation
.github/              CI/CD workflows and templates
```

## Making a change

1. Read the relevant script's doc comment and `docs/` before editing.
2. Keep changes focused; one concern per commit.
3. Add/adjust tests in `tests/`. New scenes must pass the scene-load smoke test.
4. Update docs when behaviour changes (`README`, `CHANGELOG`, design docs).
5. Use Conventional Commits (see `CONTRIBUTING.md`).
6. Do not push directly to `main`; open a PR.

## Validation before proposing a change as done

- Run the GUT suite headless (see `docs/TESTING.md`).
- Confirm every new/edited `.tscn` instantiates (the smoke test enforces this).
- Confirm no new hardcoded gameplay constants were introduced.

## Safe-by-default behaviours

- Prefer additive, reversible edits. Flag destructive or irreversible actions.
- If a required credential (e.g., GitHub auth, Android keystore) is missing,
  stop at that boundary and document exactly how to provide it rather than
  inventing a substitute.
