extends PanelContainer

const PHYSICAL_COLOR := Color(0.98, 0.45, 0.58, 1.0)
const MENTAL_COLOR := Color(0.68, 0.52, 0.98, 1.0)
const SOCIAL_COLOR := Color(0.92, 0.52, 0.82, 1.0)

const CARD_HEIGHT := 84.0
const CARD_COLUMNS := 2
const CARD_GAP := 9

const STAT_ICON_PATHS := {
	"strength": "res://assets/stat_icons/strength.svg",
	"agility": "res://assets/stat_icons/agility.svg",
	"endurance": "res://assets/stat_icons/endurance.svg",
	"balance": "res://assets/stat_icons/balance.svg",
	"knowledge": "res://assets/stat_icons/knowledge.svg",
	"wisdom": "res://assets/stat_icons/wisdom.svg",
	"intelligence": "res://assets/stat_icons/intelligence.svg",
	"logic": "res://assets/stat_icons/logic.svg",
	"leadership": "res://assets/stat_icons/leadership.svg",
	"persuasion": "res://assets/stat_icons/persuasion.svg",
	"charisma": "res://assets/stat_icons/charisma.svg",
	"communication": "res://assets/stat_icons/communication.svg",
}

@onready var stats_scroll: ScrollContainer = %StatsScroll

@onready var player_name_label: Label = %PlayerNameLabel
@onready var physical_stats_container: GridContainer = %PhysicalStats
@onready var mental_stats_container: GridContainer = %MentalStats
@onready var social_stats_container: GridContainer = %SocialStats

@export var fade_duration: float = 0.1
@export var glow_duration: float = 1.2
@export var progress_animation_duration: float = 0.25

var stats_display_nodes: Dictionary = {}
var current_fade_tween: Tween = null
var glow_tweens: Dictionary = {}
var hover_tweens: Dictionary = {}
var progress_tweens: Dictionary = {}
var current_active_stat: String = ""


func _ready() -> void:
	if not _required_nodes_exist():
		printerr("StatsPanel: required nodes missing")
		return

	_setup_panel_styling()
	_setup_scroll_container()
	_setup_grids()
	_connect_player_data_signals()

	_populate_stat_nodes()
	update_stats_display(false)
	update_player_name_display()


func _exit_tree() -> void:
	_disconnect_player_data_signals()
	_stop_all_tweens()


func _required_nodes_exist() -> bool:
	return (
		is_instance_valid(player_name_label)
		and is_instance_valid(physical_stats_container)
		and is_instance_valid(mental_stats_container)
		and is_instance_valid(social_stats_container)
		and is_instance_valid(stats_scroll)
	)


func _connect_player_data_signals() -> void:
	if not PlayerData:
		printerr("StatsPanel: PlayerData not found")
		return

	if not PlayerData.player_stat_changed.is_connected(on_stat_changed):
		PlayerData.player_stat_changed.connect(on_stat_changed)
	if not PlayerData.player_name_changed.is_connected(on_player_name_changed):
		PlayerData.player_name_changed.connect(on_player_name_changed)
	if not PlayerData.player_data_loaded.is_connected(refresh_stats_panel):
		PlayerData.player_data_loaded.connect(refresh_stats_panel)


func _disconnect_player_data_signals() -> void:
	if not PlayerData:
		return

	if PlayerData.player_stat_changed.is_connected(on_stat_changed):
		PlayerData.player_stat_changed.disconnect(on_stat_changed)
	if PlayerData.player_name_changed.is_connected(on_player_name_changed):
		PlayerData.player_name_changed.disconnect(on_player_name_changed)
	if PlayerData.player_data_loaded.is_connected(refresh_stats_panel):
		PlayerData.player_data_loaded.disconnect(refresh_stats_panel)


func _setup_scroll_container() -> void:
	# Keep wheel/touch scrolling available as a small-screen fallback,
	# but never draw the scrollbar.
	stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stats_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER


func _setup_grids() -> void:
	for grid in [physical_stats_container, mental_stats_container, social_stats_container]:
		grid.columns = CARD_COLUMNS
		grid.add_theme_constant_override("h_separation", CARD_GAP)
		grid.add_theme_constant_override("v_separation", CARD_GAP)


func _setup_panel_styling() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.18, 0.10, 0.26, 0.96)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.92, 0.68, 1.0, 0.85)
	panel_style.set_corner_radius_all(18)
	panel_style.shadow_color = Color(0.35, 0.12, 0.5, 0.45)
	panel_style.shadow_size = 14
	panel_style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", panel_style)

	player_name_label.add_theme_color_override("font_color", Color(0.98, 0.94, 1.0, 1.0))
	player_name_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.2, 0.7, 0.7))
	player_name_label.add_theme_constant_override("shadow_offset_x", 2)
	player_name_label.add_theme_constant_override("shadow_offset_y", 2)


