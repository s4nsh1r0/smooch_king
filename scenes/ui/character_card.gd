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
@onready var character_details_label: Label = %CharacterDetailsLabel
@onready var mood_panel: PanelContainer = %MoodPanel
@onready var mood_label: Label = %MoodLabel
@onready var mood_multiplier_label: Label = %MoodMultiplierLabel
@onready var mood_dot: ColorRect = %MoodDot
@onready var portrait_frame: Control = %PortraitFrame
@onready var header_panel: PanelContainer = %HeaderPanel

signal gift_requested(character_id: String, character_data: Dictionary)
signal date_requested(character_id: String, character_data: Dictionary)
signal close_requested

const TALK_AP_COST: int = 1
const TALK_RELATIONSHIP_POINTS: int = 1
const DATE_MIN_AP: int = 5
const MAX_RELATIONSHIP_POINTS: int = 1500
const MOOD_VISUALS := {
	"angry": {
		"label": "Angry",
		"color": Color(0.95, 0.30, 0.36, 1.0),
		"background": Color(0.34, 0.10, 0.15, 0.96)
	},
	"upset": {
		"label": "Upset",
		"color": Color(0.95, 0.58, 0.32, 1.0),
		"background": Color(0.34, 0.19, 0.10, 0.96)
	},
	"neutral": {
		"label": "Neutral",
		"color": Color(0.72, 0.75, 0.86, 1.0),
		"background": Color(0.20, 0.20, 0.30, 0.96)
	},
	"happy": {
		"label": "Happy",
		"color": Color(0.42, 0.94, 0.66, 1.0),
		"background": Color(0.10, 0.31, 0.22, 0.96)
	},
	"excited": {
		"label": "Excited",
		"color": Color(1.00, 0.76, 0.32, 1.0),
		"background": Color(0.36, 0.25, 0.08, 0.96)
	}
}

const STAGE_HEADER_COLORS := {
	"Stranger": {
		"background": Color(0.25, 0.13, 0.34, 0.98),
		"border": Color(0.88, 0.58, 0.96, 0.78)
	},
	"Acquaintance": {
		"background": Color(0.22, 0.16, 0.36, 0.98),
		"border": Color(0.68, 0.60, 1.00, 0.82)
	},
	"Friend": {
		"background": Color(0.15, 0.23, 0.34, 0.98),
		"border": Color(0.48, 0.82, 1.00, 0.82)
	},
	"Good Friend": {
		"background": Color(0.14, 0.28, 0.27, 0.98),
		"border": Color(0.45, 0.95, 0.75, 0.84)
	},
	"Crush": {
		"background": Color(0.34, 0.14, 0.30, 0.98),
		"border": Color(1.00, 0.52, 0.82, 0.88)
	},
	"Dating": {
		"background": Color(0.38, 0.13, 0.22, 0.98),
		"border": Color(1.00, 0.48, 0.60, 0.92)
	},
	"Soulmate": {
		"background": Color(0.34, 0.24, 0.08, 0.99),
		"border": Color(1.00, 0.82, 0.36, 0.96)
	}
}


# Must match PlayerData.RELATIONSHIP_STAGES thresholds
var relationship_stages: Array = [
	{"name": "Stranger",     "min": 0,    "max": 49,   "color": Color(0.7, 0.7, 0.75)},
	{"name": "Acquaintance", "min": 50,   "max": 149,  "color": Color(0.85, 0.75, 0.5)},
	{"name": "Friend",       "min": 150,  "max": 299,  "color": Color(1.0, 0.85, 0.4)},
	{"name": "Good Friend",  "min": 300,  "max": 599,  "color": Color(1.0, 0.6, 0.35)},
	{"name": "Crush",        "min": 600,  "max": 999,  "color": Color(1.0, 0.45, 0.7)},
	{"name": "Dating",       "min": 1000, "max": 1499, "color": Color(0.95, 0.3, 0.45)},
	{"name": "Soulmate",     "min": 1500, "max": 1500, "color": Color(0.85, 0.4, 0.95)},
]

var character_id: String = ""
var character_data: Dictionary = {}
var dialogue_timer: Timer = null
var _last_filled_hearts: int = -1

