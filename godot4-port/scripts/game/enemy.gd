class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy, counts_for_clear: bool)
signal projectile_requested(config: Dictionary)
signal effect_requested(config: Dictionary)

const GRAVITY := 1700.0
const WORLD_COLLISION_MASK := 1
const ACTOR_COLLISION_LAYER := 2

const ROLE_CONFIG := {
	"thief_1": {"object_id": 8, "health": 30.0, "damage": 6, "speed": 110.0, "attack_range": 56.0, "aggro_range": 280.0, "collision": Vector2(30, 44)},
	"thief_2": {"object_id": 19, "health": 55.0, "damage": 10, "speed": 100.0, "attack_range": 62.0, "aggro_range": 320.0, "collision": Vector2(34, 50)},
	"thief_3": {"object_id": 22, "health": 80.0, "damage": 14, "speed": 90.0, "attack_range": 68.0, "aggro_range": 360.0, "collision": Vector2(38, 54)},
	"thief_4": {"object_id": 25, "health": 95.0, "damage": 18, "speed": 120.0, "attack_range": 78.0, "aggro_range": 380.0, "collision": Vector2(40, 58)},
	"boss": {"object_id": 78, "health": 360.0, "damage": 22, "speed": 92.0, "attack_range": 100.0, "aggro_range": 520.0, "collision": Vector2(56, 84)},
	"reply": {"object_id": 97, "health": 60.0, "damage": 8, "speed": 0.0, "attack_range": 0.0, "aggro_range": 520.0, "collision": Vector2(32, 54)},
}

var role := "thief_1"
var player: Hero
var counts_for_clear := true
var facing := -1
var health := 30.0
var max_health := 30.0
var damage := 6
var move_speed := 100.0
var attack_range := 56.0
var aggro_range := 280.0
var dead := false

var _sprite: ConstructSprite
var _collision: CollisionShape2D
var _attack_cooldown := 0.0
var _shoot_cooldown := 1.6
var _stun_timer := 0.0
var _action_lock_timer := 0.0
var _action_animation := "stand"
var _patrol_direction := -1
var _turn_markers: Array[Dictionary] = []
var _turn_override_direction := 0
var _turn_override_timer := 0.0
var _last_turn_marker_index := -1
var _melee_hit_timer := 0.0
var _melee_damage_pending := false
var _queued_projectile: Dictionary = {}
var _projectile_fire_timer := 0.0


func setup_from_entry(entry: Dictionary, player_ref: Hero, turn_markers: Array = []) -> void:
	role = String(entry.get("role", "thief_1"))
	player = player_ref
	counts_for_clear = role != "reply"

	var config: Dictionary = ROLE_CONFIG.get(role, ROLE_CONFIG["thief_1"])
	max_health = float(config.get("health", 30.0))
	health = max_health
	damage = int(config.get("damage", 6))
	move_speed = float(config.get("speed", 100.0))
	attack_range = float(config.get("attack_range", 56.0))
	aggro_range = float(config.get("aggro_range", 280.0))
	set_turn_markers(turn_markers)

	if entry.has("vars"):
		var vars: Array = entry.get("vars", [])
		if vars.size() >= 1 and typeof(vars[0]) == TYPE_STRING:
			var dir_text := String(vars[0])
			facing = -1 if dir_text == "left" else 1
			_patrol_direction = facing


func set_turn_markers(turn_markers: Array) -> void:
	_turn_markers.clear()
	for marker in turn_markers:
		if marker is Dictionary:
			_turn_markers.append((marker as Dictionary).duplicate(true))


