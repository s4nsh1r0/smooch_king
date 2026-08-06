extends PanelContainer
class_name DateMenu

signal date_selected(character_id: String, date_type: String, ap_cost: float, points: int)
signal close_pressed

@onready var dinner_button: Button = %DinnerButton
@onready var park_button: Button = %ParkButton
@onready var beach_button: Button = %BeachButton
@onready var home_button: Button = %HomeButton
@onready var special_button: Button = %SpecialButton
@onready var close_menu_button: Button = %CloseMenuButton
@onready var date_popup: Control = %DatePopup
@onready var date_image: TextureRect = %DateImage
@onready var date_title: Label = %DateTitle
@onready var date_progress_bar: ProgressBar = %DateProgressBar
@onready var popup_close_button: Button = %PopupCloseButton
@onready var border_panel: Panel = %BorderPanel

const DATE_DATA := {
	"Dinner": {"ap_cost": 10, "points": 20, "required_level": "Friend"},
	"Park": {"ap_cost": 15, "points": 30, "required_level": "Good Friend"},
	"Beach": {"ap_cost": 20, "points": 40, "required_level": "Crush"},
	"Home": {"ap_cost": 25, "points": 50, "required_level": "Dating"},
	"Special": {"ap_cost": 50, "points": 100, "required_level": "Soulmate"},
}

const DATE_DURATION := 5.0

var character_id: String = ""
var character_data: Dictionary = {}
var is_date_active: bool = false
var current_date_type: String = ""
var click_hearts: Array = []
var previous_enabled: Dictionary = {}
var emoji_font: Font = null
var date_progress_tween: Tween = null
var _date_dim: ColorRect = null

func _ready() -> void:
	emoji_font = _load_font("res://assets/fonts/NotoColorEmoji-Regular.ttf")

	for node in [
		dinner_button, park_button, beach_button, home_button, special_button,
		close_menu_button, date_popup, date_image, date_title, popup_close_button, border_panel
	]:
		if not is_instance_valid(node):
			printerr("DateMenu: required node missing")
			return

	_setup_modern_styling()

	dinner_button.pressed.connect(_on_date_button_pressed.bind("Dinner"))
	park_button.pressed.connect(_on_date_button_pressed.bind("Park"))
	beach_button.pressed.connect(_on_date_button_pressed.bind("Beach"))
	home_button.pressed.connect(_on_date_button_pressed.bind("Home"))
	special_button.pressed.connect(_on_date_button_pressed.bind("Special"))
	close_menu_button.pressed.connect(_on_close_menu_button_pressed)
	popup_close_button.pressed.connect(_on_popup_close_button_pressed)
	date_image.gui_input.connect(_on_date_image_gui_input)

	if PlayerData:
		if not PlayerData.player_relationship_stage_changed.is_connected(_on_player_relationship_stage_changed):
			PlayerData.player_relationship_stage_changed.connect(_on_player_relationship_stage_changed)
		if not PlayerData.player_ap_changed.is_connected(_on_player_ap_changed):
			PlayerData.player_ap_changed.connect(_on_player_ap_changed)

	date_popup.visible = false
	popup_close_button.disabled = true
	popup_close_button.custom_minimum_size = Vector2(140, 60)
	is_date_active = false
	update_date_button_availability()

func _exit_tree() -> void:
	_disconnect_player_signals()
	_cleanup_popup_layer(true)

# ---------- Styling ----------

func _setup_modern_styling() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.32, 0.18, 0.42, 0.92)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.95, 0.7, 1.0, 0.9)
	panel_style.set_corner_radius_all(22)
	panel_style.shadow_color = Color(0.5, 0.2, 0.7, 0.5)
	panel_style.shadow_size = 16
	panel_style.shadow_offset = Vector2(0, 6)
	add_theme_stylebox_override("panel", panel_style)

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
	pressed.border_color = Color(0.9, 0.65, 0.95, 1.0)

	var disabled = normal.duplicate()
	disabled.bg_color = Color(0.3, 0.2, 0.35, 0.6)
	disabled.border_color = Color(0.5, 0.35, 0.55, 0.5)

	for button in [dinner_button, park_button, beach_button, home_button, special_button]:
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("disabled", disabled)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_disabled_color", Color(0.6, 0.55, 0.65))

	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.75, 0.3, 0.45, 0.95)
	close_style.set_corner_radius_all(16)
	close_style.border_width_left = 2
	close_style.border_width_top = 2
	close_style.border_width_right = 2
	close_style.border_width_bottom = 2
	close_style.border_color = Color(1.0, 0.55, 0.7, 0.85)

	var close_hover = close_style.duplicate()
	close_hover.bg_color = Color(0.9, 0.4, 0.55, 1.0)
	close_hover.border_color = Color(1.0, 0.7, 0.8, 1.0)

	for b in [close_menu_button, popup_close_button]:
		b.add_theme_stylebox_override("normal", close_style)
		b.add_theme_stylebox_override("hover", close_hover)
		b.add_theme_stylebox_override("pressed", close_style)
		b.add_theme_color_override("font_color", Color.WHITE)