func _ready() -> void:
	for node in [
		character_name_label, character_image, dialogue_panel, dialogue_label,
		talk_button, gift_button, date_button, interaction_buttons, heart_container, stage_label,
		character_details_label, mood_panel, mood_label, mood_multiplier_label, mood_dot,
		portrait_frame, header_panel
	]:
		if not is_instance_valid(node):
			push_error("CharacterCard: required node missing")
			return

	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	transparent_style.draw_center = false
	add_theme_stylebox_override("panel", transparent_style)

	if dialogue_panel.get_parent() != character_image:
		var original_parent = dialogue_panel.get_parent()
		if original_parent:
			original_parent.remove_child(dialogue_panel)
		character_image.add_child(dialogue_panel)

	_setup_dialogue_panel()
	_setup_button_styles()
	_style_name_and_relationship()
	_add_close_button()

	talk_button.pressed.connect(_on_talk_button_pressed)
	gift_button.pressed.connect(_on_gift_button_pressed)
	date_button.pressed.connect(_on_date_button_pressed)

	if PlayerData:
		if not PlayerData.player_relationship_stage_changed.is_connected(_on_player_relationship_stage_changed):
			PlayerData.player_relationship_stage_changed.connect(_on_player_relationship_stage_changed)
		if not PlayerData.player_ap_changed.is_connected(_on_player_ap_changed):
			PlayerData.player_ap_changed.connect(_on_player_ap_changed)
	if CharacterMoodManager and not CharacterMoodManager.mood_changed.is_connected(_on_character_mood_changed):
		CharacterMoodManager.mood_changed.connect(_on_character_mood_changed)
	else:
		push_error("CharacterCard: PlayerData not found")

	create_heart_meter()

	dialogue_timer = Timer.new()
	dialogue_timer.one_shot = true
	dialogue_timer.timeout.connect(hide_dialogue)
	add_child(dialogue_timer)

func _exit_tree() -> void:
	if PlayerData:
		if PlayerData.player_relationship_stage_changed.is_connected(_on_player_relationship_stage_changed):
			PlayerData.player_relationship_stage_changed.disconnect(_on_player_relationship_stage_changed)
		if PlayerData.player_ap_changed.is_connected(_on_player_ap_changed):
			PlayerData.player_ap_changed.disconnect(_on_player_ap_changed)
	if CharacterMoodManager and CharacterMoodManager.mood_changed.is_connected(_on_character_mood_changed):
		CharacterMoodManager.mood_changed.disconnect(_on_character_mood_changed)

# ---------- Styling ----------

func _style_name_and_relationship() -> void:
	var name_bg = character_name_label.get_parent() as PanelContainer
	if name_bg:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.42, 0.22, 0.55, 0.92)
		style.set_corner_radius_all(14)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.95, 0.7, 1.0, 0.7)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		style.shadow_color = Color(0.4, 0.15, 0.55, 0.4)
		style.shadow_size = 8
		name_bg.add_theme_stylebox_override("panel", style)

	character_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 1.0, 1))
	character_name_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.2, 0.6, 0.6))
	character_name_label.add_theme_constant_override("shadow_offset_x", 2)
	character_name_label.add_theme_constant_override("shadow_offset_y", 2)

	var rel_bg = heart_container.get_parent().get_parent() as PanelContainer
	if rel_bg:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.32, 0.18, 0.42, 0.85)
		style.set_corner_radius_all(12)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.85, 0.6, 0.95, 0.5)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		rel_bg.add_theme_stylebox_override("panel", style)

func _update_header_style(stage_name: String) -> void:
	var palette: Dictionary = STAGE_HEADER_COLORS.get(
		stage_name,
		STAGE_HEADER_COLORS["Stranger"]
	)

	var style := StyleBoxFlat.new()
	style.bg_color = palette.get(
		"background",
		Color(0.25, 0.13, 0.34, 0.98)
	)
	style.border_color = palette.get(
		"border",
		Color(0.88, 0.58, 0.96, 0.78)
	)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = style.border_color.darkened(0.65)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)

	header_panel.add_theme_stylebox_override("panel", style)


func _update_profile_details() -> void:
	if character_data.is_empty():
		character_details_label.text = ""
		return

	var age := str(character_data.get("age", "—"))
	var profession := str(character_data.get("profession", "Unknown profession"))
	character_details_label.text = "%s  •  %s" % [age, profession]


