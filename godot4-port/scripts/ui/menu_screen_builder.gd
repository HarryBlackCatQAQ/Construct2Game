class_name MenuScreenBuilder
extends RefCounted

const ConstructSpriteScript := preload("res://scripts/game/construct_sprite.gd")

const UI_TEXT := {
	"guide_hint": "滚轮可查看完整说明，游戏中打开帮助时会自动暂停。",
	"guide_missing": "未找到游戏说明图片。",
	"close": "关闭",
	"back_to_menu": "返回主菜单",
}

var _standalone_texture_cache: Dictionary = {}

func build_start_screen(parent: Control, layout: Dictionary, on_start: Callable, on_stage_select: Callable, on_guide: Callable) -> void:
	_build_construct2_layout(
		parent,
		layout,
		{
			56: on_start,
			115: on_stage_select,
			59: on_guide,
		}
	)


func build_stage_select_screen(parent: Control, layout: Dictionary, stage_order: Array[String], on_stage_selected: Callable, on_back: Callable) -> void:
	var callbacks := {
		83: on_back,
	}

	var stage_button_ids := [104, 105, 106, 107, 108]
	for index in range(min(stage_button_ids.size(), stage_order.size())):
		callbacks[stage_button_ids[index]] = on_stage_selected.bind(String(stage_order[index]))

	_build_construct2_layout(parent, layout, callbacks)


func build_guide_screen(parent: Control, _layout: Dictionary, viewport_size: Vector2, exit_action: Callable, in_modal: bool = false) -> void:
	if in_modal:
		_build_help_modal(parent, viewport_size, exit_action)
	else:
		_build_help_page(parent, exit_action)


func build_win_screen(parent: Control, win_banner_asset: String, copy: Dictionary, on_restart: Callable, on_back_to_menu: Callable) -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 0)
	_style_main_panel(panel)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(680, 0)
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	vbox.add_child(_make_eyebrow_label(String(copy.get("eyebrow", ""))))
	vbox.add_child(_make_texture_banner(win_banner_asset, 520.0))
	vbox.add_child(_make_title_label(String(copy.get("title", "")), 34))
	vbox.add_child(_make_body_label(String(copy.get("message", "")), true))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 18)
	vbox.add_child(actions)

	actions.add_child(_make_win_action_card(
		"images/textofrestart.png",
		String(copy.get("restart_hint", "")),
		String(copy.get("restart_label", "")),
		on_restart,
		true
	))
	actions.add_child(_make_win_action_card(
		"images/textofreturnmain-sheet0.png",
		String(copy.get("menu_hint", "")),
		String(copy.get("menu_label", "")),
		on_back_to_menu,
		false
	))


func _build_construct2_layout(parent: Control, layout: Dictionary, callbacks: Dictionary) -> void:
	if layout.is_empty():
		return

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(root)

	for element in layout.get("elements", []):
		if element is not Dictionary:
			continue

		var entry := element as Dictionary
		var asset := String(entry.get("asset", ""))
		if asset.is_empty():
			continue

		if asset == String(layout.get("background_asset", "")):
			continue

		var object_id := int(entry.get("object_id", -1))
		if GameData.object_has_animation(object_id):
			_add_construct2_animated_sprite(root, entry)
		elif callbacks.has(object_id):
			_add_construct2_button(root, entry, callbacks[object_id])
		else:
			_add_construct2_texture(root, entry)


func _build_help_page(parent: Control, exit_action: Callable) -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(root)

	var image_rect := TextureRect.new()
	image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_rect.texture = _load_texture("res://assets/wails-app/gameShowsImage.png")
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(image_rect)

	var back_button := _make_legacy_compact_button_control(
		Vector2(300, 57),
		"images/textofreturnmain-sheet0.png",
		Vector2(270, 57),
		exit_action
	)
	var viewport_size := Vector2(GameData.viewport_size())
	back_button.position = Vector2(viewport_size.x - 332.0, viewport_size.y - 81.0)
	root.add_child(back_button)


func _build_help_modal(parent: Control, viewport_size: Vector2, exit_action: Callable) -> void:
	var margin := _make_margin(
		parent,
		96,
		72,
		96,
		72
	)

	var shell := VBoxContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_theme_constant_override("separation", 18)
	margin.add_child(shell)

	shell.add_child(_make_texture_banner("images/textofgameshow.png", 520.0))
	shell.add_child(_make_body_label(_t("guide_hint"), true))

	var frame := _make_help_frame()
	frame.custom_minimum_size = Vector2(0, 0)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(frame)

	var max_width := maxf(720.0, viewport_size.x - 192.0)
	var showcase := _make_guide_showcase(max_width)
	showcase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	showcase.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(showcase)

	var footer := HBoxContainer.new()
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var close_button := _make_menu_button(_t("close"), exit_action, true)
	close_button.custom_minimum_size = Vector2(180, 48)
	footer.add_child(close_button)
	shell.add_child(footer)