func _ready() -> void:
	collision_layer = ACTOR_COLLISION_LAYER
	collision_mask = WORLD_COLLISION_MASK
	floor_snap_length = 10.0

	var config: Dictionary = ROLE_CONFIG.get(role, ROLE_CONFIG["thief_1"])
	var collision_size: Vector2 = config.get("collision", Vector2(30, 44))

	_collision = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = collision_size
	_collision.shape = rect_shape
	_collision.position = Vector2(0, -collision_size.y * 0.5)
	add_child(_collision)

	_sprite = ConstructSprite.new()
	_sprite.setup_from_object(int(config.get("object_id", 8)))
	_sprite.play("stand", true)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	if dead:
		return

	var previous_melee_timer := _melee_hit_timer
	var previous_projectile_timer := _projectile_fire_timer
	_attack_cooldown = max(_attack_cooldown - delta, 0.0)
	_shoot_cooldown = max(_shoot_cooldown - delta, 0.0)
	_stun_timer = max(_stun_timer - delta, 0.0)
	_action_lock_timer = max(_action_lock_timer - delta, 0.0)
	_turn_override_timer = max(_turn_override_timer - delta, 0.0)
	_melee_hit_timer = max(_melee_hit_timer - delta, 0.0)
	_projectile_fire_timer = max(_projectile_fire_timer - delta, 0.0)

	if _melee_damage_pending and previous_melee_timer > 0.0 and _melee_hit_timer <= 0.0:
		_deliver_melee_hit()

	if not _queued_projectile.is_empty() and previous_projectile_timer > 0.0 and _projectile_fire_timer <= 0.0:
		projectile_requested.emit(_queued_projectile.duplicate(true))
		_queued_projectile.clear()

	if role == "reply":
		_process_reply()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if _stun_timer <= 0.0:
		if _action_lock_timer > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
		else:
			_apply_turn_markers()

			var desired_direction := _choose_direction()
			if desired_direction != 0:
				facing = desired_direction

			if role == "boss" and _should_use_boss_skill():
				velocity.x = 0.0
				_start_boss_skill()
			elif _should_attack():
				velocity.x = 0.0
				_start_melee_attack()
			else:
				if desired_direction != 0 and not _can_move_safely(desired_direction):
					var fallback_direction := _reverse_direction(desired_direction)
					_patrol_direction = fallback_direction
					_force_turn(fallback_direction, 0.28)
					desired_direction = fallback_direction

				velocity.x = move_toward(velocity.x, desired_direction * move_speed, 1200.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)

	move_and_slide()
	_update_animation()


func get_hurt_rect() -> Rect2:
	if _collision == null or _collision.shape == null:
		return Rect2(global_position - Vector2.ONE * 10.0, Vector2.ONE * 20.0)

	var size := (_collision.shape as RectangleShape2D).size
	return Rect2(global_position + Vector2(-size.x * 0.5, -size.y), size)


func take_damage(amount: int, knockback: float) -> bool:
	if dead:
		return false

	health = max(health - float(amount), 0.0)
	_stun_timer = 0.14
	_action_lock_timer = 0.0
	_melee_hit_timer = 0.0
	_melee_damage_pending = false
	_projectile_fire_timer = 0.0
	_queued_projectile.clear()
	velocity.x = knockback
	velocity.y = -180.0

	if health <= 0.0:
		_die()
		return true

	_update_animation()
	return false


func _process_reply() -> void:
	velocity = Vector2.ZERO
	if player == null or dead:
		return

	if _shoot_cooldown > 0.0:
		_update_animation()
		return

	var delta_to_player := player.global_position - global_position
	if absf(delta_to_player.x) <= aggro_range and absf(delta_to_player.y) <= 200.0:
		facing = -1 if delta_to_player.x < 0.0 else 1
		_shoot_cooldown = 1.8
		_begin_action("attack", 0.34)
		_queue_projectile(0.12, {
			"object_id": 81,
			"position": global_position + Vector2(facing * 26, -40),
			"velocity": Vector2(facing * 280.0, 0.0),
			"damage": damage,
			"radius": 22.0,
			"friendly": false,
			"lifetime": 2.6,
			"scale": 0.34,
		})
	_update_animation()


