extends PanelContainer
class_name DateMenu

signal date_selected(character_id: String, date_type: String, stamina_cost: float, points: int)
signal close_pressed

@onready var dinner_button: Button = %DinnerButton
@onready var park_button: Button = %ParkButton
@onready var beach_button: Button = %BeachButton
@onready var home_button: Button = %HomeButton
@onready var kiss_button: Button = %KissButton
@onready var close_menu_button: Button = %CloseMenuButton
@onready var date_popup: Control = %DatePopup
@onready var date_image: TextureRect = %DateImage
@onready var countdown_label: RichTextLabel = %CountdownLabel
@onready var date_title: Label = %DateTitle
@onready var popup_close_button: Button = %PopupCloseButton
@onready var border_panel: Panel = %BorderPanel

var character_id: String = ""
var character_data: Dictionary = {}
var countdown: int = 5
var countdown_timer: Timer
var is_date_active: bool = false
var click_hearts: Array = []
var previous_button_states: Dictionary = {}
var current_date_type: String = ""
var emoji_font: Font = null
var text_font: Font = null

const DATE_DATA = {
	"Dinner": {"stamina_cost": 5.0, "points": 10, "required_level": "Friend"},
	"Park": {"stamina_cost": 10.0, "points": 20, "required_level": "Good Friend"},
	"Beach": {"stamina_cost": 15.0, "points": 30, "required_level": "Crush"},
	"Home": {"stamina_cost": 20.0, "points": 40, "required_level": "Dating"},
	"Kiss": {"stamina_cost": 25.0, "points": 50, "required_level": "Soulmate"}
}

func _ready():
	# Load fonts
	emoji_font = _load_emoji_font()
	text_font = _load_text_font()

	# Validate nodes
	var nodes = {
		"dinner_button": dinner_button,
		"park_button": park_button,
		"beach_button": beach_button,
		"home_button": home_button,
		"kiss_button": kiss_button,
		"close_menu_button": close_menu_button,
		"date_popup": date_popup,
		"date_image": date_image,
		"countdown_label": countdown_label,
		"date_title": date_title,
		"popup_close_button": popup_close_button,
		"border_panel": border_panel
	}
	for node_name in nodes:
		if not nodes[node_name] or not is_instance_valid(nodes[node_name]):
			printerr("DateMenu: %s is null or invalid! Path: %s" % [node_name, get_path_to(nodes[node_name])])
			return

	# Apply emoji font to buttons (for fallback or disabled state)
	if emoji_font:
		for button in [dinner_button, park_button, beach_button, home_button, kiss_button, close_menu_button]:
			button.add_theme_font_override("font", emoji_font)

	# Connect button signals
	dinner_button.pressed.connect(_on_date_button_pressed.bind("Dinner"))
	park_button.pressed.connect(_on_date_button_pressed.bind("Park"))
	beach_button.pressed.connect(_on_date_button_pressed.bind("Beach"))
	home_button.pressed.connect(_on_date_button_pressed.bind("Home"))
	kiss_button.pressed.connect(_on_date_button_pressed.bind("Kiss"))
	close_menu_button.pressed.connect(_on_close_menu_button_pressed)
	popup_close_button.pressed.connect(_on_popup_close_button_pressed)

	# Connect image click for hearts
	date_image.gui_input.connect(_on_date_image_gui_input)

	# Connect to PlayerData signals
	if PlayerData:
		PlayerData.player_relationship_stage_changed.connect(_on_player_relationship_stage_changed)
		PlayerData.player_stamina_changed.connect(_on_player_stamina_changed)
	else:
		printerr("DateMenu: PlayerData singleton not found in _ready!")

	# Initialize popup
	date_popup.visible = false
	popup_close_button.disabled = true
	is_date_active = false

	# Create countdown timer
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.one_shot = false
	countdown_timer.timeout.connect(_on_countdown_timeout)
	add_child(countdown_timer)

	# Prevent text wrapping in countdown label
	countdown_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	countdown_label.tooltip_text = "Countdown to date completion"

	# Apply border style to border_panel
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	border_style.border_width_left = 4
	border_style.border_width_top = 4
	border_style.border_width_right = 4
	border_style.border_width_bottom = 4
	border_style.border_color = Color(1, 1, 1, 1)
	border_style.corner_radius_top_left = 16
	border_style.corner_radius_top_right = 16
	border_style.corner_radius_bottom_right = 16
	border_style.corner_radius_bottom_left = 16
	border_style.shadow_color = Color(0, 0, 0, 0.7)
	border_style.shadow_size = 16
	border_style.shadow_offset = Vector2(4, 6)
	border_panel.add_theme_stylebox_override("panel", border_style)
	if border_panel:
		print("DateMenu: Border style applied to BorderPanel")

	# Slightly increase close button size for prominence
	popup_close_button.custom_minimum_size = Vector2(140, 60)

	update_date_button_availability()