func _make_guide_showcase(max_width: float) -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var padding := MarginContainer.new()
	padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padding.size_flags_vertical = Control.SIZE_EXPAND_FILL
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 12)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(padding)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	padding.add_child(center)

	var guide_texture := _load_texture("res://assets/wails-app/gameShowsImage.png")
	if guide_texture == null:
		center.add_child(_make_body_label(_t("guide_missing"), true))
		return scroll

	var image_rect := TextureRect.new()
	image_rect.texture = guide_texture
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.stretch_mode = TextureRect.STRETCH_SCALE
	image_rect.custom_minimum_size = _fit_texture_width(guide_texture.get_size(), max_width)
	center.add_child(image_rect)
	return scroll


func _add_construct2_texture(parent: Control, entry: Dictionary) -> TextureRect:
	var texture := _resolve_entry_texture(entry)
	return _add_legacy_texture(
		parent,
		"",
		_position_from_entry(entry),
		_to_vector2(entry.get("size", [0, 0])),
		texture
	)


func _add_construct2_animated_sprite(parent: Control, entry: Dictionary) -> Node2D:
	var sprite = ConstructSpriteScript.new()
	sprite.setup_from_object(int(entry.get("object_id", -1)))
	sprite.play(String(entry.get("animation", "Default")), true)
	sprite.position = _to_vector2(entry.get("position", [0, 0]))

	var frame_size := sprite.get_current_frame_size()
	var desired_size := _to_vector2(entry.get("size", [frame_size.x, frame_size.y]))
	sprite.scale = Vector2(
		desired_size.x / max(frame_size.x, 1.0),
		desired_size.y / max(frame_size.y, 1.0)
	)
	parent.add_child(sprite)
	return sprite


func _add_construct2_button(parent: Control, entry: Dictionary, callback: Callable) -> TextureButton:
	var texture := _resolve_entry_texture(entry)
	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.position = _position_from_entry(entry)
	button.size = _to_vector2(entry.get("size", [0, 0]))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _make_help_frame() -> PanelContainer:
	var frame := PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.06, 0.03, 0.18)
	style.border_color = Color(1, 0.94, 0.86, 0.12)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	frame.add_theme_stylebox_override("panel", style)
	return frame


func _make_legacy_compact_button_control(
	button_size: Vector2,
	text_asset: String,
	text_size: Vector2,
	callback: Callable
) -> Control:
	var wrapper := Control.new()
	wrapper.size = button_size

	var texture := GameData.get_texture("images/buttonofstart-sheet0.png")
	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.size = button_size
	button.pressed.connect(callback)
	wrapper.add_child(button)

	var label := TextureRect.new()
	label.texture = GameData.get_texture(text_asset)
	label.position = Vector2((button_size.x - text_size.x) * 0.5, (button_size.y - text_size.y) * 0.5)
	label.size = text_size
	label.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	label.stretch_mode = TextureRect.STRETCH_SCALE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(label)
	return wrapper


func _resolve_entry_texture(entry: Dictionary) -> Texture2D:
	var object_id := int(entry.get("object_id", -1))
	if object_id >= 0 and GameData.object_has_animation(object_id):
		var frame := GameData.get_frame_data(
			object_id,
			String(entry.get("animation", "Default")),
			int(entry.get("frame", 0))
		)
		var frame_texture := GameData.get_frame_texture(frame)
		if frame_texture != null:
			return frame_texture
	return GameData.get_texture(String(entry.get("asset", "")))


func _make_margin(parent: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	parent.add_child(margin)
	return margin


func _position_from_entry(entry: Dictionary) -> Vector2:
	return _to_vector2(entry.get("position", [0, 0])) - (
		_to_vector2(entry.get("size", [0, 0])) * _to_vector2(entry.get("origin", [0, 0]))
	)


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


func _add_legacy_texture(parent: Control, asset: String, position: Vector2, size: Vector2, texture_override: Texture2D = null) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture_override if texture_override != null else GameData.get_texture(asset)
	rect.position = position
	rect.size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _add_legacy_menu_button(
	parent: Control,
	text_asset: String,
	position: Vector2,
	text_size: Vector2,
	button_offset: Vector2,
	callback: Callable,
	button_size: Vector2 = Vector2(250, 57)
) -> Control:
	var wrapper := Control.new()
	wrapper.position = position
	wrapper.size = text_size
	parent.add_child(wrapper)

	var texture := GameData.get_texture("images/buttonofstart-sheet0.png")
	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.position = button_offset
	button.size = button_size
	button.pressed.connect(callback)
	wrapper.add_child(button)

	var label := TextureRect.new()
	label.texture = GameData.get_texture(text_asset)
	label.size = text_size
	label.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	label.stretch_mode = TextureRect.STRETCH_SCALE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(label)
	return wrapper


func _make_win_action_card(texture_asset: String, description: String, button_text: String, callback: Callable, accent: bool) -> PanelContainer:
	var card := _make_surface_card(Vector2(0, 220))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	vbox.add_child(_make_texture_banner(texture_asset, 360.0))
	vbox.add_child(_make_body_label(description))
	vbox.add_child(_make_menu_button(button_text, callback, accent))
	return card


func _style_main_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.11, 0.94)
	style.border_color = Color(0.92, 0.75, 0.45, 0.34)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_right = 28
	style.corner_radius_bottom_left = 28
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 24
	style.content_margin_left = 26
	style.content_margin_top = 26
	style.content_margin_right = 26
	style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", style)


