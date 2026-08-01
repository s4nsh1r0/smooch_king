extends CanvasLayer
class_name PinGuessMinigame

signal finished(won: bool)

const DIGIT_COUNT := 4
const MAX_TRIES := 4
const AP_REWARD := 1

@onready var title_label: Label = %TitleLabel
@onready var tries_label: Label = %TriesLabel
@onready var message_label: Label = %MessageLabel
@onready var digits_row: HBoxContainer = %DigitsRow
@onready var submit_button: Button = %SubmitButton
@onready var close_button: Button = %CloseButton

var secret: Array[int] = []
var tries_left: int = MAX_TRIES
var locked: Array[bool] = []
var digit_values: Array[int] = []
var digit_labels: Array[Label] = []
var up_buttons: Array[Button] = []
var down_buttons: Array[Button] = []
var digit_panels: Array[PanelContainer] = []
var game_over: bool = false

func _ready() -> void:
	layer = 130
	_build_digit_slots()
	submit_button.pressed.connect(_on_submit)
	close_button.pressed.connect(_on_close)
	_reset_game()
	_style_ui()

func _build_digit_slots() -> void:
	for child in digits_row.get_children():
		child.queue_free()
	digit_labels.clear()
	up_buttons.clear()
	down_buttons.clear()
	digit_panels.clear()
	digit_values.clear()
	locked.clear()

	for i in DIGIT_COUNT:
		digit_values.append(0)
		locked.append(false)

		var panel = PanelContainer.new()
		var pstyle = StyleBoxFlat.new()
		pstyle.bg_color = Color(0.25, 0.14, 0.34, 0.95)
		pstyle.set_corner_radius_all(14)
		pstyle.border_width_left = 2
		pstyle.border_width_top = 2
		pstyle.border_width_right = 2
		pstyle.border_width_bottom = 2
		pstyle.border_color = Color(0.85, 0.6, 0.95, 0.7)
		pstyle.content_margin_left = 10
		pstyle.content_margin_right = 10
		pstyle.content_margin_top = 8
		pstyle.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", pstyle)
		panel.custom_minimum_size = Vector2(72, 140)
		digits_row.add_child(panel)
		digit_panels.append(panel)

		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		panel.add_child(vbox)

		var up = Button.new()
		up.text = "▲"
		up.focus_mode = Control.FOCUS_NONE
		up.custom_minimum_size = Vector2(56, 28)
		_style_arrow(up)
		var idx = i
		up.pressed.connect(func(): _nudge(idx, 1))
		vbox.add_child(up)
		up_buttons.append(up)

		var lab = Label.new()
		lab.text = "0"
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 36)
		lab.add_theme_color_override("font_color", Color.WHITE)
		lab.custom_minimum_size = Vector2(56, 40)
		vbox.add_child(lab)
		digit_labels.append(lab)

		var down = Button.new()
		down.text = "▼"
		down.focus_mode = Control.FOCUS_NONE
		down.custom_minimum_size = Vector2(56, 28)
		_style_arrow(down)
		down.pressed.connect(func(): _nudge(idx, -1))
		vbox.add_child(down)
		down_buttons.append(down)

func _style_arrow(btn: Button) -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.55, 0.3, 0.7, 0.9)
	s.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = Color(0.7, 0.4, 0.85, 1.0)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _style_ui() -> void:
	# Panel already in scene; light polish on buttons
	for b in [submit_button, close_button]:
		if not b:
			continue
		b.focus_mode = Control.FOCUS_NONE
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.72, 0.38, 0.72, 0.95)
		s.set_corner_radius_all(14)
		s.border_width_left = 2
		s.border_width_top = 2
		s.border_width_right = 2
		s.border_width_bottom = 2
		s.border_color = Color(0.95, 0.7, 0.95, 0.85)
		b.add_theme_stylebox_override("normal", s)
		var h = s.duplicate()
		h.bg_color = Color(0.85, 0.48, 0.85, 1.0)
		b.add_theme_stylebox_override("hover", h)
		b.add_theme_color_override("font_color", Color.WHITE)

func _reset_game() -> void:
	game_over = false
	tries_left = MAX_TRIES
	secret = _generate_unique_pin()
	for i in DIGIT_COUNT:
		digit_values[i] = 0
		locked[i] = false
		digit_labels[i].text = "0"
		digit_labels[i].add_theme_color_override("font_color", Color.WHITE)
		up_buttons[i].disabled = false
		down_buttons[i].disabled = false
		_set_panel_border(i, Color(0.85, 0.6, 0.95, 0.7))
	tries_label.text = "Tries left: %d" % tries_left
	message_label.text = "Guess the %d-digit code (no repeats)." % DIGIT_COUNT
	submit_button.disabled = false
	submit_button.text = "Submit"