func _update_mood_display() -> void:
	if character_id.is_empty() or not CharacterMoodManager:
		_apply_mood_visuals("neutral", 1.0)
		return

	var mood_name := CharacterMoodManager.get_mood(character_id)
	var multiplier := CharacterMoodManager.get_mood_multiplier(character_id)
	_apply_mood_visuals(mood_name, multiplier)


func _apply_mood_visuals(mood_name: String, multiplier: float) -> void:
	var mood_key := mood_name.to_lower()
	var visual: Dictionary = MOOD_VISUALS.get(
		mood_key,
		MOOD_VISUALS["neutral"]
	)
	var mood_color: Color = visual.get("color", Color.WHITE)
	var mood_background: Color = visual.get(
		"background",
		Color(0.20, 0.20, 0.30, 0.96)
	)

	mood_dot.color = mood_color
	mood_label.text = str(visual.get("label", "Neutral"))
	mood_label.add_theme_color_override("font_color", mood_color)
	mood_multiplier_label.text = "×%.1f RP" % multiplier
	mood_multiplier_label.add_theme_color_override(
		"font_color",
		mood_color.lightened(0.15)
	)

	var style := StyleBoxFlat.new()
	style.bg_color = mood_background
	style.border_color = mood_color.darkened(0.08)
	style.set_border_width_all(1)
	style.set_corner_radius_all(13)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	mood_panel.add_theme_stylebox_override("panel", style)


func _on_character_mood_changed(
	changed_character_id: String,
	_old_mood: String,
	_new_mood: String
) -> void:
	if changed_character_id == character_id:
		_update_mood_display()


func _setup_dialogue_panel() -> void:
	dialogue_panel.modulate.a = 0.0
	dialogue_panel.anchor_left = 0.0
	dialogue_panel.anchor_right = 1.0
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH

	var dialogue_style = StyleBoxFlat.new()
	dialogue_style.bg_color = Color(0.32, 0.18, 0.42, 0.92)
	dialogue_style.set_corner_radius_all(12)
	dialogue_style.border_width_left = 2
	dialogue_style.border_width_top = 2
	dialogue_style.border_width_right = 2
	dialogue_style.border_width_bottom = 2
	dialogue_style.border_color = Color(0.95, 0.7, 1.0, 0.6)
	dialogue_style.content_margin_left = 14
	dialogue_style.content_margin_right = 14
	dialogue_style.content_margin_top = 10
	dialogue_style.content_margin_bottom = 10
	dialogue_style.shadow_color = Color(0.4, 0.15, 0.55, 0.4)
	dialogue_style.shadow_size = 8
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)

	var emoji_font = load("res://assets/fonts/NotoSans-Regular.ttf")
	if emoji_font:
		dialogue_label.add_theme_font_override("font", emoji_font)
	dialogue_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.98, 1.0))
	dialogue_label.add_theme_color_override("font_shadow_color", Color(0.3, 0.1, 0.4, 0.7))
	dialogue_label.add_theme_constant_override("shadow_offset_x", 1)
	dialogue_label.add_theme_constant_override("shadow_offset_y", 1)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _setup_button_styles() -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.72, 0.38, 0.72, 0.95)
	normal.set_corner_radius_all(14)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.95, 0.7, 0.95, 0.85)
	normal.shadow_color = Color(0.4, 0.15, 0.55, 0.35)
	normal.shadow_size = 5
	normal.shadow_offset = Vector2(0, 2)

	var hover = normal.duplicate()
	hover.bg_color = Color(0.85, 0.48, 0.85, 1.0)
	hover.border_color = Color(1.0, 0.8, 1.0, 1.0)
	hover.shadow_size = 7

	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.6, 0.3, 0.65, 1.0)
	pressed.border_color = Color(0.9, 0.65, 0.95, 1.0)

	var disabled = normal.duplicate()
	disabled.bg_color = Color(0.3, 0.2, 0.35, 0.6)
	disabled.border_color = Color(0.5, 0.35, 0.55, 0.5)

	for button in [talk_button, gift_button, date_button]:
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("disabled", disabled)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color(0.95, 0.9, 1.0))
		button.add_theme_color_override("font_disabled_color", Color(0.6, 0.55, 0.65))

