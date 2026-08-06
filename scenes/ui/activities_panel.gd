extends PanelContainer

@onready var location_name_label: Label = %LocationNameLabel
@onready var normal_activities_scroll: ScrollContainer = %NormalActivitiesScroll
@onready var normal_activities_vbox: VBoxContainer = %NormalActivitiesVBox
@onready var job_tiers_tab_container: TabContainer = %JobTiersTabContainer
@onready var tier1_jobs_vbox: VBoxContainer = %Tier1Jobs
@onready var tier2_jobs_vbox: VBoxContainer = %Tier2Jobs
@onready var tier3_jobs_vbox: VBoxContainer = %Tier3Jobs
@onready var tier4_jobs_vbox: VBoxContainer = %Tier4Jobs
@onready var tier5_jobs_vbox: VBoxContainer = %Tier5Jobs
@onready var special_tasks_button: Button = %SpecialTasksButton

const SHOP_SCENE = preload("res://scenes/ui/shop.tscn")
const SPECIAL_TASKS_SCENE_PATH: String = "res://scenes/ui/special_tasks.tscn"
const PIN_GUESS_SCENE = preload("res://scenes/minigames/pin_guess.tscn")
const WORD_GUESS_SCENE = preload("res://scenes/minigames/word_guess.tscn")

const JOB_TIER_LOOKUP: Dictionary = {
	"job_cafe_server": 1, "job_shop_assistant": 1, "job_office_clerk": 1,
	"job_barista": 2, "job_cafe_shift_lead": 2, "job_sales_associate": 2, "job_stock_coordinator": 2, "job_junior_analyst": 2, "job_admin_assistant": 2,
	"job_restaurant_supervisor": 3, "job_bartender": 3, "job_store_supervisor": 3, "job_merchandiser": 3, "job_data_analyst": 3, "job_hr_coordinator": 3,
	"job_restaurant_manager": 4, "job_bar_manager": 4, "job_store_manager": 4, "job_regional_buyer": 4, "job_senior_analyst": 4, "job_team_lead": 4,
	"job_hospitality_director": 5, "job_retail_ops_director": 5, "job_ops_manager": 5
}

@export var fade_duration: float = 0.15
@export var emoji_font: Font = preload("res://assets/fonts/NotoSans-Regular.ttf")

var current_fade_tween: Tween = null
var button_hover_tweens: Dictionary = {}
var button_pulse_tweens: Dictionary = {}
var _tier_vbox_map: Dictionary = {}
var _activity_button_map: Dictionary = {}

var custom_tooltip: PanelContainer = null
var _tooltip_layer: CanvasLayer = null

var _shift_picker_layer: CanvasLayer = null
var shop_button: Button = null
var current_shop: Node = null
var current_pin_guess: Node = null
var current_word_guess: Node = null
var pin_guess_button: Button = null
var word_guess_button: Button = null
var special_tasks_panel: PanelContainer = null

func _ready() -> void:
	if not is_instance_valid(location_name_label) or not is_instance_valid(normal_activities_vbox):
		printerr("ActivitiesPanel: critical nodes missing")

	modulate.a = 0.0
	visible = false
	_setup_modern_styling()

	if is_instance_valid(normal_activities_scroll):
		normal_activities_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		normal_activities_scroll.size_flags_stretch_ratio = 1.0
		normal_activities_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

	if is_instance_valid(job_tiers_tab_container):
		job_tiers_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		job_tiers_tab_container.size_flags_stretch_ratio = 1.0
		job_tiers_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		job_tiers_tab_container.focus_mode = Control.FOCUS_NONE
		job_tiers_tab_container.tab_focus_mode = Control.FOCUS_NONE

	for tier_vbox in [tier1_jobs_vbox, tier2_jobs_vbox, tier3_jobs_vbox, tier4_jobs_vbox, tier5_jobs_vbox]:
		if is_instance_valid(tier_vbox):
			tier_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tier_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			tier_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			var parent_scroll = tier_vbox.get_parent()
			if parent_scroll is ScrollContainer:
				parent_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
				parent_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

	_tier_vbox_map = {
		1: tier1_jobs_vbox,
		2: tier2_jobs_vbox,
		3: tier3_jobs_vbox,
		4: tier4_jobs_vbox,
		5: tier5_jobs_vbox,
	}

	_connect_global_signals()

	if is_instance_valid(special_tasks_button):
		_add_special_tasks_bottom_spacing()
		if not special_tasks_button.pressed.is_connected(_on_special_tasks_button_pressed):
			special_tasks_button.pressed.connect(_on_special_tasks_button_pressed)

func _exit_tree() -> void:
	_hide_custom_tooltip()
	_hide_shift_picker()
	_disconnect_global_signals()
	_kill_all_tweens()