func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path) as Font
	return ThemeDB.fallback_font

# ---------- Input during date ----------

func _input(event: InputEvent) -> void:
	if not is_date_active:
		return
	# Block everything while the progress bar is running
	if date_progress_bar and date_progress_bar.visible:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not popup_close_button.disabled and popup_close_button.visible:
			_on_popup_close_button_pressed()
		get_viewport().set_input_as_handled()

func _on_date_image_gui_input(event: InputEvent) -> void:
	if not is_date_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if click_hearts.size() < 20:
			_create_click_heart(event.position)

func _create_click_heart(click_position: Vector2) -> void:
	var heart = RichTextLabel.new()
	heart.custom_minimum_size = Vector2(40, 40)
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart.fit_content = true
	heart.scroll_active = false
	heart.bbcode_enabled = true
	heart.autowrap_mode = TextServer.AUTOWRAP_OFF
	if emoji_font:
		heart.add_theme_font_override("normal_font", emoji_font)
	var heart_emojis = ["💖", "💕", "💗", "💓", "❤️", "🧡", "💛", "💚", "💙", "💜"]
	heart.text = "[font_size=32][center]%s[/center][/font_size]" % heart_emojis[randi() % heart_emojis.size()]
	heart.position = click_position - heart.custom_minimum_size / 2.0
	heart.modulate = Color(1, 1, 1, 0)
	date_image.add_child(heart)
	click_hearts.append(heart)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(heart, "modulate:a", 1.0, 0.3)
	tween.tween_property(heart, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "position:y", heart.position.y - 80, 1.5).set_delay(0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "modulate:a", 0.0, 0.8).set_delay(0.7)
	tween.tween_property(heart, "scale", Vector2(0.8, 0.8), 0.8).set_delay(0.7)
	tween.tween_property(heart, "rotation", randf_range(-0.3, 0.3), 1.5).set_delay(0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_remove_click_heart.bind(heart)).set_delay(1.5)

func _remove_click_heart(heart: Node) -> void:
	if is_instance_valid(heart):
		click_hearts.erase(heart)
		heart.queue_free()

func _clear_click_hearts() -> void:
	for heart in click_hearts.duplicate():
		if is_instance_valid(heart):
			heart.queue_free()
	click_hearts.clear()

# ---------- Character / buttons ----------

func set_character_data(id: String, data: Dictionary) -> void:
	character_id = id
	character_data = data
	update_date_button_availability()

func _on_player_relationship_stage_changed(changed_id: String, _new_stage: String) -> void:
	if changed_id == character_id:
		update_date_button_availability()

func _on_player_ap_changed(_ap: int) -> void:
	update_date_button_availability()

func _is_relationship_level_sufficient(current_stage: String, required_stage: String) -> bool:
	if not PlayerData:
		return false
	var stage_points = PlayerData.RELATIONSHIP_STAGES
	var current_points := 0
	var required_points := 0
	for threshold in stage_points.keys():
		if stage_points[threshold] == current_stage:
			current_points = int(threshold)
		if stage_points[threshold] == required_stage:
			required_points = int(threshold)
	return current_points >= required_points

