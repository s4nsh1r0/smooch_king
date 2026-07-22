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

# Animation properties
@export var fade_duration: float = 0.15
var current_fade_tween: Tween = null
var active_button_tweens: Dictionary = {}  # Track tweens by node

var _tier_vbox_map: Dictionary = {}
var _activity_button_map: Dictionary = {}

# Emoji font for consistent rendering
@export var emoji_font: Font = preload("res://fonts/NotoSans-Regular.ttf")

# Reference to Special Tasks Panel (instantiated dynamically)
var special_tasks_panel: PanelContainer = null
const SPECIAL_TASKS_SCENE_PATH: String = "res://ui/special_tasks.tscn"

func _ready() -> void:
	# Check critical nodes
	for node_name in ["location_name_label", "normal_activities_vbox", "job_tiers_tab_container"]:
		var node = get(node_name)
		if not is_instance_valid(node):
			printerr("ActivitiesPanel: Critical node %s is null!" % node_name)

	modulate.a = 0.0
	visible = false
	
	# Apply modern styling
	_setup_modern_styling()

	if is_instance_valid(normal_activities_scroll):
		normal_activities_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		normal_activities_scroll.size_flags_stretch_ratio = 1.0
	if is_instance_valid(job_tiers_tab_container):
		job_tiers_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		job_tiers_tab_container.size_flags_stretch_ratio = 1.0
		job_tiers_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		job_tiers_tab_container.focus_mode = Control.FOCUS_NONE
		job_tiers_tab_container.tab_focus_mode = Control.FOCUS_NONE

	# Center job tier containers
	for tier_vbox in [tier1_jobs_vbox, tier2_jobs_vbox, tier3_jobs_vbox, tier4_jobs_vbox, tier5_jobs_vbox]:
		if is_instance_valid(tier_vbox):
			tier_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tier_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			tier_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_tier_vbox_map = {
		1: tier1_jobs_vbox,
		2: tier2_jobs_vbox,
		3: tier3_jobs_vbox,
		4: tier4_jobs_vbox,
		5: tier5_jobs_vbox,
	}

	if LocationManager:
		LocationManager.connect("location_data_updated", _on_location_data_updated)
	else:
		printerr("ActivitiesPanel: LocationManager autoload not found!")
	
	if PlayerData:
		PlayerData.player_activity_started.connect(_on_player_activity_started)
		PlayerData.player_activity_progress.connect(_on_player_activity_progress)
		PlayerData.player_activity_stopped.connect(_on_player_activity_stopped)
		PlayerData.player_location_changed.connect(_on_player_location_changed)
	else:
		printerr("ActivitiesPanel: PlayerData autoload not found!")
	
	if GameManager:
		GameManager.scene_changed.connect(_on_scene_changed)
	else:
		printerr("ActivitiesPanel: GameManager autoload not found!")

	# Connect special tasks button
	if is_instance_valid(special_tasks_button):
		special_tasks_button.pressed.connect(_on_special_tasks_button_pressed)

func _setup_modern_styling():
	# Enhanced glassmorphism panel background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.10, 0.18, 0.92)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.25, 0.55, 0.95, 0.5)
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0, 6)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", panel_style)
	
	# Enhanced location label with emoji font
	if location_name_label:
		location_name_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
		location_name_label.add_theme_color_override("font_shadow_color", Color(0.15, 0.35, 0.75, 0.8))
		location_name_label.add_theme_constant_override("shadow_offset_x", 2)
		location_name_label.add_theme_constant_override("shadow_offset_y", 2)
		location_name_label.add_theme_font_size_override("font_size", 26)
		if emoji_font:
			location_name_label.add_theme_font_override("font", emoji_font)
	
	# Enhanced tab container styling
	if job_tiers_tab_container:
		_setup_tab_container_styling()
	
	# Style the special tasks button
	if special_tasks_button:
		_style_special_tasks_button(special_tasks_button)

