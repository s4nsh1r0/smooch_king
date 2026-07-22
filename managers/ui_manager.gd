extends Node

# Scene paths
const ACTIVITIES_SCENE_PATH: String = "res://ui/activities_panel.tscn"
const STATS_SCENE_PATH: String = "res://ui/stats_panel.tscn"
const SOCIAL_HUB_SCENE_PATH: String = "res://ui/social_hub_panel.tscn"
const LOVE_BOOK_SCENE_PATH: String = "res://scenes/love_book.tscn"
const BOTTOM_BUTTONS_PATH: String = "res://ui/bottom_buttons.tscn"
const RESOURCE_PANEL_PATH: String = "res://ui/resources_panel.tscn"
const CHARACTER_CARD_PATH: String = "res://ui/character_card.tscn"
const GIFT_MENU_SCENE_PATH: String = "res://ui/gift_menu.tscn"
const MAP_SCENE_PATH: String = "res://scenes/map_scene.tscn"
const ACTIVITY_INDICATOR_SCENE_PATH: String = "res://ui/activity_indicator.tscn"
const PAUSE_MENU_SCENE_PATH: String = "res://ui/pause_menu.tscn"
const DATE_MENU_SCENE_PATH: String = "res://ui/date_menu.tscn"

# Animation constants
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
var stamina_bar: ProgressBar
var stamina_label: Label
var gift_menu_instance: Control
var date_menu_instance: Control
var activity_indicator: Control
var pause_menu: CanvasLayer

func _ready() -> void:
	_load_resources()
	_connect_signals()
	get_viewport().connect("size_changed", _on_viewport_size_changed)
	if _cached_pause_menu_resource:
		var pause_menu_instance = _cached_pause_menu_resource.instantiate()
		pause_menu = pause_menu_instance
		get_tree().root.call_deferred("add_child", pause_menu_instance)
		call_deferred("_setup_pause_menu")
	else:
		push_error("UIManager: Failed to load PauseMenu")
	# Check for an active activity when the UI Manager is ready
	if PlayerData and PlayerData.is_activity_active:
		_on_player_activity_started(PlayerData.get_current_activity_data())
	
	call_deferred("_update_ui_visibility")

func _setup_pause_menu() -> void:
	if pause_menu and is_instance_valid(pause_menu):
		if pause_menu.has_signal("pause_menu_toggled"):
			if not pause_menu.is_connected("pause_menu_toggled", _on_pause_menu_toggled):
				pause_menu.connect("pause_menu_toggled", _on_pause_menu_toggled)
		else:
			push_error("UIManager: PauseMenu does not have pause_menu_toggled signal")
	else:
		push_error("UIManager: PauseMenu instance invalid")

func _exit_tree() -> void:
	_disconnect_signals()

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
		[DATE_MENU_SCENE_PATH, "_cached_date_menu_resource"]
	]
	for path in paths:
		if ResourceLoader.exists(path[0]):
			set(path[1], ResourceLoader.load(path[0]))
		else:
			push_error("UIManager: Failed to load %s" % path[0])

# In UIManager.gd
func _connect_signals() -> void:
	if LocationManager and not LocationManager.is_connected("location_data_updated", _on_location_data_updated):
		LocationManager.connect("location_data_updated", _on_location_data_updated)
	else:
		push_error("UIManager: LocationManager not found or signal already connected")
	
	if GameManager and not GameManager.is_connected("scene_changed", _on_scene_changed):
		GameManager.connect("scene_changed", _on_scene_changed)
	
	if PlayerData:
		if not PlayerData.is_connected("player_money_changed", _on_player_money_changed):
			PlayerData.player_money_changed.connect(_on_player_money_changed)
		if not PlayerData.is_connected("player_stamina_changed", _on_player_stamina_changed):
			PlayerData.player_stamina_changed.connect(_on_player_stamina_changed)
		if not PlayerData.is_connected("player_stat_changed", _on_player_stat_changed):
			PlayerData.player_stat_changed.connect(_on_player_stat_changed)
		if not PlayerData.is_connected("player_activity_started", _on_player_activity_started):
			PlayerData.player_activity_started.connect(_on_player_activity_started)
		if not PlayerData.is_connected("player_activity_stopped", _on_player_activity_stopped):
			PlayerData.player_activity_stopped.connect(_on_player_activity_stopped)
	else:
		push_error("UIManager: PlayerData not found")
		
	if SaveManager and not SaveManager.is_connected("load_completed", _on_game_loaded):
		SaveManager.connect("load_completed", _on_game_loaded)
	else:
		push_error("UIManager: SaveManager not found or load_completed signal already connected")

