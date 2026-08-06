extends Control

@onready var pages_container: HBoxContainer = %PagesContainer
@onready var stats_label: Label = %Stats
@onready var detail_panel: Panel = %CharacterDetailPanel
@onready var character_name_label: Label = %CharacterName
@onready var details_container: VBoxContainer = %DetailsContainer
@onready var left_arrow: Button = %LeftArrow
@onready var right_arrow: Button = %RightArrow
@onready var page_indicator: Label = %PageIndicator

var current_page: int = 0
var hover_tweens: Dictionary = {}
var _button_original_positions := {}

const MAX_RELATIONSHIP_POINTS = 1500
const PLACEHOLDER_TEXTURE = preload("res://assets/images/placeholder_portrait.png")
const DATE_PLACEHOLDER_TEXTURE = preload("res://assets/images/placeholder_date.png")
const SILHOUETTE_SHADER = preload("res://shaders/locked_silhouette.gdshader")

const DATE_ORDER = ["dinner", "park", "beach", "home", "special"]
const DATE_DISPLAY_NAMES = {
	"dinner": "Dinner",
	"park": "Park",
	"beach": "Beach",
	"home": "Home",
	"special": "Special"
}

const LOCATION_ICONS := {
	"cafeteria": "☕",
	"library": "📚",
	"park": "🌳",
	"beach": "🌊",
	"gym": "🏋",
	"night club": "♬",
	"nightclub": "♬",
	"job center": "💼",
	"home": "⌂",
	"restaurant": "🍽",
	"mall": "🛍"
}

const STAGE_COLORS := {
	"Stranger": Color(0.66, 0.54, 0.78, 1.0),
	"Acquaintance": Color(0.65, 0.60, 0.96, 1.0),
	"Friend": Color(0.40, 0.76, 1.0, 1.0),
	"Good Friend": Color(0.38, 0.92, 0.70, 1.0),
	"Crush": Color(1.0, 0.46, 0.80, 1.0),
	"Dating": Color(1.0, 0.38, 0.56, 1.0),
	"Soulmate": Color(1.0, 0.80, 0.30, 1.0)
}

const MOOD_COLORS := {
	"angry": Color(0.95, 0.30, 0.36, 1.0),
	"upset": Color(0.95, 0.58, 0.32, 1.0),
	"neutral": Color(0.72, 0.75, 0.86, 1.0),
	"happy": Color(0.42, 0.94, 0.66, 1.0),
	"excited": Color(1.0, 0.76, 0.32, 1.0)
}

func _ready() -> void:
	visible = false
	left_arrow.pressed.connect(_on_left_arrow_pressed)
	right_arrow.pressed.connect(_on_right_arrow_pressed)
	
	populate_love_book()
	update_stats()
	update_navigation()
	call_deferred("_hide_scrollbars")

	if CharacterMoodManager and not CharacterMoodManager.mood_changed.is_connected(_on_mood_changed):
		CharacterMoodManager.mood_changed.connect(_on_mood_changed)

func _hide_scrollbars() -> void:
	var scroll_containers = find_children("*", "ScrollContainer", true, false)
	for scroll_container in scroll_containers:
		if scroll_container is ScrollContainer:
			var v_scrollbar = scroll_container.get_v_scroll_bar()
			var h_scrollbar = scroll_container.get_h_scroll_bar()
			if v_scrollbar:
				v_scrollbar.modulate.a = 0.0
			if h_scrollbar:
				h_scrollbar.modulate.a = 0.0

func _exit_tree() -> void:
	for tween in hover_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	hover_tweens.clear()
	_button_original_positions.clear()

	if CharacterMoodManager and CharacterMoodManager.mood_changed.is_connected(_on_mood_changed):
		CharacterMoodManager.mood_changed.disconnect(_on_mood_changed)


func _on_mood_changed(
	_character_id: String,
	_old_mood: String,
	_new_mood: String
) -> void:
	if visible:
		populate_love_book()
		update_navigation()


func _get_stage_name(character_id: String) -> String:
	if PlayerData:
		return PlayerData.get_relationship_stage(character_id)
	return "Stranger"


func _get_stage_color(stage_name: String) -> Color:
	return STAGE_COLORS.get(stage_name, STAGE_COLORS["Stranger"])