func _connect_global_signals() -> void:
	if LocationManager and not LocationManager.location_data_updated.is_connected(_on_location_data_updated):
		LocationManager.location_data_updated.connect(_on_location_data_updated)
	if PlayerData:
		if not PlayerData.player_activity_started.is_connected(_on_player_activity_started):
			PlayerData.player_activity_started.connect(_on_player_activity_started)
		if not PlayerData.player_activity_progress.is_connected(_on_player_activity_progress):
			PlayerData.player_activity_progress.connect(_on_player_activity_progress)
		if not PlayerData.player_activity_stopped.is_connected(_on_player_activity_stopped):
			PlayerData.player_activity_stopped.connect(_on_player_activity_stopped)
		if not PlayerData.player_location_changed.is_connected(_on_player_location_changed):
			PlayerData.player_location_changed.connect(_on_player_location_changed)
	if GameManager and not GameManager.scene_changed.is_connected(_on_scene_changed):
		GameManager.scene_changed.connect(_on_scene_changed)

func _disconnect_global_signals() -> void:
	if LocationManager and LocationManager.location_data_updated.is_connected(_on_location_data_updated):
		LocationManager.location_data_updated.disconnect(_on_location_data_updated)
	if PlayerData:
		if PlayerData.player_activity_started.is_connected(_on_player_activity_started):
			PlayerData.player_activity_started.disconnect(_on_player_activity_started)
		if PlayerData.player_activity_progress.is_connected(_on_player_activity_progress):
			PlayerData.player_activity_progress.disconnect(_on_player_activity_progress)
		if PlayerData.player_activity_stopped.is_connected(_on_player_activity_stopped):
			PlayerData.player_activity_stopped.disconnect(_on_player_activity_stopped)
		if PlayerData.player_location_changed.is_connected(_on_player_location_changed):
			PlayerData.player_location_changed.disconnect(_on_player_location_changed)
	if GameManager and GameManager.scene_changed.is_connected(_on_scene_changed):
		GameManager.scene_changed.disconnect(_on_scene_changed)

func _setup_modern_styling() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.24, 0.14, 0.32, 0.92)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.95, 0.75, 1.0, 0.6)
	panel_style.set_corner_radius_all(18)
	panel_style.shadow_color = Color(0.1, 0.05, 0.2, 0.6)
	panel_style.shadow_size = 20
	add_theme_stylebox_override("panel", panel_style)

	if location_name_label:
		location_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 1.0, 1))
		location_name_label.add_theme_font_size_override("font_size", 26)
		if emoji_font:
			location_name_label.add_theme_font_override("font", emoji_font)

	if job_tiers_tab_container:
		_setup_tab_container_styling()
	if special_tasks_button:
		_style_special_tasks_button(special_tasks_button)

func _setup_tab_container_styling() -> void:
	var radius = 14

	var selected = StyleBoxFlat.new()
	selected.bg_color = Color(0.62, 0.32, 0.78, 0.95)
	selected.set_corner_radius_all(radius)
	selected.border_width_left = 2
	selected.border_width_top = 3
	selected.border_width_right = 2
	selected.border_width_bottom = 1
	selected.border_color = Color(1.0, 0.85, 1.0, 0.95)
	selected.shadow_color = Color(0.5, 0.18, 0.65, 0.55)
	selected.shadow_size = 10
	selected.shadow_offset = Vector2(0, 3)
	selected.content_margin_left = 18
	selected.content_margin_right = 18
	selected.content_margin_top = 10
	selected.content_margin_bottom = 10
	job_tiers_tab_container.add_theme_stylebox_override("tab_selected", selected)

	var unselected = StyleBoxFlat.new()
	unselected.bg_color = Color(0.22, 0.12, 0.3, 0.65)
	unselected.set_corner_radius_all(radius)
	unselected.border_width_left = 1
	unselected.border_width_top = 1
	unselected.border_width_right = 1
	unselected.border_width_bottom = 1
	unselected.border_color = Color(0.6, 0.45, 0.7, 0.35)
	unselected.content_margin_left = 16
	unselected.content_margin_right = 16
	unselected.content_margin_top = 8
	unselected.content_margin_bottom = 8
	job_tiers_tab_container.add_theme_stylebox_override("tab_unselected", unselected)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.48, 0.25, 0.62, 0.85)
	hover.set_corner_radius_all(radius)
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 1
	hover.border_color = Color(0.92, 0.72, 1.0, 0.8)
	hover.shadow_color = Color(0.4, 0.15, 0.5, 0.35)
	hover.shadow_size = 6
	hover.content_margin_left = 16
	hover.content_margin_right = 16
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	job_tiers_tab_container.add_theme_stylebox_override("tab_hovered", hover)

	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.2, 0.1, 0.28, 0.7)
	panel.set_corner_radius_all(16)
	panel.border_width_left = 2
	panel.border_width_top = 2
	panel.border_width_right = 2
	panel.border_width_bottom = 2
	panel.border_color = Color(0.75, 0.5, 0.95, 0.45)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 18
	panel.content_margin_bottom = 16
	job_tiers_tab_container.add_theme_stylebox_override("panel", panel)

	if emoji_font:
		job_tiers_tab_container.add_theme_font_override("font", emoji_font)
	job_tiers_tab_container.add_theme_color_override("font_selected_color", Color.WHITE)
	job_tiers_tab_container.add_theme_color_override("font_unselected_color", Color(0.8, 0.7, 0.9, 0.75))
	job_tiers_tab_container.add_theme_font_size_override("font_size", 15)
	
	job_tiers_tab_container.add_theme_constant_override("side_margin", 8)
	job_tiers_tab_container.add_theme_constant_override("icon_max_width", 0)

	if not job_tiers_tab_container.tab_changed.is_connected(_on_job_tab_changed):
		job_tiers_tab_container.tab_changed.connect(_on_job_tab_changed)

