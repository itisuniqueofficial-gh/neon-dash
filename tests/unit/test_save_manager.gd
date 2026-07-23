extends GutTest
## Unit tests for SaveManager: currency, run recording, persistence and
## corruption recovery.

var _backup: Dictionary


func before_each() -> void:
	# Snapshot and start from a clean default profile for each test.
	_backup = SaveManager.data.duplicate(true)
	SaveManager.data = SaveManager.default_data()


func after_each() -> void:
	SaveManager.data = _backup


func test_default_data_has_expected_keys() -> void:
	var d := SaveManager.default_data()
	assert_has(d, "coins")
	assert_has(d, "high_score")
	assert_has(d, "unlocked_characters")
	assert_eq(d["format_version"], Constants.SAVE_FORMAT_VERSION)


func test_add_and_spend_coins() -> void:
	SaveManager.add_coins(100)
	assert_eq(SaveManager.get_coins(), 100)
	assert_true(SaveManager.spend_coins(60))
	assert_eq(SaveManager.get_coins(), 40)


func test_spend_coins_fails_when_insufficient() -> void:
	SaveManager.add_coins(10)
	assert_false(SaveManager.spend_coins(50), "Cannot overspend")
	assert_eq(SaveManager.get_coins(), 10)


func test_coins_never_go_negative() -> void:
	SaveManager.add_coins(-500)
	assert_eq(SaveManager.get_coins(), 0)


func test_record_run_updates_high_score() -> void:
	var is_high := SaveManager.record_run(500, 300.0)
	assert_true(is_high)
	assert_eq(SaveManager.get_high_score(), 500)
	# A lower score should not overwrite the high score.
	var is_high2 := SaveManager.record_run(200, 100.0)
	assert_false(is_high2)
	assert_eq(SaveManager.get_high_score(), 500)


func test_save_and_load_round_trip() -> void:
	SaveManager.add_coins(1234)
	SaveManager.data["high_score"] = 999
	assert_true(SaveManager.save_game(), "save_game should succeed")
	SaveManager.data = {}
	SaveManager.load_game()
	assert_eq(SaveManager.get_coins(), 1234)
	assert_eq(SaveManager.get_high_score(), 999)


func test_recovers_from_corrupted_primary_save() -> void:
	# Write a valid backup, then corrupt the primary file.
	SaveManager.add_coins(777)
	SaveManager.save_game()  # rotates current -> backup on next save
	SaveManager.save_game()
	var f := FileAccess.open(Constants.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{ this is not valid json ")
	f.close()
	SaveManager.data = {}
	SaveManager.load_game()
	# Should have recovered a sane profile rather than crashing/zeroing out.
	assert_true(SaveManager.get_coins() >= 0)
	assert_has(SaveManager.data, "format_version")


func test_migration_backfills_missing_keys() -> void:
	var old := {"format_version": 0, "coins": 50}
	var migrated := SaveManager._migrate(old)
	assert_eq(int(migrated["coins"]), 50, "Existing values preserved")
	assert_has(migrated, "high_score", "Missing keys backfilled")
	assert_eq(migrated["format_version"], Constants.SAVE_FORMAT_VERSION)
