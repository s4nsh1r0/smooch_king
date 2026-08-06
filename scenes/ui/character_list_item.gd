extends Button
class_name CharacterListItem

signal character_selected(character_data: Dictionary)

const MOOD_DATA := {
	"angry": {
		"label": "Angry",
		"multiplier": 0.0,
		"color": Color(0.95, 0.30, 0.36, 1.0),
		"background": Color(0.34, 0.10, 0.15, 0.96)
	},
	"upset": {
		"label": "Upset",
		"multiplier": 0.5,
		"color": Color(0.95, 0.58, 0.32, 1.0),
		"background": Color(0.34, 0.19, 0.10, 0.96)
	},
	"neutral": {
		"label": "Neutral",
		"multiplier": 1.0,
		"color": Color(0.72, 0.75, 0.86, 1.0),
		"background": Color(0.20, 0.20, 0.30, 0.96)
	},
	"happy": {
		"label": "Happy",
		"multiplier": 1.5,
		"color": Color(0.42, 0.94, 0.66, 1.0),
		"background": Color(0.10, 0.31, 0.22, 0.96)
	},
	"excited": {
		"label": "Excited",
		"multiplier": 2.0,
		"color": Color(1.00, 0.76, 0.32, 1.0),
		"background": Color(0.36, 0.25, 0.08, 0.96)
	}
}

@onready var character_name_label: Label = %CharacterNameLabel
@onready var character_details_label: Label = %CharacterDetailsLabel
@onready var mood_panel: PanelContainer = %MoodPanel
@onready var mood_dot: ColorRect = %MoodDot
@onready var mood_label: Label = %MoodLabel
@onready var mood_multiplier_label: Label = %MoodMultiplierLabel
@onready var lock_icon: Label = %LockIcon
@onready var accent_line: ColorRect = %AccentLine

var character_data: Dictionary = {}
var current_mood: String = "neutral"
var custom_tooltip: PanelContainer = null
var hover_tween: Tween = null