func _generate_unique_pin() -> Array[int]:
	var pool: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	pool.shuffle()
	var result: Array[int] = []
	for i in DIGIT_COUNT:
		result.append(pool[i])
	return result

func _nudge(index: int, delta: int) -> void:
	if game_over or locked[index]:
		return
	var v = (digit_values[index] + delta) % 10
	if v < 0:
		v = 9
	digit_values[index] = v
	digit_labels[index].text = str(v)
	# Visual hint if this digit is already used elsewhere
	_refresh_digit_hint(index)

func _refresh_digit_hint(index: int) -> void:
	if locked[index]:
		return
	var v = digit_values[index]
	var is_duplicate := false
	for i in DIGIT_COUNT:
		if i != index and digit_values[i] == v:
			is_duplicate = true
			break
	if is_duplicate:
		digit_labels[index].add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	else:
		digit_labels[index].add_theme_color_override("font_color", Color.WHITE)

func _on_submit() -> void:
	if game_over:
		return
	# Player digits must be unique among unlocked? allow submit even if player repeats
	# Prefer blocking duplicate guesses for clarity
	if not _player_digits_unique():
		message_label.text = "Use different digits in each slot."
		return

	tries_left -= 1
	tries_label.text = "Tries left: %d" % tries_left

	var result = _evaluate()
	# result[i]: "green" | "orange" | "none"
	for i in DIGIT_COUNT:
		if locked[i]:
			continue
		match result[i]:
			"green":
				locked[i] = true
				digit_labels[i].add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
				up_buttons[i].disabled = true
				down_buttons[i].disabled = true
				_set_panel_border(i, Color(0.4, 0.95, 0.55, 0.95))
			"orange":
				digit_labels[i].add_theme_color_override("font_color", Color(1.0, 0.7, 0.25))
				_set_panel_border(i, Color(1.0, 0.65, 0.2, 0.9))
			_:
				digit_labels[i].add_theme_color_override("font_color", Color(1.0, 0.45, 0.5))
				_set_panel_border(i, Color(0.9, 0.35, 0.45, 0.85))

	if _all_locked():
		_win()
		return
	if tries_left <= 0:
		_lose()
		return
	message_label.text = "Keep going…"

func _player_digits_unique() -> bool:
	var seen: Dictionary = {}
	for v in digit_values:
		if seen.has(v):
			return false
		seen[v] = true
	return true

func _evaluate() -> Array:
	# Two-pass like Mastermind with unique secret
	var result: Array = []
	result.resize(DIGIT_COUNT)
	var secret_used: Array[bool] = []
	secret_used.resize(DIGIT_COUNT)
	for i in DIGIT_COUNT:
		secret_used[i] = false
		result[i] = "none"

	# Exact matches first
	for i in DIGIT_COUNT:
		if digit_values[i] == secret[i]:
			result[i] = "green"
			secret_used[i] = true

	# Then present-but-wrong-place
	for i in DIGIT_COUNT:
		if result[i] == "green":
			continue
		for j in DIGIT_COUNT:
			if secret_used[j]:
				continue
			if digit_values[i] == secret[j]:
				result[i] = "orange"
				secret_used[j] = true
				break
	return result

func _all_locked() -> bool:
	for i in DIGIT_COUNT:
		if not locked[i]:
			return false
	return true

func _set_panel_border(index: int, color: Color) -> void:
	var panel = digit_panels[index]
	var style = panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var s = (style as StyleBoxFlat).duplicate()
		s.border_color = color
		panel.add_theme_stylebox_override("panel", s)

func _win() -> void:
	game_over = true
	submit_button.disabled = true
	message_label.text = "Cracked! +%d AP" % AP_REWARD
	if PlayerData and PlayerData.has_method("add_action_points"):
		PlayerData.add_action_points(AP_REWARD)
	elif PlayerData and "action_points" in PlayerData:
		PlayerData.action_points += AP_REWARD
	await get_tree().create_timer(1.2).timeout
	finished.emit(true)
	queue_free()

func _lose() -> void:
	game_over = true
	submit_button.disabled = true
	var code = ""
	for d in secret:
		code += str(d)
	message_label.text = "Out of tries. Code was %s." % code
	await get_tree().create_timer(1.8).timeout
	finished.emit(false)
	queue_free()

func _on_close() -> void:
	if not game_over:
		finished.emit(false)
	queue_free()
