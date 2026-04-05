class_name GameView
extends Node2D

const GameHudScript := preload("res://scripts/game/game_hud.gd")

signal request_return_to_menu
signal request_help
signal game_completed

const HIDDEN_VISUAL_OBJECT_IDS := [9, 10]
const UI_TEXT := {
	"menu": "\u4e3b\u83dc\u5355",
	"help": "\u8bf4\u660e",
	"restart": "\u91cd\u5f00",
	"health": "\u751f\u547d",
	"mana": "\u6cd5\u529b",
	"controls": "\u79fb\u52a8 \u5de6/\u53f3\u65b9\u5411\u952e | \u8df3\u8dc3 Space/\u4e0a | \u653b\u51fb A | \u6280\u80fd Q/W/E/R | \u6ed1\u7fd4 T | \u5168\u5c4f F11",
	"portal_inactive": "\u4f20\u9001\u95e8\u672a\u6fc0\u6d3b",
	"portal_active": "\u4f20\u9001\u95e8\u5df2\u6fc0\u6d3b",
	"stage_format": "\u5173\u5361: %s",
	"enemy_format": "\u5269\u4f59\u666e\u901a\u654c\u4eba: %d",
	"fps_format": "FPS: %d",
	"entered_stage": "\u5df2\u8fdb\u5165 %s\u3002\u6e05\u7a7a\u666e\u901a\u654c\u4eba\u540e\u524d\u5f80\u53f3\u4fa7\u4f20\u9001\u95e8\u3002",
	"portal_ready": "\u4f20\u9001\u95e8\u5df2\u6fc0\u6d3b\uff0c\u5411\u53f3\u524d\u8fdb\u5373\u53ef\u8fc7\u5173\u3002",
}

var current_stage_name := ""

var _background_root: Node2D
var _solid_root: Node2D
var _visual_root: Node2D
var _actor_root: Node2D
var _projectile_root: Node2D
var _effect_root: Node2D

var _camera: Camera2D
var _hud
var _health_bar: ProgressBar
var _mana_bar: ProgressBar

var _player: Hero
var _portal_node: Node2D
var _portal_rect := Rect2()
var _portal_active := false
var _portal_sprite: ConstructSprite
var _regular_enemies: Array[Enemy] = []
var _optional_enemies: Array[Enemy] = []
var _stage_turn_markers: Array[Dictionary] = []


func _ready() -> void:
	_build_world_roots()
	_build_hud()


func start_stage(stage_name: String) -> void:
	current_stage_name = stage_name
	_clear_stage()

	var stage: Dictionary = GameData.get_stage(stage_name)
	if stage.is_empty():
		push_error("Missing stage data for %s" % stage_name)
		return

	_build_stage(stage)
	_set_status(_t("entered_stage") % stage_name)


func get_player() -> Hero:
	return _player


func get_damageable_enemies(include_optional: bool = true) -> Array[Enemy]:
	return _get_all_damageable_enemies(include_optional)


func damage_enemies_in_circle(center: Vector2, radius: float, damage: int, knockback: float, include_optional: bool) -> bool:
	var hit_any := false
	var area := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	for enemy in _get_all_damageable_enemies(include_optional):
		if enemy.dead:
			continue
		if enemy.get_hurt_rect().intersects(area):
			enemy.take_damage(damage, knockback)
			hit_any = true
	return hit_any


func _physics_process(_delta: float) -> void:
	_update_hud()
	_update_portal_state()


func _build_world_roots() -> void:
	_background_root = Node2D.new()
	_background_root.z_index = -20
	add_child(_background_root)

	_solid_root = Node2D.new()
	add_child(_solid_root)

	_visual_root = Node2D.new()
	_visual_root.z_index = -5
	add_child(_visual_root)

	_actor_root = Node2D.new()
	_actor_root.z_index = 10
	add_child(_actor_root)

	_projectile_root = Node2D.new()
	_projectile_root.z_index = 12
	add_child(_projectile_root)

	_effect_root = Node2D.new()
	_effect_root.z_index = 14
	add_child(_effect_root)

	_camera = Camera2D.new()
	_camera.enabled = true
	add_child(_camera)