func _load_emoji_font() -> Font:
	var font: Font = null
	var font_path: String = "res://fonts/NotoColorEmoji-Regular.ttf"
	if ResourceLoader.exists(font_path):
		font = load(font_path) as Font
		if font:
			print("DateMenu: Emoji font loaded successfully: %s" % font_path)
		else:
			printerr("DateMenu: Failed to load emoji font: %s" % font_path)
	else:
		printerr("DateMenu: Emoji font not found: %s" % font_path)
		# Fallback to system font
		font = ThemeDB.fallback_font
		print("DateMenu: Using system fallback font for emojis")
	return font

func _load_text_font() -> Font:
	var font: Font = null
	var font_path: String = "res://fonts/NotoSans-Regular.ttf"
	if ResourceLoader.exists(font_path):
		font = load(font_path) as Font
		if font:
			print("DateMenu: Text font loaded successfully: %s" % font_path)
		else:
			printerr("DateMenu: Failed to load text font: %s" % font_path)
	else:
		printerr("DateMenu: Text font not found: %s" % font_path)
		# Fallback to system font
		font = ThemeDB.fallback_font
		print("DateMenu: Using system fallback font for text")
	return font

func _input(event):
	# Only allow ESC close after countdown ends (when close button is enabled)
	if is_date_active and not popup_close_button.disabled and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_popup_close_button_pressed()

func _on_date_image_gui_input(event):
	# Create hearts when clicking on the image during a date (limit to 20 active)
	if is_date_active and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and click_hearts.size() < 20:
		_create_click_heart(event.position)