func _setup_tab_container_styling():
	# Selected tab
	var tab_selected_style = StyleBoxFlat.new()
	tab_selected_style.bg_color = Color(0.2, 0.45, 0.85, 0.95)
	tab_selected_style.corner_radius_top_left = 12
	tab_selected_style.corner_radius_top_right = 12
	tab_selected_style.border_width_top = 3
	tab_selected_style.border_width_left = 2
	tab_selected_style.border_width_right = 2
	tab_selected_style.border_color = Color(0.3, 0.6, 1.0, 0.8)
	tab_selected_style.content_margin_left = 16
	tab_selected_style.content_margin_right = 16
	tab_selected_style.content_margin_top = 8
	tab_selected_style.content_margin_bottom = 8
	job_tiers_tab_container.add_theme_stylebox_override("tab_selected", tab_selected_style)
	
	# Unselected tabs
	var tab_unselected_style = StyleBoxFlat.new()
	tab_unselected_style.bg_color = Color(0.12, 0.12, 0.18, 0.7)
	tab_unselected_style.corner_radius_top_left = 12
	tab_unselected_style.corner_radius_top_right = 12
	tab_unselected_style.border_width_top = 1
	tab_unselected_style.border_width_left = 1
	tab_unselected_style.border_width_right = 1
	tab_unselected_style.border_color = Color(0.3, 0.3, 0.4, 0.4)
	tab_unselected_style.content_margin_left = 16
	tab_unselected_style.content_margin_right = 16
	tab_unselected_style.content_margin_top = 8
	tab_unselected_style.content_margin_bottom = 8
	job_tiers_tab_container.add_theme_stylebox_override("tab_unselected", tab_unselected_style)
	
	# Tab hover effect
	var tab_hover_style = StyleBoxFlat.new()
	tab_hover_style.bg_color = Color(0.18, 0.35, 0.65, 0.8)
	tab_hover_style.corner_radius_top_left = 12
	tab_hover_style.corner_radius_top_right = 12
	tab_hover_style.border_width_top = 2
	tab_hover_style.border_width_left = 1
	tab_hover_style.border_width_right = 1
	tab_hover_style.border_color = Color(0.4, 0.65, 0.9, 0.6)
	tab_hover_style.content_margin_left = 16
	tab_hover_style.content_margin_right = 16
	tab_hover_style.content_margin_top = 8
	tab_hover_style.content_margin_bottom = 8
	job_tiers_tab_container.add_theme_stylebox_override("tab_hover", tab_hover_style)
	
	# Panel background for tab content
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.12, 0.20, 0.6)
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.25, 0.45, 0.75, 0.4)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 12
	job_tiers_tab_container.add_theme_stylebox_override("panel", panel_style)
	
	# Enhanced typography for tabs
	if emoji_font:
		job_tiers_tab_container.add_theme_font_override("font", emoji_font)
	job_tiers_tab_container.add_theme_color_override("font_selected_color", Color(1.0, 1.0, 1.0, 1.0))
	job_tiers_tab_container.add_theme_color_override("font_unselected_color", Color(0.7, 0.75, 0.85, 0.9))
	job_tiers_tab_container.add_theme_color_override("font_hovered_color", Color(0.9, 0.95, 1.0, 1.0))
	job_tiers_tab_container.add_theme_font_size_override("font_size", 15)

func show_panel_animated():
	_kill_all_tweens()
	
	modulate.a = 0.0
	visible = true
	
	# Animate first, then populate content
	current_fade_tween = create_tween().set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	current_fade_tween.tween_property(self, "scale", Vector2.ONE, fade_duration).from(Vector2(0.98, 0.98))
	current_fade_tween.tween_callback(func():
		refresh_activities_panel()
		current_fade_tween = null
	)

func hide_panel_animated():
	_kill_all_tweens()

	# Hide special tasks if open
	if special_tasks_panel and is_instance_valid(special_tasks_panel) and special_tasks_panel.visible:
		special_tasks_panel.hide_panel_animated()

	current_fade_tween = create_tween().set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	current_fade_tween.tween_property(self, "scale", Vector2(0.98, 0.98), fade_duration)
	current_fade_tween.tween_callback(func():
		visible = false
		current_fade_tween = null
		_clear_activities_panel_content()
		# Clean up special tasks panel on hide
		if special_tasks_panel and is_instance_valid(special_tasks_panel):
			special_tasks_panel.queue_free()
			special_tasks_panel = null
	)

func _kill_all_tweens():
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()
		current_fade_tween = null
	
	for node in active_button_tweens.keys():
		var tween = active_button_tweens[node]
		if tween and tween.is_valid():
			tween.kill()
	active_button_tweens.clear()

func get_fade_tween() -> Tween:
	return current_fade_tween

func refresh_activities_panel():
	if not LocationManager:
		printerr("ActivitiesPanel: LocationManager not found!")
		return
	
	var current_location_data = LocationManager.get_current_location()
	update_activities_for_location(current_location_data)
	_update_all_button_states()

