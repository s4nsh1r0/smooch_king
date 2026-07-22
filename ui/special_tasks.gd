extends PanelContainer

@onready var special_tasks_title: Label = %SpecialTasksTitle
@onready var special_tasks_subtitle: Label = %SpecialTasksSubtitle
@onready var special_tasks_scroll: ScrollContainer = %SpecialTasksScroll
@onready var special_tasks_vbox: VBoxContainer = %SpecialTasksVBox
@onready var back_button: Button = %BackButton

# Animation properties
@export var fade_duration: float = 0.15
var current_fade_tween: Tween = null
var active_button_tweens: Dictionary = {}

var _special_task_button_map: Dictionary = {}

# Emoji font for consistent rendering
@export var emoji_font: Font = preload("res://fonts/NotoSans-Regular.ttf")

# Special tasks data structure
var special_tasks_data: Dictionary = {
	"Home": [
		{"name": "Quick Meditation", "description": "A short mindfulness session to center yourself", "duration": 5, "stat_boost": {"wellbeing": 2.0}},
		{"name": "Deep Reflection", "description": "Contemplate your goals and aspirations", "duration": 10, "stat_boost": {"intelligence": 1.5, "wellbeing": 1.0}},
		{"name": "Life Planning", "description": "Create detailed plans for your future", "duration": 20, "stat_boost": {"intelligence": 2.5, "charisma": 1.0}}
	],
	"Gym": [
		{"name": "Intense Cardio", "description": "Push your cardiovascular limits", "duration": 5, "stat_boost": {"fitness": 2.0}},
		{"name": "Strength Challenge", "description": "Test your maximum lifting capacity", "duration": 10, "stat_boost": {"fitness": 2.5, "wellbeing": 0.5}},
		{"name": "Athletic Training", "description": "Complete training regimen like a pro athlete", "duration": 20, "stat_boost": {"fitness": 4.0, "confidence": 1.0}}
	],
	"Library": [
		{"name": "Speed Reading", "description": "Absorb knowledge at lightning speed", "duration": 5, "stat_boost": {"intelligence": 2.0}},
		{"name": "Research Project", "description": "Dive deep into a fascinating topic", "duration": 10, "stat_boost": {"intelligence": 2.5, "creativity": 1.0}},
		{"name": "Academic Study", "description": "Intensive learning session on advanced subjects", "duration": 20, "stat_boost": {"intelligence": 4.0, "confidence": 0.5}}
	],
	"Park": [
		{"name": "Nature Walk", "description": "Connect with the natural world around you", "duration": 5, "stat_boost": {"wellbeing": 2.0}},
		{"name": "Outdoor Sketch", "description": "Capture the beauty of nature through art", "duration": 10, "stat_boost": {"creativity": 2.0, "wellbeing": 1.0}},
		{"name": "Environmental Study", "description": "Observe and document local wildlife", "duration": 20, "stat_boost": {"intelligence": 1.5, "creativity": 2.0, "wellbeing": 1.0}}
	],
	"Coffee Shop": [
		{"name": "People Watching", "description": "Observe social dynamics and human behavior", "duration": 5, "stat_boost": {"charisma": 2.0}},
		{"name": "Creative Writing", "description": "Write stories inspired by the atmosphere", "duration": 10, "stat_boost": {"creativity": 2.5, "intelligence": 0.5}},
		{"name": "Social Networking", "description": "Build meaningful connections with strangers", "duration": 20, "stat_boost": {"charisma": 3.0, "confidence": 1.5}}
	],
	"Job Center": [
		{"name": "Skill Assessment", "description": "Evaluate your professional capabilities", "duration": 5, "stat_boost": {"confidence": 2.0}},
		{"name": "Interview Practice", "description": "Rehearse for job interviews", "duration": 10, "stat_boost": {"charisma": 2.0, "confidence": 1.5}},
		{"name": "Career Planning", "description": "Map out your professional development path", "duration": 20, "stat_boost": {"intelligence": 2.0, "charisma": 1.5, "confidence": 1.0}}
	]
}

signal panel_closed

func _ready() -> void:
	# Initially hidden
	modulate.a = 0.0
	visible = false
	
	# Apply styling
	_setup_styling()
	
	# Setup scroll container
	if is_instance_valid(special_tasks_scroll):
		special_tasks_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		special_tasks_scroll.size_flags_stretch_ratio = 1.0
	
	if is_instance_valid(special_tasks_vbox):
		special_tasks_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		special_tasks_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		special_tasks_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Connect back button
	if is_instance_valid(back_button):
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect to player data signals for updates
	if PlayerData:
		PlayerData.player_activity_started.connect(_on_player_activity_changed)
		PlayerData.player_activity_stopped.connect(_on_player_activity_stopped)