func animate_entry_list(container: Control) -> void:
	var delay = 0.0
	for child in container.get_children():
		if child is Control:
			child.modulate.a = 0.0
			child.position.y += 10.0
			var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(child, "modulate:a", 1.0, 0.15).set_delay(delay)
			tw.tween_property(child, "position:y", child.position.y - 10.0, 0.15).set_delay(delay)
			delay += 0.03

func _on_job_tab_changed(tab_idx: int) -> void:
	var current_child = job_tiers_tab_container.get_tab_control(tab_idx)
	if is_instance_valid(current_child):
		current_child.pivot_offset = current_child.size * 0.5
		current_child.scale = Vector2(0.97, 0.97)
		current_child.modulate.a = 0.8
		
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(current_child, "scale", Vector2.ONE, 0.15)
		tw.tween_property(current_child, "modulate:a", 1.0, 0.15)

func show_panel_animated() -> void:
	_kill_all_tweens()
	modulate.a = 0.0
	visible = true
	current_fade_tween = create_tween().set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	current_fade_tween.tween_property(self, "scale", Vector2.ONE, fade_duration).from(Vector2(0.98, 0.98))
	current_fade_tween.tween_callback(func():
		refresh_activities_panel()
		current_fade_tween = null
	)

func hide_panel_animated() -> void:
	_kill_all_tweens()
	_hide_custom_tooltip()
	_hide_shift_picker()
	if special_tasks_panel and is_instance_valid(special_tasks_panel) and special_tasks_panel.visible:
		special_tasks_panel.hide_panel_animated()
		
	current_fade_tween = create_tween().set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	current_fade_tween.tween_property(self, "scale", Vector2(0.98, 0.98), fade_duration)
	current_fade_tween.tween_callback(func():
		visible = false
		current_fade_tween = null
		_clear_activities_panel_content()
		if special_tasks_panel and is_instance_valid(special_tasks_panel):
			special_tasks_panel.queue_free()
			special_tasks_panel = null
		if current_pin_guess and is_instance_valid(current_pin_guess):
			current_pin_guess.queue_free()
			current_pin_guess = null
		if current_word_guess and is_instance_valid(current_word_guess):
			current_word_guess.queue_free()
			current_word_guess = null
	)

func _kill_all_tweens() -> void:
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()
		current_fade_tween = null

	for tween in button_hover_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	button_hover_tweens.clear()

	for tween in button_pulse_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	button_pulse_tweens.clear()

func _tween_button_scale(button: Button, target_scale: Vector2) -> void:
	if !is_instance_valid(button):
		return

	var button_id := button.get_instance_id()
	if button_hover_tweens.has(button_id):
		var old: Tween = button_hover_tweens[button_id]
		if old and old.is_valid():
			old.kill()

	var target_rotation := 0.0
	if target_scale.x > 1.0:
		target_rotation = randf_range(-1.0, 1.0)

	var tween := create_tween()
	button_hover_tweens[button_id] = tween
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, 0.15)
	tween.tween_property(button, "rotation_degrees", target_rotation, 0.15)
	tween.finished.connect(_on_button_hover_tween_finished.bind(button_id))

func _on_button_hover_tween_finished(button_id: int) -> void:
	button_hover_tweens.erase(button_id)

func refresh_activities_panel() -> void:
	if not LocationManager:
		return
	update_activities_for_location(LocationManager.get_current_location())
	_update_all_button_states()

func _on_location_data_updated(location_data: Dictionary) -> void:
	if visible:
		update_activities_for_location(location_data)
		_update_all_button_states()

func _on_player_location_changed(_location_data: Dictionary) -> void:
	refresh_activities_panel()

func _on_scene_changed(_scene_path: String) -> void:
	if visible:
		refresh_activities_panel()

