extends Node

# Scene paths
const ACTIVITIES_SCENE_PATH: String = "res://scenes/ui/activities_panel.tscn"
const STATS_SCENE_PATH: String = "res://scenes/ui/stats_panel.tscn"
const SOCIAL_HUB_SCENE_PATH: String = "res://scenes/ui/social_hub_panel.tscn"
const LOVE_BOOK_SCENE_PATH: String = "res://scenes/ui/love_book.tscn"
const BOTTOM_BUTTONS_PATH: String = "res://scenes/ui/bottom_buttons.tscn"
const RESOURCE_PANEL_PATH: String = "res://scenes/ui/resources_panel.tscn"
const CHARACTER_CARD_PATH: String = "res://scenes/ui/character_card.tscn"
const GIFT_MENU_SCENE_PATH: String = "res://scenes/ui/gift_menu.tscn"
const MAP_SCENE_PATH: String = "res://scenes/main/map_scene.tscn"
const ACTIVITY_INDICATOR_SCENE_PATH: String = "res://scenes/ui/activity_indicator.tscn"
const PAUSE_MENU_SCENE_PATH: String = "res://scenes/ui/pause_menu.tscn"
const DATE_MENU_SCENE_PATH: String = "res://scenes/ui/date_menu.tscn"
const CONTINUE_POPUP = preload("res://scenes/ui/continue_activity_popup.tscn")

const FADE_DURATION: float = 0.15
const FADE_TRANS: Tween.TransitionType = Tween.TRANS_QUART
const FADE_EASE: Tween.EaseType = Tween.EASE_OUT

# Cached resources
var _cached_activities_resource: Resource
var _cached_stats_resource: Resource
var _cached_social_hub_resource: Resource
var _cached_love_book_resource: Resource
var _cached_bottom_buttons_resource: Resource
var _cached_resource_panel_resource: Resource
var _cached_character_card_resource: Resource
var _cached_gift_menu_resource: Resource
var _cached_activity_indicator_resource: Resource
var _cached_pause_menu_resource: Resource
var _cached_date_menu_resource: Resource

# Node references
var activities_panel: Node
var stats_panel: Node
var social_hub_panel: Node
var love_book_panel: Node
var bottom_buttons: Node
var resource_panel: Node
var character_card: Node
var main_canvas: CanvasLayer
var money_label: Label
var ap_label: Label
var gift_menu_instance: Control
var date_menu_instance: Control
var activity_indicator: Control
var pause_menu: CanvasLayer

func _ready() -> void:
	_load_resources()
	_connect_signals()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	if _cached_pause_menu_resource:
		var pause_menu_instance = _cached_pause_menu_resource.instantiate()
		pause_menu = pause_menu_instance
		get_tree().root.call_deferred("add_child", pause_menu_instance)
		call_deferred("_setup_pause_menu")
	else:
		push_error("UIManager: Failed to load PauseMenu")

	if PlayerData and PlayerData.is_activity_active:
		_on_player_activity_started(PlayerData.get_current_activity_data())

	call_deferred("_update_ui_visibility")

func _exit_tree() -> void:
	_disconnect_signals()

func _input(event: InputEvent) -> void:
	if get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("start_scene.tscn"):
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# 1) Minigame only — panel stays open
		if _close_active_minigame():
			get_viewport().set_input_as_handled()
			return

		# 2) Normal panels
		if has_open_panels():
			close_topmost_panel()
			get_viewport().set_input_as_handled()
			return

		# 3) Pause
		if pause_menu and is_instance_valid(pause_menu):
			if pause_menu.has_method("show_menu") and pause_menu.has_method("hide_menu"):
				var panel = pause_menu.get_node_or_null("%PanelContainer")
				if panel and panel.visible:
					pause_menu.hide_menu()
				else:
					pause_menu.show_menu()
				get_viewport().set_input_as_handled()

# ---------- Setup ----------