# -----------------------------------------------------------------------------
# Card construction
# -----------------------------------------------------------------------------

func _populate_stat_nodes() -> void:
	if not PlayerData:
		return

	_stop_all_tweens()
	stats_display_nodes.clear()
	current_active_stat = ""

	for container in [physical_stats_container, mental_stats_container, social_stats_container]:
		_clear_container(container)

	for stat_name in PlayerData.get_physical_stats():
		_create_stat_card(str(stat_name), physical_stats_container, PHYSICAL_COLOR)
	for stat_name in PlayerData.get_mental_stats():
		_create_stat_card(str(stat_name), mental_stats_container, MENTAL_COLOR)
	for stat_name in PlayerData.get_social_stats():
		_create_stat_card(str(stat_name), social_stats_container, SOCIAL_COLOR)


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


func _create_stat_card(stat_name: String, parent_grid: GridContainer, theme_color: Color) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	card.clip_contents = true
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override("panel", _make_card_style(theme_color, false, false))
	card.mouse_entered.connect(_on_card_mouse_entered.bind(stat_name))
	card.mouse_exited.connect(_on_card_mouse_exited.bind(stat_name))
	parent_grid.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	content.add_child(header)

	var icon_badge := PanelContainer.new()
	icon_badge.custom_minimum_size = Vector2(28, 28)
	icon_badge.add_theme_stylebox_override("panel", _make_icon_badge_style(theme_color))
	header.add_child(icon_badge)

	var icon_margin := MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_left", 5)
	icon_margin.add_theme_constant_override("margin_top", 5)
	icon_margin.add_theme_constant_override("margin_right", 5)
	icon_margin.add_theme_constant_override("margin_bottom", 5)
	icon_badge.add_child(icon_margin)

	var icon_rect := TextureRect.new()
	icon_rect.texture = _get_stat_icon_texture(stat_name)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.modulate = theme_color.lightened(0.28)
	icon_margin.add_child(icon_rect)

	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.98, 0.96, 1.0, 1.0))
	name_label.text = stat_name.capitalize()
	header.add_child(name_label)

	var active_label := Label.new()
	active_label.visible = false
	active_label.text = "ACTIVE"
	active_label.add_theme_font_size_override("font_size", 9)
	active_label.add_theme_color_override("font_color", theme_color.lightened(0.35))
	header.add_child(active_label)

	var value_row := HBoxContainer.new()
	value_row.add_theme_constant_override("separation", 4)
	content.add_child(value_row)

	var value_label := Label.new()
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.text = "0"
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	value_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.02, 0.09, 0.9))
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	value_row.add_child(value_label)

	var percent_label := Label.new()
	percent_label.text = "0%"
	percent_label.add_theme_font_size_override("font_size", 10)
	percent_label.add_theme_color_override("font_color", theme_color.lightened(0.2))
	percent_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	value_row.add_child(percent_label)

	var progress_bar := ProgressBar.new()
	progress_bar.custom_minimum_size.y = 8
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	_style_progress_bar(progress_bar, theme_color, false)
	content.add_child(progress_bar)

	stats_display_nodes[stat_name] = {
		"card": card,
		"icon_rect": icon_rect,
		"icon_badge": icon_badge,
		"name_label": name_label,
		"value_label": value_label,
		"percent_label": percent_label,
		"active_label": active_label,
		"progress_bar": progress_bar,
		"theme_color": theme_color,
	}


func _get_stat_icon_texture(stat_name: String) -> Texture2D:
	var normalized := stat_name.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	var icon_path: String = str(STAT_ICON_PATHS.get(normalized, ""))
	if icon_path.is_empty():
		return null
	return load(icon_path) as Texture2D


func _make_icon_badge_style(theme_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.14)
	style.border_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.58)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(9)
	return style


func _make_card_style(theme_color: Color, active: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	if active:
		style.bg_color = Color(0.30, 0.15, 0.38, 0.98)
		style.border_color = theme_color.lightened(0.22)
		style.shadow_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.34)
		style.shadow_size = 8
	elif hovered:
		style.bg_color = Color(0.25, 0.14, 0.34, 0.98)
		style.border_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.72)
		style.shadow_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.18)
		style.shadow_size = 5
	else:
		style.bg_color = Color(0.14, 0.075, 0.20, 0.88)
		style.border_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.36)
		style.shadow_color = Color(0.02, 0.01, 0.04, 0.28)
		style.shadow_size = 3

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(12)
	style.shadow_offset = Vector2(0, 2)
	return style