func _disconnect_signals() -> void:
	if LocationManager and LocationManager.is_connected("location_data_updated", _on_location_data_updated):
		LocationManager.disconnect("location_data_updated", _on_location_data_updated)
	if GameManager and GameManager.is_connected("scene_changed", _on_scene_changed):
		GameManager.disconnect("scene_changed", _on_scene_changed)
	if PlayerData:
		if PlayerData.is_connected("player_money_changed", _on_player_money_changed):
			PlayerData.player_money_changed.disconnect(_on_player_money_changed)
		if PlayerData.is_connected("player_stamina_changed", _on_player_stamina_changed):
			PlayerData.player_stamina_changed.disconnect(_on_player_stamina_changed)
		if PlayerData.is_connected("player_stat_changed", _on_player_stat_changed):
			PlayerData.player_stat_changed.disconnect(_on_player_stat_changed)
		if PlayerData.is_connected("player_activity_started", _on_player_activity_started):
			PlayerData.player_activity_started.disconnect(_on_player_activity_started)
		if PlayerData.is_connected("player_activity_stopped", _on_player_activity_stopped):
			PlayerData.player_activity_stopped.disconnect(_on_player_activity_stopped)
	if SaveManager and SaveManager.is_connected("load_completed", _on_game_loaded):
		SaveManager.disconnect("load_completed", _on_game_loaded)

func _on_game_loaded(success: bool, message: String) -> void:
	print("UIManager: Game load completed. Success: %s, Message: %s" % [success, message])
	if success:
		update_resource_panel_display()
		
		# FIXED: Force activity restoration with proper timing
		if PlayerData and PlayerData.is_activity_active and PlayerData.current_activity_data.has("name"):
			print("UIManager: Restoring active activity: %s" % PlayerData.current_activity_data.name)
			# Remove any existing activity indicator first
			if activity_indicator and is_instance_valid(activity_indicator):
				activity_indicator.queue_free()
				activity_indicator = null
			# Wait a frame to ensure cleanup
			await get_tree().process_frame
			# Now create the new activity indicator
			_on_player_activity_started(PlayerData.current_activity_data)
		
		_update_ui_visibility()
	else:
		show_notification("Load failed: %s" % message, 5.0)
		
func _restore_activity_post_scene_change() -> void:
	if has_meta("_should_restore_activity") and get_meta("_should_restore_activity"):
		remove_meta("_should_restore_activity")
		var data = get_meta("_activity_data_to_restore", {})
		remove_meta("_activity_data_to_restore")
		var stat = get_meta("_stat_accum", 0.0)
		remove_meta("_stat_accum")
		var money = get_meta("_money_accum", 0.0)
		remove_meta("_money_accum")
		
		if not data.is_empty():
			print("UIManager: Re-restoring activity after scene change")
			# Ensure clean state
			if PlayerData.is_activity_active:
				PlayerData.stop_activity(false)
			await get_tree().process_frame
			
			# Restore state
			PlayerData.is_activity_active = true
			PlayerData.current_activity_data = data
			PlayerData._current_activity_stat_accumulated_display = stat
			PlayerData._current_activity_money_accumulated_display = money
			PlayerData.last_activity_timestamp = Time.get_unix_time_from_system()
			
			# Recreate indicator
			if activity_indicator and is_instance_valid(activity_indicator):
				activity_indicator.queue_free()
				activity_indicator = null
			await get_tree().process_frame
			_on_player_activity_started(data)
	else:
		print("UIManager: No activity restoration needed post-scene change")

func _on_location_data_updated(_location_data_dict: Dictionary) -> void:
	_update_ui_visibility()

func _on_scene_changed(_scene_path: String) -> void:
	call_deferred("_update_ui_visibility")
	call_deferred("_restore_activity_post_scene_change")

func _on_viewport_size_changed() -> void:
	_update_panel_positions()

func _on_player_money_changed(_current_money: float) -> void:
	update_resource_panel_display()

func _on_player_stamina_changed(_current_stamina: float, _max_stamina: float) -> void:
	update_resource_panel_display()

func _on_player_stat_changed(stat_name: String, value: float) -> void:
	if stats_panel and is_instance_valid(stats_panel):
		var label = stats_panel.get_node_or_null("StatsContainer/%sLabel" % stat_name.capitalize())
		if label:
			label.text = "%s: %.2f" % [stat_name.capitalize(), value]
			
