extends Node

const MenuScreenBuilderScript := preload("res://scripts/ui/menu_screen_builder.gd")

const UI_TEXT := {
	"win_eyebrow": "通关完成",
	"win_title": "通关完成",
	"win_message": "Godot 4 版本已经跑通全部流程，你可以重新开始或重新选关。",
	"restart": "重新开始",
	"back_to_menu": "返回主菜单",
	"restart_hint": "从第一关重新体验完整流程。",
	"menu_hint": "回到主菜单后，可以重新查看说明或选择关卡。",
}

var _game_container: Node
var _game_view: GameView
var _ui_layer: CanvasLayer
var _screen_root: Control
var _modal_root: Control
var _background_rect: TextureRect
var _overlay_rect: ColorRect
var _music_player: AudioStreamPlayer
var _current_screen := "main_menu"
var _screen_builder = MenuScreenBuilderScript.new()


func _ready() -> void:
	_install_input_map()
	GameData.ensure_loaded()
	_build_scene_shell()
	_play_music()

	var requested_screen := _get_autostart_screen()
	var autostart_stage := _get_autostart_stage()
	if not requested_screen.is_empty():
		_show_requested_screen(requested_screen)
	elif autostart_stage.is_empty():
		_show_main_menu()
	else:
		_start_stage(autostart_stage)


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
	_register_action("toggle_fullscreen", [KEY_F11])


func _unhandled_input(event: InputEvent) -> void:
	if _modal_root.visible and event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			_hide_help_modal()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("toggle_fullscreen"):
		_toggle_fullscreen()


func _toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var next_mode := DisplayServer.WINDOW_MODE_FULLSCREEN
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		next_mode = DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(next_mode)


func _register_action(action: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	for existing in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, existing)

	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


func _build_scene_shell() -> void:
	_game_container = Node.new()
	add_child(_game_container)

	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	_screen_root = Control.new()
	_screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(_screen_root)

	_background_rect = TextureRect.new()
	_background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_screen_root.add_child(_background_rect)

	_overlay_rect = ColorRect.new()
	_overlay_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_rect.color = Color(0, 0, 0, 0.48)
	_screen_root.add_child(_overlay_rect)

	_modal_root = Control.new()
	_modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_root.visible = false
	_ui_layer.add_child(_modal_root)

	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -7.0
	_music_player.finished.connect(func() -> void:
		if _music_player.stream != null:
			_music_player.play()
	)
	add_child(_music_player)


func _play_music() -> void:
	for resource_path in _get_music_candidates():
		if not ResourceLoader.exists(resource_path):
			continue

		var stream := load(resource_path)
		if stream == null:
			continue

		if stream is AudioStreamOggVorbis:
			stream.loop = true
		elif stream is AudioStreamMP3:
			stream.loop = true

		if _music_player.stream == stream and _music_player.playing:
			return

		_music_player.stream = stream
		_music_player.play()
		return


func _get_music_candidates() -> Array[String]:
	var candidates: Array[String] = []
	var menu_assets := GameData.get_menu_assets()
	var configured_music := String(menu_assets.get("music", ""))
	if not configured_music.is_empty():
		_append_music_candidate(candidates, "res://assets/construct2/%s" % configured_music)

	for fallback in [
		"res://assets/construct2/media/bkmusic.mp3",
		"res://assets/construct2/media/bkmusic.ogg",
		"res://assets/construct2/media/bkmusic.m4a",
		"res://assets/construct2/media/bkmusic2.m4a",
	]:
		_append_music_candidate(candidates, fallback)
	return candidates


func _append_music_candidate(candidates: Array[String], resource_path: String) -> void:
	if resource_path.is_empty():
		return

	if resource_path.ends_with(".ogg"):
		var mp3_path := resource_path.trim_suffix(".ogg") + ".mp3"
		if not candidates.has(mp3_path):
			candidates.append(mp3_path)

	if not candidates.has(resource_path):
		candidates.append(resource_path)


func _get_autostart_stage() -> String:
	var args := OS.get_cmdline_user_args()
	var requested_stage := ""

	for index in range(args.size()):
		var arg := String(args[index])
		if arg.begins_with("--start-stage="):
			requested_stage = arg.trim_prefix("--start-stage=")
			break
		if arg == "--start-stage" and index + 1 < args.size():
			requested_stage = String(args[index + 1])
			break

	if requested_stage.is_empty():
		return ""

	if GameData.get_stage(requested_stage).is_empty():
		push_warning("Unknown start stage: %s" % requested_stage)
		return ""

	return requested_stage