func _build_hud() -> void:
	_hud = GameHudScript.new()
	_hud.ensure_built()
	_health_bar = _hud.get_health_bar()
	_mana_bar = _hud.get_mana_bar()
	_hud.menu_requested.connect(func() -> void:
		request_return_to_menu.emit()
	)
	_hud.help_requested.connect(func() -> void:
		request_help.emit()
	)
	_hud.restart_requested.connect(func() -> void:
		if not current_stage_name.is_empty():
			start_stage(current_stage_name)
	)
	add_child(_hud)
	_refresh_locale_text()


func _build_stage(stage: Dictionary) -> void:
	_camera.position = Vector2(float(stage.get("width", 1709)) * 0.5, float(stage.get("height", 960)) * 0.5)
	_stage_turn_markers = _duplicate_marker_list(stage.get("turn_markers", []))

	for visual in stage.get("visuals", []):
		_spawn_visual(visual)

	for collider in stage.get("colliders", []):
		_spawn_collider(collider)

	_spawn_player(stage.get("player_spawn", {}))
	_spawn_portal(stage.get("portal", {}))

	for enemy_entry in stage.get("regular_enemies", []):
		_spawn_enemy(enemy_entry, true)

	for reply_entry in stage.get("reply_enemies", []):
		var platform: Dictionary = reply_entry.get("platform", {})
		if not platform.is_empty():
			_spawn_optional_platform(platform)
		_spawn_enemy(reply_entry, false)


func _spawn_visual(entry: Dictionary) -> void:
	var object_id := int(entry.get("object_id", -1))
	if object_id < 0:
		return
	if HIDDEN_VISUAL_OBJECT_IDS.has(object_id):
		return

	if GameData.object_has_animation(object_id):
		var animated := ConstructSprite.new()
		animated.set_static_frame(
			object_id,
			String(entry.get("animation", "Default")),
			int(entry.get("frame", 0))
		)
		animated.position = _to_vector2(entry.get("position", [0, 0]))
		var frame_size := animated.get_current_frame_size()
		var desired_size := _to_vector2(entry.get("size", [frame_size.x, frame_size.y]))
		animated.scale = Vector2(
			desired_size.x / max(frame_size.x, 1.0),
			desired_size.y / max(frame_size.y, 1.0)
		)
		_visual_root.add_child(animated)
	else:
		var texture := GameData.get_texture(String(entry.get("asset", "")))
		if texture == null:
			return
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.position = _to_vector2(entry.get("top_left", [0, 0]))
		var desired := _to_vector2(entry.get("size", [texture.get_size().x, texture.get_size().y]))
		var texture_size := texture.get_size()
		sprite.scale = Vector2(
			desired.x / max(texture_size.x, 1.0),
			desired.y / max(texture_size.y, 1.0)
		)
		_visual_root.add_child(sprite)


func _spawn_collider(entry: Dictionary) -> void:
	var size := _to_vector2(entry.get("size", [64, 32]))
	var top_left := _to_vector2(entry.get("top_left", [0, 0]))
	var body := StaticBody2D.new()
	body.position = top_left + size * 0.5
	body.collision_layer = 1

	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	collision.shape = rect
	collision.one_way_collision = String(entry.get("mode", "solid")) == "one_way"
	collision.one_way_collision_margin = 2.0
	body.add_child(collision)
	_solid_root.add_child(body)


func _spawn_optional_platform(platform: Dictionary) -> void:
	var top_left := _to_vector2(platform.get("top_left", [0, 0]))
	var size := _to_vector2(platform.get("size", [232, 132]))
	var texture := GameData.get_texture(String(platform.get("asset", "")))

	if texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.position = top_left
		var texture_size := texture.get_size()
		sprite.scale = Vector2(
			size.x / max(texture_size.x, 1.0),
			size.y / max(texture_size.y, 1.0)
		)
		_visual_root.add_child(sprite)

	var body := StaticBody2D.new()
	body.position = top_left + Vector2(size.x * 0.5, size.y * 0.5)
	body.collision_layer = 1

	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, size.y * 0.22)
	collision.shape = rect
	collision.position = Vector2(0, -size.y * 0.39)
	collision.one_way_collision = true
	body.add_child(collision)
	_solid_root.add_child(body)