func _on_player_activity_started(activity_data: Dictionary) -> void:
	print("UIManager: Player activity started, creating indicator.")
	if activity_indicator and is_instance_valid(activity_indicator):
		activity_indicator.queue_free()
		activity_indicator = null
	
	if _cached_activity_indicator_resource:
		activity_indicator = _cached_activity_indicator_resource.instantiate()
		if not main_canvas or not is_instance_valid(main_canvas):
			main_canvas = CanvasLayer.new()
			main_canvas.layer = 10
			main_canvas.name = "MainCanvas"
			get_tree().root.add_child(main_canvas)
		main_canvas.add_child(activity_indicator)
		activity_indicator._on_player_activity_started(activity_data)
	else:
		push_error("UIManager: Failed to instantiate activity indicator.")
		
func _on_player_activity_stopped(_stopped_activity_data: Dictionary, _was_stamina_exhausted: bool) -> void:
	if activity_indicator and is_instance_valid(activity_indicator):
		activity_indicator.queue_free()
		activity_indicator = null
		
func _on_player_activity_progress(activity_data: Dictionary):
	if activity_indicator and is_instance_valid(activity_indicator):
		activity_indicator._on_player_activity_progress(activity_data)

func _update_ui_visibility() -> void:
	if not LocationManager:
		_remove_ui_elements()
		close_all_panels()
		return
	
	if LocationManager.get_current_location_type() == "normal":
		if not main_canvas or not is_instance_valid(main_canvas):
			main_canvas = CanvasLayer.new()
			main_canvas.layer = 10
			main_canvas.name = "MainCanvas"
			get_tree().root.add_child(main_canvas)
		
		if not bottom_buttons or not is_instance_valid(bottom_buttons):
			if _cached_bottom_buttons_resource:
				bottom_buttons = _cached_bottom_buttons_resource.instantiate()
				bottom_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
				main_canvas.add_child(bottom_buttons)
			else:
				return
		
		if not resource_panel or not is_instance_valid(resource_panel):
			if _cached_resource_panel_resource:
				resource_panel = _cached_resource_panel_resource.instantiate()
				resource_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
				main_canvas.add_child(resource_panel)
				setup_resource_panel_references()
				update_resource_panel_display()
			else:
				return
		else:
			# Resource panel already exists, just update its display
			update_resource_panel_display()
		
		if not activity_indicator or not is_instance_valid(activity_indicator):
			if _cached_activity_indicator_resource:
				activity_indicator = _cached_activity_indicator_resource.instantiate()
				activity_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
				main_canvas.add_child(activity_indicator)
				activity_indicator.modulate.a = 1.0
			else:
				push_error("UIManager: Failed to load ActivityIndicator")
				return
		
		bottom_buttons.visible = true
		bottom_buttons.modulate = Color.WHITE
		if pause_menu and is_instance_valid(pause_menu) and pause_menu.get_node_or_null("%PanelContainer") and pause_menu.get_node("%PanelContainer").visible:
			bottom_buttons.set_process_input(false)
		else:
			bottom_buttons.set_process_input(true)
		resource_panel.visible = true
		resource_panel.modulate = Color.WHITE
		_update_panel_positions()
	else:
		_remove_ui_elements()
		close_all_panels()

# Enhanced resource panel functions
func setup_resource_panel_references():
	if resource_panel:
		money_label = resource_panel.get_node_or_null("ResourcesContainer/MoneyLabel")
		stamina_bar = resource_panel.get_node_or_null("ResourcesContainer/StaminaBar")
		stamina_label = stamina_bar.get_node_or_null("StaminaLabel")
		
		if money_label:
			money_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if stamina_bar:
			stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stamina_bar.max_value = 1000.0  # Set max to 1000 for decimal precision
		if stamina_label:
			stamina_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_resource_panel_display():
	# Update money display
	if money_label:
		money_label.text = "Money: $%.2f" % (PlayerData.money if PlayerData else 0.0)
	
	# Update stamina display with decimal precision and color changes
	if stamina_bar:
		var stamina_percentage = PlayerData.get_stamina_percentage() if PlayerData else 1.0
		var stamina_value = stamina_percentage * 100.0
		
		# Update bar value (multiply by 10 for decimal precision)
		stamina_bar.value = stamina_value * 10.0
		
		# Update label with one decimal place
		if stamina_label:
			stamina_label.text = "Stamina: %.1f" % stamina_value
		
		# Update bar color based on percentage
		update_stamina_bar_color(stamina_percentage * 100.0)

