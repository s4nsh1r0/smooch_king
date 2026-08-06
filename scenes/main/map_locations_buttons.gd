extends Control

@export var location_name: String = "Location Name"
@export var hover_color: Color = Color(1.0, 0.55, 0.75, 1.0)
@export var click_color: Color = Color(1.0, 0.4, 0.6, 0.9)

var hover_indicator: Control
var location_label: Label
var click_ripple: Control

var hover_tween: Tween
var click_tween: Tween
var _pulse_tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

	call_deferred("setup_effects")

func setup_effects() -> void:
	create_hover_indicator()
	create_location_label()

	if is_instance_valid(hover_indicator):
		hover_indicator.visible = false
	if is_instance_valid(location_label):
		location_label.visible = false


func create_hover_indicator() -> void:
	if is_instance_valid(hover_indicator):
		return

	hover_indicator = Control.new()
	hover_indicator.name = "HoverIndicator"
	hover_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_indicator.modulate.a = 0.0
	hover_indicator.z_index = 50
	hover_indicator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hover_indicator)

	# match the tooltip's rose/pink palette
	var color = Color(0.55, 0.22, 0.4, 0.95)
	var glow_color = Color(1.0, 0.7, 0.85, 0.7)
	var bracket_len = 20.0
	var thickness = 2.0

	var final_inset = 10.0
	var start_inset = 24.0     # slide-in starts further out
	var overshoot_inset = 6.0  # dips in past final_inset before settling
	var pulse_inset = 9.0      # continuous breathing target

	var w = size.x
	var h = size.y

	var corners = [
		{"fx": 1, "fy": 1},
		{"fx": -1, "fy": 1},
		{"fx": 1, "fy": -1},
		{"fx": -1, "fy": -1},
	]

	for c in corners:
		var bracket = _make_corner_bracket(bracket_len, thickness, color, glow_color)
		bracket.scale = Vector2(c.fx, c.fy)
		bracket.pivot_offset = Vector2.ZERO

		var start_pos = _corner_pivot(w, h, c.fx, c.fy, start_inset)
		var overshoot_pos = _corner_pivot(w, h, c.fx, c.fy, overshoot_inset)
		var final_pos = _corner_pivot(w, h, c.fx, c.fy, final_inset)
		var pulse_pos = _corner_pivot(w, h, c.fx, c.fy, pulse_inset)

		bracket.position = start_pos
		bracket.set_meta("overshoot_position", overshoot_pos)
		bracket.set_meta("final_position", final_pos)
		bracket.set_meta("pulse_position", pulse_pos)

		hover_indicator.add_child(bracket)



func _corner_pivot(w: float, h: float, fx: int, fy: int, inset: float) -> Vector2:
	var x = inset if fx > 0 else w - inset
	var y = inset if fy > 0 else h - inset
	return Vector2(x, y)


func _make_corner_bracket(arm_len: float, thickness: float, color: Color, glow_color: Color) -> Control:
	var bracket = Control.new()
	bracket.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(thickness / 2))
	style.shadow_color = glow_color
	style.shadow_size = 8

	var h_bar = Panel.new()
	h_bar.position = Vector2.ZERO
	h_bar.size = Vector2(arm_len, thickness)
	h_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h_bar.add_theme_stylebox_override("panel", style)
	bracket.add_child(h_bar)

	var v_bar = Panel.new()
	v_bar.position = Vector2.ZERO
	v_bar.size = Vector2(thickness, arm_len)
	v_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_bar.add_theme_stylebox_override("panel", style.duplicate())
	bracket.add_child(v_bar)

	return bracket