func _get_mood(character_data: Dictionary) -> String:
	var character_id := str(character_data.get("id", ""))
	if CharacterMoodManager and not character_id.is_empty():
		CharacterMoodManager.register_character(character_data)
		return CharacterMoodManager.get_mood(character_id)
	return "neutral"


func _get_mood_display_name(mood_name: String) -> String:
	return mood_name.capitalize()


func _get_location_icon(location: String) -> String:
	return str(LOCATION_ICONS.get(location.to_lower(), "♥"))


func _count_completed_dates(character_id: String) -> int:
	var completed := 0
	for date_name in DATE_ORDER:
		if has_completed_date(character_id, date_name):
			completed += 1
	return completed


func _make_panel_style(
	background: Color,
	border: Color,
	radius: int = 16,
	border_width: int = 2
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func show_love_book() -> void:
	visible = true
	populate_love_book()
	update_stats()
	update_navigation()

func hide_love_book() -> void:
	visible = false

func populate_love_book() -> void:
	for tween in hover_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	hover_tweens.clear()
	_button_original_positions.clear()

	for child in pages_container.get_children():
		child.queue_free()

	var all_characters = CharacterDatabase.get_all_characters()
	var location_groups: Dictionary = {}

	for char_data in all_characters:
		if CharacterMoodManager:
			CharacterMoodManager.register_character(char_data)

		var location := extract_location(str(char_data.get("id", "")))
		if not location_groups.has(location):
			location_groups[location] = []
		location_groups[location].append(char_data)

	var locations := location_groups.keys()
	locations.sort_custom(
		func(a, b):
			return str(a).naturalnocasecmp_to(str(b)) < 0
	)

	for location_variant in locations:
		var location := str(location_variant)
		location_groups[location].sort_custom(
			func(a, b):
				return str(a.get("name", "")).naturalnocasecmp_to(
					str(b.get("name", ""))
				) < 0
		)

		var page_scroll := ScrollContainer.new()
		page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page_scroll.custom_minimum_size = Vector2(1100, 550)
		page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

		var content_margin := MarginContainer.new()
		content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_margin.add_theme_constant_override("margin_left", 18)
		content_margin.add_theme_constant_override("margin_right", 18)
		content_margin.add_theme_constant_override("margin_top", 6)
		content_margin.add_theme_constant_override("margin_bottom", 18)
		page_scroll.add_child(content_margin)

		var content_container := VBoxContainer.new()
		content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_container.add_theme_constant_override("separation", 16)
		content_margin.add_child(content_container)

		var location_header := PanelContainer.new()
		location_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		location_header.add_theme_stylebox_override(
			"panel",
			_make_panel_style(
				Color(0.24, 0.14, 0.34, 0.94),
				Color(0.88, 0.62, 1.0, 0.72),
				16,
				1
			)
		)

		var location_label := Label.new()
		location_label.text = "%s  %s" % [
			_get_location_icon(location),
			location.to_upper()
		]
		location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		location_label.add_theme_font_size_override("font_size", 23)
		location_label.add_theme_color_override(
			"font_color",
			Color(0.97, 0.88, 1.0, 1.0)
		)
		location_label.custom_minimum_size = Vector2(0, 48)
		location_header.add_child(location_label)
		content_container.add_child(location_header)

		var grid := GridContainer.new()
		grid.columns = 4
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 26)
		content_container.add_child(grid)

		for char_data in location_groups[location]:
			create_simple_character_entry(grid, char_data)

		pages_container.add_child(page_scroll)

	call_deferred("_hide_scrollbars")


