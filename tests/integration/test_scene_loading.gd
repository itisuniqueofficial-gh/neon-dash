extends GutTest
## Integration smoke test: every scene in the project must load and instantiate
## without error. This is the primary guard against broken .tscn files or
## script/scene mismatches, especially valuable in headless CI where the editor
## is not opened.

var _scenes := [
	"res://scenes/boot/Splash.tscn",
	"res://scenes/boot/Loading.tscn",
	"res://scenes/ui/MainMenu.tscn",
	"res://scenes/ui/Settings.tscn",
	"res://scenes/ui/CharacterSelect.tscn",
	"res://scenes/ui/Store.tscn",
	"res://scenes/ui/Achievements.tscn",
	"res://scenes/ui/Statistics.tscn",
	"res://scenes/ui/Credits.tscn",
	"res://scenes/ui/HUD.tscn",
	"res://scenes/ui/PauseMenu.tscn",
	"res://scenes/ui/GameOverMenu.tscn",
	"res://scenes/collectibles/Coin.tscn",
	"res://scenes/collectibles/Gem.tscn",
	"res://scenes/obstacles/Obstacle.tscn",
	"res://scenes/powerups/PowerUp.tscn",
	"res://scenes/world/Chunk.tscn",
	"res://scenes/gameplay/Player.tscn",
	"res://scenes/game/Game.tscn",
]


func test_all_scenes_exist() -> void:
	for path in _scenes:
		assert_true(ResourceLoader.exists(path), "Missing scene: " + path)


func test_all_scenes_instantiate() -> void:
	for path in _scenes:
		if not ResourceLoader.exists(path):
			continue
		var packed := load(path)
		assert_true(packed is PackedScene, "Not a PackedScene: " + path)
		var inst = (packed as PackedScene).instantiate()
		assert_not_null(inst, "Failed to instantiate: " + path)
		if inst:
			inst.free()