func _add_close_button() -> void:
	var close_button = Button.new()
	close_button.text = "✕  CLOSE"
	close_button.custom_minimum_size = Vector2(80, 50)
	close_button.focus_mode = Control.FOCUS_NONE

	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.75, 0.3, 0.45, 0.95)
	close_style.set_corner_radius_all(14)
	close_style.border_width_left = 2
	close_style.border_width_top = 2
	close_style.border_width_right = 2
	close_style.border_width_bottom = 2
	close_style.border_color = Color(1.0, 0.55, 0.7, 0.85)

	var close_hover = close_style.duplicate()
	close_hover.bg_color = Color(0.9, 0.4, 0.55, 1.0)
	close_hover.border_color = Color(1.0, 0.7, 0.8, 1.0)

	var close_pressed = close_style.duplicate()
	close_pressed.bg_color = Color(0.6, 0.22, 0.35, 1.0)

	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_stylebox_override("hover", close_hover)
	close_button.add_theme_stylebox_override("pressed", close_pressed)
	close_button.add_theme_font_size_override("font_size", 15)
	close_button.add_theme_color_override("font_color", Color.WHITE)

	close_button.pressed.connect(func():
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(close_requested.emit)
	)
	interaction_buttons.add_child(close_button)

# ---------- Data / display ----------

func set_character_data(data: Dictionary, revealed: bool, stats_needed_text: String = "") -> void:
	if data.is_empty() or str(data.get("id", "")).is_empty():
		push_error("CharacterCard: Invalid or empty character data!")
		return

	character_data = data
	character_id = str(data.id)
	character_name_label.text = str(data.get("name", "Unknown")) if revealed else "???"
	character_details_label.text = ""
	mood_panel.visible = revealed
	_last_filled_hearts = -1

	if revealed:
		_update_profile_details()
		_update_mood_display()
		var image_path = str(data.get("image_path", ""))
		if image_path and ResourceLoader.exists(image_path):
			character_image.texture = load(image_path)
		else:
			character_image.texture = null

		talk_button.disabled = false
		talk_button.tooltip_text = "Talk to build relationship (Costs %d AP)" % TALK_AP_COST
		update_relationship_display()
	else:
		character_image.texture = null
		for heart in heart_container.get_children():
			heart.modulate = Color(0.25, 0.2, 0.3, 0.4)
		stage_label.text = "???"
		talk_button.disabled = true
		gift_button.disabled = true
		date_button.disabled = true
		dialogue_label.text = "Requires: %s" % stats_needed_text
		_update_dialogue_panel_size()
		_animate_dialogue_panel(true)

func set_gift_button_enabled(enabled: bool) -> void:
	gift_button.disabled = not enabled

func create_heart_meter() -> void:
	for child in heart_container.get_children():
		child.queue_free()
	for i in range(10):
		var heart = TextureRect.new()
		heart.texture = preload("res://assets/images/ui_elements/heart.png")
		heart.custom_minimum_size = Vector2(24, 24)
		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart_container.add_child(heart)

func get_current_stage(points: float) -> Dictionary:
	for stage in relationship_stages:
		if points >= stage.min and points <= stage.max:
			return stage
	if points >= MAX_RELATIONSHIP_POINTS:
		return relationship_stages[relationship_stages.size() - 1]
	return relationship_stages[0]