func create_simple_character_entry(
	grid: GridContainer,
	char_data: Dictionary
) -> void:
	var character_id := str(char_data.get("id", ""))
	var points := float(PlayerData.get_relationship_points(character_id))
	var is_unlocked := points > 0.0
	var stage_name := _get_stage_name(character_id)
	var stage_color := _get_stage_color(stage_name)
	var mood_name := _get_mood(char_data)
	var mood_color: Color = MOOD_COLORS.get(
		mood_name,
		MOOD_COLORS["neutral"]
	)
	var completed_dates := _count_completed_dates(character_id)

	var entry_container := Control.new()
	entry_container.custom_minimum_size = Vector2(260, 374)
	entry_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	entry_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	entry_container.pivot_offset = Vector2(130, 187)

	var card_bg := Panel.new()
	var card_style := _make_panel_style(
		Color(0.20, 0.11, 0.29, 0.97),
		stage_color if is_unlocked else Color(0.40, 0.32, 0.49, 0.62),
		18,
		2
	)
	card_style.shadow_color = (
		stage_color.darkened(0.70)
		if is_unlocked
		else Color(0.06, 0.03, 0.09, 0.55)
	)
	card_style.shadow_size = 8
	card_style.shadow_offset = Vector2(0, 3)
	card_bg.add_theme_stylebox_override("panel", card_style)
	card_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	entry_container.add_child(card_bg)

	var content_margin := MarginContainer.new()
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_theme_constant_override("margin_left", 12)
	content_margin.add_theme_constant_override("margin_right", 12)
	content_margin.add_theme_constant_override("margin_top", 12)
	content_margin.add_theme_constant_override("margin_bottom", 12)
	card_bg.add_child(content_margin)

	var content_vbox := VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 7)
	content_margin.add_child(content_vbox)

	var portrait_container := Control.new()
	portrait_container.custom_minimum_size = Vector2(236, 225)
	portrait_container.clip_contents = true
	content_vbox.add_child(portrait_container)

	var portrait := TextureRect.new()
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var image_path := str(char_data.get("image_path", ""))
	if image_path != "" and ResourceLoader.exists(image_path):
		var texture = load(image_path)
		portrait.texture = texture if texture else PLACEHOLDER_TEXTURE
	else:
		portrait.texture = PLACEHOLDER_TEXTURE

	if is_unlocked:
		portrait.material = null
		portrait.modulate = Color.WHITE
	else:
		var mat := ShaderMaterial.new()
		mat.shader = SILHOUETTE_SHADER
		portrait.material = mat
		portrait.modulate = Color(0.80, 0.74, 0.90, 1.0)

	portrait_container.add_child(portrait)

	var portrait_gradient := ColorRect.new()
	portrait_gradient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_gradient.color = Color(0.12, 0.06, 0.18, 0.12)
	portrait_container.add_child(portrait_gradient)


	var name_label := Label.new()
	name_label.text = str(char_data.get("name", "Unknown")) if is_unlocked else "Unknown Girl"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override(
		"font_color",
		Color(0.99, 0.93, 1.0, 1.0)
		if is_unlocked
		else Color(0.66, 0.60, 0.74, 0.9)
	)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content_vbox.add_child(name_label)

	var profession_label := Label.new()
	profession_label.text = (
		str(char_data.get("profession", "Unknown profession"))
		if is_unlocked
		else "Profile undiscovered"
	)
	profession_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profession_label.add_theme_font_size_override("font_size", 12)
	profession_label.add_theme_color_override(
		"font_color",
		Color(0.76, 0.70, 0.84, 1.0)
	)
	profession_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content_vbox.add_child(profession_label)


	if is_unlocked and completed_dates == DATE_ORDER.size():
		var completion_ribbon := Label.new()
		completion_ribbon.text = "★  PROFILE COMPLETE  ★"
		completion_ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		completion_ribbon.add_theme_font_size_override("font_size", 12)
		completion_ribbon.add_theme_color_override(
			"font_color",
			Color(0.18, 0.08, 0.04, 1.0)
		)
		completion_ribbon.add_theme_stylebox_override(
			"normal",
			_make_panel_style(
				Color(1.0, 0.78, 0.28, 0.96),
				Color(1.0, 0.92, 0.60, 1.0),
				10,
				1
			)
		)
		completion_ribbon.custom_minimum_size = Vector2(0, 28)
		content_vbox.add_child(completion_ribbon)

	var status_row := HBoxContainer.new()
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", 7)
	content_vbox.add_child(status_row)

	var stage_pill := Label.new()
	stage_pill.text = stage_name if is_unlocked else "LOCKED"
	stage_pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_pill.add_theme_font_size_override("font_size", 11)
	stage_pill.add_theme_color_override(
		"font_color",
		stage_color if is_unlocked else Color(0.70, 0.64, 0.78, 1.0)
	)
	stage_pill.add_theme_stylebox_override(
		"normal",
		_make_panel_style(
			Color(stage_color.r * 0.16, stage_color.g * 0.16, stage_color.b * 0.16, 0.96)
			if is_unlocked
			else Color(0.15, 0.12, 0.18, 0.96),
			stage_color.darkened(0.15)
			if is_unlocked
			else Color(0.40, 0.34, 0.46, 0.7),
			10,
			1
		)
	)
	stage_pill.custom_minimum_size = Vector2(90, 26)
	status_row.add_child(stage_pill)

	var mood_pill := Label.new()
	mood_pill.text = _get_mood_display_name(mood_name) if is_unlocked else "???"
	mood_pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mood_pill.add_theme_font_size_override("font_size", 11)
	mood_pill.add_theme_color_override(
		"font_color",
		mood_color if is_unlocked else Color(0.65, 0.60, 0.72, 0.9)
	)
	mood_pill.add_theme_stylebox_override(
		"normal",
		_make_panel_style(
			Color(mood_color.r * 0.16, mood_color.g * 0.16, mood_color.b * 0.16, 0.96)
			if is_unlocked
			else Color(0.15, 0.12, 0.18, 0.96),
			mood_color.darkened(0.15)
			if is_unlocked
			else Color(0.40, 0.34, 0.46, 0.7),
			10,
			1
		)
	)
	mood_pill.custom_minimum_size = Vector2(76, 26)
	status_row.add_child(mood_pill)

	var progress_bar := ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(210, 8)
	progress_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_bar.max_value = MAX_RELATIONSHIP_POINTS
	progress_bar.value = maxf(points, 0.0)
	progress_bar.show_percentage = false

	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color(0.10, 0.07, 0.14, 0.85)
	progress_bg.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("background", progress_bg)

	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = stage_color if is_unlocked else Color(0.35, 0.28, 0.42, 0.40)
	progress_fill.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("fill", progress_fill)
	content_vbox.add_child(progress_bar)

	var memory_label := Label.new()
	memory_label.text = (
		"%d / %d memories" % [completed_dates, DATE_ORDER.size()]
		if is_unlocked
		else "Meet her to unlock"
	)
	memory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_label.add_theme_font_size_override("font_size", 11)
	memory_label.add_theme_color_override(
		"font_color",
		Color(0.84, 0.72, 0.92, 1.0)
		if is_unlocked
		else Color(0.58, 0.53, 0.64, 1.0)
	)
	content_vbox.add_child(memory_label)

	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, empty_style)
	entry_container.add_child(button)

	button.pressed.connect(_on_character_clicked.bind(char_data))
	button.mouse_entered.connect(
		_on_character_hover.bind(entry_container, true, is_unlocked)
	)
	button.mouse_exited.connect(
		_on_character_hover.bind(entry_container, false, is_unlocked)
	)

	grid.add_child(entry_container)


