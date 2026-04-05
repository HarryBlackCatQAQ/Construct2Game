extends SceneTree

var _captured_attack_rect := Rect2()
var _captured_projectile_configs: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	GameData.ensure_loaded()
	_install_input_map()

	var root := Node2D.new()
	get_root().add_child(root)

	await _test_hidden_turn_markers()
	await _test_music_asset_loads()
	await _test_player_attack_has_windup(root)
	await _test_attack_rect_orientation(root)
	await _test_skill_input_map()
	await _test_skill_q_hurricane_is_persistent(root)
	await _test_skill_w_spawns_projectile_after_windup(root)
	await _test_projectile_spawn_uses_vector2_config(root)
	await _test_stage_turn_markers_are_forwarded(root)
	await _test_enemy_melee_attack_has_windup(root)
	await _test_looped_effect_respects_lifetime(root)
	await _test_wing_skill_uses_persistent_visual(root)
	await _test_reply_enemy_restores_resources(root)
	await _test_actor_collision_layers(root)

	print("logic smoke passed")
	quit(0)


func _test_hidden_turn_markers() -> void:
	for stage_name in GameData.get_stage_order():
		var stage: Dictionary = GameData.get_stage(stage_name)
		for visual in stage.get("visuals", []):
			var object_id := int(visual.get("object_id", -1))
			_assert(object_id != 9 and object_id != 10, "Hidden turn markers leaked into %s." % stage_name)


func _test_music_asset_loads() -> void:
	var stream := load("res://assets/construct2/media/bkmusic.mp3")
	_assert(stream != null, "Background music asset failed to load.")


func _test_player_attack_has_windup(root: Node2D) -> void:
	var hero: Hero = await _spawn_hero(root)
	_captured_attack_rect = Rect2()
	hero.attack_requested.connect(_capture_attack_rect)
	hero.facing = 1
	hero._start_normal_attack()
	_assert(hero.attack_lock_timer > 0.0, "Normal attack did not enter an action lock.")
	_assert(_captured_attack_rect.size.x <= 0.0, "Normal attack dealt damage immediately without a windup.")

	await _wait_frames(28)
	_assert(_captured_attack_rect.size.x > 0.0, "Normal attack never emitted its delayed hit rect.")

	hero.queue_free()
	await process_frame


func _test_attack_rect_orientation(root: Node2D) -> void:
	var hero: Hero = await _spawn_hero(root)
	_captured_attack_rect = Rect2()
	hero.attack_requested.connect(_capture_attack_rect)

	hero.global_position = Vector2(300, 400)
	hero.facing = 1
	hero._start_normal_attack()
	await _wait_frames(28)
	_assert(_captured_attack_rect.size.x > 0.0, "Normal attack did not emit a hit rect.")
	_assert(_captured_attack_rect.position.x <= hero.global_position.x, "Right-facing attack rect starts too far forward.")
	_assert(_captured_attack_rect.position.x + _captured_attack_rect.size.x > hero.global_position.x + 70.0, "Right-facing attack rect does not extend forward enough.")

	hero.attack_cooldown = 0.0
	hero.attack_lock_timer = 0.0
	hero.facing = -1
	_captured_attack_rect = Rect2()
	hero._start_normal_attack()
	await _wait_frames(28)
	_assert(_captured_attack_rect.position.x < hero.global_position.x - 70.0, "Left-facing attack rect does not extend far enough to the left.")
	_assert(_captured_attack_rect.position.x + _captured_attack_rect.size.x >= hero.global_position.x, "Left-facing attack rect lost the character overlap zone.")

	hero.queue_free()
	await process_frame


func _test_actor_collision_layers(root: Node2D) -> void:
	var hero: Hero = await _spawn_hero(root)
	var enemy := Enemy.new()
	enemy.setup_from_entry({"role": "thief_1"}, hero)
	root.add_child(enemy)
	await process_frame

	_assert(hero.collision_layer == 2 and hero.collision_mask == 1, "Hero collision layers are misconfigured.")
	_assert(enemy.collision_layer == 2 and enemy.collision_mask == 1, "Enemy collision layers are misconfigured.")

	enemy.queue_free()
	hero.queue_free()
	await process_frame