func _ready() -> void:
	pressed.connect(_on_button_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_mood_visuals("neutral")


func _exit_tree() -> void:
	_hide_custom_tooltip()
	_kill_hover_tween()


func set_character_data(
	data: Dictionary,
	revealed: bool,
	_unlock_text: String = ""
) -> void:
	character_data = data

	if mouse_entered.is_connected(_on_locked_hover_enter):
		mouse_entered.disconnect(_on_locked_hover_enter)

	if revealed:
		_apply_revealed_character(data)
	else:
		_apply_locked_character(data)


func set_mood(mood_name: String) -> void:
	current_mood = mood_name.to_lower()

	if not MOOD_DATA.has(current_mood):
		current_mood = "neutral"

	_apply_mood_visuals(current_mood)


func get_mood_multiplier() -> float:
	var mood: Dictionary = MOOD_DATA.get(current_mood, MOOD_DATA["neutral"])
	return float(mood.get("multiplier", 1.0))


func _apply_revealed_character(data: Dictionary) -> void:
	var character_name := str(data.get("name", "Unknown"))
	var age := str(data.get("age", "—"))
	var profession := str(data.get("profession", "Unknown profession"))

	character_name_label.text = character_name
	character_details_label.text = "%s  •  %s" % [age, profession]

	lock_icon.hide()
	mood_panel.show()

	disabled = false
	modulate = Color.WHITE
	tooltip_text = ""

	# This already supports mood data once it is added to the character state.
	set_mood(str(data.get("mood", "neutral")))


func _apply_locked_character(_data: Dictionary) -> void:
	character_name_label.text = "Unknown Character"
	character_details_label.text = "Meet the requirements to reveal"

	lock_icon.show()
	mood_panel.hide()

	disabled = true
	modulate = Color(0.72, 0.68, 0.78, 0.92)

	if not mouse_entered.is_connected(_on_locked_hover_enter):
		mouse_entered.connect(_on_locked_hover_enter)


func _apply_mood_visuals(mood_name: String) -> void:
	if not is_node_ready():
		return

	var mood: Dictionary = MOOD_DATA.get(mood_name, MOOD_DATA["neutral"])
	var mood_color: Color = mood.get("color", Color.WHITE)
	var mood_background: Color = mood.get(
		"background",
		Color(0.20, 0.20, 0.30, 0.96)
	)
	var multiplier := float(mood.get("multiplier", 1.0))

	mood_dot.color = mood_color
	mood_label.text = str(mood.get("label", "Neutral"))
	mood_label.add_theme_color_override("font_color", mood_color)
	mood_multiplier_label.text = "×%s" % _format_multiplier(multiplier)
	mood_multiplier_label.add_theme_color_override(
		"font_color",
		mood_color.lightened(0.12)
	)

	var mood_style := StyleBoxFlat.new()
	mood_style.bg_color = mood_background
	mood_style.border_color = mood_color.darkened(0.10)
	mood_style.set_border_width_all(1)
	mood_style.set_corner_radius_all(12)
	mood_style.content_margin_left = 9
	mood_style.content_margin_right = 9
	mood_style.content_margin_top = 4
	mood_style.content_margin_bottom = 4
	mood_panel.add_theme_stylebox_override("panel", mood_style)


func _format_multiplier(value: float) -> String:
	if is_equal_approx(value, floorf(value)):
		return "%.0f" % value
	return "%.1f" % value


func _on_button_pressed() -> void:
	if disabled:
		return

	character_selected.emit(character_data)


func _on_mouse_entered() -> void:
	if disabled:
		return

	_kill_hover_tween()

	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.set_trans(Tween.TRANS_CUBIC)
	hover_tween.set_ease(Tween.EASE_OUT)

	hover_tween.tween_property(
		accent_line,
		"modulate:a",
		1.0,
		0.18
	)
	hover_tween.tween_property(
		mood_panel,
		"modulate",
		Color(1.08, 1.08, 1.08, 1.0),
		0.18
	)
	hover_tween.tween_property(
		character_name_label,
		"position:x",
		3.0,
		0.18
	)


func _on_mouse_exited() -> void:
	_hide_custom_tooltip()
	_kill_hover_tween()

	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.set_trans(Tween.TRANS_CUBIC)
	hover_tween.set_ease(Tween.EASE_OUT)

	hover_tween.tween_property(
		accent_line,
		"modulate:a",
		0.35,
		0.16
	)
	hover_tween.tween_property(
		mood_panel,
		"modulate",
		Color.WHITE,
		0.16
	)
	hover_tween.tween_property(
		character_name_label,
		"position:x",
		0.0,
		0.16
	)


func _kill_hover_tween() -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = null


func _on_locked_hover_enter() -> void:
	if disabled:
		_show_custom_tooltip(
			_build_requirements_tooltip(character_data)
		)


func _build_requirements_tooltip(data: Dictionary) -> String:
	var stats_required = data.get("stats_required", {})

	if not stats_required is Dictionary or stats_required.is_empty():
		return "[b][color=#f0c0ff]Requirements[/color][/b]\nUnknown"

	var lines := PackedStringArray([
		"[b][color=#f0c0ff]Requirements[/color][/b]"
	])

	for stat_name in stats_required:
		var required := int(stats_required[stat_name])
		var current := (
			int(PlayerData.get_stat(str(stat_name)))
			if PlayerData
			else 0
		)

		if current >= required:
			lines.append(
				"[color=#70ff90]✓ %s: %d / %d[/color]"
				% [str(stat_name).capitalize(), current, required]
			)
		else:
			lines.append(
				"[color=#ff7070]✗ %s: %d / %d[/color]"
				% [str(stat_name).capitalize(), current, required]
			)

	return "\n".join(lines)


func _show_custom_tooltip(content: String) -> void:
	_hide_custom_tooltip()

	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.name = "CharacterRequirementsTooltipLayer"
	get_tree().root.add_child(layer)

	custom_tooltip = PanelContainer.new()
	custom_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_tooltip.custom_minimum_size = Vector2(240, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.10, 0.24, 0.98)
	style.border_color = Color(0.92, 0.66, 1.0, 0.90)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.10, 0.03, 0.18, 0.65)
	style.shadow_size = 10
	custom_tooltip.add_theme_stylebox_override("panel", style)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(220, 0)
	label.add_theme_font_size_override("normal_font_size", 14)
	label.text = content
	custom_tooltip.add_child(label)

	layer.add_child(custom_tooltip)
	custom_tooltip.set_meta("tooltip_layer", layer)

	await get_tree().process_frame

	if not is_instance_valid(custom_tooltip):
		return

	var item_rect := get_global_rect()
	var tooltip_size := custom_tooltip.size
	var tooltip_position := Vector2(
		item_rect.position.x
			+ (item_rect.size.x - tooltip_size.x) * 0.5,
		item_rect.position.y - tooltip_size.y - 8
	)
	var viewport_size := get_viewport().get_visible_rect().size

	tooltip_position.x = clampf(
		tooltip_position.x,
		8.0,
		viewport_size.x - tooltip_size.x - 8.0
	)
	tooltip_position.y = maxf(tooltip_position.y, 8.0)
	custom_tooltip.global_position = tooltip_position


func _hide_custom_tooltip() -> void:
	if custom_tooltip and is_instance_valid(custom_tooltip):
		if custom_tooltip.has_meta("tooltip_layer"):
			var layer = custom_tooltip.get_meta("tooltip_layer")
			if is_instance_valid(layer):
				layer.queue_free()
		else:
			custom_tooltip.queue_free()

	custom_tooltip = null