func _on_character_hover(
	card_container: Control,
	is_hovering: bool,
	is_unlocked: bool
) -> void:
	if hover_tweens.has(card_container):
		var old_tween: Tween = hover_tweens[card_container]
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	hover_tweens[card_container] = tween

	var target_scale := Vector2(1.025, 1.025) if is_hovering else Vector2.ONE
	var target_modulate := (
		Color(1.08, 1.05, 1.10, 1.0)
		if is_hovering and is_unlocked
		else Color(1.04, 1.04, 1.06, 1.0)
		if is_hovering
		else Color.WHITE
	)

	tween.tween_property(card_container, "scale", target_scale, 0.18)
	tween.tween_property(card_container, "modulate", target_modulate, 0.18)


func create_date_button(container: GridContainer, char_data: Dictionary, date_name: String) -> void:
	var date_button_container = Control.new()
	date_button_container.custom_minimum_size = Vector2(170, 136)
	
	var date_bg = Panel.new()
	var date_style = StyleBoxFlat.new()
	date_style.bg_color = Color(0.25, 0.16, 0.35, 0.92)
	date_style.set_corner_radius_all(10)
	date_style.set_border_width_all(2)
	
	var char_id = char_data.get("id", "")
	var date_completed = has_completed_date(char_id, date_name)
	
	if date_completed:
		date_style.set_border_color(Color(0.8, 0.6, 1.0, 1))
	else:
		date_style.set_border_color(Color(0.45, 0.35, 0.55, 0.6))
	
	date_bg.add_theme_stylebox_override("panel", date_style)
	date_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var date_content = VBoxContainer.new()
	date_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	date_content.add_theme_constant_override("separation", 5)
	
	var date_image_margin = MarginContainer.new()
	date_image_margin.add_theme_constant_override("margin_left", 8)
	date_image_margin.add_theme_constant_override("margin_right", 8)
	date_image_margin.add_theme_constant_override("margin_top", 8)
	date_image_margin.add_theme_constant_override("margin_bottom", 5)
	
	var date_image = TextureRect.new()
	date_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	date_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	date_image.custom_minimum_size = Vector2(145, 80)
	date_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if date_completed:
		var date_image_path = get_date_image_path(char_id, date_name)
		var texture = null
		if date_image_path != "" and ResourceLoader.exists(date_image_path):
			texture = load(date_image_path)
		date_image.texture = texture if texture else DATE_PLACEHOLDER_TEXTURE
	else:
		date_image.texture = DATE_PLACEHOLDER_TEXTURE
		date_image.modulate = Color(0.5, 0.45, 0.6, 0.7)
	
	date_image_margin.add_child(date_image)
	date_content.add_child(date_image_margin)
	
	var date_label_margin = MarginContainer.new()
	date_label_margin.add_theme_constant_override("margin_left", 5)
	date_label_margin.add_theme_constant_override("margin_right", 5)
	date_label_margin.add_theme_constant_override("margin_bottom", 8)
	
	var date_label = Label.new()
	var display_name = DATE_DISPLAY_NAMES.get(date_name, date_name.capitalize())
	
	if date_completed:
		date_label.text = "✓  %s" % display_name
		date_label.add_theme_color_override("font_color", Color(0.9, 0.82, 1.0, 1))
	else:
		date_label.text = "🔒  %s" % display_name
		date_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.7, 1))
	
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 12)
	
	date_label_margin.add_child(date_label)
	date_content.add_child(date_label_margin)
	
	date_bg.add_child(date_content)
	date_button_container.add_child(date_bg)
	
	var date_button = Button.new()
	date_button.flat = true
	date_button.focus_mode = Control.FOCUS_NONE
	date_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var empty_style = StyleBoxEmpty.new()
	date_button.add_theme_stylebox_override("normal", empty_style)
	date_button.add_theme_stylebox_override("hover", empty_style)
	date_button.add_theme_stylebox_override("pressed", empty_style)
	date_button.add_theme_stylebox_override("focus", empty_style)
	
	date_button_container.add_child(date_button)
	
	date_button.pressed.connect(_on_date_button_clicked.bind(char_data, date_name))
	date_button.mouse_entered.connect(_on_date_button_hover.bind(date_button_container, true))
	date_button.mouse_exited.connect(_on_date_button_hover.bind(date_button_container, false))
	
	container.add_child(date_button_container)