func update_date_button_availability() -> void:
	if not is_instance_valid(PlayerData) or is_date_active:
		return

	var current_stage = PlayerData.get_relationship_stage(character_id)
	var buttons := {
		"DinnerButton": {"type": "Dinner", "emoji": "🍽️"},
		"ParkButton": {"type": "Park", "emoji": "🌳"},
		"BeachButton": {"type": "Beach", "emoji": "🏖️"},
		"HomeButton": {"type": "Home", "emoji": "🏠"},
		"SpecialButton": {"type": "Special", "emoji": "💋"},
	}

	for button_name in buttons:
		var button: Button = get_node_or_null("%" + button_name)
		if not button:
			continue

		var date_type: String = buttons[button_name]["type"]
		var emoji: String = buttons[button_name]["emoji"]
		var config: Dictionary = DATE_DATA[date_type]
		var required_stage: String = config.required_level
		var ap_cost: int = int(config.ap_cost)
		var points: int = int(config.points)

		var stage_ok = _is_relationship_level_sufficient(current_stage, required_stage)
		var ap_ok = PlayerData.has_ap(ap_cost)
		var enabled = stage_ok and ap_ok

		var was_enabled = previous_enabled.get(date_type, false)
		button.disabled = not enabled

		if enabled and not was_enabled:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(button, "scale", Vector2(1.04, 1.04), 0.18)
			tween.tween_property(button, "modulate", Color(1.15, 1.05, 1.2), 0.18)
			tween.chain().tween_property(button, "scale", Vector2.ONE, 0.18)
			tween.tween_property(button, "modulate", Color.WHITE, 0.18)

		previous_enabled[date_type] = enabled

		var hbox = button.get_node_or_null("HBoxContainer")
		if hbox:
			var emoji_label = hbox.get_node_or_null("EmojiLabel")
			var text_label = hbox.get_node_or_null("TextLabel")
			if emoji_label:
				emoji_label.text = emoji
			if text_label:
				text_label.text = date_type

		if not stage_ok:
			button.tooltip_text = "Reach %s to unlock %s Date" % [required_stage, date_type]
		elif not ap_ok:
			button.tooltip_text = "Need %d AP (you have %d)" % [ap_cost, PlayerData.action_points]
		else:
			button.tooltip_text = "%s Date: %d AP → +%d relationship" % [date_type, ap_cost, points]

	var close_hbox = close_menu_button.get_node_or_null("HBoxContainer")
	if close_hbox:
		var emoji_label = close_hbox.get_node_or_null("EmojiLabel")
		var text_label = close_hbox.get_node_or_null("TextLabel")
		if emoji_label:
			emoji_label.text = "❌"
		if text_label:
			text_label.text = "Close"

# ---------- Start date ----------

func _on_date_button_pressed(date_type: String) -> void:
	if is_date_active or not PlayerData or not DATE_DATA.has(date_type):
		return

	var config = DATE_DATA[date_type]
	var current_stage = PlayerData.get_relationship_stage(character_id)
	if not _is_relationship_level_sufficient(current_stage, config.required_level):
		UIManager.show_notification("Need %s for %s Date!" % [config.required_level, date_type])
		return

	var ap_cost = int(config.ap_cost)
	if not PlayerData.has_ap(ap_cost):
		UIManager.show_notification("Not enough AP for %s Date!" % date_type)
		return

	is_date_active = true
	PlayerData.consume_ap(ap_cost)
	date_selected.emit(character_id, date_type, float(ap_cost), int(config.points))
	show_date_popup(date_type)

func show_date_popup(date_type: String) -> void:
	current_date_type = date_type
	date_title.text = date_type + " Date"
	_setup_date_image(date_type)
	_style_progress_bar()

	var layer = get_tree().root.get_node_or_null("DatePopupLayer")
	if not layer:
		layer = CanvasLayer.new()
		layer.name = "DatePopupLayer"
		layer.layer = 120
		get_tree().root.add_child(layer)

	if not is_instance_valid(_date_dim):
		_date_dim = ColorRect.new()
		_date_dim.name = "DateDim"
		_date_dim.color = Color(0.02, 0.01, 0.05, 0.85)
		_date_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_date_dim.mouse_filter = Control.MOUSE_FILTER_STOP
		layer.add_child(_date_dim)
		layer.move_child(_date_dim, 0)
	else:
		if _date_dim.get_parent() != layer:
			_date_dim.reparent(layer)
			layer.move_child(_date_dim, 0)
		_date_dim.visible = true
		_date_dim.modulate.a = 1.0

	if date_popup.get_parent() != layer:
		date_popup.reparent(layer)

	date_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	date_popup.offset_left = 0
	date_popup.offset_top = 0
	date_popup.offset_right = 0
	date_popup.offset_bottom = 0

	if date_progress_bar:
		date_progress_bar.value = 0
		date_progress_bar.visible = true

	popup_close_button.visible = false
	popup_close_button.disabled = true
	popup_close_button.modulate.a = 1.0

	date_popup.visible = true
	date_popup.modulate = Color(1, 1, 1, 0)
	date_popup.scale = Vector2(0.92, 0.92)

	var entrance = create_tween().set_parallel(true)
	entrance.tween_property(date_popup, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance.tween_property(date_popup, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_start_date_progress()

func _style_progress_bar() -> void:
	if not date_progress_bar:
		return
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.12, 0.28, 0.95)
	bg.set_corner_radius_all(12)
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(0.9, 0.5, 0.8, 0.6)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.55, 0.85, 0.95)
	fill.set_corner_radius_all(10)
	date_progress_bar.add_theme_stylebox_override("background", bg)
	date_progress_bar.add_theme_stylebox_override("fill", fill)