func update_stamina_bar_color(percentage: float):
	if stamina_bar:
		var style_box = StyleBoxFlat.new()
		
		# Set color based on stamina percentage
		if percentage > 75.0:
			style_box.bg_color = Color(0.2, 0.8, 0.3, 1)  # Green
		elif percentage > 50.0:
			style_box.bg_color = Color(0.9, 0.7, 0.2, 1)  # Yellow
		elif percentage > 25.0:
			style_box.bg_color = Color(0.9, 0.3, 0.2, 1)  # Orange-Red
		else:
			style_box.bg_color = Color(0.7, 0.1, 0.1, 1)  # Dark Red
		
		# Apply rounded corners
		style_box.corner_radius_top_left = 6
		style_box.corner_radius_top_right = 6
		style_box.corner_radius_bottom_left = 6
		style_box.corner_radius_bottom_right = 6
		
		stamina_bar.add_theme_stylebox_override("fill", style_box)
		
		# Add pulsing effect for critical stamina
		if percentage <= 10.0:
			add_critical_stamina_pulse()
		else:
			remove_critical_stamina_pulse()

func add_critical_stamina_pulse():
	if stamina_bar and not stamina_bar.has_meta("_pulse_active"):
		var tween = create_tween()
		tween.set_loops()
		tween.tween_method(_pulse_stamina_bar, 0.6, 1.0, 0.8)
		tween.tween_method(_pulse_stamina_bar, 1.0, 0.6, 0.8)
		stamina_bar.set_meta("_pulse_active", true)

func remove_critical_stamina_pulse():
	if stamina_bar and stamina_bar.has_meta("_pulse_active"):
		stamina_bar.modulate = Color.WHITE
		stamina_bar.remove_meta("_pulse_active")
		# Kill any existing tweens
		var tweens = get_tree().get_processed_tweens()
		for tween in tweens:
			if tween.is_valid():
				tween.kill()

func _pulse_stamina_bar(alpha: float):
	if stamina_bar:
		stamina_bar.modulate = Color(1.0, 1.0, 1.0, alpha)

# Panel management functions
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
		if social_hub_panel.has_signal("request_character_card_details") and not social_hub_panel.is_connected("request_character_card_details", _on_request_character_card_details):
			social_hub_panel.connect("request_character_card_details", _on_request_character_card_details)

func show_love_book() -> void:
	"""Show the Love Book panel"""
	_toggle_panel(love_book_panel, _cached_love_book_resource, LOVE_BOOK_SCENE_PATH, "love_book_panel")
	if love_book_panel and is_instance_valid(love_book_panel):
		if love_book_panel.has_method("refresh_characters"):
			love_book_panel.call_deferred("refresh_characters")

func hide_love_book() -> void:
	"""Hide the Love Book panel"""
	if love_book_panel and is_instance_valid(love_book_panel):
		if love_book_panel.has_method("hide_panel_animated"):
			love_book_panel.hide_panel_animated()
			await _wait_for_fade_out(love_book_panel)
		if love_book_panel and is_instance_valid(love_book_panel):
			love_book_panel.queue_free()
		love_book_panel = null

func refresh_love_book() -> void:
	"""Refresh the Love Book when character data changes"""
	if love_book_panel and is_instance_valid(love_book_panel):
		if love_book_panel.has_method("refresh_characters"):
			love_book_panel.refresh_characters()

func unlock_character_in_love_book(character_id: String) -> void:
	"""Call this when a character is first met to unlock them in the Love Book"""
	if love_book_panel and is_instance_valid(love_book_panel):
		if love_book_panel.has_method("unlock_character"):
			love_book_panel.unlock_character(character_id)

func update_character_in_love_book(character_id: String) -> void:
	"""Call this when character relationship data is updated"""
	if love_book_panel and is_instance_valid(love_book_panel):
		if love_book_panel.has_method("update_character_progress"):
			love_book_panel.update_character_progress(character_id)

func show_activity_indicator() -> void:
	if not activity_indicator or not is_instance_valid(activity_indicator):
		if _cached_activity_indicator_resource:
			if not main_canvas or not is_instance_valid(main_canvas):
				main_canvas = CanvasLayer.new()
				main_canvas.layer = 10
				main_canvas.name = "MainCanvas"
				get_tree().root.add_child(main_canvas)
			activity_indicator = _cached_activity_indicator_resource.instantiate()
			activity_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			main_canvas.add_child(activity_indicator)
			activity_indicator.modulate.a = 1.0
		else:
			push_error("UIManager: Failed to load ActivityIndicator")

