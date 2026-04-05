class_name Hero
extends CharacterBody2D

signal attack_requested(rect: Rect2, damage: int, knockback: float, include_optional: bool)
signal projectile_requested(config: Dictionary)
signal effect_requested(config: Dictionary)
signal status_requested(message: String)
signal died

const WORLD_COLLISION_MASK := 1
const ACTOR_COLLISION_LAYER := 2
const MOVE_SPEED := 300.0
const ACCELERATION := 1800.0
const FRICTION := 2100.0
const GRAVITY := 1700.0
const GLIDE_GRAVITY := 520.0
const JUMP_FORCE := -620.0
const DOUBLE_JUMP_FORCE := -560.0
const T_LIFT_FORCE := -260.0

const MAX_HEALTH := 100.0
const MAX_MANA := 800.0
const MANA_REGEN_PER_SECOND := 42.0

const NORMAL_DAMAGE := 12
const Q_DAMAGE := 20
const W_DAMAGE := 24
const E_DAMAGE := 28
const R_DAMAGE := 36

const Q_COST := 80.0
const W_COST := 110.0
const E_COST := 150.0
const R_COST := 220.0
const T_COST := 0.0

var health := MAX_HEALTH
var mana := MAX_MANA
var facing := 1
var jumps_left := 1
var attack_lock_timer := 0.0
var attack_cooldown := 0.0
var hit_stun_timer := 0.0
var invulnerable_timer := 0.0
var dead := false

var _dash_timer := 0.0
var _dash_speed := 0.0
var _attack_animation := "attack"
var _wing_timer := 0.0
var _pending_events: Array[Dictionary] = []

var _sprite: ConstructSprite
var _wing_sprite: ConstructSprite
var _collision: CollisionShape2D


func _ready() -> void:
	collision_layer = ACTOR_COLLISION_LAYER
	collision_mask = WORLD_COLLISION_MASK
	floor_snap_length = 12.0

	_collision = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(30, 44)
	_collision.shape = rect_shape
	_collision.position = Vector2(0, -22)
	add_child(_collision)

	_wing_sprite = ConstructSprite.new()
	_wing_sprite.setup_from_object(72)
	_wing_sprite.play("Default", true)
	_wing_sprite.position = Vector2(-10, -54)
	_wing_sprite.z_index = 2
	_wing_sprite.scale = Vector2.ONE * 0.86
	_wing_sprite.visible = false
	add_child(_wing_sprite)

	_sprite = ConstructSprite.new()
	_sprite.setup_from_object(2)
	_sprite.anchor_origin = Vector2(0.5, 1.0)
	_sprite.play("stand", true)
	_sprite.z_index = 5
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	if dead:
		return

	attack_lock_timer = max(attack_lock_timer - delta, 0.0)
	attack_cooldown = max(attack_cooldown - delta, 0.0)
	hit_stun_timer = max(hit_stun_timer - delta, 0.0)
	invulnerable_timer = max(invulnerable_timer - delta, 0.0)
	_dash_timer = max(_dash_timer - delta, 0.0)
	_wing_timer = max(_wing_timer - delta, 0.0)
	mana = min(MAX_MANA, mana + delta * MANA_REGEN_PER_SECOND)

	if not is_on_floor():
		velocity.y += _get_active_gravity() * delta
	else:
		jumps_left = 1

	if _wing_timer > 0.0 and not is_on_floor():
		var fall_cap := 80.0 if Input.is_action_pressed("jump") else 150.0
		velocity.y = min(velocity.y, fall_cap)

	if hit_stun_timer <= 0.0:
		if attack_lock_timer > 0.0:
			_process_action_lock(delta)
		else:
			_handle_input(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	move_and_slide()

	if is_on_floor():
		jumps_left = 1

	_process_scheduled_events(delta)
	_update_wing_visual()
	_update_animation()


func get_hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-15, -44), Vector2(30, 44))


func take_damage(amount: int, source_x: float) -> void:
	if dead or invulnerable_timer > 0.0:
		return

	health = max(health - float(amount), 0.0)
	invulnerable_timer = 0.7
	hit_stun_timer = 0.18
	attack_lock_timer = 0.0
	_dash_timer = 0.0
	_dash_speed = 0.0
	_wing_timer = 0.0
	_clear_pending_events()
	velocity.x = 240.0 * sign(global_position.x - source_x)
	velocity.y = -240.0
	_sprite.play("hit", true)
	status_requested.emit("You took damage.")

	if health <= 0.0:
		_die()


func restore_resources() -> void:
	health = MAX_HEALTH
	mana = MAX_MANA
	status_requested.emit("Health and mana restored.")


func _process_action_lock(delta: float) -> void:
	if _dash_timer > 0.0:
		velocity.x = _dash_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta * 0.35)