func _load_resources() -> void:
	var paths = [
		[ACTIVITIES_SCENE_PATH, "_cached_activities_resource"],
		[STATS_SCENE_PATH, "_cached_stats_resource"],
		[SOCIAL_HUB_SCENE_PATH, "_cached_social_hub_resource"],
		[LOVE_BOOK_SCENE_PATH, "_cached_love_book_resource"],
		[BOTTOM_BUTTONS_PATH, "_cached_bottom_buttons_resource"],
		[RESOURCE_PANEL_PATH, "_cached_resource_panel_resource"],
		[CHARACTER_CARD_PATH, "_cached_character_card_resource"],
		[GIFT_MENU_SCENE_PATH, "_cached_gift_menu_resource"],
		[ACTIVITY_INDICATOR_SCENE_PATH, "_cached_activity_indicator_resource"],
		[PAUSE_MENU_SCENE_PATH, "_cached_pause_menu_resource"],
		[DATE_MENU_SCENE_PATH, "_cached_date_menu_resource"],
	]
	for path in paths:
		if ResourceLoader.exists(path[0]):
			set(path[1], ResourceLoader.load(path[0]))
		else:
			push_error("UIManager: Failed to load %s" % path[0])

func _connect_signals() -> void:
	if LocationManager:
		if not LocationManager.location_data_updated.is_connected(_on_location_data_updated):
			LocationManager.location_data_updated.connect(_on_location_data_updated)
	else:
		push_error("UIManager: LocationManager not found")

	if GameManager:
		if not GameManager.scene_changed.is_connected(_on_scene_changed):
			GameManager.scene_changed.connect(_on_scene_changed)

	if PlayerData:
		if not PlayerData.player_money_changed.is_connected(_on_player_money_changed):
			PlayerData.player_money_changed.connect(_on_player_money_changed)
		if not PlayerData.player_ap_changed.is_connected(_on_player_ap_changed):
			PlayerData.player_ap_changed.connect(_on_player_ap_changed)
		if not PlayerData.player_stat_changed.is_connected(_on_player_stat_changed):
			PlayerData.player_stat_changed.connect(_on_player_stat_changed)
		if not PlayerData.player_activity_started.is_connected(_on_player_activity_started):
			PlayerData.player_activity_started.connect(_on_player_activity_started)
		if not PlayerData.player_activity_stopped.is_connected(_on_player_activity_stopped):
			PlayerData.player_activity_stopped.connect(_on_player_activity_stopped)
		if not PlayerData.offline_progress_calculated.is_connected(_on_offline_progress_calculated):
			PlayerData.offline_progress_calculated.connect(_on_offline_progress_calculated)
	else:
		push_error("UIManager: PlayerData not found")

	if SaveManager:
		if not SaveManager.load_completed.is_connected(_on_game_loaded):
			SaveManager.load_completed.connect(_on_game_loaded)
	else:
		push_error("UIManager: SaveManager not found")

func _disconnect_signals() -> void:
	if LocationManager and LocationManager.location_data_updated.is_connected(_on_location_data_updated):
		LocationManager.location_data_updated.disconnect(_on_location_data_updated)
	if GameManager and GameManager.scene_changed.is_connected(_on_scene_changed):
		GameManager.scene_changed.disconnect(_on_scene_changed)
	if PlayerData:
		if PlayerData.player_money_changed.is_connected(_on_player_money_changed):
			PlayerData.player_money_changed.disconnect(_on_player_money_changed)
		if PlayerData.player_ap_changed.is_connected(_on_player_ap_changed):
			PlayerData.player_ap_changed.disconnect(_on_player_ap_changed)
		if PlayerData.player_stat_changed.is_connected(_on_player_stat_changed):
			PlayerData.player_stat_changed.disconnect(_on_player_stat_changed)
		if PlayerData.player_activity_started.is_connected(_on_player_activity_started):
			PlayerData.player_activity_started.disconnect(_on_player_activity_started)
		if PlayerData.player_activity_stopped.is_connected(_on_player_activity_stopped):
			PlayerData.player_activity_stopped.disconnect(_on_player_activity_stopped)
		if PlayerData.offline_progress_calculated.is_connected(_on_offline_progress_calculated):
			PlayerData.offline_progress_calculated.disconnect(_on_offline_progress_calculated)
	if SaveManager and SaveManager.load_completed.is_connected(_on_game_loaded):
		SaveManager.load_completed.disconnect(_on_game_loaded)

func _setup_pause_menu() -> void:
	if not pause_menu or not is_instance_valid(pause_menu):
		push_error("UIManager: PauseMenu instance invalid")
		return
	if pause_menu.has_signal("pause_menu_toggled"):
		if not pause_menu.pause_menu_toggled.is_connected(_on_pause_menu_toggled):
			pause_menu.pause_menu_toggled.connect(_on_pause_menu_toggled)

func _ensure_main_canvas() -> void:
	if main_canvas and is_instance_valid(main_canvas):
		return
	main_canvas = CanvasLayer.new()
	main_canvas.layer = 10
	main_canvas.name = "MainCanvas"
	get_tree().root.add_child(main_canvas)

