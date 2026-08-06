extends Control

@onready var name_input: LineEdit = %InputBox
@onready var loading_label: Label = %LoadingMessage
@onready var new_game_button: Button = %NewGameButton
@onready var load_game_button: Button = %LoadGameButton
@onready var exit_button: Button = %ExitButton
@onready var back_button: Button = %BackButton
@onready var confirm_button: Button = %ConfirmButton
@onready var name_entry_container: HBoxContainer = %NameEntryContainer

const SlotsScene = preload("res://scenes/ui/load_game.tscn")
const ConfirmationDialogScene = preload("res://scenes/ui/confirmation_dialogue.tscn")

var slots_scene: Control = null
var exit_confirmation_dialog: Control = null
var options_overlay: Control = null
var selected_slot_id: int = 0

const LOADING_TIME := 2.0

enum State { MAIN_MENU, SLOTS, NAME_ENTRY, LOADING, OPTIONS }
var current_state: State = State.MAIN_MENU

func _ready() -> void:
	_set_state(State.MAIN_MENU)
	_fade_in_menu()
	
	if new_game_button:
		new_game_button.text = "Start Game"
	if load_game_button:
		load_game_button.text = "Options"
	
	if confirm_button and not confirm_button.pressed.is_connected(_on_confirm_pressed):
		confirm_button.pressed.connect(_on_confirm_pressed)
	if name_input and not name_input.text_submitted.is_connected(_on_name_submitted):
		name_input.text_submitted.connect(_on_name_submitted)
	if load_game_button and not load_game_button.pressed.is_connected(_on_options_pressed):
		load_game_button.pressed.connect(_on_options_pressed)
	
	if LocationManager:
		LocationManager.set_current_location({
	"name": "Start Scene",
	"type": "menu",
	"scene_path": "res://scenes/main/start_scene.tscn"
})

func _set_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.MAIN_MENU:
			_hide_options_overlay()
			new_game_button.visible = true
			load_game_button.visible = true
			exit_button.visible = true
			back_button.visible = false
			name_entry_container.visible = false
			loading_label.visible = false
			if slots_scene:
				slots_scene.visible = false
		State.SLOTS:
			new_game_button.visible = false
			load_game_button.visible = false
			exit_button.visible = false
			back_button.visible = false
			name_entry_container.visible = false
			loading_label.visible = false
		State.NAME_ENTRY:
			new_game_button.visible = false
			load_game_button.visible = false
			exit_button.visible = true
			back_button.visible = true
			name_entry_container.visible = true
			loading_label.visible = false
			if slots_scene:
				slots_scene.visible = false
			name_input.grab_focus()
		State.LOADING:
			new_game_button.visible = false
			load_game_button.visible = false
			exit_button.visible = false
			back_button.visible = false
			name_entry_container.visible = false
			loading_label.visible = true
			if slots_scene:
				slots_scene.visible = false
		State.OPTIONS:
			new_game_button.visible = false
			load_game_button.visible = false
			exit_button.visible = true
			back_button.visible = true
			name_entry_container.visible = false
			loading_label.visible = false

func _on_new_game_button_pressed() -> void:
	_open_slots()

func _open_slots() -> void:
	if not slots_scene:
		slots_scene = SlotsScene.instantiate()
		add_child(slots_scene)
		slots_scene.create_slot_requested.connect(_on_create_slot)
		slots_scene.continue_slot_requested.connect(_on_continue_slot)
		slots_scene.back_requested.connect(_on_slots_back)
	_set_state(State.SLOTS)
	slots_scene.visible = true
	slots_scene.refresh_save_list()

func _on_slots_back() -> void:
	_set_state(State.MAIN_MENU)

func _on_create_slot(slot_id: int) -> void:
	selected_slot_id = slot_id
	name_input.text = ""
	_set_state(State.NAME_ENTRY)

func _on_continue_slot(slot_id: int) -> void:
	selected_slot_id = slot_id
	loading_label.text = "Loading..."
	_set_state(State.LOADING)
	if not SaveManager.load_completed.is_connected(_on_load_completed):
		SaveManager.load_completed.connect(_on_load_completed)
	SaveManager.load_slot(slot_id)

func _on_back_button_pressed() -> void:
	if current_state == State.NAME_ENTRY:
		_open_slots()
	else:
		if current_state == State.OPTIONS:
			SoundManager.play_panel_close()
		_set_state(State.MAIN_MENU)
	name_input.text = ""

func _on_confirm_pressed() -> void:
	_on_name_submitted(name_input.text)

func _on_name_submitted(new_text: String) -> void:
	new_text = new_text.strip_edges()
	if new_text.is_empty():
		new_text = "Player"
	if not PlayerData or not SaveManager:
		loading_label.text = "Error: systems missing"
		_set_state(State.LOADING)
		return
	
	_reset_player_for_new_game(new_text, selected_slot_id)
	var result = SaveManager.save_to_slot(selected_slot_id, PlayerData)
	if result.success:
		_start_new_game()
	else:
		loading_label.text = "Error: " + str(result.message)
		_set_state(State.LOADING)