func has_completed_date(char_id: String, date_name: String) -> bool:
	return PlayerData.has_completed_date(char_id, date_name)

func get_date_image_path(char_id: String, date_name: String) -> String:
	var char_data = LocationManager.get_character_data(char_id) if LocationManager.has_method("get_character_data") else {}
	if char_data.is_empty() and CharacterDatabase:
		char_data = CharacterDatabase.get_character(char_id) if CharacterDatabase.has_method("get_character") else {}
	var date_images = char_data.get("date_images", {})
	return date_images.get(date_name, "")

func _on_date_button_clicked(char_data: Dictionary, date_name: String) -> void:
	var char_id = char_data.get("id", "")
	var date_completed = has_completed_date(char_id, date_name)
	var display_name = DATE_DISPLAY_NAMES.get(date_name, date_name.capitalize())
	
	if date_completed:
		if UIManager:
			UIManager.show_notification("Viewing %s date with %s" % [display_name, char_data.get("name", "Unknown")])
		show_date_image_fullscreen(char_id, date_name)
	else:
		if UIManager:
			UIManager.show_notification("%s date not yet experienced with %s!" % [display_name, char_data.get("name", "Unknown")])

func _on_date_button_hover(button_container: Control, is_hovering: bool) -> void:
	# Store the original position the first time we hover
	if !_button_original_positions.has(button_container):
		_button_original_positions[button_container] = button_container.position

	var original_pos: Vector2 = _button_original_positions[button_container]

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	if is_hovering:
		tween.parallel().tween_property(button_container, "position", original_pos + Vector2(0, -6), 0.15)
		tween.parallel().tween_property(button_container, "scale", Vector2(1.03, 1.03), 0.15)
		tween.parallel().tween_property(button_container, "modulate", Color(1.08, 1.08, 1.12), 0.15)
	else:
		tween.parallel().tween_property(button_container, "position", original_pos, 0.15)
		tween.parallel().tween_property(button_container, "scale", Vector2.ONE, 0.15)
		tween.parallel().tween_property(button_container, "modulate", Color.WHITE, 0.15)