# ---------- Load / scene / location ----------

func _on_game_loaded(success: bool, message: String) -> void:
	if not success:
		show_notification("Load failed: %s" % message, 5.0)
		return

	update_resource_panel_display()
	_update_ui_visibility()
	await get_tree().process_frame
	try_show_continue_activity_popup()

	if PlayerData and PlayerData.is_activity_active and not PlayerData.current_activity_data.is_empty():
		_on_player_activity_started(PlayerData.get_current_activity_data())

func _on_location_data_updated(_location_data_dict: Dictionary) -> void:
	_update_ui_visibility()

func _on_scene_changed(_scene_path: String) -> void:
	call_deferred("_update_ui_visibility")

func _on_viewport_size_changed() -> void:
	_update_panel_positions()

func _on_offline_progress_calculated(_data: Dictionary) -> void:
	await get_tree().process_frame
	try_show_continue_activity_popup()

# ---------- Player data callbacks ----------

func _on_player_money_changed(_current_money: float) -> void:
	update_resource_panel_display()

func _on_player_ap_changed(_ap: int) -> void:
	update_resource_panel_display()

func _on_player_stat_changed(stat_name: String, value: float) -> void:
	if stats_panel and is_instance_valid(stats_panel):
		var label = stats_panel.get_node_or_null("StatsContainer/%sLabel" % stat_name.capitalize())
		if label:
			label.text = "%s: %.2f" % [stat_name.capitalize(), value]

func _on_player_activity_started(activity_data: Dictionary) -> void:
	if activity_indicator and is_instance_valid(activity_indicator):
		activity_indicator.queue_free()
		activity_indicator = null

	if not _cached_activity_indicator_resource:
		push_error("UIManager: Failed to instantiate activity indicator.")
		return

	_ensure_main_canvas()
	activity_indicator = _cached_activity_indicator_resource.instantiate()
	main_canvas.add_child(activity_indicator)
	if activity_indicator.has_method("_on_player_activity_started"):
		activity_indicator._on_player_activity_started(activity_data)

func _on_player_activity_stopped(_stopped_activity_data: Dictionary, _was_exhausted: bool) -> void:
	if activity_indicator and is_instance_valid(activity_indicator):
		activity_indicator.queue_free()
		activity_indicator = null

# ---------- UI visibility ----------

func _update_ui_visibility() -> void:
	if not LocationManager:
		_remove_ui_elements()
		close_all_panels()
		return

	if LocationManager.get_current_location_type() != "normal":
		_remove_ui_elements()
		close_all_panels()
		return

	_ensure_main_canvas()

	if not bottom_buttons or not is_instance_valid(bottom_buttons):
		if not _cached_bottom_buttons_resource:
			return
		bottom_buttons = _cached_bottom_buttons_resource.instantiate()
		bottom_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_canvas.add_child(bottom_buttons)

	if not resource_panel or not is_instance_valid(resource_panel):
		if not _cached_resource_panel_resource:
			return
		resource_panel = _cached_resource_panel_resource.instantiate()
		resource_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_canvas.add_child(resource_panel)
		setup_resource_panel_references()
		update_resource_panel_display()
	else:
		update_resource_panel_display()

	# Indicator only when an activity is running
	if PlayerData and PlayerData.is_activity_active:
		if not activity_indicator or not is_instance_valid(activity_indicator):
			_on_player_activity_started(PlayerData.get_current_activity_data())

	bottom_buttons.visible = true
	bottom_buttons.modulate = Color.WHITE
	var pause_panel = pause_menu.get_node_or_null("%PanelContainer") if pause_menu and is_instance_valid(pause_menu) else null
	bottom_buttons.set_process_input(not (pause_panel and pause_panel.visible))

	resource_panel.visible = true
	resource_panel.modulate = Color.WHITE
	_update_panel_positions()

func setup_resource_panel_references() -> void:
	if not resource_panel:
		return
	money_label = resource_panel.get_node_or_null("%MoneyLabel")
	if money_label == null:
		money_label = resource_panel.get_node_or_null("ResourcesContainer/MoneyLabel")
	ap_label = resource_panel.get_node_or_null("%APLabel")
	if money_label:
		money_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_resource_panel_display() -> void:
	if not PlayerData:
		return
	if money_label:
		money_label.text = "Money: $%.2f" % PlayerData.money
	if ap_label:
		ap_label.text = "⚡  AP: %d" % PlayerData.action_points