func _toggle_panel(panel: Node, resource: Resource, path: String, panel_var_name: String) -> void:
	if panel and is_instance_valid(panel):
		if panel.has_method("hide_panel_animated"):
			panel.hide_panel_animated()
			await _wait_for_fade_out(panel)
		if panel and is_instance_valid(panel):
			panel.queue_free()
		set(panel_var_name, null)
	else:
		if resource:
			var new_panel = resource.instantiate()
			new_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if not main_canvas or not is_instance_valid(main_canvas):
				main_canvas = CanvasLayer.new()
				main_canvas.layer = 10
				main_canvas.name = "MainCanvas"
				get_tree().root.add_child(main_canvas)
			main_canvas.add_child(new_panel)
			new_panel.modulate.a = 0.0
			if new_panel.has_method("show_panel_animated"):
				new_panel.show_panel_animated()
			else:
				new_panel.visible = true
				new_panel.modulate = Color.WHITE
			set(panel_var_name, new_panel)
			_update_panel_positions()
		else:
			push_error("UIManager: Failed to load %s" % path)

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
		"resource_panel_width": 150.0,
		"resource_panel_height": 100.0,
		"gift_menu_width": 300.0,
		"gift_menu_height": 400.0,
		"date_menu_width": 350.0,
		"date_menu_height": 450.0
	}
	
	var scaled = {}
	for key in sizes:
		scaled[key] = sizes[key] * scale_factor
	
	var _right_offset: float = 0.0  # Unused but kept for compatibility
	_configure_panel(stats_panel, scaled, Control.PRESET_TOP_LEFT, scaled.panel_width, -scaled.margin_bottom)
	_configure_panel(activities_panel, scaled, Control.PRESET_TOP_RIGHT, scaled.panel_width, -scaled.margin_bottom, -scaled.margin_side)
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
		resource_panel.custom_minimum_size = Vector2(scaled.resource_panel_width, scaled.resource_panel_height)
		resource_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 0)
		resource_panel.offset_top = scaled.margin_top / 5
		resource_panel.offset_left = -scaled.resource_panel_width / 2
		resource_panel.offset_right = scaled.resource_panel_width / 2

func _configure_panel(panel: Node, scaled: Dictionary, preset: int, width: float, bottom_offset: float, _right_offset: float = 0.0) -> void:
	if panel and is_instance_valid(panel):
		# Calculate exact panel height to ensure both panels are identical
		var screen_size = get_viewport().get_visible_rect().size
		var panel_height = screen_size.y - scaled.margin_top - abs(bottom_offset) - 20
		
		# Set exact size for both panels - this ensures they're identical
		panel.custom_minimum_size = Vector2(width, panel_height)
		
		# Use consistent size flags for both panels
		panel.size_flags_horizontal = Control.SIZE_SHRINK_END if preset == Control.PRESET_TOP_RIGHT else Control.SIZE_SHRINK_BEGIN
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Set anchors to fixed positions (not stretching)
		panel.anchor_left = 0.0 if preset == Control.PRESET_TOP_LEFT else 1.0
		panel.anchor_right = 0.0 if preset == Control.PRESET_TOP_LEFT else 1.0
		panel.anchor_top = 0.0
		panel.anchor_bottom = 0.0
		
		# Set exact positions and sizes
		if preset == Control.PRESET_TOP_LEFT:
			# Left panel (Stats)
			panel.offset_left = scaled.margin_side
			panel.offset_right = scaled.margin_side + width
		else:
			# Right panel (Activities) 
			panel.offset_left = -width - scaled.margin_side
			panel.offset_right = -scaled.margin_side
		
		# Same vertical positioning for both panels
		panel.offset_top = scaled.margin_top
		panel.offset_bottom = scaled.margin_top + panel_height
		
		# Force the panel to respect the exact size we set
		panel.set_size(Vector2(width, panel_height))
		

func _configure_center_panel(panel: Node, scaled: Dictionary, width: float, height: float) -> void:
	if panel and is_instance_valid(panel):
		panel.custom_minimum_size = Vector2(width, height)
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
		panel.offset_left = -width / 2
		panel.offset_right = width / 2
		panel.offset_top = -height / 2 + scaled.margin_top +50
		panel.offset_bottom = height / 2 - scaled.margin_bottom

