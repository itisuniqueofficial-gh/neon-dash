extends GutTest
## Unit tests for Constants: lane math and difficulty scaling.


func test_lane_to_x_center_is_zero() -> void:
	assert_almost_eq(Constants.lane_to_x(1), 0.0, 0.001, "Centre lane sits at x=0")


func test_lane_to_x_symmetry() -> void:
	assert_almost_eq(Constants.lane_to_x(0), -Constants.LANE_WIDTH, 0.001)
	assert_almost_eq(Constants.lane_to_x(2), Constants.LANE_WIDTH, 0.001)


func test_lane_to_x_clamps_out_of_range() -> void:
	# Out-of-range indices clamp to the nearest valid lane.
	assert_eq(Constants.lane_to_x(-5), Constants.lane_to_x(0))
	assert_eq(Constants.lane_to_x(99), Constants.lane_to_x(2))


func test_difficulty_tier_increases_with_distance() -> void:
	assert_eq(Constants.difficulty_tier(0.0), 0)
	assert_gt(Constants.difficulty_tier(5000.0), Constants.difficulty_tier(1000.0))


func test_difficulty_tier_is_capped() -> void:
	assert_eq(Constants.difficulty_tier(1_000_000.0), Constants.MAX_DIFFICULTY_TIER)


func test_obstacle_gap_shrinks_with_tier() -> void:
	var easy := Constants.obstacle_gap_for_tier(0)
	var hard := Constants.obstacle_gap_for_tier(Constants.MAX_DIFFICULTY_TIER)
	assert_eq(easy, Constants.OBSTACLE_BASE_GAP)
	assert_eq(hard, Constants.OBSTACLE_MIN_GAP)
	assert_lt(hard, easy, "Higher tiers pack obstacles closer together")