# ---------- Panel toggles ----------

func show_stats_panel() -> void:
	_toggle_panel(stats_panel, _cached_stats_resource, STATS_SCENE_PATH, "stats_panel")

func show_activities_panel() -> void:
	_toggle_panel(activities_panel, _cached_activities_resource, ACTIVITIES_SCENE_PATH, "activities_panel")
	if activities_panel and is_instance_valid(activities_panel) and activities_panel.has_method("refresh_activities_panel"):
		activities_panel.call_deferred("refresh_activities_panel")

func show_social_hub_panel() -> void:
	if character_card and is_instance_valid(character_card):
		return
	_toggle_panel(social_hub_panel, _cached_social_hub_resource, SOCIAL_HUB_SCENE_PATH, "social_hub_panel")
	if social_hub_panel and is_instance_valid(social_hub_panel):
		if social_hub_panel.has_method("update_character_list"):
			social_hub_panel.call_deferred("update_character_list")
		if social_hub_panel.has_signal("request_character_card_details"):
			if not social_hub_panel.request_character_card_details.is_connected(_on_request_character_card_details):
				social_hub_panel.request_character_card_details.connect(_on_request_character_card_details)

func show_love_book() -> void:
	_toggle_panel(love_book_panel, _cached_love_book_resource, LOVE_BOOK_SCENE_PATH, "love_book_panel")
	if love_book_panel and is_instance_valid(love_book_panel) and love_book_panel.has_method("refresh_characters"):
		love_book_panel.call_deferred("refresh_characters")

func hide_love_book() -> void:
	if not love_book_panel or not is_instance_valid(love_book_panel):
		return
	if love_book_panel.has_method("hide_panel_animated"):
		love_book_panel.hide_panel_animated()
		await _wait_for_fade_out(love_book_panel)
	if love_book_panel and is_instance_valid(love_book_panel):
		love_book_panel.queue_free()
	love_book_panel = null

func refresh_love_book() -> void:
	if love_book_panel and is_instance_valid(love_book_panel) and love_book_panel.has_method("refresh_characters"):
		love_book_panel.refresh_characters()

func unlock_character_in_love_book(character_id: String) -> void:
	if love_book_panel and is_instance_valid(love_book_panel) and love_book_panel.has_method("unlock_character"):
		love_book_panel.unlock_character(character_id)

func update_character_in_love_book(character_id: String) -> void:
	if love_book_panel and is_instance_valid(love_book_panel) and love_book_panel.has_method("update_character_progress"):
		love_book_panel.update_character_progress(character_id)

func _toggle_panel(panel: Node, resource: Resource, path: String, panel_var_name: String) -> void:
	if panel and is_instance_valid(panel):
		if panel.has_method("hide_panel_animated"):
			panel.hide_panel_animated()
			await _wait_for_fade_out(panel)
		if panel and is_instance_valid(panel):
			panel.queue_free()
		set(panel_var_name, null)
		return

	if not resource:
		push_error("UIManager: Failed to load %s" % path)
		return

	_ensure_main_canvas()
	var new_panel = resource.instantiate()
	new_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_canvas.add_child(new_panel)
	new_panel.modulate.a = 0.0
	if new_panel.has_method("show_panel_animated"):
		new_panel.show_panel_animated()
	else:
		new_panel.visible = true
		new_panel.modulate = Color.WHITE
	set(panel_var_name, new_panel)
	_update_panel_positions()

# ---------- Layout ----------

