# File: res://ui/character_list_item.gd
extends Button
class_name CharacterListItem

@onready var character_name_label: Label = %CharacterNameLabel
@onready var unlock_info_label: Label = %UnlockInfoLabel
@onready var status_icon: Label = %StatusIcon
@onready var progress_bars_container: VBoxContainer = %ProgressBarsContainer

var character_data: Dictionary
var hover_tween: Tween
var unlock_pulse_tween: Tween
var progress_bars: Array[Control] = []

# For hover state management
var original_scale: Vector2 = Vector2.ONE
var is_hovering: bool = false

signal character_selected(character_data: Dictionary)

# Progress bar scene
const PROGRESS_BAR_HEIGHT = 16

func _ready():
	pressed.connect(_on_button_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Store the original scale
	original_scale = scale

func _on_mouse_entered():
	if not disabled:
		is_hovering = true
		_animate_hover_enter()

func _on_mouse_exited():
	is_hovering = false
	_animate_hover_exit()

func _animate_hover_enter():
	"""Animates hover enter effect"""
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", original_scale * 1.02, 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _animate_hover_exit():
	"""Animates hover exit effect"""
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", original_scale, 0.2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _animate_unlock_pulse():
	if unlock_pulse_tween and unlock_pulse_tween.is_valid():
		unlock_pulse_tween.kill()
	
	unlock_pulse_tween = create_tween()
	unlock_pulse_tween.set_loops(3)
	unlock_pulse_tween.tween_property(unlock_info_label, "modulate:a", 0.3, 0.3)
	unlock_pulse_tween.tween_property(unlock_info_label, "modulate:a", 0.9, 0.3)

func _clear_progress_bars():
	"""Remove all existing progress bars"""
	for bar in progress_bars:
		if is_instance_valid(bar):
			bar.queue_free()
	progress_bars.clear()

func _create_progress_bar(stat_name: String, current_value: int, required_value: int) -> Control:
	"""Creates a visual progress bar for a stat requirement"""
	var container = HBoxContainer.new()
	container.custom_minimum_size.y = PROGRESS_BAR_HEIGHT
	
	# Stat name label
	var name_label = Label.new()
	name_label.text = stat_name.capitalize() + ":"
	name_label.custom_minimum_size.x = 60
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	container.add_child(name_label)
	
	# Progress bar background
	var bg_panel = Panel.new()
	bg_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg_panel.custom_minimum_size.y = 12
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.4, 0.4, 0.4, 0.6)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	container.add_child(bg_panel)
	
	# Progress bar fill
	var fill_panel = Panel.new()
	fill_panel.position = Vector2(2, 2)
	fill_panel.size.y = 8
	
	var progress_ratio = min(float(current_value) / float(required_value), 1.0)
	fill_panel.size.x = max(0, (bg_panel.custom_minimum_size.x - 4) * progress_ratio)
	
	var fill_style = StyleBoxFlat.new()
	if current_value >= required_value:
		fill_style.bg_color = Color(0.4, 0.8, 0.4, 1)  # Green when complete
	else:
		fill_style.bg_color = Color(0.8, 0.6, 0.2, 1)  # Orange when incomplete
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	fill_panel.add_theme_stylebox_override("panel", fill_style)
	bg_panel.add_child(fill_panel)
	
	# Values label
	var values_label = Label.new()
	values_label.text = "%d/%d" % [current_value, required_value]
	values_label.custom_minimum_size.x = 40
	values_label.add_theme_font_size_override("font_size", 9)
	values_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if current_value >= required_value:
		values_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4, 1))
	else:
		values_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1))
	container.add_child(values_label)
	
	return container