func _on_location_data_updated(_location_data: Dictionary):
	if visible:
		update_activities_for_location(_location_data)
		_update_all_button_states()

func _on_player_location_changed(_location_data: Dictionary): 
	refresh_activities_panel()

func _on_scene_changed(_scene_path: String):
	if visible:
		refresh_activities_panel()

func update_activities_for_location(location_data: Dictionary):
	if location_data.is_empty() or not location_data.has("name"):
		printerr("ActivitiesPanel: Invalid location_data: ", location_data)
		location_name_label.text = "Unknown Location"
		_clear_all_activity_containers()
		return
	
	location_name_label.text = location_data.get("name", "Current Location")
	_clear_all_activity_containers()
	_activity_button_map.clear()

	var activities_to_display: Array[Dictionary]
	var current_location_name = location_data.get("name", "")

	if not location_data.has("activities") or location_data["activities"].is_empty():
		var target_vbox = normal_activities_vbox if current_location_name != "Job Center" else tier1_jobs_vbox
		if is_instance_valid(target_vbox):
			var no_activities_label = _create_styled_label("No activities available here.")
			no_activities_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			target_vbox.add_child(no_activities_label)
		else:
			printerr("ActivitiesPanel: Invalid target_vbox for ", current_location_name)
		return

	for activity in location_data.get("activities", []):
		if not activity.has("name") or not activity.has("description") or not activity.has("effects"):
			printerr("ActivitiesPanel: Invalid activity in ", current_location_name, ": ", activity)
			continue

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
				var tier_a = _get_job_tier(a.get("job_id", ""))
				var tier_b = _get_job_tier(b.get("job_id", ""))
				return tier_a < tier_b or (tier_a == tier_b and a.get("name", "") < b.get("name", ""))
			)
		else:
			activities_to_display = []
	else:
		normal_activities_scroll.show()
		normal_activities_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		normal_activities_scroll.size_flags_stretch_ratio = 1.0
		job_tiers_tab_container.hide()
		job_tiers_tab_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		job_tiers_tab_container.size_flags_stretch_ratio = 0.0
		activities_to_display = location_data.get("activities", [])

	if activities_to_display.is_empty():
		var target_vbox = normal_activities_vbox if current_location_name != "Job Center" else tier1_jobs_vbox
		if is_instance_valid(target_vbox):
			var no_activities_label = _create_styled_label("No activities available here.")
			no_activities_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			target_vbox.add_child(no_activities_label)
		else:
			printerr("ActivitiesPanel: Invalid target_vbox for ", current_location_name)
		return

	_populate_activity_buttons(activities_to_display, current_location_name == "Job Center")

func _clear_activities_panel_content():
	_clear_all_activity_containers()
	_activity_button_map.clear()

func _clear_all_activity_containers():
	# Disconnect signals and kill tweens before freeing nodes
	for activity_data in _activity_button_map.keys():
		var button = _activity_button_map[activity_data]
		if is_instance_valid(button):
			if button.is_connected("pressed", PlayerData.stop_activity):
				button.pressed.disconnect(PlayerData.stop_activity)
			if button.is_connected("pressed", _on_activity_button_pressed.bind(activity_data)):
				button.pressed.disconnect(_on_activity_button_pressed.bind(activity_data))
			if button.is_connected("mouse_entered", _show_requirements_tooltip.bind(activity_data)):
				button.mouse_entered.disconnect(_show_requirements_tooltip.bind(activity_data))
			if button.is_connected("mouse_exited", _hide_requirements_tooltip):
				button.mouse_exited.disconnect(_hide_requirements_tooltip)
			if button in active_button_tweens:
				var tween = active_button_tweens[button]
				if tween and tween.is_valid():
					tween.kill()
				active_button_tweens.erase(button)
	
	# Clear containers
	if is_instance_valid(normal_activities_vbox):
		for child in normal_activities_vbox.get_children():
			child.queue_free()
	else:
		printerr("ActivitiesPanel: normal_activities_vbox is invalid!")
	
	for tier in _tier_vbox_map.keys():
		var tier_vbox = _tier_vbox_map[tier]
		if is_instance_valid(tier_vbox):
			for child in tier_vbox.get_children():
				child.queue_free()
		else:
			printerr("ActivitiesPanel: tier_vbox for tier ", tier, " is invalid!")