func _update_panel_positions() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var reference_size = Vector2(1920, 1080)
	var scale_factor = min(screen_size.x / reference_size.x, screen_size.y / reference_size.y)

	var sizes = {
		"panel_width": 550.0,
		"social_hub_width": 350.0,
		"social_hub_height": 500.0,
		"love_book_width": 600.0,
		"love_book_height": 700.0,
		"character_card_width": 400.0,
		"character_card_height": 600.0,
		"margin_side": 50.0,
		"margin_top": 70.0,
		"margin_bottom": 150.0,
		"bottom_buttons_height": 120.0,
		"gift_menu_width": 300.0,
		"gift_menu_height": 400.0,
		"date_menu_width": 350.0,
		"date_menu_height": 450.0,
	}

	var scaled = {}
	for key in sizes:
		scaled[key] = sizes[key] * scale_factor

	_configure_panel(stats_panel, scaled, Control.PRESET_TOP_LEFT, scaled.panel_width, -scaled.margin_bottom)
	_configure_panel(activities_panel, scaled, Control.PRESET_TOP_RIGHT, scaled.panel_width, -scaled.margin_bottom)
	_configure_center_panel(social_hub_panel, scaled, scaled.social_hub_width, scaled.social_hub_height)
	_configure_center_panel(love_book_panel, scaled, scaled.love_book_width, scaled.love_book_height)
	_configure_center_panel(character_card, scaled, scaled.character_card_width, scaled.character_card_height)
	_configure_center_panel(gift_menu_instance, scaled, scaled.gift_menu_width, scaled.gift_menu_height)
	_configure_center_panel(date_menu_instance, scaled, scaled.date_menu_width, scaled.date_menu_height)

	if bottom_buttons and is_instance_valid(bottom_buttons):
		bottom_buttons.custom_minimum_size = Vector2(screen_size.x, scaled.bottom_buttons_height)
		bottom_buttons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 0)
		bottom_buttons.offset_top = -scaled.bottom_buttons_height

	if resource_panel and is_instance_valid(resource_panel):
		resource_panel.custom_minimum_size = Vector2(280, 110)
		resource_panel.size = Vector2(280, 110)
		resource_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
		resource_panel.anchor_left = 0.5
		resource_panel.anchor_right = 0.5
		resource_panel.anchor_top = 0.0
		resource_panel.anchor_bottom = 0.0
		resource_panel.offset_left = -140
		resource_panel.offset_right = 140
		resource_panel.offset_top = 20
		resource_panel.offset_bottom = 130

func _configure_panel(panel: Node, scaled: Dictionary, preset: int, width: float, bottom_offset: float) -> void:
	if not panel or not is_instance_valid(panel):
		return
	var screen_size = get_viewport().get_visible_rect().size
	var panel_height = screen_size.y - scaled.margin_top - abs(bottom_offset) - 20
	panel.custom_minimum_size = Vector2(width, panel_height)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END if preset == Control.PRESET_TOP_RIGHT else Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.anchor_left = 0.0 if preset == Control.PRESET_TOP_LEFT else 1.0
	panel.anchor_right = 0.0 if preset == Control.PRESET_TOP_LEFT else 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	if preset == Control.PRESET_TOP_LEFT:
		panel.offset_left = scaled.margin_side
		panel.offset_right = scaled.margin_side + width
	else:
		panel.offset_left = -width - scaled.margin_side
		panel.offset_right = -scaled.margin_side
	panel.offset_top = scaled.margin_top
	panel.offset_bottom = scaled.margin_top + panel_height
	panel.set_size(Vector2(width, panel_height))

func _configure_center_panel(panel: Node, scaled: Dictionary, width: float, height: float) -> void:
	if not panel or not is_instance_valid(panel):
		return
	panel.custom_minimum_size = Vector2(width, height)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	panel.offset_left = -width / 2.0
	panel.offset_right = width / 2.0
	panel.offset_top = -height / 2.0 + scaled.margin_top + 50.0
	panel.offset_bottom = height / 2.0 - scaled.margin_bottom

# ---------- Character card ----------

func _on_request_character_card_details(character_data: Dictionary) -> void:
	if character_data.is_empty() or str(character_data.get("id", "")).is_empty():
		push_error("UIManager: Invalid or empty character data")
		show_notification("Error: Invalid character data")
		return

	var is_revealed = _check_character_requirements(character_data)
	var stats_needed_text = ""
	if not is_revealed:
		stats_needed_text = _get_stats_needed_text(character_data.get("stats_required", {}))

	_disconnect_character_card_signals()
	if character_card and is_instance_valid(character_card):
		character_card.queue_free()
		character_card = null

	if social_hub_panel and is_instance_valid(social_hub_panel):
		if social_hub_panel.has_method("hide_panel_animated"):
			social_hub_panel.hide_panel_animated()
			await _wait_for_fade_out(social_hub_panel)
		if social_hub_panel and is_instance_valid(social_hub_panel):
			social_hub_panel.queue_free()
		social_hub_panel = null

	if not _cached_character_card_resource:
		push_error("UIManager: Failed to load character card scene")
		show_notification("Error: Unable to load character card")
		return

	_ensure_main_canvas()
	character_card = _cached_character_card_resource.instantiate()
	character_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_canvas.add_child(character_card)
	character_card.modulate.a = 0.0

	var adapted_data = character_data.duplicate()
	adapted_data["revealed"] = is_revealed
	adapted_data["requirements_met"] = is_revealed
	adapted_data["stats_needed_text"] = stats_needed_text
	adapted_data["id"] = character_data.get("id", "")
	adapted_data["name"] = character_data.get("name", "Unknown")
	adapted_data["image_path"] = character_data.get("image_path", "")
	adapted_data["dialogue_by_stage"] = character_data.get("dialogue_by_stage", {})
	adapted_data["dialogue_points"] = character_data.get("dialogue_points", {})
	adapted_data["date_images"] = character_data.get("date_images", {})

	if character_card.has_method("set_character_data"):
		character_card.set_character_data(adapted_data, is_revealed, stats_needed_text)

	if PlayerData and character_card.has_method("set_gift_button_enabled"):
		var stage = PlayerData.get_relationship_stage(str(adapted_data.id))
		character_card.set_gift_button_enabled(stage in ["Good Friend", "Crush", "Dating", "Soulmate"])

	_connect_character_card_signals()
	_update_panel_positions()

	var tween = create_tween()
	tween.tween_property(character_card, "modulate:a", 1.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)

