extends Resource
class_name CharacterData
## CharacterData
##
## Data-only definition of a playable character. Stored as `.tres` resources
## under `resources/characters/` so designers can add characters without code.
## Cost of 0 with `unlocked_by_default = true` marks the starter character.

@export var id: StringName = &"runner_default"
@export var display_name: String = "Runner"
@export var description: String = "The classic neon runner."
@export var color: Color = Color(0.0, 0.9, 1.0)
## Coin cost to unlock. Ignored when `unlocked_by_default` is true.
@export var cost_coins: int = 0
## Gem cost to unlock (premium characters). 0 means coin-only.
@export var cost_gems: int = 0
@export var unlocked_by_default: bool = false
## Optional passive modifiers applied while this character is selected.
@export var coin_bonus_multiplier: float = 1.0
@export var start_speed_bonus: float = 0.0
