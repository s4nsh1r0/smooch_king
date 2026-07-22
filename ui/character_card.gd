extends PanelContainer

@onready var character_name_label: Label = %CharacterNameLabel
@onready var character_image: TextureRect = %CharacterImage
@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var dialogue_label: Label = %DialogueLabel
@onready var talk_button: Button = %TalkButton
@onready var gift_button: Button = %GiftButton
@onready var date_button: Button = %DateButton
@onready var interaction_buttons: HBoxContainer = %InteractionButtons
@onready var heart_container: HBoxContainer = %HeartContainer
@onready var stage_label: Label = %StageLabel

var character_id: String = ""
var character_data: Dictionary = {}
var current_dialogue_index: int = 0
var dialogue_timer: Timer = null  # Timer for dialogue duration

signal gift_requested(character_id: String, character_data: Dictionary)
signal date_requested(character_id: String, character_data: Dictionary)
signal close_requested

# Relationship stage definitions
var relationship_stages = [
	{"name": "Stranger", "min": 0, "max": 49, "color": Color(0.6, 0.6, 0.6)},
	{"name": "Acquaintance", "min": 50, "max": 149, "color": Color(0.8, 0.8, 0.4)},
	{"name": "Friend", "min": 150, "max": 399, "color": Color(1.0, 1.0, 0.3)},
	{"name": "Good Friend", "min": 400, "max": 699, "color": Color(1.0, 0.6, 0.2)},
	{"name": "Crush", "min": 700, "max": 999, "color": Color(1.0, 0.4, 0.7)},
	{"name": "Dating", "min": 1000, "max": 1299, "color": Color(0.9, 0.2, 0.2)},
	{"name": "Soulmate", "min": 1300, "max": 1500, "color": Color(0.7, 0.3, 0.9)}
]

func _ready() -> void:
	# Validate nodes
	var nodes = {
		"character_name_label": character_name_label,
		"character_image": character_image,
		"dialogue_panel": dialogue_panel,
		"dialogue_label": dialogue_label,
		"talk_button": talk_button,
		"gift_button": gift_button,
		"date_button": date_button,
		"interaction_buttons": interaction_buttons,
		"heart_container": heart_container,
		"stage_label": stage_label
	}
	for node_name in nodes:
		if not nodes[node_name] or not is_instance_valid(nodes[node_name]):
			push_error("CharacterCard: %s is null or invalid!" % node_name)
			return

	# Reparent dialogue_panel to character_image if not already done
	if dialogue_panel.get_parent() != character_image:
		var original_parent = dialogue_panel.get_parent()
		if original_parent:
			original_parent.remove_child(dialogue_panel)
		character_image.add_child(dialogue_panel)

	# Configure dialogue panel with better styling
	_setup_dialogue_panel()
	
	# Configure button styles with modern look
	_setup_button_styles()
	
	# Add close button
	_add_close_button()

	# Connect button signals
	talk_button.pressed.connect(_on_talk_button_pressed)
	gift_button.pressed.connect(_on_gift_button_pressed)
	date_button.pressed.connect(_on_date_button_pressed)

	# Connect to PlayerData signals
	if PlayerData:
		if not PlayerData.is_connected("player_relationship_stage_changed", _on_player_relationship_stage_changed):
			PlayerData.connect("player_relationship_stage_changed", _on_player_relationship_stage_changed)
	else:
		push_error("CharacterCard: PlayerData singleton not found!")
	
	# Create the heart meter
	create_heart_meter()

	# Initialize dialogue timer
	dialogue_timer = Timer.new()
	dialogue_timer.one_shot = true
	dialogue_timer.timeout.connect(hide_dialogue)
	add_child(dialogue_timer)