func _spawn_player(player_spawn: Dictionary) -> void:
	_player = Hero.new()
	_player.position = Vector2(float(player_spawn.get("x", 64.0)), float(player_spawn.get("y", 800.0)))
	_player.attack_requested.connect(_on_player_attack_requested)
	_player.projectile_requested.connect(_spawn_projectile)
	_player.effect_requested.connect(_spawn_effect)
	_player.status_requested.connect(_set_status)
	_player.died.connect(_on_player_died)
	_actor_root.add_child(_player)


func _spawn_portal(portal: Dictionary) -> void:
	var rect_data: Dictionary = portal.get("rect", {})
	_portal_rect = Rect2(
		float(rect_data.get("left", 0.0)),
		float(rect_data.get("top", 0.0)),
		float(rect_data.get("width", 110.0)),
		float(rect_data.get("height", 130.0))
	)
	_portal_active = false

	_portal_node = Node2D.new()
	_portal_node.position = _to_vector2(portal.get("position", [1600, 400]))
	_portal_sprite = ConstructSprite.new()
	_portal_sprite.setup_from_object(29)
	_portal_sprite.play("Default", true)
	_portal_sprite.modulate = Color(0.45, 0.45, 0.45, 0.8)
	_portal_node.add_child(_portal_sprite)
	_actor_root.add_child(_portal_node)
	_hud.set_portal_hint(_t("portal_inactive"))


func _spawn_enemy(entry: Dictionary, counts_for_clear: bool) -> void:
	var enemy := Enemy.new()
	enemy.setup_from_entry(entry, _player, _stage_turn_markers)
	enemy.position = _to_vector2(entry.get("position", [200, 200]))
	enemy.counts_for_clear = counts_for_clear
	enemy.died.connect(_on_enemy_died)
	enemy.projectile_requested.connect(_spawn_projectile)
	enemy.effect_requested.connect(_spawn_effect)
	_actor_root.add_child(enemy)

	if counts_for_clear:
		_regular_enemies.append(enemy)
	else:
		_optional_enemies.append(enemy)


func _spawn_projectile(config: Dictionary) -> void:
	var projectile := CombatProjectile.new()
	projectile.arena = self
	projectile.position = _to_vector2(config.get("position", [0, 0]))
	projectile.velocity = _to_vector2(config.get("velocity", [0, 0]))
	projectile.damage = int(config.get("damage", 10))
	projectile.radius = float(config.get("radius", 24.0))
	projectile.friendly = bool(config.get("friendly", true))
	projectile.lifetime = float(config.get("lifetime", 1.2))
	projectile.object_id = int(config.get("object_id", 11))
	projectile.scale_factor = float(config.get("scale", 1.0))
	projectile.flip_h = bool(config.get("flip_h", projectile.velocity.x < 0.0))
	projectile.destroy_on_hit = bool(config.get("destroy_on_hit", true))
	projectile.max_hits = int(config.get("max_hits", 1))
	projectile.hit_interval = float(config.get("hit_interval", 0.0))
	_projectile_root.add_child(projectile)


func _spawn_effect(config: Dictionary) -> void:
	var effect := ConstructSprite.new()
	var animation_name := String(config.get("animation", "Default"))
	effect.setup_from_object(int(config.get("object_id", 85)))
	effect.position = _to_vector2(config.get("position", [0, 0]))
	effect.scale = Vector2.ONE * float(config.get("scale", 1.0))
	effect.set_flipped(bool(config.get("flip_h", false)))
	effect.auto_free_on_finish = true
	effect.play(animation_name, true)
	_effect_root.add_child(effect)

	var lifetime := float(config.get("lifetime", -1.0))
	if lifetime > 0.0:
		var timer := get_tree().create_timer(lifetime)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(effect):
				effect.queue_free()
		)