func show_hover_indicator() -> void:
	create_hover_indicator()
	hover_indicator.visible = true

	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hover_indicator, "modulate:a", 1.0, 0.15) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	for bracket in hover_indicator.get_children():
		var overshoot_pos = bracket.get_meta("overshoot_position")
		var final_pos = bracket.get_meta("final_position")

		var bracket_tween = create_tween()
		bracket_tween.tween_property(bracket, "position", overshoot_pos, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bracket_tween.tween_property(bracket, "position", final_pos, 0.1) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	tween.set_parallel(false)
	tween.tween_callback(_start_pulse)


func _start_pulse() -> void:
	if not is_instance_valid(hover_indicator):
		return

	# Stop existing tween if running
	if is_instance_valid(_pulse_tween) and _pulse_tween.is_valid():
		_pulse_tween.kill()

	var dur = 0.9
	_pulse_tween = create_tween().set_loops()

	# --- STEP 1: Breathe Outward + Fade Out ---
	_pulse_tween.tween_property(hover_indicator, "modulate:a", 0.65, dur)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	for bracket in hover_indicator.get_children():
		var pulse_pos = bracket.get_meta("pulse_position")
		# .parallel() attaches this to run AT THE SAME TIME as the fade above
		_pulse_tween.parallel().tween_property(bracket, "position", pulse_pos, dur)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# --- STEP 2: Breathe Inward + Fade Up (Runs automatically after Step 1 finishes) ---
	_pulse_tween.tween_property(hover_indicator, "modulate:a", 1.0, dur)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	for bracket in hover_indicator.get_children():
		var final_pos = bracket.get_meta("final_position")
		_pulse_tween.parallel().tween_property(bracket, "position", final_pos, dur)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func hide_hover_indicator() -> void:
	if not is_instance_valid(hover_indicator):
		return

	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	var tween = create_tween()
	tween.tween_property(hover_indicator, "modulate:a", 0.0, 0.15) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): hover_indicator.visible = false)


func create_location_label() -> void:
	if is_instance_valid(location_label):
		return

	location_label = Label.new()
	location_label.name = "LocationLabel"
	location_label.text = location_name
	location_label.add_theme_font_size_override("font_size", 20)
	location_label.add_theme_color_override("font_color", Color(1, 0.95, 0.97, 1))
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	location_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	location_label.modulate.a = 0.0
	location_label.z_index = 60

	var label_bg = StyleBoxFlat.new()
	label_bg.bg_color = Color(0.55, 0.22, 0.4, 0.95)
	label_bg.set_corner_radius_all(14)
	label_bg.content_margin_left = 18
	label_bg.content_margin_right = 18
	label_bg.content_margin_top = 8
	label_bg.content_margin_bottom = 8
	label_bg.border_width_left = 2
	label_bg.border_width_top = 2
	label_bg.border_width_right = 2
	label_bg.border_width_bottom = 2
	label_bg.border_color = Color(1.0, 0.7, 0.85, 0.7)
	label_bg.shadow_color = Color(0.4, 0.1, 0.25, 0.4)
	label_bg.shadow_size = 8

	location_label.add_theme_stylebox_override("normal", label_bg)
	add_child(location_label)

	location_label.position = Vector2(10, -45)

func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

	show_hover_indicator()

	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()

	hover_tween = create_tween().set_parallel(true)

	if is_instance_valid(location_label):
		location_label.visible = true
		hover_tween.tween_property(location_label, "modulate:a", 1.0, 0.2)
		hover_tween.tween_property(location_label, "scale", Vector2(1.05, 1.05), 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	hide_hover_indicator()

	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()

	hover_tween = create_tween().set_parallel(true)

	if is_instance_valid(location_label):
		hover_tween.tween_property(location_label, "modulate:a", 0.0, 0.2)
		hover_tween.tween_property(location_label, "scale", Vector2.ONE, 0.2)
		hover_tween.tween_callback(func(): location_label.visible = false).set_delay(0.2)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		create_click_ripple()

		if not is_instance_valid(LocationManager) or not is_instance_valid(GameManager):
			push_error("MapLocation: Missing LocationManager or GameManager")
			return

		var target_location_data = LocationManager.get_location_data_by_name(location_name)
		if target_location_data.is_empty():
			push_error("MapLocation: No data found for location: " + location_name)
			return

		var target_scene_path = target_location_data.get("scene_path", "")
		if target_scene_path.is_empty():
			push_error("MapLocation: Scene path not found for location: " + location_name)
			return

		LocationManager.set_current_location(target_location_data)

		await get_tree().create_timer(0.12).timeout
		GameManager.change_to_scene(target_scene_path)

func create_click_ripple() -> void:
	if is_instance_valid(click_ripple):
		click_ripple.queue_free()

	var ripple = Panel.new()
	ripple.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ripple.z_index = 70

	var style = StyleBoxFlat.new()
	style.bg_color = Color(click_color.r, click_color.g, click_color.b, 0.7)
	style.set_corner_radius_all(30)

	ripple.add_theme_stylebox_override("panel", style)
	ripple.size = Vector2(24, 24)
	ripple.position = get_local_mouse_position() - Vector2(12, 12)

	add_child(ripple)
	click_ripple = ripple

	var tween = create_tween().set_parallel(true)
	tween.tween_property(ripple, "scale", Vector2(4, 4), 0.35)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.35)
	tween.tween_callback(ripple.queue_free).set_delay(0.35)
