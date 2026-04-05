class_name GameData
extends RefCounted

static var _loaded := false
static var _data: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _atlas_cache: Dictionary = {}


static func ensure_loaded() -> void:
	if _loaded:
		return

	var file := FileAccess.open("res://data/construct2_export.json", FileAccess.READ)
	if file == null:
		push_error("Unable to open res://data/construct2_export.json")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("construct2_export.json does not contain a dictionary root.")
		return

	_data = parsed
	_loaded = true


static func viewport_size() -> Vector2i:
	ensure_loaded()
	var viewport: Dictionary = _data.get("viewport", {})
	return Vector2i(
		int(viewport.get("width", 1709)),
		int(viewport.get("height", 960))
	)


static func get_stage_order() -> Array[String]:
	ensure_loaded()
	var source: Array = _data.get("stage_order", [])
	var result: Array[String] = []
	for item in source:
		result.append(String(item))
	return result


static func get_stage(name: String) -> Dictionary:
	ensure_loaded()
	var stages: Dictionary = _data.get("stages", {})
	return stages.get(name, {})


static func get_menu_assets() -> Dictionary:
	ensure_loaded()
	return _data.get("menu_assets", {})


static func get_menu_layout(name: String) -> Dictionary:
	ensure_loaded()
	var layouts: Dictionary = _data.get("menu_layouts", {})
	return layouts.get(name, {})


static func get_object_def(object_id: int) -> Dictionary:
	ensure_loaded()
	var objects: Dictionary = _data.get("objects", {})
	var definition: Dictionary = objects.get(str(object_id), {})
	if object_id == 11:
		return _with_hurricane_animation(definition)
	return definition


static func object_has_animation(object_id: int) -> bool:
	var definition := get_object_def(object_id)
	var animations: Dictionary = definition.get("animations", {})
	return not animations.is_empty()


static func get_texture(asset: String) -> Texture2D:
	ensure_loaded()
	if asset.is_empty():
		return null

	if not _texture_cache.has(asset):
		var texture_path := "res://assets/construct2/%s" % asset
		_texture_cache[asset] = load(texture_path)
	return _texture_cache.get(asset)


static func get_frame_data(object_id: int, animation_name: String = "Default", frame_index: int = 0) -> Dictionary:
	var definition := get_object_def(object_id)
	var animations: Dictionary = definition.get("animations", {})
	if animations.is_empty():
		return {}

	var chosen_name := animation_name
	if not animations.has(chosen_name):
		chosen_name = String(animations.keys()[0])

	var animation: Dictionary = animations.get(chosen_name, {})
	var frames: Array = animation.get("frames", [])
	if frames.is_empty():
		return {}

	var safe_index := clampi(frame_index, 0, frames.size() - 1)
	return frames[safe_index]


static func get_atlas_texture(asset: String, region: Array) -> Texture2D:
	ensure_loaded()
	if region.size() < 4:
		return get_texture(asset)

	var cache_key := "%s:%d:%d:%d:%d" % [
		asset,
		int(region[0]),
		int(region[1]),
		int(region[2]),
		int(region[3]),
	]

	if not _atlas_cache.has(cache_key):
		var atlas := AtlasTexture.new()
		atlas.atlas = get_texture(asset)
		atlas.region = Rect2(
			float(region[0]),
			float(region[1]),
			float(region[2]),
			float(region[3])
		)
		_atlas_cache[cache_key] = atlas
	return _atlas_cache.get(cache_key)


static func get_frame_texture(frame: Dictionary) -> Texture2D:
	return get_atlas_texture(String(frame.get("asset", "")), frame.get("region", []))


static func _with_hurricane_animation(definition: Dictionary) -> Dictionary:
	if definition.is_empty():
		return {}

	var animations: Dictionary = definition.get("animations", {})
	if not animations.is_empty():
		return definition

	var patched := definition.duplicate(true)
	patched["animations"] = {
		"Default": {
			"speed": 8.0,
			"loop": true,
			"frames": [
				{"asset": "images/playerskillhurricane-sheet0.png", "region": [1, 1, 674, 592], "size": [674, 592], "origin": [0.5, 0.5]},
				{"asset": "images/playerskillhurricane-sheet0.png", "region": [677, 1, 674, 592], "size": [674, 592], "origin": [0.5, 0.5]},
				{"asset": "images/playerskillhurricane-sheet0.png", "region": [1353, 1, 674, 592], "size": [674, 592], "origin": [0.5, 0.5]},
				{"asset": "images/playerskillhurricane-sheet0.png", "region": [1, 595, 674, 592], "size": [674, 592], "origin": [0.5, 0.5]},
				{"asset": "images/playerskillhurricane-sheet0.png", "region": [677, 595, 674, 592], "size": [674, 592], "origin": [0.5, 0.5]},
				{"asset": "images/playerskillhurricane-sheet0.png", "region": [1353, 595, 674, 592], "size": [674, 592], "origin": [0.5, 0.5]},
			],
		},
	}
	return patched