func update_activities_for_location(location_data: Dictionary) -> void:
	if location_data.is_empty() or not location_data.has("name"):
		if location_name_label:
			location_name_label.text = "Unknown Location"
		_clear_all_activity_containers()
		return

	location_name_label.text = str(location_data.get("name", "Current Location"))
	_clear_all_activity_containers()

	var current_location_name = str(location_data.get("name", ""))
	var activities_to_display: Array = []

	if current_location_name == "Job Center":
		job_tiers_tab_container.show()
		job_tiers_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		job_tiers_tab_container.size_flags_stretch_ratio = 1.0
		normal_activities_scroll.hide()
		normal_activities_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		normal_activities_scroll.size_flags_stretch_ratio = 0.0
		if LocationManager and LocationManager.location_data.has("Job Center"):
			activities_to_display = LocationManager.location_data["Job Center"].get("activities", [])
			activities_to_display.sort_custom(func(a, b):
				var ta = _get_job_tier(a)
				var tb = _get_job_tier(b)
				return ta < tb or (ta == tb and str(a.get("name", "")) < str(b.get("name", "")))
			)
	else:
		normal_activities_scroll.show()
		normal_activities_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		normal_activities_scroll.size_flags_stretch_ratio = 1.0
		job_tiers_tab_container.hide()
		job_tiers_tab_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		job_tiers_tab_container.size_flags_stretch_ratio = 0.0
		activities_to_display = location_data.get("activities", [])

	if activities_to_display.is_empty():
		var target = normal_activities_vbox if current_location_name != "Job Center" else tier1_jobs_vbox
		if is_instance_valid(target):
			var lbl = _create_styled_label("No activities available here.")
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			target.add_child(lbl)
		_update_shop_button()
		_update_pin_guess_button()
		_update_word_guess_button()
		return

	_populate_activity_buttons(activities_to_display, current_location_name == "Job Center")
	_update_shop_button()
	_update_pin_guess_button()
	_update_word_guess_button()

func _activity_key(activity_data: Dictionary) -> String:
	var jid = str(activity_data.get("job_id", ""))
	if not jid.is_empty():
		return jid
	return str(activity_data.get("name", "activity"))

func _clear_activities_panel_content() -> void:
	_clear_all_activity_containers()
	_hide_custom_tooltip()

func _clear_all_activity_containers() -> void:
	# Buttons are about to be freed, so stop every tween targeting them first.
	for tween in button_hover_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	button_hover_tweens.clear()

	for tween in button_pulse_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	button_pulse_tweens.clear()

	_activity_button_map.clear()
	if is_instance_valid(normal_activities_vbox):
		for child in normal_activities_vbox.get_children():
			child.queue_free()
	for tier in _tier_vbox_map:
		var tier_vbox = _tier_vbox_map[tier]
		if is_instance_valid(tier_vbox):
			for child in tier_vbox.get_children():
				child.queue_free()

func _get_job_tier(activity_or_id) -> int:
	if activity_or_id is Dictionary:
		if activity_or_id.has("tier"):
			return clampi(int(activity_or_id.tier), 0, 5)
		return _get_job_tier_from_id(str(activity_or_id.get("job_id", "")))
	return _get_job_tier_from_id(str(activity_or_id))

func _get_job_tier_from_id(job_id: String) -> int:
	if job_id.is_empty():
		return 0
	if JOB_TIER_LOOKUP.has(job_id):
		return JOB_TIER_LOOKUP[job_id]
	if job_id.begins_with("job_waiter") or job_id.begins_with("job_retail_assistant"):
		return 1
	return 0

func _populate_activity_buttons(activities_to_display: Array, is_job_center: bool) -> void:
	for activity_data in activities_to_display:
		if not activity_data is Dictionary:
			continue
		var tier = _get_job_tier(activity_data)
		var target_vbox = _tier_vbox_map.get(tier) if is_job_center else normal_activities_vbox
		if not is_instance_valid(target_vbox):
			continue

		var entry = _create_enhanced_activity_container()
		target_vbox.add_child(entry)
		var entry_vbox = entry.get_child(0)

		var activity_button = _create_enhanced_button(str(activity_data.get("name", "Unnamed Activity")))
		var key = _activity_key(activity_data)
		_activity_button_map[key] = {"button": activity_button, "data": activity_data}
		entry_vbox.add_child(activity_button)

		var desc = _create_styled_label(str(activity_data.get("description", "No description.")))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_font_size_override("font_size", 13)
		entry_vbox.add_child(desc)

		_update_button_visual_state(activity_button, activity_data)

func _create_enhanced_activity_container() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.45, 0.28, 0.55, 0.35)
	bg.set_corner_radius_all(14)
	bg.border_width_left = 1
	bg.border_width_top = 1
	bg.border_width_right = 1
	bg.border_width_bottom = 1
	bg.border_color = Color(0.85, 0.65, 0.95, 0.25)
	bg.content_margin_left = 14
	bg.content_margin_right = 14
	bg.content_margin_top = 10
	bg.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", bg)
	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	inner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(inner)
	return panel

func _create_enhanced_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2(280, 44)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.72, 0.38, 0.72, 0.95)
	normal.set_corner_radius_all(16)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.95, 0.7, 0.95, 0.85)
	normal.shadow_color = Color(0.4, 0.15, 0.55, 0.4)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 3)

	var hover = normal.duplicate()
	hover.bg_color = Color(0.85, 0.48, 0.85, 1.0)
	hover.border_color = Color(1.0, 0.8, 1.0, 1.0)
	hover.shadow_size = 8

	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.6, 0.3, 0.65, 1.0)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 15)
	if emoji_font:
		button.add_theme_font_override("font", emoji_font)

	return button