func _on_request_character_card_details(character_data: Dictionary) -> void:
	if character_data.is_empty() or character_data.get("id", "").is_empty():
		push_error("UIManager: Invalid or empty character data")
		show_notification("Error: Invalid character data")
		return
	
	var is_revealed = _check_character_requirements(character_data)
	var stats_needed_text = _get_stats_needed_text(character_data.get("stats_required", {})) if not is_revealed else ""
	
	if character_card and is_instance_valid(character_card):
		for signal_data in [
			["gift_requested", _on_character_card_gift_requested],
			["date_requested", _on_character_card_date_requested],
			["close_requested", _on_character_card_close_requested]
		]:
			if character_card.has_signal(signal_data[0]) and character_card.is_connected(signal_data[0], signal_data[1]):
				character_card.disconnect(signal_data[0], signal_data[1])
		character_card.queue_free()
		character_card = null
	
	if social_hub_panel and is_instance_valid(social_hub_panel) and social_hub_panel.has_method("hide_panel_animated"):
		social_hub_panel.hide_panel_animated()
		await _wait_for_fade_out(social_hub_panel)
		if social_hub_panel and is_instance_valid(social_hub_panel):
			social_hub_panel.queue_free()
			social_hub_panel = null
	
	if not main_canvas or not is_instance_valid(main_canvas):
		main_canvas = CanvasLayer.new()
		main_canvas.layer = 10
		main_canvas.name = "MainCanvas"
		get_tree().root.add_child(main_canvas)
	
	if _cached_character_card_resource:
		character_card = _cached_character_card_resource.instantiate()
		character_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_canvas.add_child(character_card)
		character_card.modulate.a = 0.0
		
		var adapted_data = character_data.duplicate()
		adapted_data.revealed = is_revealed
		adapted_data.requirements_met = is_revealed
		adapted_data.stats_needed_text = stats_needed_text
		
		adapted_data["id"] = character_data.get("id", "")
		adapted_data["name"] = character_data.get("name", "Unknown")
		adapted_data["image_path"] = character_data.get("image_path", "")
		adapted_data["dialogue_by_stage"] = character_data.get("dialogue_by_stage", {})
		adapted_data["dialogue_points"] = character_data.get("dialogue_points", {})
		adapted_data["date_images"] = character_data.get("date_images", {})
		
		if character_card.has_method("set_character_data"):
			character_card.set_character_data(adapted_data, is_revealed, stats_needed_text)
		
		var gift_button_enabled = false
		if PlayerData and PlayerData.has_method("get_relationship_stage"):
			var stage = PlayerData.get_relationship_stage(adapted_data.id)
			gift_button_enabled = stage in ["Good Friend", "Crush", "Dating", "Soulmate"]
			if character_card.has_method("set_gift_button_enabled"):
				character_card.set_gift_button_enabled(gift_button_enabled)
		
		for signal_data in [
			["gift_requested", _on_character_card_gift_requested],
			["date_requested", _on_character_card_date_requested],
			["close_requested", _on_character_card_close_requested]
		]:
			if character_card.has_signal(signal_data[0]) and not character_card.is_connected(signal_data[0], signal_data[1]):
				character_card.connect(signal_data[0], signal_data[1])
		
		_update_panel_positions()
		var tween = create_tween()
		tween.tween_property(character_card, "modulate:a", 1.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)
	else:
		push_error("UIManager: Failed to load character card scene")
		show_notification("Error: Unable to load character card")

func _check_character_requirements(character_data: Dictionary) -> bool:
	if not PlayerData or not PlayerData.has_method("get_stat"):
		push_error("UIManager: PlayerData singleton not found")
		show_notification("Error: Player data not available")
		return false
	
	var stats_required = character_data.get("stats_required", {})
	for stat_name in stats_required:
		var required_value = stats_required[stat_name]
		var player_value = PlayerData.get_stat(stat_name)
		if player_value == null or player_value < required_value:
			return false
	return true

func _get_stats_needed_text(character_data: Dictionary) -> String:
	if not PlayerData or not PlayerData.has_method("get_stat"):
		push_error("UIManager: PlayerData singleton not found")
		return "Player data not available"
	
	var stats_required = character_data.get("stats_required", {})
	var missing_stats = []
	for stat_name in stats_required:
		var required_value = stats_required[stat_name]
		var player_value = PlayerData.get_stat(stat_name)
		if player_value == null:
			missing_stats.append("%s %d (unknown)" % [stat_name.capitalize(), required_value])
		elif player_value < required_value:
			missing_stats.append("%s %d (have %d)" % [stat_name.capitalize(), required_value, int(player_value)])
	return "Need: " + ", ".join(missing_stats)