func show_date_image_fullscreen(char_id: String, date_name: String) -> void:
	var date_image_path = get_date_image_path(char_id, date_name)
	
	if date_image_path.is_empty() or not ResourceLoader.exists(date_image_path):
		return
	
	var overlay_canvas = CanvasLayer.new()
	overlay_canvas.layer = 100
	
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_canvas.add_child(overlay)
	
	var background = ColorRect.new()
	background.color = Color(0.05, 0.03, 0.1, 0.9)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(background)
	
	var image_container = Control.new()
	image_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	image_container.anchor_left = 0.5
	image_container.anchor_right = 0.5
	image_container.anchor_top = 0.5
	image_container.anchor_bottom = 0.5
	
	var fullscreen_image = TextureRect.new()
	var texture = load(date_image_path)
	fullscreen_image.texture = texture
	fullscreen_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	fullscreen_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var screen_size = get_viewport().get_visible_rect().size
	var max_width = screen_size.x * 0.8
	var max_height = screen_size.y * 0.8
	var original_size = texture.get_size()
	var aspect_ratio = original_size.x / original_size.y
	
	var final_width = min(max_width, max_height * aspect_ratio)
	var final_height = min(max_height, max_width / aspect_ratio)
	final_width = max(final_width, 600)
	final_height = max(final_height, 400)
	
	fullscreen_image.custom_minimum_size = Vector2(final_width, final_height)
	fullscreen_image.size = Vector2(final_width, final_height)
	fullscreen_image.position = Vector2(-final_width/2, -final_height/2)
	
	var image_frame = Panel.new()
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.18, 0.12, 0.28, 0.95)
	frame_style.set_corner_radius_all(16)
	frame_style.set_border_width_all(4)
	frame_style.set_border_color(Color(0.8, 0.6, 1.0, 1))
	image_frame.add_theme_stylebox_override("panel", frame_style)
	
	var frame_padding = 20
	image_frame.position = Vector2(-final_width/2 - frame_padding, -final_height/2 - frame_padding)
	image_frame.size = Vector2(final_width + frame_padding*2, final_height + frame_padding*2)
	
	var image_margin = MarginContainer.new()
	image_margin.add_theme_constant_override("margin_left", frame_padding)
	image_margin.add_theme_constant_override("margin_right", frame_padding)
	image_margin.add_theme_constant_override("margin_top", frame_padding)
	image_margin.add_theme_constant_override("margin_bottom", frame_padding)
	image_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_margin.add_child(fullscreen_image)
	image_frame.add_child(image_margin)
	
	image_container.add_child(image_frame)
	overlay.add_child(image_container)
	
	var close_button = Button.new()
	close_button.text = "✕ Close"
	close_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_button.position = Vector2(-140, 20)
	close_button.custom_minimum_size = Vector2(120, 50)
	close_button.add_theme_font_size_override("font_size", 16)
	
	var close_button_style = StyleBoxFlat.new()
	close_button_style.bg_color = Color(0.6, 0.25, 0.4, 0.95)
	close_button_style.set_corner_radius_all(10)
	close_button_style.set_border_width_all(2)
	close_button_style.set_border_color(Color(0.9, 0.5, 0.7, 1))
	close_button.add_theme_stylebox_override("normal", close_button_style)
	close_button.add_theme_stylebox_override("hover", close_button_style)
	close_button.add_theme_stylebox_override("pressed", close_button_style)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	
	overlay.add_child(close_button)
	
	var instruction_label = Label.new()
	instruction_label.text = "Click anywhere or press ESC to close"
	instruction_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	instruction_label.position = Vector2(20, -50)
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.9, 0.8))
	overlay.add_child(instruction_label)
	
	get_tree().root.add_child(overlay_canvas)
	
	overlay.modulate.a = 0.0
	image_container.scale = Vector2(0.8, 0.8)
	
	var appear_tween = create_tween()
	appear_tween.set_parallel(true)
	appear_tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
	appear_tween.tween_property(image_container, "scale", Vector2.ONE, 0.3)
	appear_tween.set_ease(Tween.EASE_OUT)
	appear_tween.set_trans(Tween.TRANS_CUBIC)
	
	var close_overlay = func():
		var fade_tween = create_tween()
		fade_tween.set_parallel(true)
		fade_tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
		fade_tween.tween_property(image_container, "scale", Vector2(0.9, 0.9), 0.2)
		fade_tween.tween_callback(func(): overlay_canvas.queue_free()).set_delay(0.2)
	
	close_button.pressed.connect(close_overlay)
	background.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			close_overlay.call()
	)
	overlay.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			close_overlay.call()
	)
	
	overlay.focus_mode = Control.FOCUS_ALL
	overlay.grab_focus()

