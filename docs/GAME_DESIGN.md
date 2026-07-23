# Game Design

## Concept

Neon Dash is a fast, readable, three-lane endless runner set on a neon-lit
track. The player runs automatically; the challenge is reacting to obstacles by
switching lanes, jumping and sliding while collecting currency and chaining
power-ups. One session is a "run"; the meta-game is progression across runs.

## Core loop

```
Run → earn coins/gems + progress stats → spend on characters/skins,
complete missions/achievements, claim daily reward → Run again (stronger/fresher)
```

## Controls

| Intent | Swipe (default) | On-screen buttons | Keyboard (desktop/CI) |
|---|---|---|---|
| Move left | swipe ← | ◀ | Left Arrow |
| Move right | swipe → | ▶ | Right Arrow |
| Jump | swipe ↑ / tap | JUMP | Up Arrow |
| Slide | swipe ↓ | SLIDE | Down Arrow |
| Pause | pause button | II | Esc |

Jump has **coyote time** and **input buffering** so it feels forgiving.

## Obstacles

Three avoidance archetypes keep all inputs relevant:

- **FULL** — must be dodged by changing lanes.
- **JUMP_OVER** — cleared by jumping (passing while airborne is a near-miss).
- **SLIDE_UNDER** — cleared by sliding (passing while sliding is a near-miss).

The generator never blocks all three lanes simultaneously, so every layout is
solvable. **Near misses** (correctly clearing a hazard) grant style and feed the
"Close Call" achievement.

## Collectibles & economy

| Item | Purpose | Notes |
|---|---|---|
| 🪙 Coin | Soft currency | Spent on characters and skins. |
| 💎 Gem | Premium currency | Earned in-run (no purchases); premium unlocks. |

There are **no microtransactions** — all currency is earned by playing.

## Power-ups

| Power-up | Effect | Duration |
|---|---|---|
| Magnet | Attracts nearby coins to the player | 8 s |
| Shield | Absorbs one otherwise-fatal hit | 6 s |
| Double Coins | Coins count double | 10 s |
| Speed Boost | Temporary speed increase | 5 s |

## Progression

- **Characters:** cosmetic runners, some with small passive bonuses. Bought with
  coins or (premium) gems. Starter character is free.
- **Skins:** colour variants applied to the runner.
- **Achievements:** long-term goals tied to lifetime statistics; each pays a
  coin reward on unlock.
- **Daily missions:** three short goals per day, regenerated at local midnight.
- **Daily reward:** an offline login streak that scales up to day 7, then holds.

## Difficulty curve

Speed rises gradually toward a cap; obstacle spacing tightens and higher tiers
may block two lanes. The curve is defined entirely in `Constants.gd`
(`DIFFICULTY_DISTANCE_STEP`, `OBSTACLE_BASE_GAP`, `OBSTACLE_MIN_GAP`,
`PLAYER_*_SPEED`) so it can be tuned without touching gameplay code.

## Juice

Camera shake (trauma-based, decaying), particle trails, coin/gem pitch
variation, music cross-fade between menu and gameplay, and haptic feedback on
jumps/hits/power-ups. All juice respects accessibility settings (screen shake
and vibration can be disabled).

## Accessibility

- Toggle screen shake and vibration.
- High-contrast option.
- Selectable control scheme (swipe / buttons / tilt-ready).
- Six languages.
