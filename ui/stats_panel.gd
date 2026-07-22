extends PanelContainer

# References to the main layout and category containers
@onready var player_name_label: Label = %PlayerNameLabel
@onready var physical_stats_container: VBoxContainer = %PhysicalStats
@onready var mental_stats_container: VBoxContainer = %MentalStats
@onready var social_stats_container: VBoxContainer = %SocialStats

# Dictionary to hold references to stat display components
var stats_display_nodes := {}

# Animation Properties
@export var fade_duration: float = 0.1
@export var glow_duration: float = 1.2  # Slower glow
@export var glow_intensity: float = 3.0  # Much more intense
var current_fade_tween: Tween = null
var glow_tweens := {}

# Track the currently active stat for glow animation
var current_active_stat: String = ""

func _ready():
	# Check critical nodes
	if not is_instance_valid(player_name_label): 
		printerr("StatsPanel: player_name_label not found!")
	if not is_instance_valid(physical_stats_container): 
		printerr("StatsPanel: physical_stats_container not found!")
	if not is_instance_valid(mental_stats_container): 
		printerr("StatsPanel: mental_stats_container not found!")
	if not is_instance_valid(social_stats_container): 
		printerr("StatsPanel: social_stats_container not found!")

	# Apply modern styling
	_setup_modern_styling()

	# Connect to PlayerData signals
	if is_instance_valid(PlayerData):
		var connection_result = PlayerData.player_stat_changed.connect(on_stat_changed)
		if connection_result == OK:
			print("Stats panel: Successfully connected to player_stat_changed signal")
		else:
			printerr("Stats panel: Failed to connect to player_stat_changed signal: ", connection_result)
		
		PlayerData.player_name_changed.connect(on_player_name_changed)
		PlayerData.player_data_loaded.connect(refresh_stats_panel)
	else:
		printerr("StatsPanel: PlayerData autoload not found!")

	# Initial population of stat nodes
	call_deferred("_populate_stat_nodes")
	call_deferred("update_stats_display")
	call_deferred("update_player_name_display")

func _setup_modern_styling():
	# Modern glassmorphism panel background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.3, 0.8, 0.6, 0.4)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", panel_style)
	
	# Style player name label
	if player_name_label:
		player_name_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.95))
		player_name_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.8, 0.6, 0.5))
		player_name_label.add_theme_constant_override("shadow_offset_x", 1)
		player_name_label.add_theme_constant_override("shadow_offset_y", 1)

# NEW: Segmented Arc Stat Display
func create_segmented_arc_stat_display(stat_name: String, parent_container: VBoxContainer, theme_color: Color):
	var stat_container = HBoxContainer.new()
	stat_container.add_theme_constant_override("separation", 10)
	stat_container.custom_minimum_size.y = 50
	parent_container.add_child(stat_container)

	# Segmented arc progress control
	var arc_progress = Control.new()
	arc_progress.custom_minimum_size = Vector2(50, 50)
	arc_progress.set_meta("progress", 0.0)
	arc_progress.set_meta("theme_color", theme_color)
	arc_progress.set_meta("segment_count", 8)
	arc_progress.set_meta("line_width", 4.0)
	arc_progress.draw.connect(_draw_segmented_arc_progress.bind(arc_progress))
	# Add mouse hover support
	arc_progress.mouse_entered.connect(_on_stat_mouse_entered.bind(stat_name))
	arc_progress.mouse_exited.connect(_on_stat_mouse_exited.bind(stat_name))
	stat_container.add_child(arc_progress)

	# Info container
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	stat_container.add_child(info_vbox)

	# Stat name and level label
	var header_label = Label.new()
	header_label.add_theme_font_size_override("font_size", 14)
	header_label.add_theme_color_override("font_color", Color.WHITE)
	header_label.add_theme_color_override("font_shadow_color", theme_color * 0.4)
	header_label.add_theme_constant_override("shadow_offset_x", 1)
	header_label.add_theme_constant_override("shadow_offset_y", 1)
	info_vbox.add_child(header_label)

	# Small progress bar for precise progress
	var mini_bar = ProgressBar.new()
	mini_bar.custom_minimum_size.y = 8
	mini_bar.max_value = 1.0
	mini_bar.show_percentage = false
	_style_mini_progress_bar(mini_bar, theme_color)
	info_vbox.add_child(mini_bar)

	stats_display_nodes[stat_name] = {
		"container": stat_container,
		"arc_progress": arc_progress,
		"header_label": header_label,
		"progress_bar": mini_bar,
		"theme_color": theme_color
	}

func _draw_segmented_arc_progress(control: Control):
	var progress = control.get_meta("progress", 0.0)
	var theme_color = control.get_meta("theme_color", Color.WHITE)
	var segment_count = control.get_meta("segment_count", 8)
	var line_width = control.get_meta("line_width", 4.0)
	
	var center = control.size * 0.5
	var radius = min(control.size.x, control.size.y) * 0.4
	var filled_segments = int(progress * segment_count)
	
	# Draw background segments
	for i in range(segment_count):
		var start_angle = -PI * 0.5 + (i * TAU / segment_count)
		var end_angle = start_angle + (TAU / segment_count) * 0.8  # 80% arc length for gap
		var color = Color(0.2, 0.2, 0.2, 0.6) if i >= filled_segments else theme_color
		control.draw_arc(center, radius, start_angle, end_angle, 16, color, line_width)
	
	# Draw percentage text
	var font = ThemeDB.fallback_font
	var percentage = int(progress * 100)
	var text = str(percentage) + "%"
	var font_size = 12
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_position = Vector2(center.x - text_size.x * 0.5, center.y + text_size.y * 0.25)
	control.draw_string(font, text_position + Vector2(0.5, 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.6))
	control.draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _style_mini_progress_bar(bar: ProgressBar, theme_color: Color):
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.3)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = theme_color * 0.8
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_style)

