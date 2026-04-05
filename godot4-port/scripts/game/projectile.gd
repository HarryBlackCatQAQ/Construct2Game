class_name CombatProjectile
extends Node2D

var arena: Node
var velocity := Vector2.ZERO
var radius := 24.0
var damage := 10
var friendly := true
var lifetime := 1.2
var object_id := 11
var scale_factor := 1.0
var flip_h := false
var destroy_on_hit := true
var max_hits := 1
var hit_interval := 0.0

var _sprite: ConstructSprite
var _hit_count := 0
var _recent_hits: Dictionary = {}


func _ready() -> void:
	_sprite = ConstructSprite.new()
	_sprite.setup_from_object(object_id)
	_sprite.play("Default", true)
	_sprite.scale = Vector2.ONE * scale_factor
	_sprite.set_flipped(flip_h)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	_tick_recent_hits(delta)

	if lifetime <= 0.0:
		queue_free()
		return

	if arena == null:
		return

	if friendly:
		_process_friendly_hits()
	else:
		var player = arena.get_player()
		if player != null:
			var projectile_rect := Rect2(global_position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
			if player.get_hurt_rect().intersects(projectile_rect):
				player.take_damage(damage, global_position.x)
				queue_free()


func _process_friendly_hits() -> void:
	if not arena.has_method("get_damageable_enemies"):
		var hit: bool = bool(arena.damage_enemies_in_circle(global_position, radius, damage, velocity.x * 0.18, true))
		if hit and destroy_on_hit:
			queue_free()
		return

	var projectile_rect := Rect2(global_position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	for enemy in arena.get_damageable_enemies(true):
		if enemy == null or enemy.dead:
			continue
		if not enemy.get_hurt_rect().intersects(projectile_rect):
			continue

		var enemy_id: int = enemy.get_instance_id()
		if hit_interval > 0.0 and _recent_hits.has(enemy_id):
			continue

		enemy.take_damage(damage, velocity.x * 0.18)
		_hit_count += 1

		if hit_interval > 0.0:
			_recent_hits[enemy_id] = hit_interval

		if destroy_on_hit:
			queue_free()
			return

		if max_hits > 0 and _hit_count >= max_hits:
			queue_free()
			return


func _tick_recent_hits(delta: float) -> void:
	if _recent_hits.is_empty():
		return

	for key in _recent_hits.keys():
		var remaining := float(_recent_hits[key]) - delta
		if remaining <= 0.0:
			_recent_hits.erase(key)
		else:
			_recent_hits[key] = remaining