func _handle_input(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = int(sign(direction))

	var target_speed := direction * MOVE_SPEED
	var accel := ACCELERATION if absf(target_speed) > 0.01 else FRICTION
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_FORCE
			status_requested.emit("Jump.")
		elif _wing_timer > 0.0:
			velocity.y = DOUBLE_JUMP_FORCE
			status_requested.emit("Jump boosted by glide.")
		elif jumps_left > 0:
			jumps_left -= 1
			velocity.y = DOUBLE_JUMP_FORCE
			status_requested.emit("Double jump.")

	if Input.is_action_just_pressed("skill_t"):
		_cast_t()
		return

	if attack_cooldown > 0.0:
		return

	if Input.is_action_just_pressed("attack"):
		_start_normal_attack()
	elif Input.is_action_just_pressed("skill_q"):
		_cast_q()
	elif Input.is_action_just_pressed("skill_w"):
		_cast_w()
	elif Input.is_action_just_pressed("skill_e"):
		_cast_e()
	elif Input.is_action_just_pressed("skill_r"):
		_cast_r()


func _start_normal_attack() -> void:
	var hit_delay: float = _animation_frame_delay("attack", 3)
	var total_duration: float = max(_animation_duration("attack"), hit_delay + 0.18)
	_begin_action("attack", total_duration + 0.04, total_duration)
	_schedule_event(hit_delay, {
		"type": "attack",
		"forward": 96.0,
		"back": 22.0,
		"top_offset": -88.0,
		"height": 88.0,
		"damage": NORMAL_DAMAGE,
		"knockback": 220.0,
		"include_optional": true,
	})


func _cast_q() -> void:
	if not _spend_mana(Q_COST, "Not enough mana for Q."):
		return

	var hit_delay: float = _animation_frame_delay("attack2", 3)
	var total_duration: float = max(_animation_duration("attack2"), hit_delay + 0.18)
	_begin_action("attack2", total_duration + 0.04, total_duration)
	_schedule_event(hit_delay, {
		"type": "projectile",
		"object_id": 11,
		"offset": Vector2(68, -42),
		"speed": Vector2(220.0, 0.0),
		"damage": Q_DAMAGE,
		"radius": 36.0,
		"friendly": true,
		"lifetime": 1.45,
		"scale": 0.15,
		"destroy_on_hit": false,
		"max_hits": 4,
		"hit_interval": 0.18,
	})
	status_requested.emit("Q: Hurricane.")


func _cast_w() -> void:
	if not _spend_mana(W_COST, "Not enough mana for W."):
		return

	var hit_delay: float = _animation_frame_delay("attack2", 3)
	var total_duration: float = max(_animation_duration("attack2"), hit_delay + 0.18)
	_begin_action("attack2", total_duration + 0.04, total_duration)
	_schedule_event(hit_delay, {
		"type": "projectile",
		"object_id": 73,
		"offset": Vector2(68, -34),
		"speed": Vector2(260.0, 0.0),
		"damage": W_DAMAGE,
		"radius": 54.0,
		"friendly": true,
		"lifetime": 0.55,
		"scale": 0.52,
	})
	status_requested.emit("W skill.")


func _cast_e() -> void:
	if not _spend_mana(E_COST, "Not enough mana for E."):
		return

	var hit_delay: float = _animation_frame_delay("attack2", 3)
	var total_duration: float = max(_animation_duration("attack2"), hit_delay + 0.18)
	_begin_action("attack2", total_duration + 0.04, total_duration)
	_schedule_event(hit_delay, {
		"type": "projectile",
		"object_id": 85,
		"offset": Vector2(72, -40),
		"speed": Vector2(340.0, 0.0),
		"damage": E_DAMAGE,
		"radius": 60.0,
		"friendly": true,
		"lifetime": 0.4,
		"scale": 0.58,
	})
	status_requested.emit("E skill.")


func _cast_r() -> void:
	if not _spend_mana(R_COST, "Not enough mana for R."):
		return

	var hit_delay: float = _animation_frame_delay("attack2", 3)
	var total_duration: float = max(_animation_duration("attack2"), hit_delay + 0.22)
	_begin_action("attack2", total_duration + 0.08, total_duration + 0.02)
	_schedule_event(hit_delay, {
		"type": "projectile",
		"object_id": 74,
		"offset": Vector2(28, -30),
		"speed": Vector2(220.0, 0.0),
		"damage": R_DAMAGE,
		"radius": 78.0,
		"friendly": true,
		"lifetime": 0.8,
		"scale": 0.72,
	})
	status_requested.emit("R skill.")


func _cast_t() -> void:
	if T_COST > 0.0 and not _spend_mana(T_COST, "Not enough mana for T."):
		return

	_wing_timer = 1.1
	attack_cooldown = max(attack_cooldown, 0.18)
	jumps_left = 1
	if velocity.y > T_LIFT_FORCE:
		velocity.y = T_LIFT_FORCE

	_update_wing_visual()
	status_requested.emit("T glide.")


func _begin_action(animation_name: String, cooldown: float, lock_time: float, dash_speed: float = 0.0, dash_time: float = 0.0) -> void:
	attack_cooldown = cooldown
	attack_lock_timer = lock_time
	_dash_speed = dash_speed
	_dash_timer = dash_time

	_attack_animation = animation_name
	if _sprite.get_frame_count(_attack_animation) <= 0:
		_attack_animation = "attack"
	_sprite.play(_attack_animation, true)


func _make_attack_rect(forward: float, back: float, top_offset: float, height: float) -> Rect2:
	var width := forward + back
	var left := -back if facing >= 0 else -forward
	return Rect2(global_position + Vector2(left, top_offset), Vector2(width, height))


func _update_animation() -> void:
	_sprite.set_flipped(facing < 0)
	_wing_sprite.set_flipped(facing < 0)

	if dead:
		return

	if hit_stun_timer > 0.0:
		_sprite.play("hit")
	elif attack_lock_timer > 0.0:
		_sprite.play(_attack_animation)
	elif absf(velocity.x) > 20.0:
		_sprite.play("run")
	else:
		_sprite.play("stand")


func _die() -> void:
	if dead:
		return

	dead = true
	attack_lock_timer = 0.0
	_dash_timer = 0.0
	_wing_timer = 0.0
	_clear_pending_events()
	visible = false
	effect_requested.emit({
		"object_id": 53,
		"position": global_position + Vector2(0, -30),
		"scale": 0.8,
		"lifetime": 0.7,
	})
	status_requested.emit("You were defeated. Restarting stage.")
	died.emit()


func _get_active_gravity() -> float:
	return GLIDE_GRAVITY if _wing_timer > 0.0 else GRAVITY


func _update_wing_visual() -> void:
	var should_show := _wing_timer > 0.0 and not dead
	_wing_sprite.position = Vector2(-10, -54) if facing >= 0 else Vector2(10, -54)
	if should_show and not _wing_sprite.visible:
		_wing_sprite.visible = true
		_wing_sprite.play("Default", true)
	elif not should_show and _wing_sprite.visible:
		_wing_sprite.visible = false


func _schedule_event(delay: float, event: Dictionary) -> void:
	var queued_event := event.duplicate(true)
	queued_event["delay"] = max(delay, 0.0)
	_pending_events.append(queued_event)


func _process_scheduled_events(delta: float) -> void:
	for index in range(_pending_events.size() - 1, -1, -1):
		var event := _pending_events[index]
		var remaining := float(event.get("delay", 0.0)) - delta
		event["delay"] = remaining
		if remaining > 0.0:
			_pending_events[index] = event
			continue

		_pending_events.remove_at(index)
		_fire_scheduled_event(event)


func _fire_scheduled_event(event: Dictionary) -> void:
	match String(event.get("type", "")):
		"attack":
			attack_requested.emit(
				_make_attack_rect(
					float(event.get("forward", 96.0)),
					float(event.get("back", 22.0)),
					float(event.get("top_offset", -88.0)),
					float(event.get("height", 88.0))
				),
				int(event.get("damage", NORMAL_DAMAGE)),
				float(facing) * float(event.get("knockback", 220.0)),
				bool(event.get("include_optional", true))
			)
		"projectile":
			var offset := event.get("offset", Vector2.ZERO) as Vector2
			var speed := event.get("speed", Vector2.ZERO) as Vector2
			projectile_requested.emit({
				"object_id": int(event.get("object_id", 11)),
				"position": global_position + Vector2(offset.x * facing, offset.y),
				"velocity": Vector2(speed.x * facing, speed.y),
				"damage": int(event.get("damage", Q_DAMAGE)),
				"radius": float(event.get("radius", 24.0)),
				"friendly": bool(event.get("friendly", true)),
				"lifetime": float(event.get("lifetime", 1.2)),
				"scale": float(event.get("scale", 1.0)),
				"flip_h": facing < 0,
				"destroy_on_hit": bool(event.get("destroy_on_hit", true)),
				"max_hits": int(event.get("max_hits", 1)),
				"hit_interval": float(event.get("hit_interval", 0.0)),
			})


func _clear_pending_events() -> void:
	_pending_events.clear()


func _animation_duration(animation_name: String) -> float:
	return _sprite.get_animation_duration(animation_name)


func _animation_frame_delay(animation_name: String, frame_index: int) -> float:
	var speed := _sprite.get_animation_speed(animation_name)
	if speed <= 0.0:
		return 0.0
	return float(max(frame_index, 0)) / speed


func _spend_mana(cost: float, failure_message: String) -> bool:
	if mana < cost:
		status_requested.emit(failure_message)
		return false

	mana -= cost
	return true