func _on_character_card_gift_requested(character_id: String, _character_data: Dictionary) -> void:
	if gift_menu_instance and is_instance_valid(gift_menu_instance):
		return
	
	if _cached_gift_menu_resource:
		gift_menu_instance = _cached_gift_menu_resource.instantiate()
		gift_menu_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not main_canvas or not is_instance_valid(main_canvas):
			main_canvas = CanvasLayer.new()
			main_canvas.layer = 10
			main_canvas.name = "MainCanvas"
			get_tree().root.add_child(main_canvas)
		
		main_canvas.add_child(gift_menu_instance)
		if gift_menu_instance.has_method("set_character_id"):
			gift_menu_instance.set_character_id(character_id)
		gift_menu_instance.modulate.a = 0.0
		
		if gift_menu_instance.has_signal("gift_selected") and not gift_menu_instance.is_connected("gift_selected", _on_gift_selected):
			gift_menu_instance.connect("gift_selected", _on_gift_selected)
		if gift_menu_instance.has_signal("close_pressed") and not gift_menu_instance.is_connected("close_pressed", _on_gift_menu_closed):
			gift_menu_instance.connect("close_pressed", _on_gift_menu_closed)
		
		_update_panel_positions()
		var tween = create_tween()
		tween.tween_property(gift_menu_instance, "modulate:a", 1.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)
	else:
		push_error("UIManager: Failed to load gift menu scene")
		show_notification("Error: Unable to load gift menu")

func _on_character_card_date_requested(character_id: String, character_data: Dictionary) -> void:
	if date_menu_instance and is_instance_valid(date_menu_instance):
		return
	
	if _cached_date_menu_resource:
		date_menu_instance = _cached_date_menu_resource.instantiate()
		date_menu_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not main_canvas or not is_instance_valid(main_canvas):
			main_canvas = CanvasLayer.new()
			main_canvas.layer = 10
			main_canvas.name = "MainCanvas"
			get_tree().root.add_child(main_canvas)
		
		main_canvas.add_child(date_menu_instance)
		if date_menu_instance.has_method("set_character_data"):
			date_menu_instance.set_character_data(character_id, character_data)
		date_menu_instance.modulate.a = 0.0
		
		if date_menu_instance.has_signal("date_selected") and not date_menu_instance.is_connected("date_selected", _on_date_selected):
			date_menu_instance.connect("date_selected", _on_date_selected)
		if date_menu_instance.has_signal("close_pressed") and not date_menu_instance.is_connected("close_pressed", _on_date_menu_closed):
			date_menu_instance.connect("close_pressed", _on_date_menu_closed)
		
		_update_panel_positions()
		var tween = create_tween()
		tween.tween_property(date_menu_instance, "modulate:a", 1.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)
	else:
		push_error("UIManager: Failed to load date menu scene")
		show_notification("Error: Unable to load date menu")

func _on_character_card_close_requested() -> void:
	if character_card and is_instance_valid(character_card):
		for signal_data in [
			["gift_requested", _on_character_card_gift_requested],
			["date_requested", _on_character_card_date_requested],
			["close_requested", _on_character_card_close_requested]
		]:
			if character_card.has_signal(signal_data[0]) and character_card.is_connected(signal_data[0], signal_data[1]):
				character_card.disconnect(signal_data[0], signal_data[1])
		var tween = create_tween()
		tween.tween_property(character_card, "modulate:a", 0.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)
		await tween.finished
		if character_card and is_instance_valid(character_card):
			character_card.queue_free()
			character_card = null
			if _cached_social_hub_resource:
				show_social_hub_panel()

func _on_gift_menu_closed() -> void:
	if gift_menu_instance and is_instance_valid(gift_menu_instance):
		if gift_menu_instance.has_method("hide_panel_animated"):
			gift_menu_instance.hide_panel_animated()
			await _wait_for_fade_out(gift_menu_instance)
		if gift_menu_instance and is_instance_valid(gift_menu_instance):
			gift_menu_instance.queue_free()
		gift_menu_instance = null

func _on_date_menu_closed() -> void:
	if date_menu_instance and is_instance_valid(date_menu_instance):
		# Don't use hide_panel_animated - just fade out and remove
		var tween = create_tween()
		tween.tween_property(date_menu_instance, "modulate:a", 0.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)
		await tween.finished
		if date_menu_instance and is_instance_valid(date_menu_instance):
			date_menu_instance.queue_free()
		date_menu_instance = null