func _setup_dialogue_panel():
	dialogue_panel.modulate.a = 0.0
	
	# Set "Bottom Wide" preset for dialogue panel
	dialogue_panel.anchor_left = 0.0
	dialogue_panel.anchor_right = 1.0
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialogue_panel.custom_minimum_size.x = character_image.size.x  # Match character_image width
	
	# Create a semi-transparent stylish background for dialogue
	var dialogue_style = StyleBoxFlat.new()
	dialogue_style.bg_color = Color(0.15, 0.15, 0.15, 0.85)
	dialogue_style.set_corner_radius_all(8)
	dialogue_style.border_width_left = 2
	dialogue_style.border_width_top = 2
	dialogue_style.border_width_right = 2
	dialogue_style.border_width_bottom = 2
	dialogue_style.border_color = Color(0.8, 0.8, 0.8, 0.4)
	dialogue_style.content_margin_left = 12
	dialogue_style.content_margin_right = 12
	dialogue_style.content_margin_top = 8
	dialogue_style.content_margin_bottom = 8
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)
	
	# Style the dialogue label for readability, centering, and emoji support
	var emoji_font = load("res://fonts/NotoSans-Regular.ttf")
	dialogue_label.add_theme_font_override("font", emoji_font)
	dialogue_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))  # Neon cyan
	dialogue_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.2, 0.2, 0.8))  # Lighter shadow
	dialogue_label.add_theme_constant_override("shadow_offset_x", 1)
	dialogue_label.add_theme_constant_override("shadow_offset_y", 1)
	dialogue_label.add_theme_constant_override("separation", 0)  # Minimize word spacing
	dialogue_label.add_theme_constant_override("letter_spacing", -2)  # Tighten character spacing
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.custom_minimum_size.x = character_image.size.x * 0.9  # Constrain label width

func _setup_button_styles():
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.3, 0.5, 0.9)
	button_style.set_corner_radius_all(8)
	button_style.border_width_left = 1
	button_style.border_width_top = 1
	button_style.border_width_right = 1
	button_style.border_width_bottom = 1
	button_style.border_color = Color(0.4, 0.5, 0.7, 0.8)
	
	var button_hover_style = button_style.duplicate()
	button_hover_style.bg_color = Color(0.3, 0.4, 0.6, 0.95)
	button_hover_style.border_color = Color(0.6, 0.7, 0.9, 0.9)
	
	var button_pressed_style = button_style.duplicate()
	button_pressed_style.bg_color = Color(0.15, 0.25, 0.4, 0.95)
	
	var button_disabled_style = button_style.duplicate()
	button_disabled_style.bg_color = Color(0.1, 0.1, 0.1, 0.6)
	button_disabled_style.border_color = Color(0.2, 0.2, 0.2, 0.6)

	for button in [talk_button, gift_button, date_button]:
		button.add_theme_stylebox_override("normal", button_style)
		button.add_theme_stylebox_override("hover", button_hover_style)
		button.add_theme_stylebox_override("pressed", button_pressed_style)
		button.add_theme_stylebox_override("disabled", button_disabled_style)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9, 1))
		button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 1))

func _add_close_button():
	var close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(80, 40)
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.6, 0.2, 0.2, 0.9)
	close_style.set_corner_radius_all(8)
	close_style.border_width_left = 1
	close_style.border_width_top = 1
	close_style.border_width_right = 1
	close_style.border_width_bottom = 1
	close_style.border_color = Color(0.8, 0.3, 0.3, 0.8)
	
	var close_hover_style = close_style.duplicate()
	close_hover_style.bg_color = Color(0.7, 0.3, 0.3, 0.95)
	close_hover_style.border_color = Color(0.9, 0.5, 0.5, 0.9)
	
	var close_pressed_style = close_style.duplicate()
	close_pressed_style.bg_color = Color(0.5, 0.15, 0.15, 0.95)
	
	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_stylebox_override("hover", close_hover_style)
	close_button.add_theme_stylebox_override("pressed", close_pressed_style)
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	close_button.pressed.connect(func():
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(close_requested.emit)
	)
	interaction_buttons.add_child(close_button)

func _on_player_relationship_stage_changed(changed_character_id: String, _new_stage: String) -> void:
	if changed_character_id == character_id:
		update_relationship_display()

func set_character_data(data: Dictionary, revealed: bool, stats_needed_text: String) -> void:
	if data.is_empty() or data.get("id", "").is_empty():
		push_error("CharacterCard: Invalid or empty character data!")
		return

	character_data = data
	character_id = data.id
	if character_id != data.id:
		push_warning("CharacterCard: character_id mismatch! Using %s from data" % [data.id if data.id is String else "Invalid ID"])

	character_name_label.text = data.get("name", "Unknown") if revealed else "???"

	if revealed:
		var image_path = data.get("image_path", "")
		if image_path and ResourceLoader.exists(image_path):
			character_image.texture = load(image_path)
		else:
			character_image.texture = null

		update_relationship_display()
		talk_button.disabled = false
		set_gift_button_enabled(PlayerData.get_relationship_stage(character_id) in ["Good Friend", "Crush", "Dating", "Soulmate"])
		var stage = PlayerData.get_relationship_stage(character_id)
		var can_date = stage in ["Friend", "Good Friend", "Crush", "Dating", "Soulmate"] and PlayerData.stamina >= 5.0
		date_button.disabled = not can_date
		date_button.tooltip_text = _get_date_button_tooltip(stage, PlayerData.stamina)
		talk_button.tooltip_text = "Talk to build relationship (Costs 1 stamina)"
		gift_button.tooltip_text = "Requires Good Friend status"
	else:
		character_image.texture = null
		var hearts = heart_container.get_children()
		for heart in hearts:
			heart.modulate = Color(0.1, 0.1, 0.1, 0.3)
		stage_label.text = "???"
		talk_button.disabled = true
		gift_button.disabled = true
		date_button.disabled = true
		var safe_stats_needed_text = stats_needed_text if typeof(stats_needed_text) == TYPE_STRING else ""
		date_button.tooltip_text = "Requires: %s" % safe_stats_needed_text
		dialogue_label.text = "Requires: %s" % safe_stats_needed_text
		dialogue_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))  # Neon cyan
		dialogue_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.2, 0.2, 0.8))  # Lighter shadow
		_update_dialogue_panel_size()
		dialogue_panel.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(dialogue_panel, "modulate:a", 0.7, 0.3)

