extends Control

@onready var name_input = $InputBox
@onready var loading_label = $LoadingMessage
@onready var new_game_button = %NewGameButton
@onready var load_game_button = %LoadGameButton
@onready var exit_button = %ExitButton
@onready var back_button = %BackButton

# Load the load game scene
const LoadGameScene = preload("res://ui/load_game.tscn")
var load_game_scene: Control = null

const LOADING_TIME = 3.0

func _ready() -> void:
	print("StartScreen: Scene loaded successfully")
	# Connect text_submitted signal for InputBox
	if name_input is LineEdit:
		if not name_input.is_connected("text_submitted", _on_name_submitted):
			name_input.connect("text_submitted", _on_name_submitted)
	else:
		push_warning("StartScreen: InputBox is not a LineEdit, text_submitted signal not connected.")
	
	# Connect load game button
	if load_game_button and not load_game_button.is_connected("pressed", _on_load_game_button_pressed):
		load_game_button.connect("pressed", _on_load_game_button_pressed)
	
	# Ensure initial UI state
	name_input.visible = false
	back_button.visible = false
	loading_label.visible = false
	
	if LocationManager:
		LocationManager.set_current_location({
			"name": "Start Scene",
			"type": "menu",
			"scene_path": "res://scenes/start_scene.tscn"
		})
	else:
		push_error("StartScreen: LocationManager autoload not found!")

func _on_new_game_button_pressed() -> void:
	back_button.visible = true
	name_input.visible = true
	new_game_button.visible = false
	load_game_button.visible = false
	exit_button.visible = true

func _on_load_game_button_pressed() -> void:
	if not load_game_scene:
		load_game_scene = LoadGameScene.instantiate()
		add_child(load_game_scene)
		load_game_scene.load_game_requested.connect(_on_load_game_requested)
		load_game_scene.back_requested.connect(_on_load_back_requested)
	
	# Hide main menu and show load game scene
	new_game_button.visible = false
	load_game_button.visible = false
	exit_button.visible = false
	load_game_scene.visible = true
	load_game_scene.refresh_save_list()

func _on_load_game_requested(file_path: String):
	if not SaveManager:
		push_error("StartScreen: SaveManager not found!")
		loading_label.text = "Error: SaveManager not available"
		loading_label.visible = true
		await get_tree().create_timer(2.0).timeout
		_return_to_main_menu()
		return
	
	loading_label.text = "Loading game..."
	loading_label.visible = true
	if load_game_scene:
		load_game_scene.visible = false
	
	if not SaveManager.is_connected("load_completed", _on_load_completed):
		SaveManager.connect("load_completed", _on_load_completed)
	SaveManager.load_game(file_path)

func _on_load_completed(success: bool, message: String):
	SaveManager.disconnect("load_completed", _on_load_completed)
	if success:
		# Debug activity state
		print("StartScreen: Load completed. is_activity_active: %s, current_activity: %s" % [
			PlayerData.is_activity_active, PlayerData.current_activity_data.get("name", "None")
		])
		
		# Store activity restoration flag for after scene transition
		if PlayerData.is_activity_active and not PlayerData.current_activity_data.is_empty():
			# Set a flag that the activity needs to be restored
			PlayerData.set_meta("_needs_activity_restoration", true)
			print("StartScreen: Activity restoration flagged for after scene transition")
		
		# Wait for systems to stabilize
		await get_tree().process_frame
		await get_tree().process_frame
		
		_transition_to_loaded_game()
	else:
		push_error("StartScreen: Load failed: %s" % message)
		show_error_dialog("Load failed: %s" % message)

func _restart_activity_system():
	# This function should restart the activity system with the loaded activity data
	var activity_data = PlayerData.current_activity_data
	print("StartScreen: Restarting activity system with activity: %s" % activity_data.get("name", "Unknown"))
	
	# Make sure we have valid activity data
	if activity_data.is_empty():
		print("StartScreen: No activity data to restore")
		return
	
	# Clear any existing activity state first
	PlayerData.is_activity_active = false
	
	# Wait a frame to ensure state is cleared
	await get_tree().process_frame
	
	# Now restart the activity
	PlayerData.start_activity(activity_data)
	
	# Emit the signal to ensure UI systems are notified
	PlayerData.player_activity_started.emit(activity_data)
	
	print("StartScreen: Activity system restarted successfully")

func _restore_activity_after_load():
	# Wait for the new scene to be fully loaded and initialized
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var activity_data = PlayerData.current_activity_data
	print("StartScreen: Restoring activity after scene load: %s" % activity_data.get("name", "Unknown"))
	
	if activity_data.is_empty():
		print("StartScreen: No activity data to restore")
		return
	
	# Clear and restart the activity
	PlayerData.is_activity_active = false
	await get_tree().process_frame
	
	# Start the activity through PlayerData which should properly initialize everything
	PlayerData.start_activity(activity_data)
	PlayerData.player_activity_started.emit(activity_data)
	
	print("StartScreen: Activity restored successfully after scene load")