func _create_styled_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.92, 0.85, 0.95, 0.95))
	if emoji_font:
		label.add_theme_font_override("font", emoji_font)
	return label

func _show_requirements_tooltip(activity_data: Dictionary) -> void:
	var key = _activity_key(activity_data)
	var entry = _activity_button_map.get(key, {})
	var button: Button = entry.get("button")
	if not is_instance_valid(button) or not button.disabled:
		return
	var text = _get_requirements_text(activity_data)
	if text.is_empty():
		return
	_show_custom_tooltip(text, button)

func _get_requirements_text(activity_data: Dictionary) -> String:
	if not PlayerData or not activity_data.get("is_job", false):
		return ""
	var parts: PackedStringArray = ["[b][color=#f0c0ff]Requirements[/color][/b]"]
	for stat_name in activity_data.get("stat_requirements", {}):
		var required = float(activity_data.stat_requirements[stat_name])
		var current = PlayerData.get_stat(stat_name)
		if current >= required:
			parts.append("[color=#70ff90]✓ %s: %.1f / %.1f[/color]" % [str(stat_name).capitalize(), current, required])
		else:
			parts.append("[color=#ff7070]✗ %s: %.1f / %.1f[/color]" % [str(stat_name).capitalize(), current, required])
	for job_id in activity_data.get("job_requirements", {}):
		var required = float(activity_data.job_requirements[job_id])
		var current = PlayerData.get_job_hours_worked(str(job_id))
		var job_name = _get_job_display_name(str(job_id))
		if current >= required:
			parts.append("[color=#70ff90]✓ %s: %.1fh / %.1fh[/color]" % [job_name, current, required])
		else:
			parts.append("[color=#ff7070]✗ %s: %.1fh / %.1fh[/color]" % [job_name, current, required])
	var money_req = float(activity_data.get("money_requirement", 0.0))
	if money_req > 0.0:
		var current = PlayerData.money
		if current >= money_req:
			parts.append("[color=#70ff90]✓ Money: $%.2f / $%.2f[/color]" % [current, money_req])
		else:
			parts.append("[color=#ff7070]✗ Money: $%.2f / $%.2f[/color]" % [current, money_req])
	return "\n".join(parts)

func _show_custom_tooltip(text: String, button: Button) -> void:
	_hide_custom_tooltip()
	
	_tooltip_layer = CanvasLayer.new()
	_tooltip_layer.layer = 128
	_tooltip_layer.name = "TooltipLayer"
	get_tree().root.add_child(_tooltip_layer)

	custom_tooltip = PanelContainer.new()
	custom_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_tooltip.custom_minimum_size = Vector2(280, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.15, 0.38, 0.97)
	style.set_corner_radius_all(12)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.7, 1.0, 0.85)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.3, 0.1, 0.45, 0.55)
	style.shadow_size = 12
	custom_tooltip.add_theme_stylebox_override("panel", style)

	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(250, 0)
	label.add_theme_font_size_override("normal_font_size", 14)
	label.text = text
	custom_tooltip.add_child(label)
	_tooltip_layer.add_child(custom_tooltip)

	await get_tree().process_frame
	if not is_instance_valid(custom_tooltip) or not is_instance_valid(button):
		return
	var button_rect = button.get_global_rect()
	var tooltip_size = custom_tooltip.size
	var screen = get_viewport().get_visible_rect().size
	var pos = Vector2(
		button_rect.position.x - tooltip_size.x - 12,
		button_rect.position.y + (button_rect.size.y - tooltip_size.y) * 0.5
	)
	if pos.x < 10:
		pos.x = button_rect.position.x + button_rect.size.x + 12
	pos.y = clampf(pos.y, 10, screen.y - tooltip_size.y - 10)
	custom_tooltip.global_position = pos
	custom_tooltip.modulate.a = 0.0
	custom_tooltip.scale = Vector2(0.9, 0.9)
	custom_tooltip.pivot_offset = custom_tooltip.size * 0.5

	var t_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t_tween.tween_property(custom_tooltip, "modulate:a", 1.0, 0.12)
	t_tween.tween_property(custom_tooltip, "scale", Vector2.ONE, 0.12)

func _hide_custom_tooltip() -> void:
	if _tooltip_layer and is_instance_valid(_tooltip_layer):
		_tooltip_layer.queue_free()
		_tooltip_layer = null
	custom_tooltip = null

func _on_activity_button_pressed(activity_data: Dictionary) -> void:
	if not PlayerData:
		return
	if activity_data.get("is_job", false):
		_show_shift_picker(activity_data)
		return
	if PlayerData.start_activity(activity_data):
		_update_all_button_states()

func _on_player_activity_started(_activity_data: Dictionary) -> void:
	_update_all_button_states()

func _on_player_activity_progress(_activity_data: Dictionary) -> void:
	_update_all_button_states()

func _on_player_activity_stopped(_activity_data: Dictionary, _was_exhausted: bool) -> void:
	_update_all_button_states()

func _update_all_button_states() -> void:
	for key in _activity_button_map:
		var entry = _activity_button_map[key]
		var button: Button = entry.get("button")
		var data: Dictionary = entry.get("data", {})
		if is_instance_valid(button):
			_update_button_visual_state(button, data)