func _setup_styling():
	# Style the panel with golden theme
	var special_panel_style = StyleBoxFlat.new()
	special_panel_style.bg_color = Color(0.08, 0.10, 0.18, 0.95)
	special_panel_style.border_width_left = 3
	special_panel_style.border_width_top = 3
	special_panel_style.border_width_right = 3
	special_panel_style.border_width_bottom = 3
	special_panel_style.border_color = Color(0.8, 0.6, 0.2, 0.7)
	special_panel_style.corner_radius_top_left = 20
	special_panel_style.corner_radius_top_right = 20
	special_panel_style.corner_radius_bottom_right = 20
	special_panel_style.corner_radius_bottom_left = 20
	special_panel_style.shadow_color = Color(0.8, 0.6, 0.0, 0.3)
	special_panel_style.shadow_size = 15
	special_panel_style.shadow_offset = Vector2(0, 8)
	special_panel_style.content_margin_left = 25
	special_panel_style.content_margin_right = 25
	special_panel_style.content_margin_top = 20
	special_panel_style.content_margin_bottom = 25
	add_theme_stylebox_override("panel", special_panel_style)
	
	# Style the title and subtitle
	if is_instance_valid(special_tasks_title):
		special_tasks_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		special_tasks_title.add_theme_color_override("font_shadow_color", Color(0.8, 0.6, 0.0, 0.8))
		special_tasks_title.add_theme_constant_override("shadow_offset_x", 2)
		special_tasks_title.add_theme_constant_override("shadow_offset_y", 2)
		if emoji_font:
			special_tasks_title.add_theme_font_override("font", emoji_font)
	
	if is_instance_valid(special_tasks_subtitle):
		special_tasks_subtitle.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		if emoji_font:
			special_tasks_subtitle.add_theme_font_override("font", emoji_font)
	
	# Style the back button
	if is_instance_valid(back_button):
		_style_back_button(back_button)

func _style_back_button(button: Button):
	button.focus_mode = Control.FOCUS_NONE
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.5, 0.5, 0.6, 0.8)
	normal_style.corner_radius_top_left = 15
	normal_style.corner_radius_top_right = 15
	normal_style.corner_radius_bottom_left = 15
	normal_style.corner_radius_bottom_right = 15
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.7, 0.7, 0.8, 0.6)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.6, 0.6, 0.7, 1.0)
	hover_style.corner_radius_top_left = 15
	hover_style.corner_radius_top_right = 15
	hover_style.corner_radius_bottom_left = 15
	hover_style.corner_radius_bottom_right = 15
	hover_style.border_width_left = 1
	hover_style.border_width_top = 1
	hover_style.border_width_right = 1
	hover_style.border_width_bottom = 1
	hover_style.border_color = Color(0.8, 0.8, 0.9, 0.8)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 14)
	if emoji_font:
		button.add_theme_font_override("font", emoji_font)

func show_panel_animated(location_name: String):
	_kill_all_tweens()
	
	# Update the title based on location
	if is_instance_valid(special_tasks_title):
		special_tasks_title.text = "⭐ " + location_name + " Special Tasks"
	
	modulate.a = 0.0
	visible = true
	
	# Animate first, then populate content
	current_fade_tween = create_tween().set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	current_fade_tween.tween_property(self, "scale", Vector2.ONE, fade_duration).from(Vector2(0.98, 0.98))
	current_fade_tween.tween_callback(func():
		_populate_special_tasks(location_name)
		current_fade_tween = null
	)

func hide_panel_animated():
	_kill_all_tweens()

	current_fade_tween = create_tween().set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	current_fade_tween.tween_property(self, "scale", Vector2(0.98, 0.98), fade_duration)
	current_fade_tween.tween_callback(func():
		visible = false
		current_fade_tween = null
		_clear_special_tasks()
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

func _populate_special_tasks(location_name: String):
	_clear_special_tasks()
	
	var tasks_for_location = special_tasks_data.get(location_name, [])
	
	if tasks_for_location.is_empty():
		var no_tasks_label = _create_styled_label("No special tasks available at this location.")
		no_tasks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		special_tasks_vbox.add_child(no_tasks_label)
		return
	
	for task_data in tasks_for_location:
		var task_container = _create_special_task_container()
		special_tasks_vbox.add_child(task_container)
		
		var task_vbox = task_container.get_child(0)
		
		# Create task button
		var task_button = _create_special_task_button(task_data)
		_special_task_button_map[task_data] = task_button
		task_container.set_meta("task_data", task_data)
		task_vbox.add_child(task_button)
		
		# Create description label
		var desc_label = _create_styled_label(task_data.get("description", "No description."))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 0.9))
		desc_label.add_theme_font_size_override("font_size", 13)
		task_vbox.add_child(desc_label)
		
		# Create duration and rewards info
		var info_label = _create_info_label(task_data)
		task_vbox.add_child(info_label)
		
		_update_task_button_state(task_button, task_data)