func _test_skill_input_map() -> void:
	var attack_keys := _action_keys("attack")
	var move_left_keys := _action_keys("move_left")
	var jump_keys := _action_keys("jump")
	var skill_q_keys := _action_keys("skill_q")
	var skill_w_keys := _action_keys("skill_w")
	var skill_t_keys := _action_keys("skill_t")

	_assert(attack_keys.has(KEY_A), "Attack is not mapped to the A key.")
	_assert(not move_left_keys.has(KEY_A), "Move left still consumes the A key.")
	_assert(jump_keys.has(KEY_SPACE), "Jump is not mapped to Space.")
	_assert(jump_keys.has(KEY_UP), "Jump is not mapped to Up Arrow.")
	_assert(skill_q_keys.has(KEY_Q), "Skill Q is not mapped to Q.")
	_assert(skill_w_keys.has(KEY_W), "Skill W is not mapped to the W key.")
	_assert(not jump_keys.has(KEY_W), "Jump still consumes the W key, which blocks the W skill.")
	_assert(skill_t_keys.has(KEY_T), "Wing glide is not mapped to T.")


func _test_skill_q_hurricane_is_persistent(root: Node2D) -> void:
	var hero: Hero = await _spawn_hero(root)
	_captured_projectile_configs.clear()
	hero.projectile_requested.connect(_capture_projectile)
	hero.facing = 1
	hero.mana = Hero.MAX_MANA
	hero._cast_q()
	_assert(_captured_projectile_configs.is_empty(), "Skill Q spawned before the attack windup completed.")

	await _wait_frames(28)
	_assert(_captured_projectile_configs.size() == 1, "Skill Q never emitted its hurricane projectile.")

	var config := _captured_projectile_configs[0]
	_assert(not bool(config.get("destroy_on_hit", true)), "Skill Q still destroys itself on first hit.")
	_assert(int(config.get("max_hits", 0)) >= 4, "Skill Q does not allow repeated hits.")
	_assert(float(config.get("hit_interval", 0.0)) > 0.0, "Skill Q is missing its repeat-hit interval.")

	hero.queue_free()
	await process_frame


func _test_skill_w_spawns_projectile_after_windup(root: Node2D) -> void:
	var hero: Hero = await _spawn_hero(root)
	_captured_projectile_configs.clear()
	hero.projectile_requested.connect(_capture_projectile)
	hero.facing = -1
	hero.mana = Hero.MAX_MANA
	hero._cast_w()
	_assert(_captured_projectile_configs.is_empty(), "Skill W spawned its projectile before the attack windup completed.")

	await _wait_frames(28)
	_assert(_captured_projectile_configs.size() == 1, "Skill W never emitted its projectile.")
	_assert(int(_captured_projectile_configs[0].get("object_id", -1)) == 73, "Skill W emitted the wrong projectile object.")

	var velocity := _captured_projectile_configs[0].get("velocity", Vector2.ZERO) as Vector2
	_assert(velocity.x < 0.0, "Skill W projectile ignored the facing direction.")

	hero.queue_free()
	await process_frame


func _test_projectile_spawn_uses_vector2_config(root: Node2D) -> void:
	var view := GameView.new()
	root.add_child(view)
	await process_frame

	view._spawn_projectile({
		"position": Vector2(120, 240),
		"velocity": Vector2(360, -24),
		"damage": 9,
		"friendly": true,
	})

	var projectile_root: Node2D = view._projectile_root
	_assert(projectile_root.get_child_count() == 1, "Projectile was not spawned into the arena.")

	var projectile := projectile_root.get_child(0) as CombatProjectile
	_assert(projectile != null, "Spawned projectile has the wrong node type.")
	_assert(projectile.position == Vector2(120, 240), "Projectile spawn position lost its Vector2 config.")
	_assert(projectile.velocity == Vector2(360, -24), "Projectile velocity lost its Vector2 config.")

	view.queue_free()
	await process_frame


func _test_stage_turn_markers_are_forwarded(root: Node2D) -> void:
	var view := GameView.new()
	root.add_child(view)
	await process_frame

	view.start_stage("Layout 1")
	await process_frame

	_assert(view._regular_enemies.size() > 0, "Stage did not spawn any regular enemies for turn-marker testing.")
	var first_enemy := view._regular_enemies[0]
	_assert(first_enemy._turn_markers.size() > 0, "Stage turn markers were not forwarded to enemies.")

	view.queue_free()
	await process_frame