func set_character_data(data: Dictionary, revealed: bool, unlock_text: String = ""):
	character_data = data
	var character_name = data.get("name", "Unknown Character")
	
	# Clear existing progress bars
	_clear_progress_bars()
	
	if revealed:
		character_name_label.text = character_name
		unlock_info_label.text = ""
		unlock_info_label.hide()
		progress_bars_container.hide()
		status_icon.text = "✓"
		status_icon.modulate = Color.GREEN
		self.disabled = false
		self.modulate = Color(1,1,1,1)
		
		# Set a smaller minimum size for revealed characters
		custom_minimum_size.y = 60
		
		# Add subtle entrance animation for newly unlocked characters
		if unlock_text != "":  # This was previously locked
			_animate_character_unlock()
			
	else:
		character_name_label.text = "???"
		unlock_info_label.text = "Requirements:"
		unlock_info_label.show()
		progress_bars_container.show()
		status_icon.text = "🔒"
		status_icon.modulate = Color(1, 0.6, 0.4, 0.8)
		self.disabled = true
		self.modulate = Color(0.6, 0.6, 0.6, 0.8)
		
		# Set a dynamic minimum size based on requirements
		var stats_required = data.get("stats_required", {})
		var num_requirements = stats_required.size() if stats_required is Dictionary else 0
		# Base height + space for each requirement
		custom_minimum_size.y = 80 + (num_requirements * 20)
		
		# Create progress bars for each stat requirement
		if stats_required is Dictionary and not stats_required.is_empty():
			for stat_name in stats_required.keys():
				var required_level = stats_required[stat_name]
				var current_level = 0
				
				# Get player's current stat level (you'll need to access PlayerData)
				if PlayerData and PlayerData.has_method("get_stat"):
					var player_stat = PlayerData.get_stat(stat_name)
					if player_stat != null:
						current_level = int(player_stat)
				
				var progress_bar = _create_progress_bar(stat_name, current_level, int(required_level))
				progress_bars_container.add_child(progress_bar)
				progress_bars.append(progress_bar)
		
		# Pulse the requirement text to draw attention
		_animate_unlock_pulse()

func _animate_character_unlock():
	"""Plays a special animation when a character becomes available"""
	var unlock_tween = create_tween()
	unlock_tween.set_parallel(true)
	
	# Scale pulse
	scale = original_scale * 1.1
	unlock_tween.tween_property(self, "scale", original_scale, 0.4)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Glow effect
	modulate = Color(1.3, 1.3, 1.0, 1.0)
	unlock_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4)

func _animate_progress_bar_update(bar: Control):
	"""Animates a progress bar when it updates"""
	if not is_instance_valid(bar):
		return
		
	var anim_tween = create_tween()
	var original_bar_scale = bar.scale
	bar.scale = original_bar_scale * 1.1
	anim_tween.tween_property(bar, "scale", original_bar_scale, 0.3)\
		.set_trans(Tween.TRANS_ELASTIC)

func update_progress_bars():
	"""Updates all progress bars with current player stats"""
	if character_data.is_empty() or progress_bars.is_empty():
		return
		
	var stats_required = character_data.get("stats_required", {})
	if not stats_required is Dictionary:
		return
	
	for i in range(progress_bars.size()):
		var bar = progress_bars[i]
		if not is_instance_valid(bar):
			continue
			
		# Find the corresponding stat requirement
		var stat_names = stats_required.keys()
		if i >= stat_names.size():
			continue
			
		var stat_name = stat_names[i]
		var required_level = stats_required[stat_name]
		var current_level = 0
		
		if PlayerData and PlayerData.has_method("get_stat"):
			var player_stat = PlayerData.get_stat(stat_name)
			if player_stat != null:
				current_level = int(player_stat)
		
		# Update the progress bar (recreate it for simplicity)
		var parent_container = bar.get_parent()
		bar.queue_free()
		progress_bars[i] = _create_progress_bar(stat_name, current_level, int(required_level))
		parent_container.add_child(progress_bars[i])
		_animate_progress_bar_update(progress_bars[i])

func _on_button_pressed():
	# Add a press animation that respects the original scale
	var press_tween = create_tween()
	press_tween.set_parallel(true)
	press_tween.tween_property(self, "scale", original_scale * 0.95, 0.1)
	press_tween.tween_property(self, "scale", original_scale, 0.1).set_delay(0.1)
	
	character_selected.emit(character_data)