func _make_surface_card(minimum_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = minimum_size

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.04)
	style.border_color = Color(1, 1, 1, 0.08)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.content_margin_left = 18
	style.content_margin_top = 18
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", style)
	return card


func _make_eyebrow_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.94, 0.76, 0.44, 1))
	return label


func _make_title_label(text: String, font_size: int = 32) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.97, 0.91, 0.78, 1))
	return label


func _make_body_label(text: String, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_color_override("font_color", Color(0.76, 0.71, 0.62, 1))
	label.add_theme_font_size_override("font_size", 15)
	return label


func _make_texture_banner(asset: String, max_width: float = 570.0) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = GameData.get_texture(asset)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if rect.texture != null:
		var size: Vector2 = rect.texture.get_size()
		var width: float = minf(max_width, size.x)
		var height: float = size.y * (width / maxf(size.x, 1.0))
		rect.custom_minimum_size = Vector2(width, height)
	return rect


func _style_button(button: Button, accent: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 999
	normal.corner_radius_top_right = 999
	normal.corner_radius_bottom_right = 999
	normal.corner_radius_bottom_left = 999

	var hover := normal.duplicate()
	var pressed := normal.duplicate()

	if accent:
		normal.bg_color = Color(0.85, 0.62, 0.24, 0.98)
		normal.border_color = Color(0.95, 0.8, 0.52, 0.46)
		hover.bg_color = Color(0.9, 0.68, 0.29, 0.98)
		hover.border_color = Color(0.98, 0.85, 0.56, 0.52)
		pressed.bg_color = Color(0.77, 0.54, 0.18, 0.98)
		pressed.border_color = Color(0.92, 0.72, 0.42, 0.52)
		button.add_theme_color_override("font_color", Color(0.14, 0.1, 0.05, 1))
	else:
		normal.bg_color = Color(1, 1, 1, 0.06)
		normal.border_color = Color(1, 1, 1, 0.08)
		hover.bg_color = Color(1, 1, 1, 0.1)
		hover.border_color = Color(0.92, 0.75, 0.45, 0.24)
		pressed.bg_color = Color(1, 1, 1, 0.12)
		pressed.border_color = Color(0.92, 0.75, 0.45, 0.32)
		button.add_theme_color_override("font_color", Color(0.97, 0.91, 0.78, 1))

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_font_size_override("font_size", 16)


func _make_menu_button(text: String, callback: Callable, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.pressed.connect(callback)
	_style_button(button, accent)
	return button


func _fit_texture_width(texture_size: Vector2, max_width: float) -> Vector2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2(max_width, max_width)

	var width := minf(max_width, texture_size.x)
	var ratio := width / maxf(texture_size.x, 1.0)
	return Vector2(width, texture_size.y * ratio)


func _load_texture(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null

	if _standalone_texture_cache.has(resource_path):
		return _standalone_texture_cache.get(resource_path)

	var texture := load(resource_path) as Texture2D
	if texture == null:
		var remapped_path := _get_imported_texture_path(resource_path)
		if not remapped_path.is_empty():
			texture = load(remapped_path) as Texture2D
	if texture == null:
		var fallback_image := Image.new()
		if fallback_image.load(ProjectSettings.globalize_path(resource_path)) == OK:
			texture = ImageTexture.create_from_image(fallback_image)

	_standalone_texture_cache[resource_path] = texture
	return texture


func _get_imported_texture_path(resource_path: String) -> String:
	var import_path := resource_path + ".import"
	if not FileAccess.file_exists(import_path):
		return ""

	var config := ConfigFile.new()
	if config.load(import_path) != OK:
		return ""

	return String(config.get_value("remap", "path", ""))


func _t(key: String) -> String:
	return String(UI_TEXT.get(key, key))