func _create_click_heart(click_position: Vector2):
	var heart = RichTextLabel.new()
	heart.custom_minimum_size = Vector2(40, 40)
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart.fit_content = true
	heart.scroll_active = false
	heart.bbcode_enabled = true
	heart.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	if emoji_font:
		heart.add_theme_font_override("normal_font", emoji_font)
	
	# Random heart emoji
	var heart_emojis = ["💖", "💕", "💗", "💓", "❤️", "🧡", "💛", "💚", "💙", "💜"]
	var emoji = heart_emojis[randi() % heart_emojis.size()]
	heart.text = "[font_size=32][center]%s[/center][/font_size]" % emoji
	
	# Position at click location
	heart.position = click_position - heart.custom_minimum_size / 2
	heart.modulate = Color(1, 1, 1, 0)
	heart.rotation = 0
	
	# Add to date image
	date_image.add_child(heart)
	click_hearts.append(heart)
	
	# Animate heart with added rotation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in and scale up
	tween.tween_property(heart, "modulate:a", 1.0, 0.3)
	tween.tween_property(heart, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Float upward, fade out, and rotate slightly
	tween.tween_property(heart, "position:y", heart.position.y - 80, 1.5).set_delay(0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "modulate:a", 0.0, 0.8).set_delay(0.7)
	tween.tween_property(heart, "scale", Vector2(0.8, 0.8), 0.8).set_delay(0.7)
	tween.tween_property(heart, "rotation", randf_range(-0.3, 0.3), 1.5).set_delay(0.3).set_trans(Tween.TRANS_SINE)
	
	# Clean up after animation
	tween.tween_callback(_remove_click_heart.bind(heart)).set_delay(1.5)

func _remove_click_heart(heart):
	if is_instance_valid(heart):
		click_hearts.erase(heart)
		heart.queue_free()

func _on_player_relationship_stage_changed(changed_character_id: String, _new_stage: String):
	if changed_character_id == character_id:
		update_date_button_availability()

func _on_player_stamina_changed(_current_stamina: float, _max_stamina: float):
	update_date_button_availability()

func set_character_data(id: String, data: Dictionary):
	character_id = id
	character_data = data
	update_date_button_availability()

func _is_relationship_level_sufficient(current_stage: String, required_stage: String) -> bool:
	var stage_points = PlayerData.RELATIONSHIP_STAGES
	var current_points = 0
	var required_points = 0
	
	for threshold in stage_points.keys():
		if stage_points[threshold] == current_stage:
			current_points = threshold
		if stage_points[threshold] == required_stage:
			required_points = threshold
	
	if current_points == 0 and current_stage != "Stranger":
		printerr("DateMenu: Unknown current relationship stage: %s" % current_stage)
		return false
	if required_points == 0 and required_stage != "Stranger":
		printerr("DateMenu: Unknown required relationship stage: %s" % required_stage)
		return false
	
	return current_points >= required_points

func update_date_button_availability():
	if not is_instance_valid(PlayerData):
		printerr("DateMenu: Player singleton not found!")
		return

	if is_date_active:
		return

	var current_relationship_stage = PlayerData.get_relationship_stage(character_id)

	var buttons = {
		"DinnerButton": {"type": "Dinner", "emoji": "🍽️"},
		"ParkButton": {"type": "Park", "emoji": "🌳"},
		"BeachButton": {"type": "Beach", "emoji": "🏖️"},
		"HomeButton": {"type": "Home", "emoji": "🏠"},
		"KissButton": {"type": "Kiss", "emoji": "💋"}
	}

	for button_name in buttons:
		var button = get_node_or_null("%" + button_name)
		if button:
			var info = buttons[button_name]
			var date_type = info["type"]
			var emoji = info["emoji"]
			var date_config = DATE_DATA[date_type]
			var required_stage = date_config.required_level
			var stamina_cost = date_config.stamina_cost
			var points = date_config.points
			
			var stage_unlocked = _is_relationship_level_sufficient(current_relationship_stage, required_stage)
			var has_stamina = PlayerData.stamina >= stamina_cost
			
			var is_enabled = stage_unlocked and has_stamina
			button.disabled = not is_enabled
			
			if previous_button_states.get(date_type, true) and is_enabled:
				var tween = create_tween().set_parallel(true)
				tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2)
				tween.tween_property(button, "modulate", Color(1.2, 1.2, 0.9), 0.2)
				tween.chain().tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
				tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0), 0.2)
			
			previous_button_states[date_type] = button.disabled
			
			# Update HBoxContainer labels
			var hbox = button.get_node_or_null("HBoxContainer")
			if hbox:
				var emoji_label = hbox.get_node_or_null("EmojiLabel")
				var text_label = hbox.get_node_or_null("TextLabel")
				if emoji_label and text_label:
					emoji_label.text = emoji
					text_label.text = date_type
			
			# Set tooltip based on availability
			if not stage_unlocked:
				button.tooltip_text = "Reach %s relationship stage to unlock %s Date" % [required_stage, date_type]
			elif not has_stamina:
				button.tooltip_text = "Not enough stamina for %s Date! Need %.1f⚡ (you have %.1f⚡) , gives %d points" % [date_type, stamina_cost, PlayerData.stamina, points]
			else:
				button.tooltip_text = "%s Date: Costs %0.0f⚡ , gives %d relationship points" % [date_type, stamina_cost, points]

	# Update CloseMenuButton labels
	var close_hbox = close_menu_button.get_node_or_null("HBoxContainer")
	if close_hbox:
		var emoji_label = close_hbox.get_node_or_null("EmojiLabel")
		var text_label = close_hbox.get_node_or_null("TextLabel")
		if emoji_label and text_label:
			emoji_label.text = "❌"
			text_label.text = "Close"

func _on_date_button_pressed(date_type: String):
	if is_date_active:
		return
		
	if not PlayerData or not DATE_DATA.has(date_type):
		printerr("DateMenu: PlayerData or date type %s not found!" % date_type)
		return
		
	var config = DATE_DATA[date_type]
	var required_stage = config.required_level
	var current_relationship_stage = PlayerData.get_relationship_stage(character_id)
	
	if not _is_relationship_level_sufficient(current_relationship_stage, required_stage):
		UIManager.show_notification("Need %s relationship stage for %s Date!" % [required_stage, date_type])
		return
		
	if PlayerData.stamina >= config.stamina_cost:
		is_date_active = true
		# Deduct stamina here
		PlayerData.consume_stamina(config.stamina_cost)
		# Emit signal for other actions (e.g., logging, UI updates)
		date_selected.emit(character_id, date_type, config.stamina_cost, config.points)
		show_date_popup(date_type)
	else:
		UIManager.show_notification("Not enough stamina for %s Date!" % date_type)