func _on_load_back_requested():
	# Hide load game scene and show main menu
	if load_game_scene:
		load_game_scene.visible = false
	_return_to_main_menu()

func _transition_to_loaded_game():
	# Emit player_data_loaded signal to ensure systems know about the load
	if PlayerData:
		PlayerData.player_data_loaded.emit()
	
	# Set restoration metadata on UIManager before scene change
	if UIManager:
		UIManager.set_meta("_should_restore_activity", PlayerData.is_activity_active)
		if PlayerData.is_activity_active and not PlayerData.current_activity_data.is_empty():
			UIManager.set_meta("_activity_data_to_restore", PlayerData.current_activity_data.duplicate())
			UIManager.set_meta("_stat_accum", PlayerData._current_activity_stat_accumulated_display)
			UIManager.set_meta("_money_accum", PlayerData._current_activity_money_accumulated_display)
			print("StartScreen: Set activity restoration metadata on UIManager")
	
	# Transition to the loaded game's location
	var scene_path = "res://scenes/intro_scene.tscn"  # Default fallback
	if LocationManager and PlayerData.current_location.has("scene_path"):
		scene_path = PlayerData.current_location.scene_path
	
	if scene_path and scene_path != "res://scenes/start_scene.tscn" and ResourceLoader.exists(scene_path):
		if GameManager:
			GameManager.change_to_scene(scene_path)
		else:
			get_tree().change_scene_to_file(scene_path)
	else:
		# Fallback to intro scene
		if GameManager:
			GameManager.change_to_scene("res://scenes/intro_scene.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/intro_scene.tscn")

func _return_to_main_menu():
	# Reset to main menu state
	new_game_button.visible = true
	load_game_button.visible = true
	exit_button.visible = true
	back_button.visible = false
	name_input.visible = false
	loading_label.visible = false
	name_input.text = ""

func _on_back_button_pressed() -> void:
	_return_to_main_menu()

func _on_name_submitted(new_text: String) -> void:
	if new_text.is_empty():
		new_text = "DefaultPlayer"
		push_warning("StartScreen: Empty name entered, using default name.")
	
	if not PlayerData or not SaveManager:
		push_error("StartScreen: PlayerData or SaveManager not found!")
		loading_label.text = "Error: Game systems not found."
		loading_label.visible = true
		return
	
	PlayerData.set_player_name(new_text)
	var result = SaveManager.save_game(PlayerData)
	if result.success:
		PlayerData.money = 100.0
		PlayerData.stamina = 100.0
		PlayerData.current_location = {"name": "Intro", "type": "normal", "scene_path": "res://scenes/intro_scene.tscn"}
		PlayerData.is_activity_active = false
		PlayerData.current_activity_data = {}
		
		loading_label.text = "Entering Paradise City"
		loading_label.visible = true
		name_input.visible = false
		back_button.visible = false
		await get_tree().create_timer(LOADING_TIME).timeout
		_on_loading_timer_timeout()
	elif result.needs_confirmation:
		_show_overwrite_confirmation(result.file_path)
	else:
		loading_label.text = "Error: %s" % result.message
		loading_label.visible = true
		await get_tree().create_timer(2.0).timeout
		_return_to_main_menu()

func _show_overwrite_confirmation(_file_path: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Overwrite Save?"
	dialog.dialog_text = "A save file for this player already exists. Overwrite?"
	dialog.add_button("Overwrite", true, "overwrite")
	add_child(dialog)
	dialog.confirmed.connect(func():
		var result = SaveManager.save_game(PlayerData, true)
		if result.success:
			PlayerData.money = 100.0
			PlayerData.stamina = 100.0
			PlayerData.current_location = {"name": "Intro", "type": "normal", "scene_path": "res://scenes/intro_scene.tscn"}
			PlayerData.is_activity_active = false
			PlayerData.current_activity_data = {}
			loading_label.text = "Entering Paradise City"
			loading_label.visible = true
			name_input.visible = false
			back_button.visible = false
			await get_tree().create_timer(LOADING_TIME).timeout
			_on_loading_timer_timeout()
		else:
			loading_label.text = "Error: %s" % result.message
			loading_label.visible = true
			await get_tree().create_timer(2.0).timeout
			_return_to_main_menu()
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.custom_action.connect(func(action):
		if action == "overwrite":
			dialog.confirmed.emit()
	)
	dialog.popup_centered()

func _on_loading_timer_timeout() -> void:
	print("StartScreen: Loading complete, initiating scene change.")
	if GameManager:
		GameManager.change_to_scene("res://scenes/intro_scene.tscn")
	else:
		push_error("StartScreen: GameManager autoload not found!")
		loading_label.text = "Error: GameManager not found."
		loading_label.visible = true

func _on_exit_button_pressed() -> void:
	get_tree().quit()

# Handle ESC key to close load menu
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if load_game_scene and load_game_scene.visible:
			_on_load_back_requested()
			get_viewport().set_input_as_handled()

# Clean up resources
func _exit_tree():
	if load_game_scene:
		load_game_scene.queue_free()

func show_error_dialog(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = message
	dialog.ok_button_text = "OK"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