func _start_date_progress() -> void:
	if not date_progress_bar:
		_on_date_progress_finished()
		return
	if date_progress_tween and date_progress_tween.is_valid():
		date_progress_tween.kill()
	date_progress_bar.value = 0
	date_progress_bar.visible = true
	date_progress_tween = create_tween()
	date_progress_tween.tween_property(date_progress_bar, "value", 100.0, DATE_DURATION).set_trans(Tween.TRANS_LINEAR)
	date_progress_tween.tween_callback(_on_date_progress_finished)

func _on_date_progress_finished() -> void:
	# Points applied only when the date fully completes
	if PlayerData and current_date_type != "" and DATE_DATA.has(current_date_type):
		var points = int(DATE_DATA[current_date_type].get("points", 0))
		PlayerData.add_relationship_points(character_id, points)
		PlayerData.mark_date_completed(character_id, current_date_type.to_lower())

	if date_progress_bar:
		date_progress_bar.visible = false
	popup_close_button.visible = true
	popup_close_button.disabled = false
	popup_close_button.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(popup_close_button, "modulate:a", 1.0, 0.35)

func _setup_date_image(date_type: String) -> void:
	var path = str(character_data.get("date_images", {}).get(date_type.to_lower(), ""))
	if path != "" and ResourceLoader.exists(path):
		var texture = load(path)
		if texture:
			date_image.texture = texture
			return
	_create_modern_gradient_texture(date_type)

func _create_modern_gradient_texture(date_type: String) -> void:
	var gradient_texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	var color_schemes = {
		"Dinner": [Color("#FF6B9D"), Color("#C44569")],
		"Park": [Color("#A8E6CF"), Color("#56C596")],
		"Beach": [Color("#74B9FF"), Color("#0984E3")],
		"Home": [Color("#FD79A8"), Color("#E84393")],
		"Special": [Color("#FDCB6E"), Color("#E17055")],
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

# ---------- Close / cleanup ----------

func _on_popup_close_button_pressed() -> void:
	await _end_date_popup()
	update_date_button_availability()

func _end_date_popup() -> void:
	if date_progress_tween and date_progress_tween.is_valid():
		date_progress_tween.kill()
		date_progress_tween = null
	_clear_click_hearts()
	is_date_active = false

	var exit_tween = create_tween().set_parallel(true)
	exit_tween.tween_property(date_popup, "modulate:a", 0.0, 0.28)
	exit_tween.tween_property(date_popup, "scale", Vector2(0.92, 0.92), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await exit_tween.finished

	date_popup.visible = false
	date_popup.modulate = Color.WHITE
	date_popup.scale = Vector2.ONE
	if date_popup.get_parent() and date_popup.get_parent().name == "DatePopupLayer":
		date_popup.reparent(self)

	if is_instance_valid(_date_dim):
		_date_dim.visible = false

	if date_progress_bar:
		date_progress_bar.visible = false
		date_progress_bar.value = 0
	popup_close_button.visible = false
	popup_close_button.modulate.a = 1.0
	current_date_type = ""

func _cleanup_popup_layer(free_layer: bool = false) -> void:
	if date_progress_tween and date_progress_tween.is_valid():
		date_progress_tween.kill()
		date_progress_tween = null
	_clear_click_hearts()
	is_date_active = false
	if is_instance_valid(date_popup) and date_popup.get_parent() and date_popup.get_parent().name == "DatePopupLayer":
		date_popup.reparent(self)
		date_popup.visible = false
	if is_instance_valid(_date_dim):
		_date_dim.queue_free()
		_date_dim = null
	if free_layer:
		var layer = get_tree().root.get_node_or_null("DatePopupLayer")
		if layer:
			layer.queue_free()

func _disconnect_player_signals() -> void:
	if not PlayerData:
		return
	if PlayerData.player_relationship_stage_changed.is_connected(_on_player_relationship_stage_changed):
		PlayerData.player_relationship_stage_changed.disconnect(_on_player_relationship_stage_changed)
	if PlayerData.player_ap_changed.is_connected(_on_player_ap_changed):
		PlayerData.player_ap_changed.disconnect(_on_player_ap_changed)

func _on_close_menu_button_pressed() -> void:
	# Closing the whole menu mid-date cancels the date (AP already spent, no points)
	if is_date_active:
		_cleanup_popup_layer(false)
		if date_progress_bar:
			date_progress_bar.visible = false
			date_progress_bar.value = 0
		popup_close_button.visible = false
	_disconnect_player_signals()
	close_pressed.emit()

func show_panel_animated() -> void:
	visible = true
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func hide_panel_animated() -> void:
	_disconnect_player_signals()
	_cleanup_popup_layer(true)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
	queue_free()

func get_fade_tween() -> Tween:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	return tween