func _get_job_tier(job_id: String) -> int:
	if job_id.begins_with("job_waiter") or job_id.begins_with("job_retail_assistant") or job_id.begins_with("job_office_clerk"): return 1
	elif job_id.begins_with("job_bartender") or job_id.begins_with("job_head_waiter") or job_id.begins_with("job_sales_associate") or job_id.begins_with("job_visual_merchandiser") or job_id.begins_with("job_junior_analyst") or job_id.begins_with("job_administrative_assistant"): return 2
	elif job_id.begins_with("job_mixologist") or job_id.begins_with("job_event_coordinator") or job_id.begins_with("job_restaurant_manager") or job_id.begins_with("job_sommelier") or job_id.begins_with("job_store_manager") or job_id.begins_with("job_regional_sales_manager") or job_id.begins_with("job_brand_ambassador") or job_id.begins_with("job_fashion_buyer") or job_id.begins_with("job_data_analyst") or job_id.begins_with("job_executive_assistant") or job_id.begins_with("job_project_coordinator") or job_id.begins_with("job_hr_specialist"): return 3
	elif job_id.begins_with("job_luxury_bartender") or job_id.begins_with("job_celebrity_event_planner") or job_id.begins_with("job_hotel_general_manager") or job_id.begins_with("job_master_sommelier") or job_id.begins_with("job_cruise_ship_director") or job_id.begins_with("job_michelin_star_chef") or job_id.begins_with("job_hospitality_consultant") or job_id.begins_with("job_food_critic") or job_id.begins_with("job_national_sales_director") or job_id.begins_with("job_e_commerce_head") or job_id.begins_with("job_luxury_brand_manager") or job_id.begins_with("job_global_buyer") or job_id.begins_with("job_retail_chain_ceo") or job_id.begins_with("job_franchise_developer") or job_id.begins_with("job_marketing_director") or job_id.begins_with("job_supply_chain_head") or job_id.begins_with("job_senior_data_scientist") or job_id.begins_with("job_chief_of_staff") or job_id.begins_with("job_program_manager") or job_id.begins_with("job_hr_director") or job_id.begins_with("job_financial_analyst") or job_id.begins_with("job_legal_counsel") or job_id.begins_with("job_it_manager") or job_id.begins_with("job_communications_specialist"): return 4
	elif job_id.begins_with("job_hospitality_ceo") or job_id.begins_with("job_retail_magnate") or job_id.begins_with("job_corporate_mogul"): return 5
	return 0

func _populate_activity_buttons(activities_to_display: Array[Dictionary], is_job_center: bool): 
	var target_vbox: VBoxContainer

	for activity_data in activities_to_display:
		var current_tier = _get_job_tier(activity_data.get("job_id", ""))
		target_vbox = _tier_vbox_map.get(current_tier) if is_job_center else normal_activities_vbox
		if not is_instance_valid(target_vbox):
			printerr("ActivitiesPanel: Invalid target_vbox for tier: ", current_tier)
			continue

		# Create enhanced activity container
		var activity_entry_panel = _create_enhanced_activity_container()
		target_vbox.add_child(activity_entry_panel) 

		# Get the VBoxContainer from the panel
		var activity_entry_vbox = activity_entry_panel.get_child(0) 

		var activity_button = _create_enhanced_button(activity_data.get("name", "Unnamed Activity"))
		_activity_button_map[activity_data] = activity_button
		activity_entry_panel.set_meta("activity_data", activity_data)
		
		activity_entry_vbox.add_child(activity_button) 

		var desc_label = _create_styled_label(activity_data.get("description", "No description."))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9, 0.9))
		desc_label.add_theme_font_size_override("font_size", 13)
		activity_entry_vbox.add_child(desc_label) 

		var requirements_label = _create_enhanced_requirements_label()
		requirements_label.hide()
		activity_entry_vbox.add_child(requirements_label) 
		activity_entry_panel.set_meta("requirements_label", requirements_label) 
		
		_update_button_visual_state(activity_button, activity_data, requirements_label)
	
	# Add elegant spacers
	for vbox in ([normal_activities_vbox] if not is_job_center else _tier_vbox_map.values()):
		if is_instance_valid(vbox) and not vbox.get_children().is_empty():
			var spacer = Control.new()
			spacer.set_custom_minimum_size(Vector2(0, 24))
			vbox.add_child(spacer)