func _on_gift_selected(character_id: String, points: int, cost: float) -> void:
	if not PlayerData:
		push_error("UIManager: PlayerData singleton not found")
		show_notification("Error: Player data not available")
		return
	if PlayerData.has_method("has_money") and PlayerData.has_money(cost):
		PlayerData.money -= cost
		if PlayerData.has_method("add_relationship_points"):
			PlayerData.add_relationship_points(character_id, points)
		if character_card and is_instance_valid(character_card) and character_card.has_method("update_relationship_display"):
			character_card.update_relationship_display()
		show_notification("Gave a %s gift to %s!" % [get_gift_name(points), character_id])
		
		# Update Love Book when gift is given
		update_character_in_love_book(character_id)
	else:
		show_notification("Not enough money for this gift!")
	_on_gift_menu_closed()

func _on_date_selected(character_id: String, date_type: String, stamina_cost: float, points: int) -> void:
	if not PlayerData:
		push_error("UIManager: PlayerData singleton not found")
		show_notification("Error: Player data not available")
		return
	
	if PlayerData.has_method("consume_stamina") and PlayerData.consume_stamina(stamina_cost):
		if PlayerData.has_method("add_relationship_points"):
			PlayerData.add_relationship_points(character_id, points)
		if PlayerData.has_method("complete_character_date"):
			PlayerData.complete_character_date(character_id, date_type)
		if character_card and is_instance_valid(character_card) and character_card.has_method("update_relationship_display"):
			character_card.update_relationship_display()
		show_notification("Went on a %s with %s!" % [date_type.capitalize(), character_id])
		
		# Update Love Book when date is completed
		update_character_in_love_book(character_id)
	else:
		show_notification("Not enough stamina for this date!")

func get_gift_name(points: int) -> String:
	var gift_data = {
		1: "Small",
		5: "Medium",
		10: "Large",
		25: "Fancy",
		50: "Luxury",
		100: "Extravagant"
	}
	return gift_data.get(points, "Unknown")

func show_map() -> void:
	if has_open_panels():
		for panel in [activities_panel, stats_panel, social_hub_panel, love_book_panel, character_card, gift_menu_instance, date_menu_instance]:
			if panel and is_instance_valid(panel):
				if panel.has_method("get_fade_tween"):
					var tween = panel.get_fade_tween()
					if tween and tween.is_valid():
						tween.kill()
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

func show_notification(message: String, _duration: float = 3.0) -> void:
	var notification = Label.new()
	notification.text = message
	notification.add_theme_font_size_override("font_size", 16)
	notification.position = Vector2(100, 100)
	notification.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parent = main_canvas if main_canvas and is_instance_valid(main_canvas) else get_tree().root
	parent.add_child(notification)
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(notification.queue_free)

func close_all_panels() -> void:
	for panel in [activities_panel, stats_panel, social_hub_panel, love_book_panel, gift_menu_instance, date_menu_instance]:
		if panel and is_instance_valid(panel):
			if panel.has_method("hide_panel_animated"):
				if panel.has_method("get_fade_tween"):
					var tween = panel.get_fade_tween()
					if tween and tween.is_valid():
						tween.kill()
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
		for signal_data in [
			["gift_requested", _on_character_card_gift_requested],
			["date_requested", _on_character_card_date_requested],
			["close_requested", _on_character_card_close_requested]
		]:
			if character_card.has_signal(signal_data[0]) and character_card.is_connected(signal_data[0], signal_data[1]):
				character_card.disconnect(signal_data[0], signal_data[1])
		var tween = create_tween()
		tween.tween_property(character_card, "modulate:a", 0.0, FADE_DURATION).set_trans(FADE_TRANS).set_ease(FADE_EASE)
		await tween.finished
		if character_card and is_instance_valid(character_card):
			character_card.queue_free()
			character_card = null
	
	if activity_indicator and is_instance_valid(activity_indicator) and PlayerData and PlayerData.is_activity_active:
		return
	if activity_indicator and is_instance_valid(activity_indicator):
		activity_indicator.queue_free()
		activity_indicator = null
	
	if main_canvas and is_instance_valid(main_canvas) and main_canvas.get_child_count() == 0:
		main_canvas.queue_free()
		main_canvas = null

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
	stamina_bar = null
	stamina_label = null
	character_card = null
	gift_menu_instance = null
	date_menu_instance = null
	
	if activity_indicator and is_instance_valid(activity_indicator) and PlayerData and PlayerData.is_activity_active:
		return
	if activity_indicator and is_instance_valid(activity_indicator):
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
		var _timeout_timer = get_tree().create_timer(FADE_DURATION + 0.1)
		await tween.finished

func _on_pause_menu_toggled(is_visible: bool):
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