func _test_enemy_melee_attack_has_windup(root: Node2D) -> void:
	var hero: Hero = await _spawn_hero(root)
	hero.global_position = Vector2(260, 420)

	var enemy := Enemy.new()
	enemy.setup_from_entry({"role": "thief_1"}, hero)
	enemy.global_position = Vector2(302, 420)
	root.add_child(enemy)
	await process_frame

	var initial_health := hero.health
	enemy._start_melee_attack()
	_assert(enemy._action_lock_timer > 0.0, "Enemy melee attack did not enter an attack state.")
	_assert(hero.health == initial_health, "Enemy melee hit landed without a windup.")

	for _index in range(12):
		await physics_frame
		await process_frame

	_assert(hero.health < initial_health, "Enemy melee hit never landed after the attack windup.")

	enemy.queue_free()
	hero.queue_free()
	await process_frame


func _test_looped_effect_respects_lifetime(root: Node2D) -> void:
	var view := GameView.new()
	root.add_child(view)
	await process_frame

	view._spawn_effect({
		"object_id": 85,
		"lifetime": 0.05,
	})
	_assert(view._effect_root.get_child_count() == 1, "Looped effect was not spawned for lifetime testing.")

	await create_timer(0.16).timeout
	await process_frame
	_assert(view._effect_root.get_child_count() == 0, "Looped effect ignored its configured lifetime and remained onscreen.")

	view.queue_free()
	await process_frame


func _test_wing_skill_uses_persistent_visual(root: Node2D) -> void:
	var hero: Hero = await _spawn_hero(root)
	hero._cast_t()
	_assert(hero._wing_sprite != null and hero._wing_sprite.visible, "Wing skill did not enable the pinned wing visual.")

	await create_timer(1.25).timeout
	await process_frame
	_assert(not hero._wing_sprite.visible, "Wing visual remained visible after the glide skill expired.")

	hero.queue_free()
	await process_frame


func _test_reply_enemy_restores_resources(root: Node2D) -> void:
	var view := GameView.new()
	root.add_child(view)
	await process_frame

	view.start_stage("Layout 1")
	await process_frame

	_assert(view._mana_bar.max_value == Hero.MAX_MANA, "Mana HUD is not scaled to the hero mana pool.")
	_assert(view._health_bar.max_value == Hero.MAX_HEALTH, "Health HUD is not scaled to the hero health pool.")
	_assert(view._optional_enemies.size() > 0, "Reply enemy was not spawned for reward testing.")

	view._player.health = 23.0
	view._player.mana = 115.0
	view._on_enemy_died(view._optional_enemies[0], false)

	_assert(is_equal_approx(view._player.health, Hero.MAX_HEALTH), "Reply enemy did not restore the hero health pool.")
	_assert(is_equal_approx(view._player.mana, Hero.MAX_MANA), "Reply enemy did not restore the hero mana pool.")

	view.queue_free()
	await process_frame


func _spawn_hero(root: Node2D) -> Hero:
	var hero := Hero.new()
	root.add_child(hero)
	await process_frame
	return hero


func _install_input_map() -> void:
	_register_action("move_left", [KEY_LEFT])
	_register_action("move_right", [KEY_RIGHT])
	_register_action("jump", [KEY_SPACE, KEY_UP])
	_register_action("attack", [KEY_A])
	_register_action("skill_q", [KEY_Q])
	_register_action("skill_w", [KEY_W])
	_register_action("skill_e", [KEY_E])
	_register_action("skill_r", [KEY_R])
	_register_action("skill_t", [KEY_T])


func _register_action(action: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	for existing in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, existing)

	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


func _capture_attack_rect(rect: Rect2, _damage: int, _knockback: float, _include_optional: bool) -> void:
	_captured_attack_rect = rect


func _capture_projectile(config: Dictionary) -> void:
	_captured_projectile_configs.append(config.duplicate(true))


func _action_keys(action: String) -> Array[int]:
	var keys: Array[int] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
	return keys


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await physics_frame
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