func _update_button_visual_state(button: Button, activity_data: Dictionary) -> void:
	if not PlayerData:
		return

	var is_job = activity_data.get("is_job", false)
	var is_active = PlayerData.is_activity_active and PlayerData.get_current_activity_name() == activity_data.get("name")
	var is_accessible = true

	for conn in button.pressed.get_connections():
		button.pressed.disconnect(conn.callable)
	for conn in button.mouse_entered.get_connections():
		button.mouse_entered.disconnect(conn.callable)
	for conn in button.mouse_exited.get_connections():
		button.mouse_exited.disconnect(conn.callable)

	button.mouse_entered.connect(func(): _tween_button_scale(button, Vector2(1.03, 1.03)))
	button.mouse_exited.connect(func():
		_tween_button_scale(button, Vector2.ONE)
		_hide_custom_tooltip()
	)

	if is_active:
		button.text = "🛑 Stop " + str(activity_data.get("name", "Activity"))
		button.pressed.connect(func(): PlayerData.stop_activity(false))
		var active_style = StyleBoxFlat.new()
		active_style.bg_color = Color(0.85, 0.3, 0.55, 0.95)
		active_style.set_corner_radius_all(16)
		active_style.border_width_left = 3
		active_style.border_width_top = 3
		active_style.border_width_right = 3
		active_style.border_width_bottom = 3
		active_style.border_color = Color(1.0, 0.55, 0.75, 0.9)
		button.add_theme_stylebox_override("normal", active_style)
		_start_safe_pulse(button)
	else:
		_stop_safe_pulse(button)
		
		button.text = "▶ " + str(activity_data.get("name", "Activity"))
		button.pressed.connect(_on_activity_button_pressed.bind(activity_data))

	if is_job:
		for stat_name in activity_data.get("stat_requirements", {}):
			if PlayerData.get_stat(stat_name) < float(activity_data.stat_requirements[stat_name]):
				is_accessible = false
		for job_id in activity_data.get("job_requirements", {}):
			if PlayerData.get_job_hours_worked(str(job_id)) < float(activity_data.job_requirements[job_id]):
				is_accessible = false
		var money_req = float(activity_data.get("money_requirement", 0.0))
		if money_req > 0.0 and PlayerData.money < money_req:
			is_accessible = false

	if is_accessible and not is_active:
		button.disabled = false
		button.modulate = Color.WHITE
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.72, 0.38, 0.72, 0.95)
		normal_style.set_corner_radius_all(16)
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color(0.95, 0.7, 0.95, 0.85)
		button.add_theme_stylebox_override("normal", normal_style)
	elif not is_accessible:
		button.disabled = true
		button.modulate = Color(0.65, 0.65, 0.7, 0.8)
		button.mouse_entered.connect(_show_requirements_tooltip.bind(activity_data))
		var disabled_style = StyleBoxFlat.new()
		disabled_style.bg_color = Color(0.3, 0.2, 0.35, 0.6)
		disabled_style.set_corner_radius_all(16)
		disabled_style.border_width_left = 2
		disabled_style.border_width_top = 2
		disabled_style.border_width_right = 2
		disabled_style.border_width_bottom = 2
		disabled_style.border_color = Color(0.5, 0.35, 0.55, 0.5)
		button.add_theme_stylebox_override("disabled", disabled_style)

func _start_safe_pulse(button: Button) -> void:
	if !is_instance_valid(button):
		return

	var button_id := button.get_instance_id()
	if button_pulse_tweens.has(button_id):
		return

	_start_pulse_cycle(button_id)

func _start_pulse_cycle(button_id: int) -> void:
	var object := instance_from_id(button_id)
	if object == null or not is_instance_valid(object) or not (object is Button):
		button_pulse_tweens.erase(button_id)
		return

	var button := object as Button
	var tween := create_tween()
	button_pulse_tweens[button_id] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "modulate", Color(1.4, 0.7, 1.2, 1.0), 0.6)
	tween.tween_property(button, "modulate", Color.WHITE, 0.6)
	tween.finished.connect(_on_pulse_cycle_finished.bind(button_id))

func _on_pulse_cycle_finished(button_id: int) -> void:
	# Remove the completed finite tween before starting the next cycle.
	# Using an integer instance ID avoids capturing a Button that may be freed.
	if not button_pulse_tweens.has(button_id):
		return

	button_pulse_tweens.erase(button_id)
	var object := instance_from_id(button_id)
	if object != null and is_instance_valid(object) and object is Button:
		_start_pulse_cycle(button_id)

func _stop_safe_pulse(button: Button) -> void:
	if !is_instance_valid(button):
		return

	var button_id := button.get_instance_id()
	if button_pulse_tweens.has(button_id):
		var tween: Tween = button_pulse_tweens[button_id]
		if tween and tween.is_valid():
			tween.kill()
		button_pulse_tweens.erase(button_id)

	button.modulate = Color.WHITE

