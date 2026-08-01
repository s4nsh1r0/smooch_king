extends Button
class_name CharacterListItem

@onready var character_name_label: Label = %CharacterNameLabel
@onready var unlock_info_label: Label = %UnlockInfoLabel
@onready var status_icon: Label = %StatusIcon
@onready var progress_bars_container: VBoxContainer = %ProgressBarsContainer

signal character_selected(character_data: Dictionary)

var character_data: Dictionary = {}
var is_hovering: bool = false
var underline_top: ColorRect = null
var underline_bottom: ColorRect = null
var underline_tween: Tween = null
var custom_tooltip: PanelContainer = null

func _ready() -> void:
	pressed.connect(_on_button_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if unlock_info_label:
		unlock_info_label.hide()
	if progress_bars_container:
		progress_bars_container.hide()

	_create_underlines()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_underline_positions()

func _exit_tree() -> void:
	_hide_custom_tooltip()
	if underline_tween and underline_tween.is_valid():
		underline_tween.kill()

func set_character_data(data: Dictionary, revealed: bool, _unlock_text: String = "") -> void:
	character_data = data
	var character_name = str(data.get("name", "Unknown Character"))

	if mouse_entered.is_connected(_on_locked_hover_enter):
		mouse_entered.disconnect(_on_locked_hover_enter)
	if mouse_exited.is_connected(_hide_custom_tooltip):
		mouse_exited.disconnect(_hide_custom_tooltip)

	if revealed:
		character_name_label.text = character_name
		if status_icon:
			status_icon.hide()
		disabled = false
		modulate = Color.WHITE
		custom_minimum_size.y = 56
		tooltip_text = ""
	else:
		character_name_label.text = "???"
		if status_icon:
			status_icon.text = "🔒"
			status_icon.modulate = Color(1.0, 0.7, 0.8, 0.9)
			status_icon.show()
		disabled = true
		modulate = Color(0.75, 0.7, 0.8, 0.9)
		custom_minimum_size.y = 56
		mouse_entered.connect(_on_locked_hover_enter)
		mouse_exited.connect(_hide_custom_tooltip)

func _on_locked_hover_enter() -> void:
	if disabled:
		_show_custom_tooltip(_build_requirements_tooltip(character_data))

func _build_requirements_tooltip(data: Dictionary) -> String:
	var stats_required = data.get("stats_required", {})
	if not stats_required is Dictionary or stats_required.is_empty():
		return "[b][color=#f0c0ff]Requirements[/color][/b]\nUnknown"

	var lines: PackedStringArray = ["[b][color=#f0c0ff]Requirements[/color][/b]"]
	for stat_name in stats_required:
		var required = int(stats_required[stat_name])
		var current = int(PlayerData.get_stat(str(stat_name))) if PlayerData else 0
		if current >= required:
			lines.append("[color=#70ff90]✓ %s: %d / %d[/color]" % [str(stat_name).capitalize(), current, required])
		else:
			lines.append("[color=#ff7070]✗ %s: %d / %d[/color]" % [str(stat_name).capitalize(), current, required])
	return "\n".join(lines)

func _show_custom_tooltip(content: String) -> void:
	_hide_custom_tooltip()

	var layer = CanvasLayer.new()
	layer.layer = 128
	layer.name = "CharTooltipLayer"
	get_tree().root.add_child(layer)

	custom_tooltip = PanelContainer.new()
	custom_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_tooltip.custom_minimum_size = Vector2(240, 0)

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
	style.shadow_color = Color(0.3, 0.1, 0.45, 0.5)
	style.shadow_size = 10
	custom_tooltip.add_theme_stylebox_override("panel", style)

	var label = RichTextLabel.new()
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

	var rect = get_global_rect()
	var tip_size = custom_tooltip.size
	var pos = Vector2(
		rect.position.x + (rect.size.x - tip_size.x) * 0.5,
		rect.position.y - tip_size.y - 8
	)
	var screen = get_viewport().get_visible_rect().size
	pos.x = clampf(pos.x, 8, screen.x - tip_size.x - 8)
	pos.y = maxf(pos.y, 8)
	custom_tooltip.global_position = pos

func _hide_custom_tooltip() -> void:
	if custom_tooltip and is_instance_valid(custom_tooltip):
		if custom_tooltip.has_meta("tooltip_layer"):
			var layer = custom_tooltip.get_meta("tooltip_layer")
			if is_instance_valid(layer):
				layer.queue_free()
		elif is_instance_valid(custom_tooltip):
			custom_tooltip.queue_free()
	custom_tooltip = null

# ---------- Underline hover ----------

func _create_underlines() -> void:
	underline_top = ColorRect.new()
	underline_top.color = Color(1.0, 0.55, 0.85, 0.95)
	underline_top.size = Vector2(0, 2)
	underline_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underline_top.z_index = 10
	add_child(underline_top)

	underline_bottom = ColorRect.new()
	underline_bottom.color = Color(0.75, 0.45, 1.0, 0.95)
	underline_bottom.size = Vector2(0, 2)
	underline_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underline_bottom.z_index = 10
	add_child(underline_bottom)

	_update_underline_positions()

func _update_underline_positions() -> void:
	if not is_instance_valid(underline_top) or not is_instance_valid(underline_bottom):
		return
	var w = size.x
	var h = size.y
	underline_top.position = Vector2(w * 0.5, 5)
	underline_top.size = Vector2(0, 2)
	underline_bottom.position = Vector2(w * 0.5, h - 7)
	underline_bottom.size = Vector2(0, 2)

func _on_mouse_entered() -> void:
	if disabled:
		return
	is_hovering = true
	_animate_hover_enter()

func _on_mouse_exited() -> void:
	is_hovering = false
	_animate_hover_exit()

func _animate_hover_enter() -> void:
	if underline_tween and underline_tween.is_valid():
		underline_tween.kill()
	_update_underline_positions()

	var target_width = maxf(size.x - 20, 0)
	var start_x = 10.0
	underline_tween = create_tween().set_parallel(true)
	underline_tween.tween_property(underline_top, "size:x", target_width, 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	underline_tween.tween_property(underline_top, "position:x", start_x, 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	underline_tween.tween_property(underline_bottom, "size:x", target_width, 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	underline_tween.tween_property(underline_bottom, "position:x", start_x, 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	underline_tween.tween_property(self, "modulate", Color(1.12, 1.05, 1.18, 1.0), 0.2)

func _animate_hover_exit() -> void:
	if underline_tween and underline_tween.is_valid():
		underline_tween.kill()
	var center_x = size.x * 0.5
	underline_tween = create_tween().set_parallel(true)
	underline_tween.tween_property(underline_top, "size:x", 0.0, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	underline_tween.tween_property(underline_top, "position:x", center_x, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	underline_tween.tween_property(underline_bottom, "size:x", 0.0, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	underline_tween.tween_property(underline_bottom, "position:x", center_x, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	underline_tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func _on_button_pressed() -> void:
	if disabled:
		return
	character_selected.emit(character_data)