func _create_special_task_container() -> PanelContainer:
	var panel = PanelContainer.new()
	
	# Golden card-like design
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.18, 0.15, 0.10, 0.85)
	bg_style.corner_radius_top_left = 12
	bg_style.corner_radius_top_right = 12
	bg_style.corner_radius_bottom_left = 12
	bg_style.corner_radius_bottom_right = 12
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.8, 0.6, 0.2, 0.4)
	bg_style.content_margin_left = 16
	bg_style.content_margin_right = 16
	bg_style.content_margin_top = 12
	bg_style.content_margin_bottom = 12
	bg_style.shadow_color = Color(0.8, 0.6, 0.0, 0.2)
	bg_style.shadow_size = 4
	bg_style.shadow_offset = Vector2(0, 2)
	
	panel.add_theme_stylebox_override("panel", bg_style)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 8)
	inner_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(inner_vbox)
	
	return panel

func _create_special_task_button(task_data: Dictionary) -> Button:
	var button = Button.new()
	button.text = "⭐ " + task_data.get("name", "Unnamed Task")
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.custom_minimum_size = Vector2(300, 45)
	
	# Golden button styling
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.8, 0.6, 0.2, 0.9)
	normal_style.corner_radius_top_left = 20
	normal_style.corner_radius_top_right = 20
	normal_style.corner_radius_bottom_left = 20
	normal_style.corner_radius_bottom_right = 20
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
	hover_style.corner_radius_top_left = 20
	hover_style.corner_radius_top_right = 20
	hover_style.corner_radius_bottom_left = 20
	hover_style.corner_radius_bottom_right = 20
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
	
	# Connect to task start function
	button.pressed.connect(_on_special_task_pressed.bind(task_data))
	
	# Add hover animations
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

func _create_info_label(task_data: Dictionary) -> RichTextLabel:
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", 12)
	if emoji_font:
		label.add_theme_font_override("normal_font", emoji_font)
	
	# Create info text
	var duration = task_data.get("duration", 0)
	var stat_boosts = task_data.get("stat_boost", {})
	var info_parts = []
	
	info_parts.append("[color=#FFD700]⏱ Duration: %d minutes[/color]" % duration)
	
	if not stat_boosts.is_empty():
		var boost_text = "[color=#90EE90]📈 Boosts: "
		var boost_parts = []
		for stat in stat_boosts.keys():
			boost_parts.append("%s +%.1f" % [stat.capitalize(), stat_boosts[stat]])
		boost_text += ", ".join(boost_parts) + "[/color]"
		info_parts.append(boost_text)
	
	label.text = "\n".join(info_parts)
	label.add_theme_color_override("default_color", Color(0.9, 0.85, 0.7))
	
	return label

func _update_task_button_state(button: Button, task_data: Dictionary):
	if not PlayerData:
		return
	
	var is_active = PlayerData.is_activity_active and PlayerData.get_current_activity_name() == task_data.get("name")
	
	if is_active:
		button.text = "🛑 Stop " + task_data.get("name", "Unnamed Task")
		# Change to red stop styling
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
		button.add_theme_stylebox_override("normal", active_style)
	else:
		button.text = "⭐ " + task_data.get("name", "Unnamed Task")

func _on_special_task_pressed(task_data: Dictionary):
	if not PlayerData:
		printerr("SpecialTasksPanel: PlayerData not found!")
		return
	
	if PlayerData.is_activity_active:
		PlayerData.stop_activity()
	else:
		# Convert special task to activity format and start it
		var activity_data = {
			"name": task_data.get("name", "Special Task"),
			"description": task_data.get("description", "A special task"),
			"effects": {},
			"is_special_task": true,
			"duration": task_data.get("duration", 5),
			"stat_boost": task_data.get("stat_boost", {})
		}
		
		if PlayerData.start_activity(activity_data):
			_update_all_task_buttons()

func _update_all_task_buttons():
	for task_data in _special_task_button_map.keys():
		var button = _special_task_button_map[task_data]
		if is_instance_valid(button):
			_update_task_button_state(button, task_data)

func _clear_special_tasks():
	# Disconnect signals and clear button map
	for task_data in _special_task_button_map.keys():
		var button = _special_task_button_map[task_data]
		if is_instance_valid(button):
			if button in active_button_tweens:
				var tween = active_button_tweens[button]
				if tween and tween.is_valid():
					tween.kill()
				active_button_tweens.erase(button)
	
	_special_task_button_map.clear()
	
	# Clear container
	if is_instance_valid(special_tasks_vbox):
		for child in special_tasks_vbox.get_children():
			child.queue_free()

func _on_back_button_pressed():
	hide_panel_animated()
	panel_closed.emit()

func _on_player_activity_changed(_activity_data: Dictionary):
	_update_all_task_buttons()

func _on_player_activity_stopped(_activity_data: Dictionary, _was_stamina_exhausted: bool):
	_update_all_task_buttons()
