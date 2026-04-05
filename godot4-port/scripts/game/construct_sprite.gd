class_name ConstructSprite
extends Node2D

signal animation_finished(animation_name: String)

var object_id := -1
var current_animation := ""
var current_frame_index := 0
var playing := true
var speed_scale := 1.0
var auto_free_on_finish := false
var anchor_origin := Vector2(-1, -1)

var _definition: Dictionary = {}
var _animations: Dictionary = {}
var _elapsed := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_ensure_sprite()


func _process(delta: float) -> void:
	if not playing or _animations.is_empty() or current_animation.is_empty():
		return

	var animation: Dictionary = _animations.get(current_animation, {})
	var frames: Array = animation.get("frames", [])
	if frames.size() <= 1:
		return

	var fps := float(animation.get("speed", 8.0)) * speed_scale
	if fps <= 0.0:
		return

	_elapsed += delta
	var frame_time := 1.0 / fps

	while _elapsed >= frame_time:
		_elapsed -= frame_time
		current_frame_index += 1
		if current_frame_index >= frames.size():
			if bool(animation.get("loop", true)):
				current_frame_index = 0
			else:
				current_frame_index = frames.size() - 1
				playing = false
				_apply_current_frame()
				animation_finished.emit(current_animation)
				if auto_free_on_finish:
					queue_free()
				return
		_apply_current_frame()


func setup_from_object(new_object_id: int) -> void:
	_ensure_sprite()
	object_id = new_object_id
	_definition = GameData.get_object_def(new_object_id)
	_animations = _definition.get("animations", {})
	current_animation = ""
	current_frame_index = 0
	_elapsed = 0.0
	playing = true

	if _animations.is_empty():
		return

	current_animation = String(_animations.keys()[0])
	_apply_current_frame()


func play(animation_name: String, restart: bool = false) -> void:
	if _animations.is_empty():
		return

	var chosen_name := animation_name
	if not _animations.has(chosen_name):
		chosen_name = String(_animations.keys()[0])

	if restart or chosen_name != current_animation:
		current_animation = chosen_name
		current_frame_index = 0
		_elapsed = 0.0

	playing = true
	_apply_current_frame()


func set_static_frame(new_object_id: int, animation_name: String = "Default", frame_index: int = 0) -> void:
	setup_from_object(new_object_id)
	if _animations.is_empty():
		return

	var chosen_name := animation_name
	if not _animations.has(chosen_name):
		chosen_name = String(_animations.keys()[0])

	current_animation = chosen_name
	current_frame_index = clampi(frame_index, 0, get_frame_count(current_animation) - 1)
	playing = false
	_apply_current_frame()


func get_frame_count(animation_name: String = "") -> int:
	if _animations.is_empty():
		return 0

	var animation := _get_animation_data(animation_name)
	var frames: Array = animation.get("frames", [])
	return frames.size()


func get_animation_speed(animation_name: String = "") -> float:
	var animation := _get_animation_data(animation_name)
	return float(animation.get("speed", 0.0))


func get_animation_duration(animation_name: String = "") -> float:
	var frame_count := get_frame_count(animation_name)
	var speed := get_animation_speed(animation_name)
	if frame_count <= 0 or speed <= 0.0:
		return 0.0
	return float(frame_count) / speed


func is_animation_looping(animation_name: String = "") -> bool:
	var animation := _get_animation_data(animation_name)
	return bool(animation.get("loop", true))


func get_current_frame_size() -> Vector2:
	if _animations.is_empty() or current_animation.is_empty():
		return Vector2.ONE

	var animation: Dictionary = _animations.get(current_animation, {})
	var frames: Array = animation.get("frames", [])
	if frames.is_empty():
		return Vector2.ONE

	var frame: Dictionary = frames[clampi(current_frame_index, 0, frames.size() - 1)]
	var size: Array = frame.get("size", [1, 1])
	return Vector2(float(size[0]), float(size[1]))


func set_flipped(value: bool) -> void:
	_ensure_sprite()
	_sprite.flip_h = value


func _ensure_sprite() -> void:
	if _sprite != null:
		return

	_sprite = Sprite2D.new()
	_sprite.centered = true
	add_child(_sprite)


func _apply_current_frame() -> void:
	if _animations.is_empty() or current_animation.is_empty():
		return

	var animation: Dictionary = _animations.get(current_animation, {})
	var frames: Array = animation.get("frames", [])
	if frames.is_empty():
		return

	var safe_index := clampi(current_frame_index, 0, frames.size() - 1)
	var frame: Dictionary = frames[safe_index]
	var texture := GameData.get_frame_texture(frame)
	var size: Array = frame.get("size", [1, 1])
	var origin: Array = frame.get("origin", [0.5, 0.5])
	var width := float(size[0])
	var height := float(size[1])
	var origin_x := float(origin[0])
	var origin_y := float(origin[1])
	if anchor_origin.x >= 0.0:
		origin_x = anchor_origin.x
	if anchor_origin.y >= 0.0:
		origin_y = anchor_origin.y

	_sprite.texture = texture
	_sprite.offset = Vector2((0.5 - origin_x) * width, (0.5 - origin_y) * height)


func _get_animation_data(animation_name: String) -> Dictionary:
	if _animations.is_empty():
		return {}

	var chosen_name := animation_name
	if chosen_name.is_empty() or not _animations.has(chosen_name):
		chosen_name = String(_animations.keys()[0])

	return _animations.get(chosen_name, {})
