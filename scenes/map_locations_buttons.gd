extends Control

@export var location_name: String = "Location Name"
@export var hover_color: Color = Color.WHITE
@export var click_color: Color = Color.YELLOW
@export var debug_show_hitbox: bool = false  # Only show when needed

var debug_hitbox_rect: ColorRect = null
@onready var hover_indicator: Control
@onready var location_label: Label
var click_ripple: Control # Created dynamically

var hover_tween: Tween
var click_tween: Tween

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	call_deferred("setup_effects")
	visible = true

func setup_effects():
	create_hover_indicator()
	create_location_label()
	
	if is_instance_valid(hover_indicator):
		hover_indicator.visible = false
		
	if is_instance_valid(location_label):
		location_label.visible = false

	# Debug hitbox - only when explicitly enabled
	if debug_show_hitbox:
		if not is_instance_valid(debug_hitbox_rect):
			debug_hitbox_rect = ColorRect.new()
			debug_hitbox_rect.name = "DebugHitbox"
			debug_hitbox_rect.color = Color(1, 0, 0, 0.3)
			debug_hitbox_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(debug_hitbox_rect)
			debug_hitbox_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if is_instance_valid(debug_hitbox_rect):
			debug_hitbox_rect.visible = true

func create_hover_indicator():
	if not is_instance_valid(hover_indicator):
		hover_indicator = Control.new()
		hover_indicator.name = "HoverIndicator"
		hover_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hover_indicator.modulate = Color(1, 1, 1, 0)
		hover_indicator.z_index = 100
		add_child(hover_indicator)
		hover_indicator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		var corner_size = 20
		var corner_thickness = 3
		
		var tl_corner = create_corner_indicator(Vector2.ZERO, corner_size, corner_thickness, true, true)
		hover_indicator.add_child(tl_corner)
		
		var tr_corner = create_corner_indicator(Vector2(size.x - corner_size, 0), corner_size, corner_thickness, true, false)
		hover_indicator.add_child(tr_corner)
		
		var bl_corner = create_corner_indicator(Vector2(0, size.y - corner_size), corner_size, corner_thickness, false, true)
		hover_indicator.add_child(bl_corner)
		
		var br_corner = create_corner_indicator(Vector2(size.x - corner_size, size.y - corner_size), corner_size, corner_thickness, false, false)
		hover_indicator.add_child(br_corner)

func create_corner_indicator(pos: Vector2, size_val: int, thickness: int, top: bool, left: bool) -> Control:
	var corner = Control.new()
	corner.position = pos
	corner.size = Vector2(size_val, size_val)
	
	var h_line = ColorRect.new()
	h_line.color = hover_color
	h_line.size = Vector2(size_val, thickness)
	h_line.position = Vector2(0, 0 if top else size_val - thickness)
	corner.add_child(h_line)
	
	var v_line = ColorRect.new()
	v_line.color = hover_color
	v_line.size = Vector2(thickness, size_val)
	v_line.position = Vector2(0 if left else size_val - thickness, 0)
	corner.add_child(v_line)
	
	return corner

func create_location_label():
	if not is_instance_valid(location_label):
		location_label = Label.new()
		location_label.name = "LocationLabel"
		location_label.text = location_name
		location_label.add_theme_font_size_override("font_size", 22)
		location_label.add_theme_color_override("font_color", Color.WHITE)
		location_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.2, 0.8, 0.8))
		location_label.add_theme_constant_override("shadow_offset_x", 2)
		location_label.add_theme_constant_override("shadow_offset_y", 2)
		location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		location_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		location_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		location_label.modulate = Color(1, 1, 1, 0)
		location_label.z_index = 101
		
		var label_bg = StyleBoxFlat.new()
		label_bg.bg_color = Color(0.2, 0.3, 0.6, 0.9)
		label_bg.corner_radius_top_left = 12
		label_bg.corner_radius_top_right = 12
		label_bg.corner_radius_bottom_left = 12
		label_bg.corner_radius_bottom_right = 12
		label_bg.content_margin_left = 16
		label_bg.content_margin_right = 16
		label_bg.content_margin_top = 8
		label_bg.content_margin_bottom = 8
		label_bg.border_width_left = 2
		label_bg.border_width_right = 2
		label_bg.border_width_top = 2
		label_bg.border_width_bottom = 2
		label_bg.border_color = Color(0.4, 0.7, 1.0, 0.8)
		
		location_label.add_theme_stylebox_override("normal", label_bg)
		add_child(location_label)
		
		location_label.anchor_left = 0.0
		location_label.anchor_right = 0.0
		location_label.anchor_top = 0.0
		location_label.anchor_bottom = 0.0

		var margin_x = 5
		var margin_y = 5
		location_label.offset_left = margin_x
		location_label.offset_top = margin_y
		location_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		location_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _on_mouse_entered():
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_parallel(true)
	
	if is_instance_valid(hover_indicator):
		hover_indicator.visible = true
		hover_tween.tween_property(hover_indicator, "modulate:a", 1.0, 0.2)
	
	if is_instance_valid(location_label):
		location_label.visible = true
		hover_tween.tween_property(location_label, "modulate:a", 1.0, 0.2)
		hover_tween.tween_property(location_label, "scale", Vector2(1.05, 1.05), 0.2)

func _on_mouse_exited():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_parallel(true)
	
	if is_instance_valid(hover_indicator):
		hover_tween.tween_property(hover_indicator, "modulate:a", 0.0, 0.2)
		hover_tween.tween_callback(func(): hover_indicator.visible = false).set_delay(0.2)
	
	if is_instance_valid(location_label):
		hover_tween.tween_property(location_label, "modulate:a", 0.0, 0.2)
		hover_tween.tween_callback(func(): location_label.visible = false).set_delay(0.2)
		hover_tween.tween_property(location_label, "scale", Vector2(1.0, 1.0), 0.2)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		create_click_ripple()
		
		if not is_instance_valid(LocationManager):
			push_error("MapLocation: LocationManager autoload not found!")
			return
		if not is_instance_valid(GameManager):
			push_error("MapLocation: GameManager autoload not found!")
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
		
		await get_tree().create_timer(0.1).timeout
		GameManager.change_to_scene(target_scene_path)

func create_click_ripple():
	if is_instance_valid(click_ripple):
		click_ripple.queue_free()
		click_ripple = null

	var ripple_panel = Panel.new()
	ripple_panel.name = "ClickRipple"
	ripple_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ripple_panel.z_index = 102
	
	var circle_style = StyleBoxFlat.new()
	circle_style.bg_color = Color(click_color.r, click_color.g, click_color.b, 0.8)
	circle_style.corner_radius_top_left = 10
	circle_style.corner_radius_top_right = 10
	circle_style.corner_radius_bottom_left = 10
	circle_style.corner_radius_bottom_right = 10
	
	ripple_panel.add_theme_stylebox_override("panel", circle_style)
	ripple_panel.size = Vector2(20, 20)
	ripple_panel.position = get_local_mouse_position() - Vector2(10, 10)
	
	add_child(ripple_panel)
	click_ripple = ripple_panel

	click_tween = create_tween().set_parallel(true)
	click_tween.tween_property(ripple_panel, "scale", Vector2(3, 3), 0.3)
	click_tween.tween_property(ripple_panel, "modulate:a", 0.0, 0.3)
	click_tween.tween_callback(ripple_panel.queue_free).set_delay(0.3)