func _choose_direction() -> int:
	if _turn_override_timer > 0.0 and _turn_override_direction != 0:
		return _turn_override_direction

	if player == null:
		return _patrol_direction

	var delta_to_player := player.global_position - global_position
	if absf(delta_to_player.x) <= aggro_range and absf(delta_to_player.y) <= 110.0:
		var chase_direction := -1 if delta_to_player.x < 0.0 else 1
		if _can_move_safely(chase_direction):
			return chase_direction

	return _patrol_direction


func _should_attack() -> bool:
	if player == null or _attack_cooldown > 0.0:
		return false
	var delta_to_player := player.global_position - global_position
	return absf(delta_to_player.x) <= attack_range and absf(delta_to_player.y) <= 70.0


func _try_attack() -> void:
	if player == null:
		return
	_start_melee_attack()


func _try_boss_skill() -> void:
	if player == null or _shoot_cooldown > 0.0:
		return

	var delta_to_player := player.global_position - global_position
	if absf(delta_to_player.x) > aggro_range:
		return

	_shoot_cooldown = 2.4
	facing = -1 if delta_to_player.x < 0.0 else 1
	projectile_requested.emit({
		"object_id": 81,
		"position": global_position + Vector2(facing * 48, -54),
		"velocity": Vector2(facing * 360.0, 0.0),
		"damage": damage - 4,
		"radius": 28.0,
		"friendly": false,
		"lifetime": 3.2,
		"scale": 0.5,
	})


func _should_use_boss_skill() -> bool:
	if role != "boss" or player == null or _shoot_cooldown > 0.0:
		return false

	var delta_to_player := player.global_position - global_position
	var horizontal_distance := absf(delta_to_player.x)
	return horizontal_distance > attack_range + 28.0 and horizontal_distance <= aggro_range and absf(delta_to_player.y) <= 180.0


func _start_melee_attack() -> void:
	if player == null:
		return

	var delta_to_player := player.global_position - global_position
	if absf(delta_to_player.x) > 6.0:
		facing = -1 if delta_to_player.x < 0.0 else 1

	_attack_cooldown = 1.1 if role == "boss" else 0.95
	_begin_action("attack", 0.42 if role == "boss" else 0.32)
	_melee_damage_pending = true
	_melee_hit_timer = 0.18 if role == "boss" else 0.12


func _deliver_melee_hit() -> void:
	_melee_damage_pending = false
	if player == null or dead:
		return

	var delta_to_player := player.global_position - global_position
	var hit_range := attack_range + 16.0
	if absf(delta_to_player.x) <= hit_range and absf(delta_to_player.y) <= 84.0:
		player.take_damage(damage, global_position.x)


func _start_boss_skill() -> void:
	if player == null:
		return

	var delta_to_player := player.global_position - global_position
	facing = -1 if delta_to_player.x < 0.0 else 1
	_shoot_cooldown = 2.4
	_begin_action("attack", 0.55)
	_queue_projectile(0.2, {
		"object_id": 81,
		"position": global_position + Vector2(facing * 48, -54),
		"velocity": Vector2(facing * 360.0, 0.0),
		"damage": damage - 4,
		"radius": 28.0,
		"friendly": false,
		"lifetime": 3.2,
		"scale": 0.5,
	})


func _begin_action(animation_name: String, duration: float) -> void:
	_action_lock_timer = max(_action_lock_timer, duration)
	_action_animation = animation_name if _sprite != null and _sprite.get_frame_count(animation_name) > 0 else "stand"


func _queue_projectile(fire_delay: float, config: Dictionary) -> void:
	_projectile_fire_timer = fire_delay
	_queued_projectile = config.duplicate(true)