func _create_enhanced_activity_container() -> PanelContainer:
	var panel = PanelContainer.new()
	
	# Enhanced card-like design
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.13, 0.16, 0.24, 0.85)
	bg_style.corner_radius_top_left = 12
	bg_style.corner_radius_top_right = 12
	bg_style.corner_radius_bottom_left = 12
	bg_style.corner_radius_bottom_right = 12
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.25, 0.35, 0.5, 0.3)
	bg_style.content_margin_left = 16
	bg_style.content_margin_right = 16
	bg_style.content_margin_top = 12
	bg_style.content_margin_bottom = 12
	bg_style.shadow_color = Color(0.05, 0.05, 0.1, 0.2)
	bg_style.shadow_size = 4
	bg_style.shadow_offset = Vector2(0, 2)
	
	panel.add_theme_stylebox_override("panel", bg_style)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 8)
	inner_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(inner_vbox)
	
	return panel

func _create_enhanced_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.custom_minimum_size = Vector2(280, 42)
	
	# Enhanced modern button styling
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.18, 0.42, 0.82, 0.9)
	normal_style.corner_radius_top_left = 20
	normal_style.corner_radius_top_right = 20
	normal_style.corner_radius_bottom_left = 20
	normal_style.corner_radius_bottom_right = 20
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.25, 0.55, 0.95, 0.7)
	normal_style.shadow_color = Color(0.1, 0.3, 0.6, 0.3)
	normal_style.shadow_size = 6
	normal_style.shadow_offset = Vector2(0, 3)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.22, 0.48, 0.88, 1.0)
	hover_style.corner_radius_top_left = 20
	hover_style.corner_radius_top_right = 20
	hover_style.corner_radius_bottom_left = 20
	hover_style.corner_radius_bottom_right = 20
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(0.35, 0.65, 1.0, 0.9)
	hover_style.shadow_color = Color(0.15, 0.35, 0.7, 0.4)
	hover_style.shadow_size = 8
	hover_style.shadow_offset = Vector2(0, 4)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.14, 0.35, 0.75, 1.0)
	pressed_style.corner_radius_top_left = 20
	pressed_style.corner_radius_top_right = 20
	pressed_style.corner_radius_bottom_left = 20
	pressed_style.corner_radius_bottom_right = 20
	pressed_style.border_width_left = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_color = Color(0.2, 0.5, 0.9, 1.0)
	pressed_style.shadow_color = Color(0.05, 0.25, 0.5, 0.2)
	pressed_style.shadow_size = 3
	pressed_style.shadow_offset = Vector2(0, 1)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.95, 1.0))
	button.add_theme_font_size_override("font_size", 15)
	if emoji_font:
		button.add_theme_font_override("font", emoji_font)
	
	# Simplified hover animations
	button.mouse_entered.connect(func():
		if button in active_button_tweens:
			var old_tween = active_button_tweens[button]
			if old_tween and old_tween.is_valid():
				old_tween.kill()
		var tween = create_tween()
		active_button_tweens[button] = tween
		tween.tween_property(button, "scale", Vector2(1.02, 1.02), 0.1)
	)
	
	button.mouse_exited.connect(func():
		if button in active_button_tweens:
			var old_tween = active_button_tweens[button]
			if old_tween and old_tween.is_valid():
				old_tween.kill()
		var tween = create_tween()
		active_button_tweens[button] = tween
		tween.tween_property(button, "scale", Vector2.ONE, 0.1)
		tween.tween_callback(func(): active_button_tweens.erase(button))
	)
	
	return button

func _create_styled_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
	if emoji_font:
		label.add_theme_font_override("font", emoji_font)
	return label

func _create_enhanced_requirements_label() -> RichTextLabel:
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", 12)
	if emoji_font:
		label.add_theme_font_override("normal_font", emoji_font)
	
	# Enhanced modern requirements styling
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.25, 0.15, 0.15, 0.4)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.8, 0.35, 0.35, 0.6)
	bg_style.content_margin_left = 12
	bg_style.content_margin_right = 12
	bg_style.content_margin_top = 8
	bg_style.content_margin_bottom = 8
	bg_style.shadow_color = Color(0.8, 0.2, 0.2, 0.2)
	bg_style.shadow_size = 4
	bg_style.shadow_offset = Vector2(0, 0)
	
	label.add_theme_stylebox_override("normal", bg_style)
	label.add_theme_color_override("default_color", Color(1.0, 0.6, 0.6))
	
	return label