func update_relationship_display() -> void:
	if not PlayerData or character_id.is_empty():
		return

	var points = PlayerData.get_relationship_points(character_id)
	var current_stage = get_current_stage(points)
	var stage_progress = points - current_stage.min
	var stage_range = max(1, current_stage.max - current_stage.min + 1)
	var stage_percentage = clampf(float(stage_progress) / float(stage_range), 0.0, 1.0)

	var hearts = heart_container.get_children()
	var filled_hearts = int(stage_percentage * hearts.size())
	if points >= MAX_RELATIONSHIP_POINTS:
		filled_hearts = hearts.size()

	for i in range(hearts.size()):
		var heart = hearts[i] as TextureRect
		if i < filled_hearts:
			heart.modulate = current_stage.color
			if filled_hearts != _last_filled_hearts and i == filled_hearts - 1:
				_animate_heart_fill(heart)
		else:
			heart.modulate = Color(0.3, 0.25, 0.35, 0.5)
	_last_filled_hearts = filled_hearts

	var stage_name = str(current_stage.name)
	_update_header_style(stage_name)

	stage_label.text = "%s  •  %.1f / %d" % [
		stage_name,
		stage_progress,
		stage_range
	]
	stage_label.add_theme_color_override("font_color", current_stage.color.lerp(Color.WHITE, 0.35))
	heart_container.tooltip_text = ("%s (%.1f/%d in stage) • Total: %.1f/%d points"
		% [stage_name, stage_progress, stage_range, points, MAX_RELATIONSHIP_POINTS])

	# Use PlayerData stage string so unlocks stay consistent
	var pd_stage = PlayerData.get_relationship_stage(character_id)
	_update_header_style(pd_stage)

	gift_button.disabled = not (pd_stage in ["Good Friend", "Crush", "Dating", "Soulmate"])
	gift_button.tooltip_text = "Give a gift" if not gift_button.disabled else "Requires Good Friend status"

	var can_date = pd_stage in ["Friend", "Good Friend", "Crush", "Dating", "Soulmate"] \
		and PlayerData.has_ap(DATE_MIN_AP)
	date_button.disabled = not can_date
	date_button.tooltip_text = _get_date_button_tooltip(pd_stage, PlayerData.action_points)
	talk_button.tooltip_text = "Talk to build relationship (Costs %d AP)" % TALK_AP_COST
	talk_button.disabled = not PlayerData.has_ap(TALK_AP_COST)

func _get_date_button_tooltip(stage: String, ap: int) -> String:
	var stage_ok = stage in ["Friend", "Good Friend", "Crush", "Dating", "Soulmate"]
	var ap_ok = ap >= DATE_MIN_AP
	if stage_ok and ap_ok:
		return "Ready to date!"
	if not stage_ok and not ap_ok:
		return "Requires Friend status and %d AP" % DATE_MIN_AP
	if not stage_ok:
		return "Requires Friend status"
	return "Requires %d AP" % DATE_MIN_AP

func _animate_heart_fill(heart: TextureRect) -> void:
	var tween = create_tween().set_parallel(true)
	heart.scale = Vector2.ONE
	tween.tween_property(heart, "scale", Vector2(1.25, 1.25), 0.1)
	tween.tween_property(heart, "scale", Vector2.ONE, 0.12).set_delay(0.1)

func _on_player_relationship_stage_changed(changed_character_id: String, _new_stage: String) -> void:
	if changed_character_id == character_id:
		update_relationship_display()

func _on_player_ap_changed(_ap: int) -> void:
	if character_id.is_empty():
		return
	update_relationship_display()

# ---------- Talk / dialogue ----------

func show_dialogue() -> bool:
	if not PlayerData:
		return false

	if not PlayerData.has_ap(TALK_AP_COST):
		dialogue_label.text = "Not enough AP to talk!"
		_update_dialogue_panel_size()
		_animate_dialogue_panel(true)
		return false

	var current_stage := PlayerData.get_relationship_stage(character_id)
	var dialogues := _get_dialogues_for_stage(current_stage)

	if dialogues.is_empty():
		dialogues = [
			"Hello there!",
			"Nice to see you!",
			"How's it going?"
		]

	var old_points := PlayerData.get_relationship_points(character_id)

	PlayerData.consume_ap(TALK_AP_COST)

	var gained_points := PlayerData.add_talk_relationship_points(
		character_id,
		TALK_RELATIONSHIP_POINTS
	)

	dialogue_label.text = dialogues[randi() % dialogues.size()]
	dialogue_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.92, 0.98, 1.0)
	)

	var new_points := PlayerData.get_relationship_points(character_id)
	var stage_changed := _check_for_stage_completion(
		old_points,
		new_points
	)

	update_relationship_display()

	_show_mood_reward_notification(gained_points)

	_update_dialogue_panel_size()
	_animate_dialogue_panel(true)

	return stage_changed

func _get_dialogues_for_stage(stage: String) -> Array:
	var stage_names: Array = []
	for s in relationship_stages:
		stage_names.append(s.name)
	var current_index = stage_names.find(stage)
	if current_index == -1:
		current_index = 0

	if character_data.has("dialogue_by_stage"):
		var dialogue_by_stage = character_data.dialogue_by_stage
		for i in range(current_index, -1, -1):
			var test_stage = stage_names[i]
			if dialogue_by_stage.has(test_stage) and dialogue_by_stage[test_stage] is Array \
					and not dialogue_by_stage[test_stage].is_empty():
				return dialogue_by_stage[test_stage]

	if character_data.has("dialogue") and character_data.dialogue is Array and not character_data.dialogue.is_empty():
		return character_data.dialogue

	return []