func _on_player_attack_requested(rect: Rect2, damage: int, knockback: float, include_optional: bool) -> void:
	for enemy in _get_all_damageable_enemies(include_optional):
		if enemy.dead:
			continue
		if enemy.get_hurt_rect().intersects(rect):
			enemy.take_damage(damage, knockback)


func _on_player_died() -> void:
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func() -> void:
		if not current_stage_name.is_empty():
			start_stage(current_stage_name)
	)


func _on_enemy_died(enemy: Enemy, counts_for_clear: bool) -> void:
	if counts_for_clear:
		_regular_enemies.erase(enemy)
	else:
		_optional_enemies.erase(enemy)
		if enemy.role == "reply" and _player != null and not _player.dead:
			_player.restore_resources()
			_spawn_effect({
				"object_id": 72,
				"position": _player.global_position + Vector2(0, -44),
				"scale": 0.8,
				"lifetime": 0.45,
			})


func _update_hud() -> void:
	_hud.update_runtime(
		_t("stage_format") % current_stage_name,
		_t("enemy_format") % _regular_enemies.size(),
		_t("fps_format") % Engine.get_frames_per_second(),
		_player.health if _player != null else Hero.MAX_HEALTH,
		_player.mana if _player != null else Hero.MAX_MANA,
		_player != null
	)


func _update_portal_state() -> void:
	if _player == null or _portal_node == null:
		return

	var should_activate := _regular_enemies.size() == 0
	if should_activate != _portal_active:
		_portal_active = should_activate
		_hud.set_portal_hint(_t("portal_active") if _portal_active else _t("portal_inactive"))
		_portal_sprite.modulate = Color(1, 1, 1, 1) if _portal_active else Color(0.45, 0.45, 0.45, 0.8)
		if _portal_active:
			_set_status(_t("portal_ready"))

	if _portal_active and _player.get_hurt_rect().intersects(_portal_rect):
		_go_to_next_stage()


func _go_to_next_stage() -> void:
	var stage_order := GameData.get_stage_order()
	var current_index := stage_order.find(current_stage_name)
	if current_index == -1 or current_index == stage_order.size() - 1:
		game_completed.emit()
	else:
		start_stage(stage_order[current_index + 1])


func _get_all_damageable_enemies(include_optional: bool) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy in _regular_enemies:
		if is_instance_valid(enemy):
			result.append(enemy)
	if include_optional:
		for enemy in _optional_enemies:
			if is_instance_valid(enemy):
				result.append(enemy)
	return result


func _clear_stage() -> void:
	for root in [_background_root, _solid_root, _visual_root, _actor_root, _projectile_root, _effect_root]:
		for child in root.get_children():
			child.queue_free()

	_regular_enemies.clear()
	_optional_enemies.clear()
	_stage_turn_markers.clear()
	_player = null
	_portal_node = null
	_portal_rect = Rect2()
	_portal_active = false
	_hud.reset_resources()
	_hud.set_portal_hint(_t("portal_inactive"))


func _set_status(message: String) -> void:
	_hud.set_status(message)


func _refresh_locale_text() -> void:
	if _hud == null:
		return
	_hud.set_button_texts(
		_t("menu"),
		_t("help"),
		_t("restart"),
		_t("health"),
		_t("mana"),
		_t("controls")
	)
	_hud.set_portal_hint(_t("portal_active") if _portal_active else _t("portal_inactive"))


func _to_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(float(value.x), float(value.y))
	if value is Dictionary:
		var dict_value := value as Dictionary
		return Vector2(
			float(dict_value.get("x", 0.0)),
			float(dict_value.get("y", 0.0))
		)
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


func _duplicate_marker_list(markers: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if markers is Array:
		for marker in markers:
			if marker is Dictionary:
				result.append((marker as Dictionary).duplicate(true))
	return result


func _t(key: String) -> String:
	return String(UI_TEXT.get(key, key))
