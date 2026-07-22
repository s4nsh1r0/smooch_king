extends PanelContainer

@onready var character_list_container: VBoxContainer = %ListContent
@onready var title_label: Label = %TitleLabel
@onready var animated_glow: ColorRect = %AnimatedGlow
@onready var floating_orbs: Control = %FloatingOrbs

const CHARACTER_LIST_ITEM_SCENE = preload("res://ui/character_list_item.tscn")

# Animation properties
@export var fade_duration: float = 0.1
var current_fade_tween: Tween = null
var glow_tween: Tween = null
var orbs: Array[Control] = []
var orb_tweens: Array[Tween] = []

signal request_character_card_details(character_data: Dictionary)

func _ready():
	# Start fully transparent and invisible
	modulate.a = 0.0
	visible = false
	mouse_filter = MOUSE_FILTER_STOP

	if not is_instance_valid(character_list_container):
		printerr("SocialHubPanel ERROR: ListContent not found!")
	if not is_instance_valid(title_label):
		printerr("SocialHubPanel ERROR: TitleLabel not found!")

	# Test scene instantiation
	if not CHARACTER_LIST_ITEM_SCENE.can_instantiate():
		printerr("SocialHubPanel ERROR: Cannot instantiate character_list_item.tscn")

	# Setup visual effects
	_setup_visual_effects()

	# Connect to LocationManager's signal for location changes
	if LocationManager and not LocationManager.is_connected("location_data_updated", _on_player_location_changed):
		LocationManager.connect("location_data_updated", _on_player_location_changed)

	# Connect to PlayerData's stat changes for live updates
	if PlayerData and PlayerData.has_signal("player_stat_changed"):
		if not PlayerData.is_connected("player_stat_changed", _on_player_stat_changed):
			PlayerData.connect("player_stat_changed", _on_player_stat_changed)

	# Connect to tree_exiting to cleanup
	tree_exiting.connect(_cleanup_on_exit)

func _setup_visual_effects():
	"""Setup simple animated visual effects instead of particles"""
	if animated_glow:
		animated_glow.modulate.a = 0.0
		_start_glow_animation()
	
	if floating_orbs:
		_create_floating_orbs()