func _get_job_display_name(job_id: String) -> String:
	if not LocationManager:
		return job_id
	for loc_name in LocationManager.location_data.keys():
		for activity in LocationManager.location_data[loc_name].get("activities", []):
			if str(activity.get("job_id", "")) == job_id:
				return str(activity.get("name", job_id))
	return job_id

func _add_special_tasks_bottom_spacing() -> void:
	if not is_instance_valid(special_tasks_button):
		return

	var parent := special_tasks_button.get_parent()
	if parent is MarginContainer:
		parent.add_theme_constant_override("margin_bottom", 12)
		return

	if parent is BoxContainer:
		var spacer_name := "SpecialTasksBottomSpacer"
		if parent.has_node(spacer_name):
			return

		var spacer := Control.new()
		spacer.name = spacer_name
		spacer.custom_minimum_size = Vector2(0.0, 12.0)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(spacer)
		parent.move_child(spacer, special_tasks_button.get_index() + 1)

func _style_special_tasks_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.8, 0.6, 0.2, 0.9)
	normal.set_corner_radius_all(18)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1.0, 0.8, 0.3, 0.8)
	var hover = normal.duplicate()
	hover.bg_color = Color(0.9, 0.7, 0.3, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	button.add_theme_font_size_override("font_size", 16)

func _on_special_tasks_button_pressed() -> void:
	var current_location = location_name_label.text if is_instance_valid(location_name_label) else ""
	if current_location.is_empty():
		return
	if not special_tasks_panel or not is_instance_valid(special_tasks_panel):
		var scene = load(SPECIAL_TASKS_SCENE_PATH)
		if not scene:
			return
		special_tasks_panel = scene.instantiate()
		add_child(special_tasks_panel)
		if special_tasks_panel.has_signal("panel_closed"):
			special_tasks_panel.panel_closed.connect(_on_special_tasks_panel_closed)
	special_tasks_panel.show_panel_animated(current_location)

func _on_special_tasks_panel_closed() -> void:
	pass

func _update_shop_button() -> void:
	if shop_button and is_instance_valid(shop_button):
		shop_button.queue_free()
		shop_button = null

	var loc_name = ""
	if LocationManager:
		var loc = LocationManager.get_current_location()
		if loc is Dictionary:
			loc_name = str(loc.get("name", ""))
	if loc_name.to_lower() != "mall":
		return

	var slot = get_node_or_null("%ShopButton")
	if not slot:
		slot = normal_activities_vbox if is_instance_valid(normal_activities_vbox) else null
	if not slot:
		return

	shop_button = Button.new()
	shop_button.text = "🛍️  Open Shop"
	shop_button.custom_minimum_size = Vector2(280, 52)
	shop_button.focus_mode = Control.FOCUS_NONE
	shop_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.38, 0.72, 0.95)
	style.set_corner_radius_all(14)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.7, 0.95, 0.85)
	var hover = style.duplicate()
	hover.bg_color = Color(0.85, 0.48, 0.85, 1.0)
	shop_button.add_theme_stylebox_override("normal", style)
	shop_button.add_theme_stylebox_override("hover", hover)
	shop_button.add_theme_color_override("font_color", Color.WHITE)
	shop_button.add_theme_font_size_override("font_size", 17)
	shop_button.pressed.connect(_on_shop_button_pressed)
	slot.add_child(shop_button)

func _on_shop_button_pressed() -> void:
	if current_shop and is_instance_valid(current_shop):
		return
	current_shop = SHOP_SCENE.instantiate()
	if not current_shop:
		return
	get_tree().root.add_child(current_shop)
	if current_shop.has_method("show_panel_animated"):
		current_shop.show_panel_animated()
	if current_shop.has_signal("close_pressed"):
		current_shop.close_pressed.connect(func():
			if current_shop and is_instance_valid(current_shop):
				if current_shop.has_method("hide_panel_animated"):
					current_shop.hide_panel_animated()
				else:
					current_shop.queue_free()
				current_shop = null
		)

func _show_shift_picker(job_data: Dictionary) -> void:
	_hide_shift_picker()
	_shift_picker_layer = CanvasLayer.new()
	_shift_picker_layer.layer = 125
	get_tree().root.add_child(_shift_picker_layer)

	var dim = ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_shift_picker_layer.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shift_picker_layer.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.16, 0.38, 0.97)
	style.set_corner_radius_all(18)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.95, 0.7, 1.0, 0.9)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Choose shift — %s" % job_data.get("name", "Job")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.95, 1))
	vbox.add_child(title)

	var rate = float(job_data.get("money_gain_per_second", 0.0))
	for key in ["4h", "8h", "12h"]:
		var shift = PlayerData.JOB_SHIFTS[key]
		var est = rate * float(shift.seconds)
		var btn = Button.new()
		btn.text = "%s  ·  ~$%.2f  ·  +%d AP on complete" % [shift.label, est, shift.ap]
		btn.custom_minimum_size = Vector2(360, 44)
		btn.focus_mode = Control.FOCUS_NONE
		_style_shift_button(btn)
		btn.pressed.connect(_on_shift_chosen.bind(job_data, key))
		vbox.add_child(btn)

	var cancel = Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(360, 40)
	cancel.focus_mode = Control.FOCUS_NONE
	_style_shift_button(cancel, true)
	cancel.pressed.connect(_hide_shift_picker)
	vbox.add_child(cancel)

