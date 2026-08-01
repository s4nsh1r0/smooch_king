extends CanvasLayer
class_name WordGuessMinigame

signal finished(won: bool)

const WORD_LENGTH := 5
const MAX_TRIES := 5
const AP_REWARD := 1

const WORD_POOL: PackedStringArray = [
	"CRUSH","HEART","SMILE","FLIRT","CHARM","LOVER","SWEET","BLUSH","HONEY","ANGEL",
	"QUEEN","DREAM","HAPPY","BRAVE","FUNNY","WITTY","SUNNY","PARTY","DANCE","MUSIC",
	"BEATS","CLUBS","LIGHT","SHINE","CLASS","NOTES","BOOKS","MAJOR","STUDY","EXAMS",
	"GRADE","PAPER","TUTOR","ESSAY","DRAMA","SCENE","STAGE","ACTOR","LINES","DATES",
	"LATTE","SUGAR","CANDY","COCOA","DORMS","HALLS","MATCH","SCORE","ADORE","COURT",
	"TEASE","POWER","GRACE","ROSES","PETAL","BLOOM","LILAC","PEACH","BERRY","GRAPE",
	"MANGO","LEMON","CREAM","FROST","GLOWY","SPARK","FLAME","FIREY","MOODS","PEACE",
	"LAUGH","JOKES","HUMOR","YOUTH","FRESH","CLEAN","PRIDE","GLORY","HONOR","FAITH",
	"NOVEL","POEMS","STORY","TALES","MYTHS","PHONE","TEXTS","CHATS","VIDEO","CALLS",
	"GROUP","TRAIN","WORKS","SKILL","LEVEL","FOCUS","BRAIN","SMART","ALERT","QUICK"
]

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var grid: VBoxContainer = %Grid
@onready var keyboard: VBoxContainer = %Keyboard
@onready var close_button: Button = %CloseButton

var secret: String = ""
var current_row: int = 0
var current_col: int = 0
var rows: Array = []          # Array of Array[PanelContainer]
var labels: Array = []        # Array of Array[Label]
var game_over: bool = false
var key_buttons: Dictionary = {}  # letter -> Button
var row_guesses: Array[String] = []

func _ready() -> void:
	layer = 130
	_build_grid()
	_build_keyboard()
	close_button.pressed.connect(_on_close)
	_style_close()
	_reset_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_close()
			get_viewport().set_input_as_handled()
			return
		if game_over:
			return
		var key = event.keycode
		if key == KEY_ENTER or key == KEY_KP_ENTER:
			_submit()
			get_viewport().set_input_as_handled()
		elif key == KEY_BACKSPACE:
			_backspace()
			get_viewport().set_input_as_handled()
		else:
			var ch = char(event.unicode).to_upper()
			if ch.length() == 1 and ch >= "A" and ch <= "Z":
				_type_letter(ch)
				get_viewport().set_input_as_handled()

func _reset_game() -> void:
	game_over = false
	current_row = 0
	current_col = 0
	row_guesses.clear()
	secret = WORD_POOL[randi() % WORD_POOL.size()]
	message_label.text = "Guess the 5-letter campus word. %d tries." % MAX_TRIES
	for r in MAX_TRIES:
		for c in WORD_LENGTH:
			labels[r][c].text = ""
			_set_tile_style(rows[r][c], Color(0.28, 0.16, 0.38, 0.95), Color(0.7, 0.5, 0.9, 0.6))
	for letter in key_buttons:
		_set_key_style(key_buttons[letter], Color(0.45, 0.28, 0.55, 0.95))

func _build_grid() -> void:
	for child in grid.get_children():
		child.queue_free()
	rows.clear()
	labels.clear()
	for r in MAX_TRIES:
		var h = HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 8)
		grid.add_child(h)
		var row_panels: Array = []
		var row_labels: Array = []
		for c in WORD_LENGTH:
			var panel = PanelContainer.new()
			panel.custom_minimum_size = Vector2(52, 52)
			_set_tile_style(panel, Color(0.28, 0.16, 0.38, 0.95), Color(0.7, 0.5, 0.9, 0.6))
			var lab = Label.new()
			lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lab.add_theme_font_size_override("font_size", 26)
			lab.add_theme_color_override("font_color", Color.WHITE)
			lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lab.size_flags_vertical = Control.SIZE_EXPAND_FILL
			panel.add_child(lab)
			h.add_child(panel)
			row_panels.append(panel)
			row_labels.append(lab)
		rows.append(row_panels)
		labels.append(row_labels)

func _build_keyboard() -> void:
	for child in keyboard.get_children():
		child.queue_free()
	key_buttons.clear()
	var rows_keys = [
		["Q","W","E","R","T","Y","U","I","O","P"],
		["A","S","D","F","G","H","J","K","L"],
		["ENTER","Z","X","C","V","B","N","M","⌫"]
	]
	for row in rows_keys:
		var h = HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 6)
		keyboard.add_child(h)
		for key in row:
			var btn = Button.new()
			btn.focus_mode = Control.FOCUS_NONE
			btn.text = key
			if key == "ENTER" or key == "⌫":
				btn.custom_minimum_size = Vector2(64, 42)
			else:
				btn.custom_minimum_size = Vector2(36, 42)
			_set_key_style(btn, Color(0.45, 0.28, 0.55, 0.95))
			var k = key
			btn.pressed.connect(func(): _on_key(k))
			h.add_child(btn)
			if key.length() == 1:
				key_buttons[key] = btn