func _update_dialogue_panel_size() -> void:
	# Ensure layout is updated to get accurate label size
	dialogue_label.get_tree().process_frame.connect(func():
		var font = dialogue_label.get_theme_font("font")
		var text_size = font.get_string_size(dialogue_label.text, dialogue_label.horizontal_alignment, -1, dialogue_label.get_theme_font_size("font_size"))
		var label_width = min(text_size.x + 20, character_image.size.x * 0.9)  # Add padding, cap at 90% of image width
		dialogue_label.custom_minimum_size.x = label_width
		var label_size = dialogue_label.get_rect().size
		var padding = dialogue_panel.get_theme_constant("content_margin_top") + dialogue_panel.get_theme_constant("content_margin_bottom")
		var panel_height = label_size.y + padding
		dialogue_panel.offset_top = -panel_height
		dialogue_panel.offset_bottom = 0.0
	, CONNECT_ONE_SHOT)

func set_gift_button_enabled(enabled: bool) -> void:
	gift_button.disabled = not enabled

func _get_date_button_tooltip(stage: String, stamina: float) -> String:
	var stage_ok = stage in ["Friend", "Good Friend", "Crush", "Dating", "Soulmate"]
	var stamina_ok = stamina >= 5.0
	if stage_ok and stamina_ok:
		return "Ready to date!"
	elif not stage_ok and not stamina_ok:
		return "Requires Friend status and 5 stamina"
	elif not stage_ok:
		return "Requires Friend status"
	else:
		return "Requires 5 stamina"

func create_heart_meter():
	# Clear existing hearts if any
	for child in heart_container.get_children():
		child.queue_free()
	
	# Create 10 hearts
	for i in range(10):
		var heart = TextureRect.new()
		heart.texture = preload("res://images/ui_elements/heart.png")
		heart.custom_minimum_size = Vector2(24, 24)
		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart_container.add_child(heart)

func get_current_stage(points: int) -> Dictionary:
	for stage in relationship_stages:
		if points >= stage.min and points <= stage.max:
			return stage
	return relationship_stages[0] # Default to Stranger

func update_relationship_display() -> void:
	if not PlayerData:
		push_error("CharacterCard: PlayerData singleton not found!")
		return

	var points = PlayerData.get_relationship_points(character_id)
	var current_stage = get_current_stage(points)
	
	# Calculate progress within current stage
	var stage_progress = points - current_stage.min
	var stage_range = current_stage.max - current_stage.min + 1
	var stage_percentage = float(stage_progress) / float(stage_range) if stage_range > 0 else 0.0
	
	# Update hearts based on stage progress
	var hearts = heart_container.get_children()
	var filled_hearts = int(stage_percentage * hearts.size())
	
	for i in range(hearts.size()):
		var heart = hearts[i] as TextureRect
		if i < filled_hearts:
			heart.modulate = current_stage.color
			animate_heart_fill(heart)
		else:
			heart.modulate = Color(0.3, 0.3, 0.3, 0.5)

	# Update stage label with safe formatting
	var safe_stage_name = current_stage.name if current_stage.name is String else "Unknown"
	stage_label.text = "%s - %d/%d" % [safe_stage_name, stage_progress, stage_range]
	stage_label.add_theme_color_override("font_color", current_stage.color.lerp(Color.WHITE, 0.3))
	
	# Update tooltip with safe formatting
	var tooltip_text = "%s (%d/%d in stage) - Total: %d/1500 points" % [
		safe_stage_name, 
		stage_progress, 
		stage_range,
		points
	]
	heart_container.tooltip_text = tooltip_text
	
	# Update other UI elements
	var stage_name = safe_stage_name
	gift_button.disabled = not (stage_name in ["Good Friend", "Crush", "Dating", "Soulmate"])
	var can_date = stage_name in ["Friend", "Good Friend", "Crush", "Dating", "Soulmate"] and PlayerData.stamina >= 5.0
	date_button.disabled = not can_date
	date_button.tooltip_text = _get_date_button_tooltip(stage_name, PlayerData.stamina)