func _style_shift_button(btn: Button, is_cancel: bool = false) -> void:
	var s = StyleBoxFlat.new()
	s.set_corner_radius_all(14)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	if is_cancel:
		s.bg_color = Color(0.45, 0.22, 0.35, 0.95)
		s.border_color = Color(1.0, 0.55, 0.7, 0.85)
	else:
		s.bg_color = Color(0.72, 0.38, 0.72, 0.95)
		s.border_color = Color(0.95, 0.7, 0.95, 0.85)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _on_shift_chosen(job_data: Dictionary, shift_key: String) -> void:
	_hide_shift_picker()
	if PlayerData and PlayerData.start_job_shift(job_data, shift_key):
		_update_all_button_states()

func _hide_shift_picker() -> void:
	if _shift_picker_layer and is_instance_valid(_shift_picker_layer):
		_shift_picker_layer.queue_free()
	_shift_picker_layer = null
	
func _update_pin_guess_button() -> void:
	if pin_guess_button and is_instance_valid(pin_guess_button):
		pin_guess_button.queue_free()
		pin_guess_button = null

	var loc_name := ""
	if LocationManager:
		var loc = LocationManager.get_current_location()
		if loc is Dictionary:
			loc_name = str(loc.get("name", ""))
	if loc_name != "Library":
		return

	var slot = get_node_or_null("%PinGuessButtonSlot")
	if not slot:
		return

	pin_guess_button = Button.new()
	pin_guess_button.text = "🔐  Crack the Code"
	pin_guess_button.custom_minimum_size = Vector2(280, 52)
	pin_guess_button.focus_mode = Control.FOCUS_NONE
	pin_guess_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.45, 0.35, 0.75, 0.95)
	style.set_corner_radius_all(14)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.7, 1.0, 0.9)
	var hover = style.duplicate()
	hover.bg_color = Color(0.55, 0.45, 0.9, 1.0)
	pin_guess_button.add_theme_stylebox_override("normal", style)
	pin_guess_button.add_theme_stylebox_override("hover", hover)
	pin_guess_button.add_theme_color_override("font_color", Color.WHITE)
	pin_guess_button.add_theme_font_size_override("font_size", 17)
	pin_guess_button.pressed.connect(_on_pin_guess_button_pressed)

	slot.add_child(pin_guess_button)

func _on_pin_guess_button_pressed() -> void:
	if current_pin_guess and is_instance_valid(current_pin_guess):
		return
	current_pin_guess = PIN_GUESS_SCENE.instantiate()
	if not current_pin_guess:
		return
	get_tree().root.add_child(current_pin_guess)
	if current_pin_guess.has_signal("finished"):
		current_pin_guess.finished.connect(func(won: bool):
			current_pin_guess = null
			if won and UIManager and UIManager.has_method("show_notification"):
				UIManager.show_notification("+1 AP — code cracked!")
		)

func _update_word_guess_button() -> void:
	if word_guess_button and is_instance_valid(word_guess_button):
		word_guess_button.queue_free()
		word_guess_button = null

	var loc_name := ""
	if LocationManager:
		var loc = LocationManager.get_current_location()
		if loc is Dictionary:
			loc_name = str(loc.get("name", ""))

	var slot = get_node_or_null("%WordGuessButtonSlot")
	if slot:
		slot.visible = (loc_name == "University")
	if loc_name != "University":
		return
	if not slot:
		return

	word_guess_button = Button.new()
	word_guess_button.text = "📝  Campus Word"
	word_guess_button.custom_minimum_size = Vector2(280, 52)
	word_guess_button.focus_mode = Control.FOCUS_NONE
	word_guess_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.4, 0.75, 0.95)
	style.set_corner_radius_all(14)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.75, 1.0, 0.9)
	var hover = style.duplicate()
	hover.bg_color = Color(0.45, 0.5, 0.9, 1.0)
	word_guess_button.add_theme_stylebox_override("normal", style)
	word_guess_button.add_theme_stylebox_override("hover", hover)
	word_guess_button.add_theme_color_override("font_color", Color.WHITE)
	word_guess_button.add_theme_font_size_override("font_size", 17)
	word_guess_button.pressed.connect(_on_word_guess_button_pressed)
	slot.add_child(word_guess_button)

func _on_word_guess_button_pressed() -> void:
	if current_word_guess and is_instance_valid(current_word_guess):
		return
	current_word_guess = WORD_GUESS_SCENE.instantiate()
	get_tree().root.add_child(current_word_guess)
	current_word_guess.finished.connect(func(won: bool):
		current_word_guess = null
		if won and UIManager and UIManager.has_method("show_notification"):
			UIManager.show_notification("+1 AP — word solved!")
	)