func _reset_player_for_new_game(player_name: String, slot_id: int) -> void:
	PlayerData.set_player_name(player_name)
	PlayerData.current_slot_id = slot_id
	PlayerData.money = 100.0

	# AP: 50 start, timer begins now
	PlayerData.action_points = PlayerData.AP_STARTING  # 50
	PlayerData.ap_progress = 0.0
	PlayerData.last_ap_progress_tick = Time.get_unix_time_from_system()

	PlayerData.is_activity_active = false
	PlayerData.current_activity_data = {}
	PlayerData.activity_started_at = 0.0
	PlayerData.activity_full_rate_until = 0.0
	PlayerData.activity_last_tick_at = 0.0
	PlayerData.relationships = {}
	PlayerData.character_date_progress = {}
	PlayerData.last_date_times = {}
	PlayerData.completed_dates = {}
	PlayerData.inventory = {}
	PlayerData.job_hours_worked = {}
	PlayerData._pending_continue_activity = {}

	for s in ["strength", "agility", "endurance", "balance"]:
		PlayerData.set_physical_stat(s, 1.0)
	for s in ["knowledge", "wisdom", "intelligence", "logic"]:
		PlayerData.set_mental_stat(s, 1.0)
	for s in ["leadership", "persuasion", "charisma", "communication"]:
		PlayerData.set_social_stat(s, 1.0)

	PlayerData.current_location = {
		"name": "Intro",
		"type": "normal",
		"scene_path": "res://scenes/main/intro_scene.tscn"
	}

	PlayerData.player_ap_changed.emit(PlayerData.action_points)
	PlayerData.player_ap_progress_changed.emit(PlayerData.ap_progress, PlayerData.AP_INTERVAL_SECONDS)
	if CharacterMoodManager:
		CharacterMoodManager.reset_all_moods()

func _start_new_game() -> void:
	loading_label.text = "Entering Paradise City..."
	_set_state(State.LOADING)
	await get_tree().create_timer(LOADING_TIME).timeout
	if GameManager:
		GameManager.change_to_scene("res://scenes/main/intro_scene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main/intro_scene.tscn")

func _on_load_completed(success: bool, message: String) -> void:
	if SaveManager.load_completed.is_connected(_on_load_completed):
		SaveManager.load_completed.disconnect(_on_load_completed)
	if success:
		var scene_path = "res://scenes/main/intro_scene.tscn"
		if PlayerData and PlayerData.current_location.has("scene_path"):
			scene_path = PlayerData.current_location.scene_path
		if GameManager:
			GameManager.change_to_scene(scene_path)
		else:
			get_tree().change_scene_to_file(scene_path)
	else:
		loading_label.text = "Load failed: " + message
		await get_tree().create_timer(2.0).timeout
		_open_slots()

func _on_options_pressed() -> void:
	_set_state(State.OPTIONS)
	_show_options_overlay()
	SoundManager.play_panel_open()


func _show_options_overlay() -> void:
	if not is_instance_valid(options_overlay):
		options_overlay = _build_options_overlay()
		add_child(options_overlay)
	options_overlay.visible = true


func _hide_options_overlay() -> void:
	if is_instance_valid(options_overlay):
		options_overlay.visible = false


func _build_options_overlay() -> Control:
	var overlay := Control.new()
	overlay.name = "OptionsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 210)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-220, -105)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.10, 0.28, 0.96)
	style.border_color = Color(0.95, 0.55, 0.78, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)

	var title := Label.new()
	title.text = "AUDIO OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	content.add_child(title)

	var volume_label := Label.new()
	volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(volume_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = SoundManager.get_master_volume() * 100.0
	slider.custom_minimum_size = Vector2(380, 36)
	content.add_child(slider)
	volume_label.text = "Master Volume: %d%%" % int(slider.value)
	slider.value_changed.connect(func(value: float) -> void:
		SoundManager.set_master_volume(value / 100.0)
		volume_label.text = "Master Volume: %d%%" % int(value)
	)

	var hint := Label.new()
	hint.text = "Controls music and sound effects"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.7)
	content.add_child(hint)
	return overlay

func _on_exit_button_pressed() -> void:
	if not exit_confirmation_dialog:
		exit_confirmation_dialog = ConfirmationDialogScene.instantiate()
		add_child(exit_confirmation_dialog)
		exit_confirmation_dialog.confirmed.connect(func(): get_tree().quit())
	exit_confirmation_dialog.show_confirmation(
		"Are you sure you want to quit?",
		"Yes, Quit",
		"Cancel"
	)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		match current_state:
			State.NAME_ENTRY:
				_on_back_button_pressed()
				get_viewport().set_input_as_handled()
			State.SLOTS:
				_on_slots_back()
				get_viewport().set_input_as_handled()
			State.OPTIONS:
				_on_back_button_pressed()
				get_viewport().set_input_as_handled()

func _fade_in_menu() -> void:
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
