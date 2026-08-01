extends PanelContainer

@onready var character_list_container: VBoxContainer = %ListContent
@onready var title_label: Label = %TitleLabel
@onready var floating_hearts: Control = %FloatingHearts

const CHARACTER_LIST_ITEM_SCENE = preload("res://scenes/ui/character_list_item.tscn")

@export var fade_duration: float = 0.15

signal request_character_card_details(character_data: Dictionary)

var current_fade_tween: Tween = null
var hearts: Array[Control] = []
var heart_tweens: Array[Tween] = []

func _ready() -> void:
	modulate.a = 0.0
	visible = false
	mouse_filter = MOUSE_FILTER_STOP

	if not is_instance_valid(character_list_container):
		printerr("SocialHubPanel: ListContent not found")
	if not is_instance_valid(title_label):
		printerr("SocialHubPanel: TitleLabel not found")

	_setup_modern_styling()

	if LocationManager and not LocationManager.location_data_updated.is_connected(_on_player_location_changed):
		LocationManager.location_data_updated.connect(_on_player_location_changed)
	if PlayerData and not PlayerData.player_stat_changed.is_connected(_on_player_stat_changed):
		PlayerData.player_stat_changed.connect(_on_player_stat_changed)

	tree_exiting.connect(_cleanup_on_exit)

func _setup_modern_styling() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.32, 0.18, 0.42, 0.88)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.95, 0.7, 1.0, 0.9)
	panel_style.set_corner_radius_all(22)
	panel_style.shadow_color = Color(0.5, 0.2, 0.7, 0.5)
	panel_style.shadow_size = 16
	panel_style.shadow_offset = Vector2(0, 6)
	panel_style.content_margin_left = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_right = 20
	panel_style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", panel_style)

	if title_label:
		title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 1.0, 1))
		title_label.add_theme_color_override("font_shadow_color", Color(0.6, 0.3, 0.8, 0.6))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)

func show_panel_animated() -> void:
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()

	modulate.a = 0.0
	call_deferred("update_character_list")
	await get_tree().process_frame
	visible = true
	_create_floating_hearts()

	current_fade_tween = create_tween()
	current_fade_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	current_fade_tween.tween_callback(func(): current_fade_tween = null)

func hide_panel_animated() -> void:
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()

	current_fade_tween = create_tween()
	current_fade_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	current_fade_tween.tween_callback(func():
		visible = false
		current_fade_tween = null
		_clear_hearts()
		call_deferred("_clear_character_list_content")
	)

func get_fade_tween() -> Tween:
	return current_fade_tween

func update_character_list() -> void:
	_clear_character_list_content()

	if not PlayerData or not LocationManager:
		if title_label:
			title_label.text = "Error: Missing Data"
		return

	var current_location_data = LocationManager.get_current_location()
	if not current_location_data is Dictionary or current_location_data.is_empty():
		if title_label:
			title_label.text = "No Location Data"
		return

	var location_name = str(current_location_data.get("name", "Unknown Location"))
	title_label.text = "People in %s" % location_name

	var characters_in_location = LocationManager.get_characters_for_location(location_name)
	if not characters_in_location is Array:
		title_label.text = "Error: Invalid Character Data"
		return

	if characters_in_location.is_empty():
		var no_people_label = Label.new()
		no_people_label.text = "No one here to meet yet."
		no_people_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_people_label.add_theme_font_size_override("font_size", 18)
		no_people_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.9, 0.8))
		character_list_container.add_child(no_people_label)
		return

	for character_data in characters_in_location:
		if not character_data is Dictionary:
			continue
		var item = CHARACTER_LIST_ITEM_SCENE.instantiate()
		if not is_instance_valid(item):
			continue
		character_list_container.add_child(item)
		_update_character_item_display(item, character_data)
		if item.has_signal("character_selected") and not item.character_selected.is_connected(_on_character_list_item_selected):
			item.character_selected.connect(_on_character_list_item_selected)

func _update_character_item_display(character_item: Node, character_data: Dictionary) -> void:
	var requirements_met := true
	var stats_required = character_data.get("stats_required", {})
	if stats_required is Dictionary:
		for stat_name in stats_required:
			if PlayerData.get_stat(str(stat_name)) < float(stats_required[stat_name]):
				requirements_met = false
				break

	if character_item.has_method("set_character_data"):
		character_item.set_character_data(character_data, requirements_met)

func _clear_character_list_content() -> void:
	if not is_instance_valid(character_list_container):
		return
	for child in character_list_container.get_children():
		child.queue_free()

func _on_player_location_changed(_new_location_data: Dictionary) -> void:
	if visible:
		update_character_list()

func _on_player_stat_changed(_stat_name: String, _new_value: float) -> void:
	if not visible:
		return
	for child in character_list_container.get_children():
		if child.has_method("set_character_data") and "character_data" in child:
			_update_character_item_display(child, child.character_data)

func _on_character_list_item_selected(character_data: Dictionary) -> void:
	request_character_card_details.emit(character_data)

# ---------- Floating hearts ----------

func _create_floating_hearts() -> void:
	if not is_instance_valid(floating_hearts):
		return
	_clear_hearts()
	await get_tree().process_frame
	if not is_instance_valid(floating_hearts):
		return

	var panel_size = size
	if panel_size.x < 50 or panel_size.y < 50:
		panel_size = Vector2(400, 600)

	for i in range(7):
		var heart = Label.new()
		heart.text = "♥"
		heart.add_theme_font_size_override("font_size", randi_range(16, 26))
		heart.add_theme_color_override("font_color", Color(1.0, 0.55, 0.75, 1.0))
		heart.modulate.a = 0.0
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart.position = Vector2(
			randf_range(20, panel_size.x - 40),
			randf_range(30, panel_size.y - 50)
		)
		floating_hearts.add_child(heart)
		hearts.append(heart)
		_animate_heart(heart, i)

func _animate_heart(heart: Control, index: int) -> void:
	if not is_instance_valid(heart):
		return
	var tween = create_tween()
	tween.set_loops()
	heart_tweens.append(tween)

	var start_pos = heart.position
	var float_dist = 16.0 + index * 3.0
	var duration = 2.6 + index * 0.35

	tween.tween_property(heart, "modulate:a", 0.65, 0.7)
	tween.tween_property(heart, "position:y", start_pos.y - float_dist, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(heart, "position:y", start_pos.y + float_dist * 0.5, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(heart, "modulate:a", 0.3, duration * 0.5)
	tween.parallel().tween_property(heart, "modulate:a", 0.7, duration * 0.5)

func _clear_hearts() -> void:
	for tween in heart_tweens:
		if is_instance_valid(tween):
			tween.kill()
	heart_tweens.clear()
	for heart in hearts:
		if is_instance_valid(heart):
			heart.queue_free()
	hearts.clear()

func _cleanup_on_exit() -> void:
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()
	_clear_hearts()
	if LocationManager and LocationManager.location_data_updated.is_connected(_on_player_location_changed):
		LocationManager.location_data_updated.disconnect(_on_player_location_changed)
	if PlayerData and PlayerData.player_stat_changed.is_connected(_on_player_stat_changed):
		PlayerData.player_stat_changed.disconnect(_on_player_stat_changed)