func _apply_turn_markers() -> void:
	if _turn_markers.is_empty():
		return

	var probe_point := global_position + Vector2(0, -8)
	var hit_index := -1

	for index in range(_turn_markers.size()):
		var marker := _turn_markers[index]
		var marker_rect := _marker_rect(marker)
		if marker_rect.has_point(probe_point) or marker_rect.intersects(get_hurt_rect()):
			hit_index = index
			break

	if hit_index == -1:
		_last_turn_marker_index = -1
		return

	if hit_index == _last_turn_marker_index:
		return

	_last_turn_marker_index = hit_index
	var turn_direction := _marker_direction(_turn_markers[hit_index])
	if turn_direction != 0:
		_patrol_direction = turn_direction
		_force_turn(turn_direction, 0.32)


func _marker_rect(marker: Dictionary) -> Rect2:
	var rect_data: Dictionary = marker.get("rect", {})
	if not rect_data.is_empty():
		return Rect2(
			float(rect_data.get("left", 0.0)),
			float(rect_data.get("top", 0.0)),
			float(rect_data.get("width", 0.0)),
			float(rect_data.get("height", 0.0))
		)

	var top_left := _to_vector2(marker.get("top_left", [0, 0]))
	var size := _to_vector2(marker.get("size", [0, 0]))
	return Rect2(top_left, size)


func _marker_direction(marker: Dictionary) -> int:
	return -1 if String(marker.get("direction", "right")) == "left" else 1


func _force_turn(direction: int, duration: float) -> void:
	if direction == 0:
		return

	_turn_override_direction = direction
	_turn_override_timer = max(_turn_override_timer, duration)
	facing = direction


func _reverse_direction(direction: int) -> int:
	if direction == 0:
		return 0
	return -direction


func _can_move_safely(direction: int) -> bool:
	if direction == 0:
		return true
	return _has_floor_ahead(direction) and not _has_wall_ahead(direction)


func _has_floor_ahead(direction: int) -> bool:
	if direction == 0:
		return true

	var size := _collision_size()
	var space_state := get_world_2d().direct_space_state
	var from := global_position + Vector2(direction * (size.x * 0.45 + 6.0), -8.0)
	var to := from + Vector2(0.0, size.y * 0.95)
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [get_rid()]
	query.collision_mask = WORLD_COLLISION_MASK
	var result := space_state.intersect_ray(query)
	return not result.is_empty()


func _has_wall_ahead(direction: int) -> bool:
	if direction == 0:
		return false

	var size := _collision_size()
	var space_state := get_world_2d().direct_space_state
	var from := global_position + Vector2(0.0, -size.y * 0.5 + 10.0)
	var to := from + Vector2(direction * (size.x * 0.55 + 12.0), 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [get_rid()]
	query.collision_mask = WORLD_COLLISION_MASK
	var result := space_state.intersect_ray(query)
	return not result.is_empty()


func _collision_size() -> Vector2:
	if _collision != null and _collision.shape is RectangleShape2D:
		return (_collision.shape as RectangleShape2D).size
	return Vector2(30, 44)


func _update_animation() -> void:
	if _sprite == null:
		return

	_sprite.set_flipped(facing < 0)

	if _stun_timer > 0.0:
		_sprite.play("hit")
	elif _action_lock_timer > 0.0:
		_sprite.play(_action_animation)
	elif absf(velocity.x) > 20.0:
		_sprite.play("run")
	else:
		_sprite.play("stand")


func _die() -> void:
	if dead:
		return

	dead = true
	_action_lock_timer = 0.0
	_melee_hit_timer = 0.0
	_melee_damage_pending = false
	_projectile_fire_timer = 0.0
	_queued_projectile.clear()
	effect_requested.emit({
		"object_id": int(ROLE_CONFIG.get(role, ROLE_CONFIG["thief_1"]).get("object_id", 8)),
		"position": global_position + Vector2(0, -34),
		"scale": 0.45 if role != "boss" else 0.7,
		"lifetime": 0.25,
	})
	died.emit(self, counts_for_clear)
	queue_free()


func _to_vector2(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