func _on_key(key: String) -> void:
	if game_over:
		return
	if key == "ENTER":
		_submit()
	elif key == "⌫":
		_backspace()
	else:
		_type_letter(key)

func _type_letter(ch: String) -> void:
	if current_col >= WORD_LENGTH or current_row >= MAX_TRIES:
		return
	labels[current_row][current_col].text = ch
	current_col += 1

func _backspace() -> void:
	if current_col <= 0:
		return
	current_col -= 1
	labels[current_row][current_col].text = ""

func _submit() -> void:
	if game_over or current_col < WORD_LENGTH:
		message_label.text = "Need %d letters." % WORD_LENGTH
		return
	var guess := ""
	for c in WORD_LENGTH:
		guess += labels[current_row][c].text
	guess = guess.to_upper()
	if guess not in WORD_POOL:
		message_label.text = "Not in word list."
		return

	var result = _evaluate(guess, secret)
	for c in WORD_LENGTH:
		match result[c]:
			"green":
				_set_tile_style(rows[current_row][c], Color(0.25, 0.7, 0.4, 1.0), Color(0.4, 0.95, 0.55, 1.0))
				if key_buttons.has(guess[c]):
					_set_key_style(key_buttons[guess[c]], Color(0.25, 0.7, 0.4, 1.0))
			"yellow":
				_set_tile_style(rows[current_row][c], Color(0.85, 0.6, 0.15, 1.0), Color(1.0, 0.75, 0.25, 1.0))
				if key_buttons.has(guess[c]):
					var kb: Button = key_buttons[guess[c]]
					# don't downgrade green keys
					if not _key_is_green(kb):
						_set_key_style(kb, Color(0.85, 0.6, 0.15, 1.0))
			_:
				_set_tile_style(rows[current_row][c], Color(0.35, 0.32, 0.38, 1.0), Color(0.5, 0.45, 0.55, 0.9))
				if key_buttons.has(guess[c]):
					var kb2: Button = key_buttons[guess[c]]
					if not _key_is_green(kb2) and not _key_is_yellow(kb2):
						_set_key_style(kb2, Color(0.3, 0.28, 0.32, 1.0))

	if guess == secret:
		_win()
		return
	current_row += 1
	current_col = 0
	if current_row >= MAX_TRIES:
		_lose()
	else:
		message_label.text = "Tries left: %d" % (MAX_TRIES - current_row)

func _evaluate(guess: String, target: String) -> Array:
	var result: Array = []
	result.resize(WORD_LENGTH)
	var used: Array[bool] = []
	used.resize(WORD_LENGTH)
	for i in WORD_LENGTH:
		used[i] = false
		result[i] = "grey"
	# greens
	for i in WORD_LENGTH:
		if guess[i] == target[i]:
			result[i] = "green"
			used[i] = true
	# yellows
	for i in WORD_LENGTH:
		if result[i] == "green":
			continue
		for j in WORD_LENGTH:
			if used[j]:
				continue
			if guess[i] == target[j]:
				result[i] = "yellow"
				used[j] = true
				break
	return result

func _key_is_green(btn: Button) -> bool:
	var s = btn.get_theme_stylebox("normal")
	return s is StyleBoxFlat and (s as StyleBoxFlat).bg_color.g > 0.55

func _key_is_yellow(btn: Button) -> bool:
	var s = btn.get_theme_stylebox("normal")
	return s is StyleBoxFlat and (s as StyleBoxFlat).bg_color.r > 0.7 and (s as StyleBoxFlat).bg_color.g > 0.5

func _set_tile_style(panel: PanelContainer, bg: Color, border: Color) -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(10)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = border
	panel.add_theme_stylebox_override("panel", s)

func _set_key_style(btn: Button, bg: Color) -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = bg.lightened(0.12)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 14)

func _style_close() -> void:
	close_button.focus_mode = Control.FOCUS_NONE
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.55, 0.25, 0.4, 0.95)
	s.set_corner_radius_all(12)
	close_button.add_theme_stylebox_override("normal", s)
	close_button.add_theme_color_override("font_color", Color.WHITE)

func _win() -> void:
	game_over = true
	message_label.text = "Correct! +%d AP" % AP_REWARD
	if PlayerData and PlayerData.has_method("add_action_points"):
		PlayerData.add_action_points(AP_REWARD)
	await get_tree().create_timer(1.2).timeout
	finished.emit(true)
	queue_free()

func _lose() -> void:
	game_over = true
	message_label.text = "Out of tries. Word was %s." % secret
	await get_tree().create_timer(1.8).timeout
	finished.emit(false)
	queue_free()

func _on_close() -> void:
	if not game_over:
		finished.emit(false)
	queue_free()
