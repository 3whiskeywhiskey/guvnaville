extends GutTest

## Unit tests for UtilityScorer
## Tests action scoring and evaluation system
##
## @agent: Agent 7

var scorer: UtilityScorer

func before_each():
	scorer = UtilityScorer.new()

func after_each():
	scorer = null

func test_scorer_creation():
	assert_not_null(scorer, "UtilityScorer should be created")

func test_expansion_scoring():
	var target = Vector3i(10, 15, 0)
	var score = scorer.score_expansion(target, 1, null)

	assert_ge(score, 0.0, "Expansion score should be >= 0")
	assert_le(score, 100.0, "Expansion score should be <= 100")

func test_expansion_scoring_invalid_input():
	# Invalid faction ID
	var score1 = scorer.score_expansion(Vector3i.ZERO, -1, null)
	assert_eq(score1, 0.0, "Should return 0 for invalid faction ID")

	# Null game state is okay (uses mock data)
	var score2 = scorer.score_expansion(Vector3i(5, 5, 0), 1, null)
	assert_gt(score2, 0.0, "Should handle null game state")

func test_combat_scoring():
	var attackers = [1, 2, 3]  # 3 attacker units (mocked)
	var defenders = [4, 5]     # 2 defender units (mocked)

	var score = scorer.score_combat(attackers, defenders, null)

	assert_ge(score, -100.0, "Combat score should be >= -100")
	assert_le(score, 100.0, "Combat score should be <= 100")

func test_combat_scoring_empty_units():
	var score1 = scorer.score_combat([], [1, 2], null)
	assert_eq(score1, 0.0, "Should return 0 for empty attacker array")

	var score2 = scorer.score_combat([1, 2], [], null)
	assert_eq(score2, 0.0, "Should return 0 for empty defender array")

func test_production_scoring():
	var score_militia = scorer.score_production("militia", 1, {})
	var score_soldier = scorer.score_production("soldier", 1, {})
	var score_factory = scorer.score_production("factory", 1, {})

	assert_ge(score_militia, 0.0, "Militia production score should be valid")
	assert_ge(score_soldier, 0.0, "Soldier production score should be valid")
	assert_ge(score_factory, 0.0, "Factory production score should be valid")

	assert_le(score_militia, 100.0, "Militia production score should be <= 100")
	assert_le(score_soldier, 100.0, "Soldier production score should be <= 100")
	assert_le(score_factory, 100.0, "Factory production score should be <= 100")

func test_production_scoring_with_needs():
	# Military pressure should boost military production
	var needs = {"military_pressure": 0.8}
	var score_with_pressure = scorer.score_production("soldier", 1, needs)
	var score_without_pressure = scorer.score_production("soldier", 1, {})

	assert_gt(score_with_pressure, score_without_pressure, "Military production should be boosted by military pressure")

	# Resource shortage should boost economic production
	var resource_needs = {"resource_shortage": true}
	var score_factory_shortage = scorer.score_production("factory", 1, resource_needs)
	var score_factory_normal = scorer.score_production("factory", 1, {})

	assert_gt(score_factory_shortage, score_factory_normal, "Economic production should be boosted by resource shortage")

func test_culture_node_scoring():
	var score = scorer.score_culture_node("military_doctrine", 1, [])

	assert_ge(score, 0.0, "Culture node score should be >= 0")
	assert_le(score, 100.0, "Culture node score should be <= 100")

func test_culture_node_scoring_with_goals():
	var military_goal = AIGoal.new(AIGoal.GoalType.MILITARY_CONQUEST, 90.0)
	var goals = [military_goal]

	var military_node_score = scorer.score_culture_node("military_doctrine", 1, goals)
	var economic_node_score = scorer.score_culture_node("trade_networks", 1, goals)

	# Military node should score higher with military goal active
	assert_gt(military_node_score, economic_node_score, "Military node should score higher with military goal")

func test_trade_scoring():
	var score_neutral = scorer.score_trade(2, 1, AIThreatAssessment.Relationship.NEUTRAL)
	var score_hostile = scorer.score_trade(2, 1, AIThreatAssessment.Relationship.HOSTILE)
	var score_ally = scorer.score_trade(2, 1, AIThreatAssessment.Relationship.ALLY)

	assert_gt(score_ally, score_neutral, "Trade with ally should score higher than neutral")
	assert_gt(score_neutral, score_hostile, "Trade with neutral should score higher than hostile")
	assert_lt(score_hostile, 50.0, "Trade with hostile should have low score")

func test_trade_scoring_invalid():
	# Trading with self
	var score1 = scorer.score_trade(1, 1, AIThreatAssessment.Relationship.NEUTRAL)
	assert_eq(score1, 0.0, "Trading with self should return 0")

	# Invalid faction
	var score2 = scorer.score_trade(-1, 1, AIThreatAssessment.Relationship.NEUTRAL)
	assert_eq(score2, 0.0, "Trading with invalid faction should return 0")

func test_defense_scoring():
	var score_high_threat = scorer.score_defense(Vector3i(5, 5, 0), 80.0)
	var score_low_threat = scorer.score_defense(Vector3i(5, 5, 0), 20.0)

	assert_gt(score_high_threat, score_low_threat, "Defense should score higher with higher threat")

func test_personality_weights():
	# Set aggressive weights
	scorer.set_personality_weights({
		"military": 1.5,
		"economic": 0.7
	})

	# Military scoring should be affected
	var military_score = scorer.score_production("soldier", 1, {})
	assert_gt(military_score, 50.0, "Military production should be boosted by aggressive weights")

func test_personality_weights_invalid_keys():
	# Setting invalid keys should not crash
	scorer.set_personality_weights({
		"invalid_key": 2.0,
		"another_invalid": 0.5
	})

	# Scorer should still function
	var score = scorer.score_expansion(Vector3i(10, 10, 0), 1, null)
	assert_ge(score, 0.0, "Scorer should still work after invalid weight keys")