# Update _populate_stat_nodes to use segmented arc display
func _populate_stat_nodes():
	if not is_instance_valid(PlayerData):
		return

	# Clear existing nodes
	for container in [physical_stats_container, mental_stats_container, social_stats_container]:
		if is_instance_valid(container):
			for child in container.get_children():
				child.queue_free()
	stats_display_nodes.clear()

	# Using segmented arc displays
	for stat_name in PlayerData.get_physical_stats():
		create_segmented_arc_stat_display(stat_name, physical_stats_container, Color(1.0, 0.4, 0.4))
	for stat_name in PlayerData.get_mental_stats():
		create_segmented_arc_stat_display(stat_name, mental_stats_container, Color(0.4, 0.6, 1.0))
	for stat_name in PlayerData.get_social_stats():
		create_segmented_arc_stat_display(stat_name, social_stats_container, Color(0.4, 1.0, 0.6))

# Update stats display to handle segmented arcs
func update_stats_display():
	if not is_instance_valid(PlayerData):
		return
	
	for stat_name in stats_display_nodes.keys():
		var display_data = stats_display_nodes[stat_name]
		var current_value = PlayerData.get_stat(stat_name)
		var current_level = int(floor(current_value))
		var exp_progress = current_value - floor(current_value)
		
		if "header_label" in display_data:
			display_data["header_label"].text = stat_name.capitalize() + " [" + str(current_level) + "]"
		
		if "progress_bar" in display_data:
			var progress_tween = create_tween()
			progress_tween.tween_property(display_data["progress_bar"], "value", exp_progress, 0.2)
		
		if "arc_progress" in display_data:
			var arc_tween = create_tween()
			arc_tween.tween_method(
				func(value): set_segmented_arc_progress(display_data["arc_progress"], value, display_data["theme_color"]),
				display_data["arc_progress"].get_meta("progress", 0.0),
				exp_progress,
				0.2
			)

func set_segmented_arc_progress(control: Control, value: float, color: Color = Color.WHITE):
	control.set_meta("progress", clamp(value, 0.0, 1.0))
	control.set_meta("theme_color", color)
	control.queue_redraw()

# Glow animation system
func set_active_stat(stat_name: String):
	if current_active_stat != "" and current_active_stat in stats_display_nodes:
		stop_glow_animation(current_active_stat)
	
	current_active_stat = stat_name
	if stat_name in stats_display_nodes:
		start_glow_animation(stat_name)

func start_glow_animation(stat_name: String):
	if not stat_name in stats_display_nodes:
		return
		
	var display_data = stats_display_nodes[stat_name]
	var container = display_data.get("container")
	var theme_color = display_data["theme_color"]
	
	if not is_instance_valid(container):
		return
	
	if stat_name in glow_tweens and glow_tweens[stat_name] != null and glow_tweens[stat_name].is_valid():
		glow_tweens[stat_name].kill()
	
	glow_tweens[stat_name] = create_tween()
	glow_tweens[stat_name].set_loops()
	
	var normal_color = Color.WHITE
	var glow_color = Color(
		min(2.0, 1.0 + theme_color.r * 1.5), 
		min(2.0, 1.0 + theme_color.g * 1.5), 
		min(2.0, 1.0 + theme_color.b * 1.5), 
		1.0
	)
	
	glow_tweens[stat_name].tween_property(container, "modulate", glow_color, glow_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tweens[stat_name].tween_property(container, "modulate", normal_color, glow_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func stop_glow_animation(stat_name: String):
	if stat_name in glow_tweens and glow_tweens[stat_name] != null and glow_tweens[stat_name].is_valid():
		glow_tweens[stat_name].kill()
		glow_tweens[stat_name] = null
		
	if stat_name in stats_display_nodes:
		var container = stats_display_nodes[stat_name].get("container")
		if is_instance_valid(container):
			var return_tween = create_tween()
			return_tween.tween_property(container, "modulate", Color.WHITE, 0.3)

# Hover effects
func _on_stat_mouse_entered(stat_name: String):
	if stat_name in stats_display_nodes:
		var display_data = stats_display_nodes[stat_name]
		var arc_progress = display_data["arc_progress"]
		var tween = create_tween()
		tween.tween_property(arc_progress, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_CUBIC)

func _on_stat_mouse_exited(stat_name: String):
	if stat_name in stats_display_nodes:
		var display_data = stats_display_nodes[stat_name]
		var arc_progress = display_data["arc_progress"]
		var tween = create_tween()
		tween.tween_property(arc_progress, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC)

# Keep existing animation methods
func show_panel_animated():
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()

	modulate.a = 0.0
	visible = true
	scale = Vector2(0.95, 0.95)
	current_fade_tween = create_tween()
	current_fade_tween.set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration * 2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	current_fade_tween.tween_property(self, "scale", Vector2.ONE, fade_duration * 2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	current_fade_tween.finished.connect(func():
		current_fade_tween = null
	)

func hide_panel_animated():
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()

	current_fade_tween = create_tween()
	current_fade_tween.set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration * 2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	current_fade_tween.tween_property(self, "scale", Vector2(0.95, 0.95), fade_duration * 2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	current_fade_tween.finished.connect(func():
		visible = false
		current_fade_tween = null
	)

func refresh_stats_panel():
	update_stats_display()
	update_player_name_display()

func on_stat_changed(stat_name: String, _new_value: float):
	update_stats_display()
	set_active_stat(stat_name)

func on_player_name_changed(_new_name: String):
	update_player_name_display()

func update_player_name_display():
	if is_instance_valid(PlayerData) and is_instance_valid(player_name_label):
		player_name_label.text = PlayerData.player_name