func animate_heart_fill(heart: TextureRect):
	# Create a nice animation when a heart fills
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale up and down
	heart.scale = Vector2.ONE
	tween.tween_property(heart, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(heart, "scale", Vector2.ONE, 0.1).set_delay(0.1)
	
	# Add a subtle rotation
	tween.tween_property(heart, "rotation", deg_to_rad(15), 0.05)
	tween.tween_property(heart, "rotation", deg_to_rad(-15), 0.05).set_delay(0.05)
	tween.tween_property(heart, "rotation", 0, 0.05).set_delay(0.1)

func check_for_stage_completion(old_points: int, new_points: int) -> bool:
	var old_stage = get_current_stage(old_points)
	var new_stage = get_current_stage(new_points)
	
	if old_stage.name != new_stage.name:
		show_stage_change_dialogue(new_stage.name)
		create_stage_completion_effect()
		return true
	return false

func create_stage_completion_effect():
	# Add a temporary label
	var completion_label = Label.new()
	completion_label.text = "Stage Up!"
	completion_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
	completion_label.add_theme_font_size_override("font_size", 24)
	completion_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	completion_label.add_theme_constant_override("shadow_offset_x", 2)
	completion_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(completion_label)
	completion_label.position = stage_label.position + Vector2(0, -40)
	
	var tween = create_tween()
	tween.tween_property(completion_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(completion_label, "position:y", completion_label.position.y - 20, 1.0)
	tween.tween_property(completion_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): completion_label.queue_free())
	
	# Heart pulse
	for heart in heart_container.get_children():
		var heart_tween = create_tween()
		heart_tween.set_loops(3)
		heart_tween.tween_property(heart, "scale", Vector2(1.2, 1.2), 0.2)
		heart_tween.tween_property(heart, "scale", Vector2.ONE, 0.2)

func show_dialogue() -> bool:
	if not PlayerData:
		push_error("CharacterCard: PlayerData singleton not found!")
		return false
	if PlayerData.stamina < 1.0:
		dialogue_label.text = "Not enough stamina to talk!"
		dialogue_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))  # Neon cyan
		dialogue_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.2, 0.2, 0.8))  # Lighter shadow
		_update_dialogue_panel_size()
		_animate_dialogue_panel(true)
		return false

	var current_stage = PlayerData.get_relationship_stage(character_id)
	var dialogue_data = get_dialogue_for_stage(current_stage)
	
	if dialogue_data.dialogues.is_empty():
		push_error("CharacterCard: No dialogue available for stage '%s'!" % current_stage)
		dialogue_label.text = "Something's wrong, no dialogue available!"
		dialogue_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))  # Neon cyan
		dialogue_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.2, 0.2, 0.8))  # Lighter shadow
		_update_dialogue_panel_size()
		_animate_dialogue_panel(true)
		return false

	var old_points = PlayerData.get_relationship_points(character_id)
	current_dialogue_index = randi() % dialogue_data.dialogues.size()
	PlayerData.consume_stamina(1.0)
	PlayerData.add_relationship_points(character_id, dialogue_data.points)
	dialogue_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))  # Neon cyan
	dialogue_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.2, 0.2, 0.8))  # Lighter shadow
	dialogue_label.text = dialogue_data.dialogues[current_dialogue_index]
	
	var new_points = PlayerData.get_relationship_points(character_id)
	var stage_changed = check_for_stage_completion(old_points, new_points)
	update_relationship_display()
	
	_update_dialogue_panel_size()
	_animate_dialogue_panel(true)
	return stage_changed