func _show_requirements_tooltip(activity_data: Dictionary):
	var button = _activity_button_map.get(activity_data)
	if not is_instance_valid(button) or not button.disabled:
		return
	
	# Get the container and requirements label
	var container = button.get_parent().get_parent() if is_instance_valid(button) and is_instance_valid(button.get_parent()) else null
	var requirements_label = container.get_meta("requirements_label") if container and container.has_meta("requirements_label") else null
	
	if not is_instance_valid(requirements_label):
		return
	
	var requirements_text = _get_requirements_text(activity_data)
	if requirements_text:
		requirements_label.text = requirements_text
		requirements_label.show()

# Helper function to strip BBCode tags from text
func _strip_bbcode(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[/?[^\\]]*\\]")
	return regex.sub(text, "", true)

func _hide_requirements_tooltip():
	# Hide all visible requirement labels
	for activity_data in _activity_button_map.keys():
		var button = _activity_button_map[activity_data]
		if is_instance_valid(button):
			var container = button.get_parent().get_parent() if is_instance_valid(button.get_parent()) else null
			var requirements_label = container.get_meta("requirements_label") if container and container.has_meta("requirements_label") else null
			if is_instance_valid(requirements_label):
				requirements_label.hide()

func _get_requirements_text(activity_data: Dictionary) -> String:
	if not PlayerData:
		return ""
	
	var is_job = activity_data.get("is_job", false)
	if not is_job:
		return ""
	
	var stat_reqs = activity_data.get("stat_requirements", {})
	var job_reqs = activity_data.get("job_requirements", {})
	var req_parts = []

	for stat_name in stat_reqs.keys():
		var required_level = stat_reqs[stat_name]
		var player_level = PlayerData.get_stat(stat_name)
		var met_stat = (player_level >= required_level)
		if met_stat:
			req_parts.append("[color=#00FF00]✓ %s: %.1f/%.1f[/color]" % [stat_name.capitalize(), player_level, required_level])
		else:
			req_parts.append("[color=#FF4444]✗ %s: %.1f/%.1f[/color]" % [stat_name.capitalize(), player_level, required_level])

	for job_id in job_reqs.keys():
		var required_hours = job_reqs[job_id]
		var player_hours = PlayerData.get_job_hours_worked(job_id)
		var met_job = (player_hours >= required_hours)
		var required_job_display_name = _get_job_display_name(job_id)
		if met_job:
			req_parts.append("[color=#00FF00]✓ Experience in '%s': %.1fh/%.1fh[/color]" % [required_job_display_name, player_hours, required_hours])
		else:
			req_parts.append("[color=#FF4444]✗ Experience in '%s': %.1fh/%.1fh[/color]" % [required_job_display_name, player_hours, required_hours])
	
	var money_req = activity_data.get("money_requirement", 0.0)
	if money_req > 0:
		var player_money = PlayerData.money
		var met_money = (player_money >= money_req)
		if met_money:
			req_parts.append("[color=#00FF00]✓ Money: $%.2f/$%.2f[/color]" % [player_money, money_req])
		else:
			req_parts.append("[color=#FF4444]✗ Money: $%.2f/$%.2f[/color]" % [player_money, money_req])

	if not req_parts.is_empty():
		return "[b]Requirements:[/b]\n" + "\n".join(req_parts)
	return ""

func _on_activity_button_pressed(activity_data: Dictionary):
	if not PlayerData:
		printerr("ActivitiesPanel: PlayerData singleton not found!")
		return
	
	if PlayerData.start_activity(activity_data):
		_update_all_button_states()

func _on_player_activity_started(_activity_data: Dictionary):
	_update_all_button_states()

func _on_player_activity_progress(_activity_data: Dictionary):
	_update_all_button_states()

func _on_player_activity_stopped(_activity_data: Dictionary, was_stamina_exhausted: bool):
	_update_all_button_states()
	if was_stamina_exhausted and UIManager:
		UIManager.show_notification("Stamina exhausted! Activity stopped.") 

func _update_all_button_states():
	if _activity_button_map.is_empty():
		return
	for activity_data in _activity_button_map.keys():
		var button = _activity_button_map[activity_data]
		var container = button.get_parent().get_parent() if is_instance_valid(button) and is_instance_valid(button.get_parent()) else null
		var requirements_label = container.get_meta("requirements_label") if container and container.has_meta("requirements_label") else null
		if is_instance_valid(button) and is_instance_valid(requirements_label):
			_update_button_visual_state(button, activity_data, requirements_label)
		else:
			printerr("ActivitiesPanel: Invalid button or requirements_label for activity: ", activity_data.get("name", "Unknown"))