func show_date_popup(date_type: String):
	current_date_type = date_type
	
	date_title.text = date_type + " Date"
	countdown = 5
	countdown_label.text = "[font_size=32][center][color=#FFFF80][outline_size=3][outline_color=black]%s[/outline_color][/outline_size][/color][/center][/font_size]" % str(countdown)
	
	_setup_date_image(date_type)
	
	date_popup.visible = true
	date_popup.modulate = Color(1, 1, 1, 0)
	date_popup.scale = Vector2(0.8, 0.8)
	popup_close_button.disabled = true
	
	# Debug BorderPanel size and position when shown
	if border_panel:
		print("DateMenu: BorderPanel size when shown: %s, position: %s" % [border_panel.size, border_panel.position])
	
	# Re-apply border style to ensure it's visible
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	border_style.border_width_left = 4
	border_style.border_width_top = 4
	border_style.border_width_right = 4
	border_style.border_width_bottom = 4
	border_style.border_color = Color(1, 1, 1, 1)
	border_style.corner_radius_top_left = 16
	border_style.corner_radius_top_right = 16
	border_style.corner_radius_bottom_right = 16
	border_style.corner_radius_bottom_left = 16
	border_style.shadow_color = Color(0, 0, 0, 0.7)
	border_style.shadow_size = 16
	border_style.shadow_offset = Vector2(4, 6)
	border_panel.add_theme_stylebox_override("panel", border_style)
	
	var entrance_tween = create_tween()
	entrance_tween.set_parallel(true)
	entrance_tween.tween_property(date_popup, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(date_popup, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	countdown_timer.start()
	
	_position_countdown_label()

func _position_countdown_label():
	pass

func _setup_date_image(date_type: String):
	var date_image_path = character_data.get("date_images", {}).get(date_type.to_lower(), "")
	
	if date_image_path != "" and ResourceLoader.exists(date_image_path):
		var texture = load(date_image_path)
		if texture:
			date_image.texture = texture
			return
	_create_modern_gradient_texture(date_type)

func _create_modern_gradient_texture(date_type: String):
	var gradient_texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	
	var color_schemes = {
		"Dinner": [Color("#FF6B6B"), Color("#4ECDC4")],
		"Park": [Color("#A8E6CF"), Color("#88D8A3")], 
		"Beach": [Color("#74B9FF"), Color("#0984E3")],
		"Home": [Color("#FD79A8"), Color("#E84393")],
		"Kiss": [Color("#FDCB6E"), Color("#E17055")]
	}
	
	var colors = color_schemes.get(date_type, color_schemes["Dinner"])
	gradient.colors = colors
	gradient.offsets = [0.0, 1.0]
	
	gradient_texture.gradient = gradient
	gradient_texture.width = 1200
	gradient_texture.height = 900
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.fill_from = Vector2(0.5, 0.3)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	
	date_image.texture = gradient_texture

func _on_countdown_timeout():
	if not is_date_active:
		return
	
	countdown -= 1
	if countdown > 0:
		countdown_label.text = "[font_size=32][center][color=#FFFF80][outline_size=3][outline_color=black]%s[/outline_color][/outline_size][/color][/center][/font_size]" % str(countdown)
	else:
		countdown_label.text = "[font_size=24][center][color=yellow]✨ Date Complete! ✨[/color][/center][/font_size]"
		if emoji_font:
			countdown_label.add_theme_font_override("normal_font", emoji_font)
		countdown_timer.stop()
		popup_close_button.disabled = false
		
		if PlayerData:
			var date_info = DATE_DATA[current_date_type]
			PlayerData.add_relationship_points(character_id, date_info["points"])
			PlayerData.mark_date_completed(character_id, current_date_type.to_lower())
			print("DateMenu: Marked %s date as completed for %s" % [current_date_type, character_id])
		
		var completion_tween = create_tween()
		completion_tween.tween_property(countdown_label, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		completion_tween.tween_property(countdown_label, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(0.5)
		completion_tween.set_loops()

func _animate_countdown_number():
	var tween = create_tween()
	tween.set_parallel(true)
	
	countdown_label.scale = Vector2(1.0, 1.0)
	tween.tween_property(countdown_label, "scale", Vector2(1.4, 1.4), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	var original_color = countdown_label.modulate
	tween.tween_property(countdown_label, "modulate", Color.GOLD, 0.2)
	tween.tween_property(countdown_label, "modulate", original_color, 0.3).set_delay(0.2)
	
	# Add subtle shake using position offsets
	var original_position = countdown_label.position
	tween.tween_property(countdown_label, "position:x", original_position.x + 5, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(countdown_label, "position:x", original_position.x - 5, 0.1).set_delay(0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(countdown_label, "position:x", original_position.x + 3, 0.15).set_delay(0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(countdown_label, "position:x", original_position.x, 0.2).set_delay(0.3).set_trans(Tween.TRANS_SINE)

func _complete_date():
	if character_id != "" and current_date_type != "":
		var date_name = current_date_type.to_lower()
		PlayerData.mark_date_completed(character_id, date_name)
		print("DateMenu: Marked %s date as completed for %s" % [date_name, character_id])
	
	# Set completion message with larger font and ensured emoji support
	var complete_text = "[font_size=40][center][color=gold][outline_size=4][outline_color=black]Complete! ✨[/outline_color][/outline_size][/color][/center][/font_size]"
	countdown_label.text = complete_text
	if emoji_font:
		countdown_label.add_theme_font_override("normal_font", emoji_font)
	
	popup_close_button.disabled = false
	
	var complete_tween = create_tween()
	complete_tween.set_parallel(true)
	complete_tween.tween_property(countdown_label, "modulate", Color.GOLD, 0.5)
	complete_tween.tween_property(countdown_label, "scale", Vector2(1.3, 1.3), 0.5).set_trans(Tween.TRANS_BACK)
	
	var button_glow = create_tween()
	button_glow.set_loops()
	button_glow.tween_property(popup_close_button, "modulate", Color(1.2, 1.2, 0.9), 0.8)
	button_glow.tween_property(popup_close_button, "modulate", Color(1.0, 1.0, 1.0), 0.8)
	
	# Spawn extra hearts for "confetti" effect on completion
	for i in range(5):
		_create_click_heart(Vector2(randf_range(100, 900), randf_range(100, 700)))

func _on_popup_close_button_pressed():
	if not countdown_timer.is_stopped():
		countdown_timer.stop()
	
	_clear_click_hearts()
	
	is_date_active = false
	
	var exit_tween = create_tween()
	exit_tween.set_parallel(true)
	exit_tween.tween_property(date_popup, "modulate:a", 0.0, 0.3)
	exit_tween.tween_property(date_popup, "scale", Vector2(0.9, 0.9), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await exit_tween.finished
	date_popup.visible = false
	
	date_popup.modulate = Color.WHITE
	date_popup.scale = Vector2(1.0, 1.0)
	countdown_label.modulate = Color.WHITE
	countdown_label.scale = Vector2(1.0, 1.0)
	popup_close_button.modulate = Color.WHITE
	
	update_date_button_availability()

func _clear_click_hearts():
	for heart in click_hearts.duplicate():
		if is_instance_valid(heart):
			var tween = get_tree().create_tween() if heart.get_tree() else null
			if tween:
				tween.kill()
			heart.queue_free()
	click_hearts.clear()

func _on_close_menu_button_pressed():
	if is_date_active:
		is_date_active = false
		if countdown_timer and not countdown_timer.is_stopped():
			countdown_timer.stop()
		_clear_click_hearts()
		date_popup.visible = false
	
	if PlayerData:
		if PlayerData.player_relationship_stage_changed.is_connected(_on_player_relationship_stage_changed):
			PlayerData.player_relationship_stage_changed.disconnect(_on_player_relationship_stage_changed)
		if PlayerData.player_stamina_changed.is_connected(_on_player_stamina_changed):
			PlayerData.player_stamina_changed.disconnect(_on_player_stamina_changed)
	
	close_pressed.emit()

func show_panel_animated() -> void:
	visible = true
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, UIManager.FADE_DURATION).set_trans(UIManager.FADE_TRANS).set_ease(UIManager.FADE_EASE)

func hide_panel_animated() -> void:
	if PlayerData:
		if PlayerData.player_relationship_stage_changed.is_connected(_on_player_relationship_stage_changed):
			PlayerData.player_relationship_stage_changed.disconnect(_on_player_relationship_stage_changed)
		if PlayerData.player_stamina_changed.is_connected(_on_player_stamina_changed):
			PlayerData.player_stamina_changed.disconnect(_on_player_stamina_changed)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, UIManager.FADE_DURATION).set_trans(UIManager.FADE_TRANS).set_ease(UIManager.FADE_EASE)
	await tween.finished
	visible = false
	queue_free()

func get_fade_tween() -> Tween:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, UIManager.FADE_DURATION).set_trans(UIManager.FADE_TRANS).set_ease(UIManager.FADE_EASE)
	return tween