func _connect_character_card_signals() -> void:
	if not character_card:
		return
	if character_card.has_signal("gift_requested") and not character_card.gift_requested.is_connected(_on_character_card_gift_requested):
		character_card.gift_requested.connect(_on_character_card_gift_requested)
	if character_card.has_signal("date_requested") and not character_card.date_requested.is_connected(_on_character_card_date_requested):
		character_card.date_requested.connect(_on_character_card_date_requested)
	if character_card.has_signal("close_requested") and not character_card.close_requested.is_connected(_on_character_card_close_requested):
		character_card.close_requested.connect(_on_character_card_close_requested)

func _disconnect_character_card_signals() -> void:
	if not character_card or not is_instance_valid(character_card):
		return
	if character_card.has_signal("gift_requested") and character_card.gift_requested.is_connected(_on_character_card_gift_requested):
		character_card.gift_requested.disconnect(_on_character_card_gift_requested)
	if character_card.has_signal("date_requested") and character_card.date_requested.is_connected(_on_character_card_date_requested):
		character_card.date_requested.disconnect(_on_character_card_date_requested)
	if character_card.has_signal("close_requested") and character_card.close_requested.is_connected(_on_character_card_close_requested):
		character_card.close_requested.disconnect(_on_character_card_close_requested)

func _check_character_requirements(character_data: Dictionary) -> bool:
	if not PlayerData:
		return false
	var stats_required = character_data.get("stats_required", {})
	for stat_name in stats_required:
		if PlayerData.get_stat(stat_name) < float(stats_required[stat_name]):
			return false
	return true

func _get_stats_needed_text(stats_required: Dictionary) -> String:
	if not PlayerData:
		return "Player data not available"
	var missing_stats: PackedStringArray = []
	for stat_name in stats_required:
		var required_value = float(stats_required[stat_name])
		var player_value = PlayerData.get_stat(stat_name)
		if player_value < required_value:
			missing_stats.append("%s %d (have %d)" % [str(stat_name).capitalize(), int(required_value), int(player_value)])
	return "Need: " + ", ".join(missing_stats)

func _on_character_card_close_requested() -> void:
	if not character_card or not is_instance_valid(character_card):
		return
	_disconnect_character_card_signals()
	var tween = create_tween()
	tween.tween_property(character_card, "modulate:a", 0.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)
	await tween.finished
	if character_card and is_instance_valid(character_card):
		character_card.queue_free()
	character_card = null
	if _cached_social_hub_resource:
		show_social_hub_panel()

# ---------- Gift menu ----------

func _on_character_card_gift_requested(character_id: String, _character_data: Dictionary) -> void:
	if gift_menu_instance and is_instance_valid(gift_menu_instance):
		return
	if not _cached_gift_menu_resource:
		push_error("UIManager: Failed to load gift menu scene")
		show_notification("Error: Unable to load gift menu")
		return

	_ensure_main_canvas()
	gift_menu_instance = _cached_gift_menu_resource.instantiate()
	gift_menu_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_canvas.add_child(gift_menu_instance)

	if gift_menu_instance.has_method("set_character_id"):
		gift_menu_instance.set_character_id(character_id)

	if gift_menu_instance.has_signal("gift_given") and not gift_menu_instance.gift_given.is_connected(_on_gift_given):
		gift_menu_instance.gift_given.connect(_on_gift_given)
	if gift_menu_instance.has_signal("close_pressed") and not gift_menu_instance.close_pressed.is_connected(_on_gift_menu_closed):
		gift_menu_instance.close_pressed.connect(_on_gift_menu_closed)

	gift_menu_instance.modulate.a = 0.0
	_update_panel_positions()
	var tween = create_tween()
	tween.tween_property(gift_menu_instance, "modulate:a", 1.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)

