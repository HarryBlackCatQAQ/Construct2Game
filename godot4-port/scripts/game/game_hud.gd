class_name GameHud
extends CanvasLayer

signal menu_requested
signal help_requested
signal restart_requested

var _root: Control
var _status_label: Label
var _controls_label: Label
var _stage_label: Label
var _enemy_label: Label
var _fps_label: Label
var _menu_button: Button
var _help_button: Button
var _restart_button: Button
var _health_text_label: Label
var _mana_text_label: Label
var _health_bar: ProgressBar
var _mana_bar: ProgressBar
var _portal_hint: Label


func ensure_built() -> void:
	if _root != null:
		return

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var top_bar := HBoxContainer.new()
	top_bar.position = Vector2(24, 20)
	top_bar.custom_minimum_size = Vector2(1660, 40)
	_root.add_child(top_bar)

	_menu_button = Button.new()
	_menu_button.pressed.connect(func() -> void:
		menu_requested.emit()
	)
	top_bar.add_child(_menu_button)

	_help_button = Button.new()
	_help_button.pressed.connect(func() -> void:
		help_requested.emit()
	)
	top_bar.add_child(_help_button)

	_restart_button = Button.new()
	_restart_button.pressed.connect(func() -> void:
		restart_requested.emit()
	)
	top_bar.add_child(_restart_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	_stage_label = Label.new()
	top_bar.add_child(_stage_label)

	_enemy_label = Label.new()
	top_bar.add_child(_enemy_label)

	_fps_label = Label.new()
	top_bar.add_child(_fps_label)

	var info_panel := PanelContainer.new()
	info_panel.position = Vector2(24, 72)
	info_panel.custom_minimum_size = Vector2(380, 120)
	_root.add_child(info_panel)

	var info_vbox := VBoxContainer.new()
	info_panel.add_child(info_vbox)

	_health_text_label = Label.new()
	info_vbox.add_child(_health_text_label)

	_health_bar = ProgressBar.new()
	_health_bar.min_value = 0.0
	_health_bar.max_value = Hero.MAX_HEALTH
	_health_bar.value = Hero.MAX_HEALTH
	_health_bar.show_percentage = true
	info_vbox.add_child(_health_bar)

	_mana_text_label = Label.new()
	info_vbox.add_child(_mana_text_label)

	_mana_bar = ProgressBar.new()
	_mana_bar.min_value = 0.0
	_mana_bar.max_value = Hero.MAX_MANA
	_mana_bar.value = Hero.MAX_MANA
	_mana_bar.show_percentage = true
	info_vbox.add_child(_mana_bar)

	_controls_label = Label.new()
	_controls_label.position = Vector2(24, 200)
	_root.add_child(_controls_label)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.size = Vector2(1400, 32)
	_status_label.position = Vector2(154, 912)
	_root.add_child(_status_label)

	_portal_hint = Label.new()
	_portal_hint.position = Vector2(1360, 72)
	_root.add_child(_portal_hint)


func set_button_texts(menu_text: String, help_text: String, restart_text: String, health_text: String, mana_text: String, controls_text: String) -> void:
	ensure_built()
	_menu_button.text = menu_text
	_help_button.text = help_text
	_restart_button.text = restart_text
	_health_text_label.text = health_text
	_mana_text_label.text = mana_text
	_controls_label.text = controls_text


func update_runtime(stage_text: String, enemy_text: String, fps_text: String, health: float, mana: float, has_player: bool) -> void:
	ensure_built()
	_stage_label.text = stage_text
	_enemy_label.text = enemy_text
	_fps_label.text = fps_text

	if has_player:
		_health_bar.value = health
		_mana_bar.value = mana


func reset_resources() -> void:
	ensure_built()
	_health_bar.value = Hero.MAX_HEALTH
	_mana_bar.value = Hero.MAX_MANA


func set_status(message: String) -> void:
	ensure_built()
	_status_label.text = message


func set_portal_hint(message: String) -> void:
	ensure_built()
	_portal_hint.text = message


func get_health_bar() -> ProgressBar:
	ensure_built()
	return _health_bar


func get_mana_bar() -> ProgressBar:
	ensure_built()
	return _mana_bar