func _update_button_visual_state(button: Button, activity_data: Dictionary, requirements_label: RichTextLabel):
	if not PlayerData:
		printerr("ActivitiesPanel: PlayerData not available.")
		return

	var is_job = activity_data.get("is_job", false)
	var is_accessible = true

	var is_active = PlayerData and PlayerData.is_activity_active and PlayerData.get_current_activity_name() == activity_data.get("name")
	
	# Disconnect old signals
	if button.is_connected("pressed", PlayerData.stop_activity):
		button.pressed.disconnect(PlayerData.stop_activity)
	if button.is_connected("pressed", _on_activity_button_pressed.bind(activity_data)):
		button.pressed.disconnect(_on_activity_button_pressed.bind(activity_data))
	if button.is_connected("mouse_entered", _show_requirements_tooltip.bind(activity_data)):
		button.mouse_entered.disconnect(_show_requirements_tooltip.bind(activity_data))
	if button.is_connected("mouse_exited", _hide_requirements_tooltip):
		button.mouse_exited.disconnect(_hide_requirements_tooltip)
	
	# Kill existing tween for this button
	if button in active_button_tweens:
		var tween = active_button_tweens[button]
		if tween and tween.is_valid():
			tween.kill()
		active_button_tweens.erase(button)
	
	if is_active:
		button.text = "🛑 Stop " + activity_data.get("name", "Unnamed Activity")
		button.pressed.connect(PlayerData.stop_activity)
		
		# Enhanced active button styling (no pulsing)
		var active_style = StyleBoxFlat.new()
		active_style.bg_color = Color(0.85, 0.25, 0.15, 0.95)
		active_style.corner_radius_top_left = 20
		active_style.corner_radius_top_right = 20
		active_style.corner_radius_bottom_left = 20
		active_style.corner_radius_bottom_right = 20
		active_style.border_width_left = 3
		active_style.border_width_top = 3
		active_style.border_width_right = 3
		active_style.border_width_bottom = 3
		active_style.border_color = Color(1.0, 0.4, 0.3, 0.9)
		active_style.shadow_color = Color(0.8, 0.2, 0.1, 0.4)
		active_style.shadow_size = 8
		active_style.shadow_offset = Vector2(0, 4)
		button.add_theme_stylebox_override("normal", active_style)
	else:
		button.text = "▶ " + activity_data.get("name", "Unnamed Activity")
		button.pressed.connect(_on_activity_button_pressed.bind(activity_data))

	if is_job:
		var stat_reqs = activity_data.get("stat_requirements", {})
		var job_reqs = activity_data.get("job_requirements", {})
		var money_req = activity_data.get("money_requirement", 0.0)

		for stat_name in stat_reqs.keys():
			var required_level = stat_reqs[stat_name]
			var player_level = PlayerData.get_stat(stat_name)
			if player_level < required_level:
				is_accessible = false

		for job_id in job_reqs.keys():
			var required_hours = job_reqs[job_id]
			var player_hours = PlayerData.get_job_hours_worked(job_id)
			if player_hours < required_hours:
				is_accessible = false
		
		if money_req > 0:
			var player_money = PlayerData.money
			if player_money < money_req:
				is_accessible = false

	if is_accessible and not is_active:
		button.disabled = false
		button.modulate = Color.WHITE
		button.tooltip_text = ""  # Clear tooltip for accessible jobs
		requirements_label.hide()
		requirements_label.set("text", "")
		
		# Restore normal button styling
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.18, 0.42, 0.82, 0.9)
		normal_style.corner_radius_top_left = 20
		normal_style.corner_radius_top_right = 20
		normal_style.corner_radius_bottom_left = 20
		normal_style.corner_radius_bottom_right = 20
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color(0.25, 0.55, 0.95, 0.7)
		normal_style.shadow_color = Color(0.1, 0.3, 0.6, 0.3)
		normal_style.shadow_size = 6
		normal_style.shadow_offset = Vector2(0, 3)
		button.add_theme_stylebox_override("normal", normal_style)
		
	elif not is_accessible:
		button.disabled = true
		button.modulate = Color(0.65, 0.65, 0.7, 0.8)
		# Show requirements in tooltip on hover - Fixed connection
		button.mouse_entered.connect(_show_requirements_tooltip.bind(activity_data))
		button.mouse_exited.connect(_hide_requirements_tooltip)
		requirements_label.hide()
		requirements_label.set("text", "")
		
		# Enhanced disabled button styling
		var disabled_style = StyleBoxFlat.new()
		disabled_style.bg_color = Color(0.25, 0.25, 0.3, 0.6)
		disabled_style.corner_radius_top_left = 20
		disabled_style.corner_radius_top_right = 20
		disabled_style.corner_radius_bottom_left = 20
		disabled_style.corner_radius_bottom_right = 20
		disabled_style.border_width_left = 2
		disabled_style.border_width_top = 2
		disabled_style.border_width_right = 2
		disabled_style.border_width_bottom = 2
		disabled_style.border_color = Color(0.4, 0.4, 0.45, 0.5)
		disabled_style.shadow_color = Color(0.1, 0.1, 0.15, 0.2)
		disabled_style.shadow_size = 3
		disabled_style.shadow_offset = Vector2(0, 1)
		button.add_theme_stylebox_override("disabled", disabled_style)