func _on_gift_given(character_id: String, _gift_id: String, _points: int) -> void:
	# GiftMenu already handled inventory + relationship + notification
	if character_card and is_instance_valid(character_card) and character_card.has_method("update_relationship_display"):
		character_card.update_relationship_display()
	update_character_in_love_book(character_id)

func _on_gift_menu_closed() -> void:
	if not gift_menu_instance or not is_instance_valid(gift_menu_instance):
		return
	if gift_menu_instance.has_method("hide_panel_animated"):
		gift_menu_instance.hide_panel_animated()
		await _wait_for_fade_out(gift_menu_instance)
	if gift_menu_instance and is_instance_valid(gift_menu_instance):
		gift_menu_instance.queue_free()
	gift_menu_instance = null

# ---------- Date menu ----------

func _on_character_card_date_requested(character_id: String, character_data: Dictionary) -> void:
	if date_menu_instance and is_instance_valid(date_menu_instance):
		return
	if not _cached_date_menu_resource:
		push_error("UIManager: Failed to load date menu scene")
		show_notification("Error: Unable to load date menu")
		return

	_ensure_main_canvas()
	date_menu_instance = _cached_date_menu_resource.instantiate()
	date_menu_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_canvas.add_child(date_menu_instance)

	if date_menu_instance.has_method("set_character_data"):
		date_menu_instance.set_character_data(character_id, character_data)

	if date_menu_instance.has_signal("date_selected") and not date_menu_instance.date_selected.is_connected(_on_date_selected):
		date_menu_instance.date_selected.connect(_on_date_selected)
	if date_menu_instance.has_signal("close_pressed") and not date_menu_instance.close_pressed.is_connected(_on_date_menu_closed):
		date_menu_instance.close_pressed.connect(_on_date_menu_closed)

	date_menu_instance.modulate.a = 0.0
	_update_panel_positions()
	var tween = create_tween()
	tween.tween_property(date_menu_instance, "modulate:a", 1.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)

func _on_date_selected(character_id: String, date_type: String, _ap_cost: float, _points: int) -> void:
	if character_card and is_instance_valid(character_card) and character_card.has_method("update_relationship_display"):
		character_card.update_relationship_display()
	show_notification("Went on a %s with %s!" % [date_type.capitalize(), character_id])
	update_character_in_love_book(character_id)

func _on_date_menu_closed() -> void:
	if not date_menu_instance or not is_instance_valid(date_menu_instance):
		return
	var tween = create_tween()
	tween.tween_property(date_menu_instance, "modulate:a", 0.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)
	await tween.finished
	if date_menu_instance and is_instance_valid(date_menu_instance):
		date_menu_instance.queue_free()
	date_menu_instance = null

# ---------- Map / notifications / panels ----------

func show_map() -> void:
	if has_open_panels():
		for panel in [activities_panel, stats_panel, social_hub_panel, love_book_panel, character_card, gift_menu_instance, date_menu_instance]:
			if panel and is_instance_valid(panel):
				if panel.has_method("get_fade_tween"):
					var tw = panel.get_fade_tween()
					if tw and tw.is_valid():
						tw.kill()
				panel.queue_free()
		activities_panel = null
		stats_panel = null
		social_hub_panel = null
		love_book_panel = null
		character_card = null
		gift_menu_instance = null
		date_menu_instance = null

	_remove_ui_elements()
	if GameManager and ResourceLoader.exists(MAP_SCENE_PATH):
		GameManager.change_to_scene(MAP_SCENE_PATH)

func show_notification(message: String, duration: float = 4.0) -> void:
	var parent: Node = get_tree().root
	if main_canvas and is_instance_valid(main_canvas):
		parent = main_canvas
	
	var layer = CanvasLayer.new()
	layer.layer = 100
	parent.add_child(layer)

	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.10, 0.28, 0.84)
	style.set_corner_radius_all(14)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.92, 0.68, 1.0, 0.9)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(0.35, 0.12, 0.5, 0.5)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.98, 0.94, 1.0, 1.0))
	label.custom_minimum_size = Vector2(440, 0)
	panel.add_child(label)
	layer.add_child(panel)

	await get_tree().process_frame
	panel.position = Vector2(40, 40)
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_interval(max(1.5, duration))
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(layer.queue_free)