func extract_location(character_id: String) -> String:
	var parts = character_id.split("_")
	if parts.size() > 1:
		var location = parts[-1]
		if location == "jobcenter" or location == "anderson":
			return "Job Center"
		return location.capitalize()
	return "Unknown"

func update_stats() -> void:
	var all_characters = CharacterDatabase.get_all_characters()
	var discovered := 0
	var completed_memories := 0

	for char_data in all_characters:
		var character_id := str(char_data.get("id", ""))
		var points := float(PlayerData.get_relationship_points(character_id))

		if points > 0.0:
			discovered += 1

		completed_memories += _count_completed_dates(character_id)

	var total_characters := all_characters.size()
	var total_memories := total_characters * DATE_ORDER.size()
	var percentage := (
		int((discovered * 100.0) / float(total_characters))
		if total_characters > 0
		else 0
	)

	stats_label.text = (
		"%d/%d Discovered  •  %d/%d Memories  •  %d%% Complete"
	) % [
		discovered,
		total_characters,
		completed_memories,
		total_memories,
		percentage
	]

	stats_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.78, 0.48, 1.0)
	)


func _on_character_clicked(char_data: Dictionary) -> void:
	var points = PlayerData.get_relationship_points(char_data.get("id", ""))
	if points > 0:
		show_character_details(char_data, points)
	else:
		if UIManager:
			UIManager.show_notification("Character not yet discovered!")