func _get_job_display_name(job_id: String) -> String:
	if not LocationManager:
		printerr("ActivitiesPanel: LocationManager not available for job display name")
		return job_id
	
	for loc_name in LocationManager.location_data.keys():
		var activities_in_loc = LocationManager.location_data[loc_name].get("activities", [])
		for activity in activities_in_loc:
			if activity.get("job_id") == job_id:
				return activity.get("name", job_id)
	
	return job_id
	
func _style_special_tasks_button(button: Button):
	button.focus_mode = Control.FOCUS_NONE
	
	# Special golden styling for the special tasks button
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.8, 0.6, 0.2, 0.9)
	normal_style.corner_radius_top_left = 18
	normal_style.corner_radius_top_right = 18
	normal_style.corner_radius_bottom_left = 18
	normal_style.corner_radius_bottom_right = 18
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(1.0, 0.8, 0.3, 0.8)
	normal_style.shadow_color = Color(0.8, 0.6, 0.0, 0.4)
	normal_style.shadow_size = 6
	normal_style.shadow_offset = Vector2(0, 3)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.9, 0.7, 0.3, 1.0)
	hover_style.corner_radius_top_left = 18
	hover_style.corner_radius_top_right = 18
	hover_style.corner_radius_bottom_left = 18
	hover_style.corner_radius_bottom_right = 18
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(1.0, 0.9, 0.5, 1.0)
	hover_style.shadow_color = Color(0.9, 0.7, 0.1, 0.5)
	hover_style.shadow_size = 8
	hover_style.shadow_offset = Vector2(0, 4)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	button.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.05))
	button.add_theme_font_size_override("font_size", 16)
	if emoji_font:
		button.add_theme_font_override("font", emoji_font)
	
	# Add subtle hover animation
	button.mouse_entered.connect(func():
		if button in active_button_tweens:
			var old_tween = active_button_tweens[button]
			if old_tween and old_tween.is_valid():
				old_tween.kill()
		var tween = create_tween()
		active_button_tweens[button] = tween
		tween.tween_property(button, "scale", Vector2(1.03, 1.03), 0.1)
	)
	
	button.mouse_exited.connect(func():
		if button in active_button_tweens:
			var old_tween = active_button_tweens[button]
			if old_tween and old_tween.is_valid():
				old_tween.kill()
		var tween = create_tween()
		active_button_tweens[button] = tween
		tween.tween_property(button, "scale", Vector2.ONE, 0.1)
		tween.tween_callback(func(): active_button_tweens.erase(button))
	)
	
# Special Tasks button handlers
func _on_special_tasks_button_pressed():
	var current_location = location_name_label.text if is_instance_valid(location_name_label) else ""
	if current_location.is_empty():
		printerr("ActivitiesPanel: No current location name available")
		return
	
	if not special_tasks_panel or not is_instance_valid(special_tasks_panel):
		var special_tasks_scene = load(SPECIAL_TASKS_SCENE_PATH)
		if special_tasks_scene:
			special_tasks_panel = special_tasks_scene.instantiate()
			add_child(special_tasks_panel)
			special_tasks_panel.panel_closed.connect(_on_special_tasks_panel_closed)
		else:
			printerr("ActivitiesPanel: Failed to load special tasks scene from ", SPECIAL_TASKS_SCENE_PATH)
			return
	
	special_tasks_panel.show_panel_animated(current_location)

func _on_special_tasks_panel_closed():
	# Optional: Additional cleanup if needed (already hidden by special tasks panel)
	pass