func close_topmost_panel() -> void:
	if date_menu_instance and is_instance_valid(date_menu_instance):
		_on_date_menu_closed()
		return
	if gift_menu_instance and is_instance_valid(gift_menu_instance):
		_on_gift_menu_closed()
		return
	if character_card and is_instance_valid(character_card):
		_on_character_card_close_requested()
		return
	if love_book_panel and is_instance_valid(love_book_panel):
		hide_love_book()
		return
	if social_hub_panel and is_instance_valid(social_hub_panel):
		_toggle_panel(social_hub_panel, _cached_social_hub_resource, SOCIAL_HUB_SCENE_PATH, "social_hub_panel")
		return
	if activities_panel and is_instance_valid(activities_panel):
		_toggle_panel(activities_panel, _cached_activities_resource, ACTIVITIES_SCENE_PATH, "activities_panel")
		return
	if stats_panel and is_instance_valid(stats_panel):
		_toggle_panel(stats_panel, _cached_stats_resource, STATS_SCENE_PATH, "stats_panel")

func close_all_panels() -> void:
	for panel in [activities_panel, stats_panel, social_hub_panel, love_book_panel, gift_menu_instance, date_menu_instance]:
		if panel and is_instance_valid(panel):
			if panel.has_method("hide_panel_animated"):
				if panel.has_method("get_fade_tween"):
					var tw = panel.get_fade_tween()
					if tw and tw.is_valid():
						tw.kill()
				panel.hide_panel_animated()
				await _wait_for_fade_out(panel)
			if panel and is_instance_valid(panel):
				panel.queue_free()

	activities_panel = null
	stats_panel = null
	social_hub_panel = null
	love_book_panel = null
	gift_menu_instance = null
	date_menu_instance = null

	if character_card and is_instance_valid(character_card):
		_disconnect_character_card_signals()
		var tween = create_tween()
		tween.tween_property(character_card, "modulate:a", 0.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)
		await tween.finished
		if character_card and is_instance_valid(character_card):
			character_card.queue_free()
		character_card = null

	# Keep indicator if activity still running
	if activity_indicator and is_instance_valid(activity_indicator):
		if not (PlayerData and PlayerData.is_activity_active):
			activity_indicator.queue_free()
			activity_indicator = null

func has_open_panels() -> bool:
	for panel in [activities_panel, stats_panel, social_hub_panel, love_book_panel, character_card, gift_menu_instance, date_menu_instance]:
		if panel and is_instance_valid(panel):
			return true
	return false

func _remove_ui_elements() -> void:
	for node in [bottom_buttons, resource_panel, character_card, gift_menu_instance, date_menu_instance]:
		if node and is_instance_valid(node):
			node.queue_free()
	bottom_buttons = null
	resource_panel = null
	money_label = null
	ap_label = null
	character_card = null
	gift_menu_instance = null
	date_menu_instance = null

	if activity_indicator and is_instance_valid(activity_indicator):
		if not (PlayerData and PlayerData.is_activity_active):
			activity_indicator.queue_free()
			activity_indicator = null

	if main_canvas and is_instance_valid(main_canvas) and main_canvas.get_child_count() == 0:
		main_canvas.queue_free()
		main_canvas = null

func _wait_for_fade_out(panel: Node) -> void:
	if not panel or not is_instance_valid(panel) or not panel.has_method("get_fade_tween"):
		return
	var tween = panel.get_fade_tween()
	if tween and tween.is_valid():
		await tween.finished

func _on_pause_menu_toggled(is_visible: bool) -> void:
	if is_instance_valid(pause_menu):
		pause_menu.visible = is_visible

func show_error_dialog(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = message
	dialog.ok_button_text = "OK"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func try_show_continue_activity_popup() -> void:
	if not PlayerData or not PlayerData.has_pending_continue():
		return
	if get_tree().root.get_node_or_null("ContinueActivityPopup"):
		return
	var popup = CONTINUE_POPUP.instantiate()
	get_tree().root.add_child(popup)
	
func _close_active_minigame() -> bool:
	for node_name in ["PinGuess", "WordGuess"]:
		var node = get_tree().root.get_node_or_null(node_name)
		if node and is_instance_valid(node):
			if node.has_method("_on_close"):
				node._on_close()
			else:
				node.queue_free()
			return true
	return false
