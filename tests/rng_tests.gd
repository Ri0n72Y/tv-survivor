extends SceneTree

const RunRngManagerScript = preload("res://scripts/core/RunRngManager.gd")

var failures := 0

func _init() -> void:
	_test_same_seed_same_results()
	_test_different_seed_different_results()
	_test_map_stream_does_not_affect_reward_stream()
	_test_battle_stream_does_not_affect_shop_stream()
	_test_reward_stream_depends_only_on_reward_draw_order()
	_test_save_restore_continues_sequence()
	_test_new_stream_does_not_change_existing_stream()
	_test_random_pool_weighted_no_repeat()
	if failures > 0:
		quit(1)
	else:
		quit(0)

func _test_same_seed_same_results() -> void:
	var a := RunRngManagerScript.new()
	a.start_run(123456)
	var b := RunRngManagerScript.new()
	b.start_run(123456)
	var grid_a := GridGenerator.generate_random(123456, {}, a)
	var grid_b := GridGenerator.generate_random(123456, {}, b)
	_assert_equal(JSON.stringify(grid_a), JSON.stringify(grid_b), "同一个 run seed 应生成相同地图")
	_assert_equal(_draw_ints(a, RunRngManagerScript.STREAM_CHEST_REWARD, 5), _draw_ints(b, RunRngManagerScript.STREAM_CHEST_REWARD, 5), "同一个 run seed 应生成相同奖励序列")

func _test_different_seed_different_results() -> void:
	var a := RunRngManagerScript.new()
	a.start_run(111)
	var b := RunRngManagerScript.new()
	b.start_run(222)
	var grid_a := GridGenerator.generate_random(111, {}, a)
	var grid_b := GridGenerator.generate_random(222, {}, b)
	_assert_true(JSON.stringify(grid_a) != JSON.stringify(grid_b), "不同 run seed 应生成不同地图")
	_assert_true(_draw_ints(a, RunRngManagerScript.STREAM_CHEST_REWARD, 5) != _draw_ints(b, RunRngManagerScript.STREAM_CHEST_REWARD, 5), "不同 run seed 应生成不同奖励序列")

func _test_map_stream_does_not_affect_reward_stream() -> void:
	var a := RunRngManagerScript.new()
	a.start_run(777)
	_draw_ints(a, RunRngManagerScript.STREAM_MAP_ROUTE, 5)
	var reward_a := _draw_ints(a, RunRngManagerScript.STREAM_CHEST_REWARD, 5)
	var b := RunRngManagerScript.new()
	b.start_run(777)
	_draw_ints(b, RunRngManagerScript.STREAM_MAP_ROUTE, 50)
	var reward_b := _draw_ints(b, RunRngManagerScript.STREAM_CHEST_REWARD, 5)
	_assert_equal(reward_a, reward_b, "地图流消耗变化不能影响奖励流")

func _test_battle_stream_does_not_affect_shop_stream() -> void:
	var a := RunRngManagerScript.new()
	a.start_run(888)
	_draw_ints(a, RunRngManagerScript.STREAM_BATTLE_SPAWN, 3)
	var shop_a := _draw_ints(a, RunRngManagerScript.STREAM_SHOP_REFRESH, 5)
	var b := RunRngManagerScript.new()
	b.start_run(888)
	_draw_ints(b, RunRngManagerScript.STREAM_BATTLE_SPAWN, 30)
	var shop_b := _draw_ints(b, RunRngManagerScript.STREAM_SHOP_REFRESH, 5)
	_assert_equal(shop_a, shop_b, "战斗流消耗变化不能影响商店流")

func _test_reward_stream_depends_only_on_reward_draw_order() -> void:
	var a := RunRngManagerScript.new()
	a.start_run(999)
	var first_a := _draw_ints(a, RunRngManagerScript.STREAM_CHEST_REWARD, 1)
	_draw_ints(a, RunRngManagerScript.STREAM_BATTLE_SPAWN, 20)
	_draw_ints(a, RunRngManagerScript.STREAM_SHOP_REFRESH, 20)
	var second_a := _draw_ints(a, RunRngManagerScript.STREAM_CHEST_REWARD, 1)
	var b := RunRngManagerScript.new()
	b.start_run(999)
	var first_b := _draw_ints(b, RunRngManagerScript.STREAM_CHEST_REWARD, 1)
	var second_b := _draw_ints(b, RunRngManagerScript.STREAM_CHEST_REWARD, 1)
	_assert_equal(first_a, first_b, "第一个宝箱奖励只应取决于宝箱奖励流第一次抽取")
	_assert_equal(second_a, second_b, "第二个宝箱奖励只应取决于宝箱奖励流第二次抽取")

func _test_save_restore_continues_sequence() -> void:
	var uninterrupted := RunRngManagerScript.new()
	uninterrupted.start_run(123)
	_draw_ints(uninterrupted, RunRngManagerScript.STREAM_PASSIVE_REWARD, 4)
	var expected := _draw_ints(uninterrupted, RunRngManagerScript.STREAM_PASSIVE_REWARD, 6)
	var restored := RunRngManagerScript.new()
	restored.start_run(123)
	_draw_ints(restored, RunRngManagerScript.STREAM_PASSIVE_REWARD, 4)
	var state := restored.save_state()
	var resumed := RunRngManagerScript.new()
	resumed.restore_state(state)
	var actual := _draw_ints(resumed, RunRngManagerScript.STREAM_PASSIVE_REWARD, 6)
	_assert_equal(actual, expected, "保存并恢复后后续抽取应与未中断流程一致")

func _test_new_stream_does_not_change_existing_stream() -> void:
	var a := RunRngManagerScript.new()
	a.start_run(456)
	_draw_ints(a, "future.system", 20)
	var reward_a := _draw_ints(a, RunRngManagerScript.STREAM_WEAPON_REWARD, 5)
	var b := RunRngManagerScript.new()
	b.start_run(456)
	var reward_b := _draw_ints(b, RunRngManagerScript.STREAM_WEAPON_REWARD, 5)
	_assert_equal(reward_a, reward_b, "新增随机流不能改变已有流结果")

func _test_random_pool_weighted_no_repeat() -> void:
	var manager := RunRngManagerScript.new()
	manager.start_run(321)
	var items := [
		{"id": "a", "weight": 1.0, "tags": ["weapon"]},
		{"id": "b", "weight": 1.0, "tags": ["weapon"]},
		{"id": "c", "weight": 1.0, "tags": ["passive"]},
	]
	var result := RandomPool.draw(manager.get_stream(RunRngManagerScript.STREAM_WEAPON_REWARD), items, {
		"count": 2,
		"allow_repeats": false,
		"required_tags": ["weapon"],
	})
	_assert_equal(result.size(), 2, "奖励池应支持条件过滤后抽取")
	_assert_true(String(result[0]["id"]) != String(result[1]["id"]), "奖励池不重复抽取不应返回重复项")

func _draw_ints(manager: RunRngManager, stream_name: String, count: int) -> Array[int]:
	var result: Array[int] = []
	var stream := manager.get_stream(stream_name)
	for _i in range(count):
		result.append(stream.randi_range(0, 1000000))
	return result

func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures += 1
		push_error("%s\nactual=%s\nexpected=%s" % [message, str(actual), str(expected)])

func _assert_true(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