func _get_autostart_screen() -> String:
	var args := OS.get_cmdline_user_args()
	var requested_screen := ""

	for index in range(args.size()):
		var arg := String(args[index])
		if arg.begins_with("--show-screen="):
			requested_screen = arg.trim_prefix("--show-screen=")
			break
		if arg == "--show-screen" and index + 1 < args.size():
			requested_screen = String(args[index + 1])
			break

	requested_screen = requested_screen.strip_edges().to_lower()
	if requested_screen in ["main_menu", "guide", "stage_select"]:
		return requested_screen
	return ""


func _show_requested_screen(screen_name: String) -> void:
	match screen_name:
		"guide":
			_show_guide_screen()
		"stage_select":
			_show_stage_select()
		_:
			_show_main_menu()


func _show_main_menu() -> void:
	_current_screen = "main_menu"
	_free_game()
	_hide_help_modal()
	_play_music()
	_prepare_screen(String(GameData.get_menu_assets().get("start_background", "")))
	var start_action := Callable(self, "_start_stage").bind("Layout 1")
	var stage_select_action := Callable(self, "_show_stage_select")
	var guide_action := Callable(self, "_show_guide_screen")
	_screen_builder.build_start_screen(
		_screen_root,
		GameData.get_menu_layout("Layout Start"),
		start_action,
		stage_select_action,
		guide_action
	)


func _show_guide_screen() -> void:
	_current_screen = "guide"
	_hide_help_modal()
	_play_music()
	_prepare_screen(String(GameData.get_menu_assets().get("guide_background", "")))
	_screen_builder.build_guide_screen(
		_screen_root,
		GameData.get_menu_layout("Layout GameShows"),
		Vector2(GameData.viewport_size()),
		Callable(self, "_show_main_menu"),
		false
	)


func _show_stage_select() -> void:
	_current_screen = "stage_select"
	_hide_help_modal()
	_play_music()
	_prepare_screen("images/bkgameshows.png")
	_screen_builder.build_stage_select_screen(
		_screen_root,
		GameData.get_menu_layout("Layout CheckpointChoice"),
		GameData.get_stage_order(),
		Callable(self, "_start_stage"),
		Callable(self, "_show_main_menu")
	)


func _show_win_screen() -> void:
	_current_screen = "win"
	_free_game()
	_hide_help_modal()
	_play_music()
	_prepare_screen(String(GameData.get_menu_assets().get("guide_background", "")), 0.42)
	_screen_builder.build_win_screen(
		_screen_root,
		String(GameData.get_menu_assets().get("win_banner", "images/textofwin.png")),
		{
			"eyebrow": _t("win_eyebrow"),
			"title": _t("win_title"),
			"message": _t("win_message"),
			"restart_label": _t("restart"),
			"restart_hint": _t("restart_hint"),
			"menu_label": _t("back_to_menu"),
			"menu_hint": _t("menu_hint"),
		},
		Callable(self, "_start_stage").bind("Layout 1"),
		Callable(self, "_show_main_menu")
	)


func _show_help_modal() -> void:
	_clear_children(_modal_root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.03, 0.05, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_root.add_child(backdrop)

	_screen_builder.build_guide_screen(
		_modal_root,
		GameData.get_menu_layout("Layout GameShows"),
		Vector2(GameData.viewport_size()),
		Callable(self, "_hide_help_modal"),
		true
	)

	_modal_root.visible = true
	_set_game_interaction_enabled(false)


func _hide_help_modal() -> void:
	_modal_root.visible = false
	_clear_children(_modal_root)
	_set_game_interaction_enabled(true)


func _start_stage(stage_name: String) -> void:
	_current_screen = "game"
	_hide_help_modal()
	_play_music()
	_screen_root.visible = false

	if _game_view == null:
		_game_view = GameView.new()
		_game_view.request_return_to_menu.connect(_show_main_menu)
		_game_view.request_help.connect(_show_help_modal)
		_game_view.game_completed.connect(_show_win_screen)
		_game_container.add_child(_game_view)

	_set_game_interaction_enabled(true)
	_game_view.start_stage(stage_name)


func _prepare_screen(background_asset: String, overlay_alpha: float = 0.0) -> void:
	_screen_root.visible = true
	_clear_children(_screen_root, [_background_rect, _overlay_rect])
	_background_rect.texture = GameData.get_texture(background_asset)
	_overlay_rect.color = Color(0.01, 0.02, 0.04, overlay_alpha)


func _clear_children(parent: Node, preserve: Array[Node] = []) -> void:
	for child in parent.get_children():
		if preserve.has(child):
			continue
		child.queue_free()


func _set_game_interaction_enabled(enabled: bool) -> void:
	if _game_view == null:
		return
	_game_view.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED


func _free_game() -> void:
	if _game_view != null:
		_game_view.queue_free()
		_game_view = null


func _t(key: String) -> String:
	return String(UI_TEXT.get(key, key))