func _style_progress_bar(bar: ProgressBar, theme_color: Color, active: bool) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.065, 0.035, 0.095, 0.86)
	background.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)

	var fill := StyleBoxFlat.new()
	fill.bg_color = theme_color.lightened(0.14) if active else theme_color
	fill.set_corner_radius_all(4)
	if active:
		fill.shadow_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.55)
		fill.shadow_size = 5
	bar.add_theme_stylebox_override("fill", fill)


# -----------------------------------------------------------------------------
# Display updates
# -----------------------------------------------------------------------------

func update_stats_display(animate: bool = true) -> void:
	if not PlayerData:
		return

	for stat_name in stats_display_nodes.keys():
		_update_single_stat(stat_name, animate)


func _update_single_stat(stat_name: String, animate: bool = true) -> void:
	if not stats_display_nodes.has(stat_name):
		return

	var display_data: Dictionary = stats_display_nodes[stat_name]
	var current_value: float = float(PlayerData.get_stat(stat_name))
	var whole_value := int(floor(current_value))
	var progress := clampf(current_value - floor(current_value), 0.0, 1.0)

	var value_label: Label = display_data.get("value_label")
	var percent_label: Label = display_data.get("percent_label")
	var progress_bar: ProgressBar = display_data.get("progress_bar")

	if is_instance_valid(value_label):
		value_label.text = _format_large_integer(whole_value)
		value_label.add_theme_font_size_override("font_size", _font_size_for_value(value_label.text))

	if is_instance_valid(percent_label):
		percent_label.text = "%d%%" % int(round(progress * 100.0))

	if is_instance_valid(progress_bar):
		if progress_tweens.has(stat_name):
			var old_tween: Tween = progress_tweens[stat_name]
			if old_tween and old_tween.is_valid():
				old_tween.kill()

		if animate:
			var tween := create_tween()
			progress_tweens[stat_name] = tween
			tween.tween_property(progress_bar, "value", progress, progress_animation_duration)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			progress_bar.value = progress


func _format_large_integer(value: int) -> String:
	var negative := value < 0
	var digits := str(absi(value))
	var formatted := ""
	var count := 0

	for index in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = digits[index] + formatted
		count += 1

	return "-" + formatted if negative else formatted


func _font_size_for_value(formatted_value: String) -> int:
	var length := formatted_value.length()
	if length <= 7:
		return 20
	if length <= 10:
		return 18
	if length <= 13:
		return 16
	return 14


func update_player_name_display() -> void:
	if PlayerData and is_instance_valid(player_name_label):
		player_name_label.text = PlayerData.player_name


func refresh_stats_panel() -> void:
	if stats_display_nodes.is_empty():
		_populate_stat_nodes()
	update_stats_display(false)
	update_player_name_display()


func on_stat_changed(stat_name: String, _new_value: float) -> void:
	_update_single_stat(stat_name, true)
	set_active_stat(stat_name)


func on_player_name_changed(_new_name: String) -> void:
	update_player_name_display()


# -----------------------------------------------------------------------------
# Active state and hover
# -----------------------------------------------------------------------------

func set_active_stat(stat_name: String) -> void:
	if current_active_stat != "" and current_active_stat != stat_name:
		stop_glow_animation(current_active_stat)

	current_active_stat = stat_name
	if stats_display_nodes.has(stat_name):
		start_glow_animation(stat_name)