func _check_for_stage_completion(old_points: float, new_points: float) -> bool:
	var old_stage = get_current_stage(old_points)
	var new_stage = get_current_stage(new_points)
	if old_stage.name == new_stage.name:
		return false
	_show_stage_change_dialogue(new_stage.name)
	_create_stage_completion_effect()
	return true

func _show_stage_change_dialogue(new_stage: String) -> void:
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
			"You're a really good friend to me.",
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
			"*loving embrace* This is forever, isn't it?"
		],
	}
	if not stage_change_dialogues.has(new_stage):
		return
	var special: Array = stage_change_dialogues[new_stage]
	dialogue_label.text = "💕 " + special[randi() % special.size()] + " 💕"
	dialogue_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.8, 1.0))
	_update_dialogue_panel_size()

func _create_stage_completion_effect() -> void:
	var completion_label = Label.new()
	completion_label.text = "💕 Stage Up! 💕"
	completion_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.9))
	completion_label.add_theme_font_size_override("font_size", 22)
	completion_label.add_theme_color_override("font_shadow_color", Color(0.3, 0.1, 0.4, 0.8))
	completion_label.add_theme_constant_override("shadow_offset_x", 2)
	completion_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(completion_label)
	completion_label.position = stage_label.global_position - global_position + Vector2(0, -36)

	var tween = create_tween()
	tween.tween_property(completion_label, "modulate:a", 1.0, 0.15)
	tween.tween_property(completion_label, "position:y", completion_label.position.y - 18, 0.9)
	tween.tween_property(completion_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(completion_label.queue_free)

	for heart in heart_container.get_children():
		var ht = create_tween().set_loops(2)
		ht.tween_property(heart, "scale", Vector2(1.2, 1.2), 0.15)
		ht.tween_property(heart, "scale", Vector2.ONE, 0.15)

func _update_dialogue_panel_size() -> void:
	await get_tree().process_frame
	if not is_instance_valid(dialogue_label) or not is_instance_valid(dialogue_panel):
		return
	var font = dialogue_label.get_theme_font("font")
	var font_size = dialogue_label.get_theme_font_size("font_size")
	var text_size = font.get_string_size(dialogue_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var label_width = min(text_size.x + 24, character_image.size.x * 0.92)
	dialogue_label.custom_minimum_size.x = label_width
	var label_size = dialogue_label.get_rect().size
	var panel_height = label_size.y + 24
	dialogue_panel.offset_top = -panel_height
	dialogue_panel.offset_bottom = 0.0

func _animate_dialogue_panel(should_show: bool) -> void:
	var target_alpha = 0.95 if should_show else 0.0
	if is_equal_approx(dialogue_panel.modulate.a, target_alpha):
		return
	var tween = create_tween()
	tween.tween_property(dialogue_panel, "modulate:a", target_alpha, 0.28)

func hide_dialogue() -> void:
	_animate_dialogue_panel(false)
func _show_mood_reward_notification(gained_points: float) -> void:
	if not UIManager:
		return

	var character_name := str(
		character_data.get("name", "Character")
	)
	var mood_name := "Neutral"
	var multiplier := 1.0

	if CharacterMoodManager:
		mood_name = CharacterMoodManager.get_mood_display_name(
			character_id
		)
		multiplier = CharacterMoodManager.get_mood_multiplier(
			character_id
		)

	if gained_points <= 0.0:
		UIManager.show_notification(
			"%s is %s. Relationship did not increase."
			% [character_name, mood_name.to_lower()]
		)
		return

	UIManager.show_notification(
		"%s is %s • Relationship +%.1f (×%.1f)"
		% [
			character_name,
			mood_name,
			gained_points,
			multiplier
		]
	)

# ---------- Buttons ----------

func _on_talk_button_pressed() -> void:
	if dialogue_timer and dialogue_timer.time_left > 0.0:
		dialogue_timer.stop()
	var stage_changed = show_dialogue()
	dialogue_timer.start(7.0 if stage_changed else 5.0)

func _on_gift_button_pressed() -> void:
	gift_requested.emit(character_id, character_data)

func _on_date_button_pressed() -> void:
	date_requested.emit(character_id, character_data)