func get_dialogue_for_stage(stage: String) -> Dictionary:
	var result = {"dialogues": [], "points": 4}
	var used_stage = stage
	
	# Get ordered stage names for fallback
	var stage_names = relationship_stages.map(func(s): return s.name)
	var current_index = stage_names.find(stage)
	if current_index == -1:
		push_error("CharacterCard: Invalid stage '%s'! Falling back to Stranger." % stage)
		current_index = 0
		used_stage = "Stranger"
	
	# Check for dialogue_by_stage
	if character_data.has("dialogue_by_stage"):
		var dialogue_by_stage = character_data.dialogue_by_stage
		var found = false
		for i in range(current_index, -1, -1):
			var test_stage = stage_names[i]
			if dialogue_by_stage.has(test_stage) and dialogue_by_stage[test_stage] is Array and not dialogue_by_stage[test_stage].is_empty():
				result.dialogues = dialogue_by_stage[test_stage]
				used_stage = test_stage
				found = true
				break
		if not found:
			push_error("CharacterCard: No valid dialogues found in dialogue_by_stage!")
	
	# Fallback to dialogue array if present and valid
	if result.dialogues.is_empty() and character_data.has("dialogue"):
		var dialogue = character_data.dialogue
		if dialogue is Array and not dialogue.is_empty() and dialogue[0] != "No dialogue available.":
			result.dialogues = dialogue
			used_stage = "Legacy"
		else:
			push_error("CharacterCard: Legacy dialogue array is invalid or contains 'No dialogue available.'")
	
	# Ultimate default if no dialogues found
	if result.dialogues.is_empty():
		push_error("CharacterCard: Using default dialogues as last resort")
		result.dialogues = ["Hello there!", "Nice to see you!", "How's it going?"]
		used_stage = "Default"
	
	# Get points (with fallback if dict)
	if character_data.has("dialogue_points"):
		var dialogue_points = character_data.dialogue_points
		if typeof(dialogue_points) == TYPE_DICTIONARY:
			var found_points = false
			for i in range(current_index, -1, -1):
				var test_stage = stage_names[i]
				if dialogue_points.has(test_stage):
					result.points = int(dialogue_points[test_stage])
					found_points = true
					break
			if not found_points:
				push_error("CharacterCard: No points found after fallback; using default 4")
		else:
			result.points = int(dialogue_points) if typeof(dialogue_points) == TYPE_FLOAT else dialogue_points
	return result

func show_stage_change_dialogue(new_stage: String):
	var stage_change_dialogues = {
		"Acquaintance": [
			"Oh, I think I recognize you now!",
			"Haven't we met before?",
			"You seem familiar somehow."
		],
		"Friend": [
			"Hey, I think we're becoming good friends!",
			"I really enjoy spending time with you!",
			"You seem like someone I can trust."
		],
		"Good Friend": [
			"You know what? You're a really good friend to me.",
			"I feel like I can really open up to you.",
			"Thanks for being such an amazing friend!"
		],
		"Crush": [
			"*blushes* I... I think I'm starting to like you as more than a friend.",
			"There's something special about you...",
			"*nervous laugh* Is it just me, or is there something between us?"
		],
		"Dating": [
			"*beaming* I can't believe we're actually together now!",
			"This feels so right... being with you.",
			"*takes your hand* I'm so happy we took this step together."
		],
		"Soulmate": [
			"*tears of joy* You're everything to me... my perfect match.",
			"I never believed in soulmates until I met you.",
			"*loving embrace* This is forever, isn't it? Us, together."
		]
	}
	
	if stage_change_dialogues.has(new_stage):
		var special_dialogues = stage_change_dialogues[new_stage]
		var special_dialogue = special_dialogues[randi() % special_dialogues.size()]
		dialogue_label.text = "💕 " + special_dialogue + " 💕"
		dialogue_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.7, 1.0))  # Vivid magenta
		dialogue_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.2, 0.2, 0.8))  # Lighter shadow
		_update_dialogue_panel_size()
		print("Stage change dialogue: ", dialogue_label.text)

func _animate_dialogue_panel(show: bool) -> void:
	var target_alpha = 0.7 if show else 0.0
	if dialogue_panel.modulate.a == target_alpha:
		return
	var tween = create_tween()
	tween.tween_property(dialogue_panel, "modulate:a", target_alpha, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

func hide_dialogue() -> void:
	_animate_dialogue_panel(false)
	dialogue_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.2, 0.2, 0.8))  # Lighter shadow

func _on_talk_button_pressed() -> void:
	if character_data.get("requirements_met", false):
		# Stop any existing dialogue timer
		if dialogue_timer and dialogue_timer.time_left > 0:
			dialogue_timer.stop()
		
		var stage_changed = show_dialogue()
		# Start a new 5-second timer for all dialogues
		dialogue_timer.start(5.0)

func _on_gift_button_pressed() -> void:
	if character_data.get("requirements_met", false):
		gift_requested.emit(character_id, character_data)

func _on_date_button_pressed() -> void:
	if character_data.get("requirements_met", false):
		date_requested.emit(character_id, character_data)