func start_glow_animation(stat_name: String) -> void:
	if not stats_display_nodes.has(stat_name):
		return

	var data: Dictionary = stats_display_nodes[stat_name]
	var card: PanelContainer = data.get("card")
	var active_label: Label = data.get("active_label")
	var progress_bar: ProgressBar = data.get("progress_bar")
	var theme_color: Color = data.get("theme_color", Color.WHITE)

	if not is_instance_valid(card):
		return

	if glow_tweens.has(stat_name):
		var old_tween: Tween = glow_tweens[stat_name]
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	card.add_theme_stylebox_override("panel", _make_card_style(theme_color, true, false))
	if is_instance_valid(active_label):
		active_label.visible = true
	if is_instance_valid(progress_bar):
		_style_progress_bar(progress_bar, theme_color, true)

	var glow_color := Color(
		minf(1.35, 1.0 + theme_color.r * 0.25),
		minf(1.35, 1.0 + theme_color.g * 0.25),
		minf(1.35, 1.0 + theme_color.b * 0.25),
		1.0
	)

	var tween := create_tween()
	glow_tweens[stat_name] = tween
	tween.set_loops()
	tween.tween_property(card, "modulate", glow_color, glow_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "modulate", Color.WHITE, glow_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_glow_animation(stat_name: String) -> void:
	if not stats_display_nodes.has(stat_name):
		return

	if glow_tweens.has(stat_name):
		var tween: Tween = glow_tweens[stat_name]
		if tween and tween.is_valid():
			tween.kill()
		glow_tweens.erase(stat_name)

	var data: Dictionary = stats_display_nodes[stat_name]
	var card: PanelContainer = data.get("card")
	var active_label: Label = data.get("active_label")
	var progress_bar: ProgressBar = data.get("progress_bar")
	var theme_color: Color = data.get("theme_color", Color.WHITE)

	if is_instance_valid(card):
		card.modulate = Color.WHITE
		card.scale = Vector2.ONE
		card.add_theme_stylebox_override("panel", _make_card_style(theme_color, false, false))
	if is_instance_valid(active_label):
		active_label.visible = false
	if is_instance_valid(progress_bar):
		_style_progress_bar(progress_bar, theme_color, false)


func _on_card_mouse_entered(stat_name: String) -> void:
	if not stats_display_nodes.has(stat_name):
		return

	var data: Dictionary = stats_display_nodes[stat_name]
	var card: PanelContainer = data.get("card")
	var icon_rect: TextureRect = data.get("icon_rect")
	var theme_color: Color = data.get("theme_color", Color.WHITE)
	if not is_instance_valid(card):
		return

	_kill_hover_tween(stat_name)
	if current_active_stat != stat_name:
		card.add_theme_stylebox_override("panel", _make_card_style(theme_color, false, true))

	var tween := create_tween()
	hover_tweens[stat_name] = tween
	tween.set_parallel(true)
	if current_active_stat != stat_name:
		tween.tween_property(card, "modulate", Color(1.08, 1.08, 1.08, 1.0), 0.12)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_instance_valid(icon_rect):
		icon_rect.pivot_offset = icon_rect.size * 0.5
		tween.tween_property(icon_rect, "scale", Vector2(1.12, 1.12), 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_card_mouse_exited(stat_name: String) -> void:
	if not stats_display_nodes.has(stat_name):
		return

	var data: Dictionary = stats_display_nodes[stat_name]
	var card: PanelContainer = data.get("card")
	var icon_rect: TextureRect = data.get("icon_rect")
	var theme_color: Color = data.get("theme_color", Color.WHITE)
	if not is_instance_valid(card):
		return

	_kill_hover_tween(stat_name)
	if current_active_stat != stat_name:
		card.add_theme_stylebox_override("panel", _make_card_style(theme_color, false, false))

	var tween := create_tween()
	hover_tweens[stat_name] = tween
	tween.set_parallel(true)
	if current_active_stat != stat_name:
		tween.tween_property(card, "modulate", Color.WHITE, 0.12)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_instance_valid(icon_rect):
		tween.tween_property(icon_rect, "scale", Vector2.ONE, 0.12)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _kill_hover_tween(stat_name: String) -> void:
	if hover_tweens.has(stat_name):
		var tween: Tween = hover_tweens[stat_name]
		if tween and tween.is_valid():
			tween.kill()
		hover_tweens.erase(stat_name)


func _stop_all_tweens() -> void:
	for dictionary in [glow_tweens, hover_tweens, progress_tweens]:
		for tween in dictionary.values():
			if tween and tween.is_valid():
				tween.kill()
		dictionary.clear()
	current_active_stat = ""


# -----------------------------------------------------------------------------
# Panel animation
# -----------------------------------------------------------------------------

func show_panel_animated() -> void:
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()

	modulate.a = 0.0
	visible = true
	scale = Vector2(0.96, 0.96)
	pivot_offset = size * 0.5

	current_fade_tween = create_tween()
	current_fade_tween.set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration * 2.0)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	current_fade_tween.tween_property(self, "scale", Vector2.ONE, fade_duration * 2.0)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_panel_animated() -> void:
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()

	pivot_offset = size * 0.5
	current_fade_tween = create_tween()
	current_fade_tween.set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration * 2.0)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	current_fade_tween.tween_property(self, "scale", Vector2(0.96, 0.96), fade_duration * 2.0)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await current_fade_tween.finished
	if is_instance_valid(self):
		visible = false
		current_fade_tween = null


func get_fade_tween() -> Tween:
	return current_fade_tween