func _start_glow_animation():
	"""Creates a subtle pulsing glow effect"""
	if not animated_glow or not is_instance_valid(animated_glow):
		return
		
	if glow_tween and glow_tween.is_valid():
		glow_tween.kill()
	
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(animated_glow, "modulate:a", 0.15, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_property(animated_glow, "modulate:a", 0.05, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Stop the loop when the node is about to be freed
	glow_tween.finished.connect(func(): glow_tween = null)

func _create_floating_orbs():
	"""Creates simple floating orb effects"""
	if not floating_orbs or not is_instance_valid(floating_orbs):
		return
	
	# Clear existing orbs and their tweens
	_clear_orbs()
	
	# Create 5 simple floating orbs
	for i in range(5):
		var orb = ColorRect.new()
		orb.size = Vector2(6, 6)
		orb.color = Color(0.4, 0.7, 1.0, 0.6)
		orb.position = Vector2(
			randf_range(20, size.x - 40),
			randf_range(20, size.y - 40)
		)
		
		# Make orbs circular by setting a custom style
		var style = StyleBoxFlat.new()
		style.bg_color = orb.color
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		orb.add_theme_stylebox_override("panel", style)
		
		floating_orbs.add_child(orb)
		orbs.append(orb)
		
		# Animate each orb with a gentle float
		_animate_orb(orb, i)

func _animate_orb(orb: Control, index: int):
	"""Animates a single orb with gentle floating motion"""
	if not is_instance_valid(orb):
		return
	
	var orb_tween = create_tween()
	orb_tween.set_loops()
	orb_tweens.append(orb_tween)
	
	var start_pos = orb.position
	var float_distance = 20 + (index * 5)  # Vary float distance
	var duration = 3.0 + (index * 0.5)    # Vary speed
	
	orb_tween.tween_property(orb, "position:y", start_pos.y - float_distance, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	orb_tween.tween_property(orb, "position:y", start_pos.y + float_distance, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Clean up tween reference when it's done
	orb_tween.finished.connect(func():
		if orb_tween in orb_tweens:
			orb_tweens.erase(orb_tween)
	)

func toggle_visibility():
	"""Toggles the visibility of the social hub panel with a fade animation."""
	if visible:
		hide_panel_animated()
	else:
		show_panel_animated()

func show_panel_animated():
	"""Animates the social hub panel to fade in and become visible."""
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()

	modulate.a = 0.0
	call_deferred("update_character_list")
	await get_tree().process_frame
	visible = true
	
	# Start visual effects
	if animated_glow:
		animated_glow.modulate.a = 0.0
		var glow_fade_tween = create_tween()
		glow_fade_tween.tween_property(animated_glow, "modulate:a", 0.1, 0.5)
	
	_create_floating_orbs()
	
	current_fade_tween = create_tween()
	current_fade_tween.tween_property(self, "modulate:a", 1.0, 0.3)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	current_fade_tween.tween_callback(func():
		current_fade_tween = null
	)

func hide_panel_animated():
	"""Animates the social hub panel to fade out and become invisible."""
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()

	# Stop the glow animation
	if glow_tween and glow_tween.is_valid():
		glow_tween.kill()
		glow_tween = null

	# Fade out visual effects
	if animated_glow and is_instance_valid(animated_glow):
		var glow_fade_tween = create_tween()
		glow_fade_tween.tween_property(animated_glow, "modulate:a", 0.0, 0.2)

	current_fade_tween = create_tween()
	current_fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	current_fade_tween.tween_callback(func():
		visible = false
		current_fade_tween = null
		_clear_orbs()
		call_deferred("_clear_character_list_content")
	)

func _clear_orbs():
	"""Clean up floating orbs and their tweens"""
	# Kill all orb tweens first
	for tween in orb_tweens:
		if is_instance_valid(tween):
			tween.kill()
	orb_tweens.clear()
	
	# Then remove the orb nodes
	for orb in orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	orbs.clear()

func get_fade_tween() -> Tween:
	return current_fade_tween

func update_character_list():
	"""Refreshes the list of characters in the social hub."""
	_clear_character_list_content()

	if not is_instance_valid(PlayerData) or not is_instance_valid(LocationManager):
		title_label.text = "Error: Missing Data"
		return

	var current_location_data = LocationManager.get_current_location_data()
	if not current_location_data or not current_location_data is Dictionary:
		title_label.text = "No Location Data"
		return

	var location_name = current_location_data.get("name", "Unknown Location")
	title_label.text = "People in %s" % location_name
	
	var characters_in_location = LocationManager.get_characters_for_location(location_name)
	if not characters_in_location is Array:
		title_label.text = "Error: Invalid Character Data"
		return

	if characters_in_location.is_empty():
		var no_people_label = Label.new()
		no_people_label.text = "No one here to meet yet."
		no_people_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_people_label.add_theme_font_size_override("font_size", 20)
		no_people_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))
		character_list_container.add_child(no_people_label)
		return

	for character_data in characters_in_location:
		if not character_data is Dictionary:
			continue

		var character_list_item_instance = CHARACTER_LIST_ITEM_SCENE.instantiate()
		if not is_instance_valid(character_list_item_instance):
			continue

		character_list_container.add_child(character_list_item_instance)
		
		# Update character display based on current requirements
		_update_character_item_display(character_list_item_instance, character_data)
		
		if not character_list_item_instance.is_connected("character_selected", _on_character_list_item_selected):
			character_list_item_instance.character_selected.connect(_on_character_list_item_selected)
	
	# After adding all character items, add a spacer to push content to top
	_add_flexible_spacer()

func _add_flexible_spacer():
	"""Adds a flexible spacer that expands to fill unused space"""
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size.y = 20  # Minimum spacing
	character_list_container.add_child(spacer)

func _update_character_item_display(character_item: CharacterListItem, character_data: Dictionary):
	"""Updates a single character item's display based on current stat requirements."""
	var requirements_met = true
	var stats_needed_text = ""
	
	var stats_required = character_data.get("stats_required", {})
	if not stats_required is Dictionary:
		character_item.set_character_data(character_data, true, "")
		return

	for stat_name in stats_required.keys():
		if not stat_name is String or stat_name.is_empty():
			continue
			
		var required_level = stats_required[stat_name]
		if not required_level is float and not required_level is int:
			continue

		var player_stat_level = 0.0
		if PlayerData.has_method("get_stat"):
			player_stat_level = PlayerData.get_stat(stat_name)
			if player_stat_level == null:
				requirements_met = false
				stats_needed_text += "%s: Unknown/%d " % [stat_name.capitalize(), int(required_level)]
				continue
		else:
			requirements_met = false
			stats_needed_text += "%s: Missing/%d " % [stat_name.capitalize(), int(required_level)]
			continue

		if player_stat_level < required_level:
			requirements_met = false
			stats_needed_text += "%s: %d/%d " % [stat_name.capitalize(), int(player_stat_level), int(required_level)]

	character_item.set_character_data(character_data, requirements_met, stats_needed_text.strip_edges())

func _clear_character_list_content():
	"""Clears all dynamically added character list items."""
	for child in character_list_container.get_children():
		child.queue_free()

func _on_player_location_changed(_new_location_data: Dictionary):
	# Update only if visible to avoid unnecessary refreshes
	if visible:
		update_character_list()
		_trigger_location_change_effect()

func _trigger_location_change_effect():
	"""Creates a subtle glow burst when location changes"""
	if not visible or not animated_glow:
		return
	
	var burst_tween = create_tween()
	burst_tween.tween_property(animated_glow, "modulate:a", 0.3, 0.2)
	burst_tween.tween_property(animated_glow, "modulate:a", 0.1, 0.4)

func _on_player_stat_changed(stat_name: String, _new_value: float):
	"""Called when any player stat changes - updates character displays live."""
	if not visible:
		return
		
	# Update progress bars for all character items
	for child in character_list_container.get_children():
		if child is CharacterListItem and child.character_data.has("stats_required"):
			var stats_required = child.character_data.get("stats_required", {})
			if stats_required.has(stat_name):
				# This character has requirements for the changed stat, update displays
				_update_character_item_display(child, child.character_data)
				# Also update progress bars if they exist
				if child.has_method("update_progress_bars"):
					child.update_progress_bars()
				_trigger_stat_change_effect()

func _trigger_stat_change_effect():
	"""Creates a subtle pulse when stats change"""
	if not visible:
		return
		
	# Pulse the panel border slightly
	var pulse_tween = create_tween()
	pulse_tween.set_parallel(true)
	pulse_tween.tween_property(self, "scale", Vector2(1.01, 1.01), 0.1)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func _cleanup_on_exit():
	"""Clean up resources when exiting to prevent crashes"""
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()
	
	if glow_tween and glow_tween.is_valid():
		glow_tween.kill()
		glow_tween = null
	
	# Kill all orb tweens
	for tween in orb_tweens:
		if is_instance_valid(tween):
			tween.kill()
	orb_tweens.clear()
	
	_clear_orbs()

func _on_character_list_item_selected(character_data: Dictionary):
	emit_signal("request_character_card_details", character_data)