func show_character_details(char_data: Dictionary, points: float) -> void:
	detail_panel.visible = true
	character_name_label.text = char_data.get("name", "Unknown")
	character_name_label.add_theme_color_override("font_color", Color(0.95, 0.88, 1.0, 1))
	
	for child in details_container.get_children():
		child.queue_free()
	
	var points_container = HBoxContainer.new()
	points_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var points_icon = Label.new()
	points_icon.text = "♥"
	points_icon.add_theme_font_size_override("font_size", 20)
	points_icon.add_theme_color_override("font_color", Color(0.9, 0.45, 0.7, 1))
	points_container.add_child(points_icon)
	
	var percentage := (points * 100.0) / float(MAX_RELATIONSHIP_POINTS)
	var stage_name := _get_stage_name(str(char_data.get("id", "")))
	var mood_name := _get_mood(char_data)
	var points_label := Label.new()
	points_label.text = " %.1f RP  •  %s  •  %s  •  %d%%" % [
		points,
		stage_name,
		_get_mood_display_name(mood_name),
		int(percentage)
	]
	points_label.add_theme_font_size_override("font_size", 18)
	points_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.95, 1))
	points_container.add_child(points_label)
	
	details_container.add_child(points_container)
	
	var portrait_and_details_margin = MarginContainer.new()
	portrait_and_details_margin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_and_details_margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_and_details_margin.add_theme_constant_override("margin_left", 20)
	portrait_and_details_margin.add_theme_constant_override("margin_right", 20)
	portrait_and_details_margin.add_theme_constant_override("margin_top", 10)
	portrait_and_details_margin.add_theme_constant_override("margin_bottom", 10)
	
	var portrait_and_details_container = HBoxContainer.new()
	portrait_and_details_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_and_details_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_and_details_container.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_and_details_container.add_theme_constant_override("separation", 20)
	
	var portrait_frame = Panel.new()
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.22, 0.14, 0.32, 0.9)
	frame_style.set_corner_radius_all(12)
	frame_style.set_border_width_all(3)
	frame_style.set_border_color(Color(0.8, 0.6, 1.0, 1))
	portrait_frame.add_theme_stylebox_override("panel", frame_style)
	portrait_frame.custom_minimum_size = Vector2(260, 310)
	
	var portrait = TextureRect.new()
	var image_path = char_data.get("image_path", "")
	if image_path != "" and ResourceLoader.exists(image_path):
		var texture = load(image_path)
		portrait.texture = texture if texture else PLACEHOLDER_TEXTURE
	else:
		portrait.texture = PLACEHOLDER_TEXTURE
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(240, 270)
	
	var portrait_margin = MarginContainer.new()
	portrait_margin.add_theme_constant_override("margin_left", 10)
	portrait_margin.add_theme_constant_override("margin_right", 10)
	portrait_margin.add_theme_constant_override("margin_top", 10)
	portrait_margin.add_theme_constant_override("margin_bottom", 10)
	portrait_margin.add_child(portrait)
	portrait_frame.add_child(portrait_margin)
	
	portrait_and_details_container.add_child(portrait_frame)
	
	var details_vbox = VBoxContainer.new()
	details_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	details_vbox.add_theme_constant_override("separation", 8)
	details_vbox.custom_minimum_size = Vector2(300, 0)
	
	var detail_fields = [
		{"key": "age", "label": "Age"},
		{"key": "height", "label": "Height"},
		{"key": "weight", "label": "Weight"},
		{"key": "hair", "label": "Hair"},
		{"key": "eyes", "label": "Eyes"},
		{"key": "body", "label": "Body"},
		{"key": "skin", "label": "Skin Tone"},
		{"key": "bust", "label": "Bust"},
		{"key": "personality", "label": "Personality"}, 
		{"key": "profession", "label": "Profession"},
		{"key": "hobby", "label": "Hobby"}
	]
	
	for field in detail_fields:
		var detail_hbox = HBoxContainer.new()
		detail_hbox.add_theme_constant_override("separation", 10)
		
		var label = Label.new()
		label.text = field.label + ":"
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.95, 1))
		label.custom_minimum_size = Vector2(100, 0)
		detail_hbox.add_child(label)
		
		var value = Label.new()
		value.text = str(char_data.get(field.key, "Unknown"))
		value.add_theme_font_size_override("font_size", 14)
		value.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0, 1))
		value.custom_minimum_size = Vector2(150, 0)
		detail_hbox.add_child(value)
		
		details_vbox.add_child(detail_hbox)
	
	portrait_and_details_container.add_child(details_vbox)
	portrait_and_details_margin.add_child(portrait_and_details_container)
	details_container.add_child(portrait_and_details_margin)
	
	var date_spacer = Control.new()
	date_spacer.custom_minimum_size = Vector2(0, 20)
	details_container.add_child(date_spacer)
	
	var date_section_title = Label.new()
	date_section_title.text = "♥  DATE MEMORIES  ♥"
	date_section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_section_title.add_theme_font_size_override("font_size", 20)
	date_section_title.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0, 1))
	details_container.add_child(date_section_title)
	
	var dates_container = GridContainer.new()
	dates_container.columns = 5
	dates_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dates_container.add_theme_constant_override("h_separation", 14)
	dates_container.add_theme_constant_override("v_separation", 6)
	
	for date_name in DATE_ORDER:
		create_date_button(dates_container, char_data, date_name)
	
	details_container.add_child(dates_container)
	
	var back_button = %BackButton
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	detail_panel.visible = false

func _on_left_arrow_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_navigation()

func _on_right_arrow_pressed() -> void:
	var total_pages = pages_container.get_child_count()
	if current_page < total_pages - 1:
		current_page += 1
		update_navigation()

func update_navigation() -> void:
	var total_pages = pages_container.get_child_count()
	
	for i in range(total_pages):
		pages_container.get_child(i).visible = (i == current_page)
	
	left_arrow.disabled = (current_page == 0)
	right_arrow.disabled = (current_page == total_pages - 1)
	
	if page_indicator:
		page_indicator.text = "Page %d of %d" % [current_page + 1, total_pages]
		page_indicator.add_theme_color_override("font_color", Color(0.8, 0.7, 0.95, 1))
