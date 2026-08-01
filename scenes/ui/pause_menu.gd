extends CanvasLayer

signal pause_menu_toggled(is_visible: bool)

@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var exit_button: Button = %ExitButton
@onready var panel_container: PanelContainer = %PanelContainer
@onready var backdrop: ColorRect = %Backdrop

# Load the confirmation dialog and load game scene
const ConfirmationDialogScene = preload("res://scenes/ui/confirmation_dialogue.tscn")
const LoadGameScene = preload("res://scenes/ui/load_game.tscn")

var confirmation_dialog: Control = null
var load_game_scene: Control = null
var main_menu_confirmation_dialog: Control = null

func _ready():
	# Set CanvasLayer layer to 15
	self.layer = 15
	
	# Set mouse filters
	if is_instance_valid(panel_container):
		panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
		panel_container.visible = false
	else:
		printerr("PauseMenu: PanelContainer not found! Check unique_name_in_owner")
	
	if is_instance_valid(save_button):
		save_button.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		printerr("PauseMenu: SaveButton not found! Check unique_name_in_owner")
	
	if is_instance_valid(load_button):
		load_button.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		printerr("PauseMenu: LoadButton not found! Check unique_name_in_owner")
	
	if is_instance_valid(main_menu_button):
		main_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		printerr("PauseMenu: MainMenuButton not found! Check unique_name_in_owner")
	
	if is_instance_valid(exit_button):
		exit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		printerr("PauseMenu: ExitButton not found! Check unique_name_in_owner")
	
	# Connect signals safely
	if is_instance_valid(save_button) and not save_button.is_connected("pressed", _on_save_button_pressed):
		save_button.connect("pressed", _on_save_button_pressed)
	if is_instance_valid(load_button) and not load_button.is_connected("pressed", _on_load_button_pressed):
		load_button.connect("pressed", _on_load_button_pressed)
	if is_instance_valid(main_menu_button) and not main_menu_button.is_connected("pressed", _on_main_menu_button_pressed):
		main_menu_button.connect("pressed", _on_main_menu_button_pressed)
	if is_instance_valid(exit_button) and not exit_button.is_connected("pressed", _on_exit_button_pressed):
		exit_button.connect("pressed", _on_exit_button_pressed)


func show_menu() -> void:
	if is_instance_valid(panel_container) and not panel_container.visible:
		panel_container.visible = true
		if is_instance_valid(backdrop):
			backdrop.visible = true
		emit_signal("pause_menu_toggled", true)
	else:
		printerr("PauseMenu: Cannot show menu, panel_container invalid or already visible")

func hide_menu() -> void:
	if is_instance_valid(panel_container) and panel_container.visible:
		panel_container.visible = false
		if is_instance_valid(backdrop):
			backdrop.visible = false
		emit_signal("pause_menu_toggled", false)
	else:
		printerr("PauseMenu: Cannot hide menu, panel_container invalid or already hidden")

func _on_save_button_pressed() -> void:
	if not PlayerData:
		if UIManager:
			UIManager.show_notification("Error: PlayerData not available")
		return
	var result = SaveManager.save_game(PlayerData, true)
	if result.success:
		if UIManager:
			UIManager.show_notification(result.message)
		hide_menu()
	else:
		if UIManager:
			UIManager.show_notification("Save failed: " + result.message)

func _show_save_confirmation(save_result: Dictionary):
	if not confirmation_dialog:
		confirmation_dialog = ConfirmationDialogScene.instantiate()
		add_child(confirmation_dialog)
		confirmation_dialog.confirmed.connect(_on_save_confirmed.bind(save_result))
		confirmation_dialog.cancelled.connect(_on_save_cancelled)
	
	var player_name = PlayerData.get_player_name()
	var message = "A save file for '%s' already exists.\nDo you want to overwrite it?" % player_name
	confirmation_dialog.show_confirmation(message, "Overwrite", "Cancel", save_result)

func _on_save_confirmed(_save_result: Dictionary):
	# Force overwrite the save
	var result = SaveManager.save_game(PlayerData, true)
	
	if result.success:
		if UIManager:
			UIManager.show_notification(result.message)
		hide_menu()
	else:
		printerr("PauseMenu: Save failed: ", result.message)
		if UIManager:
			UIManager.show_notification("Save failed: " + result.message)

func _on_save_cancelled():
	# User cancelled the save operation
	pass

func _on_load_button_pressed() -> void:
	if not load_game_scene:
		load_game_scene = LoadGameScene.instantiate()
		add_child(load_game_scene)
		load_game_scene.continue_slot_requested.connect(_on_continue_slot_from_pause)
		load_game_scene.back_requested.connect(_on_load_back_requested)
		# create from pause is optional; usually only continue/delete
	panel_container.visible = false
	if backdrop:
		backdrop.visible = false
	load_game_scene.visible = true
	load_game_scene.refresh_save_list()

func _on_continue_slot_from_pause(slot_id: int) -> void:
	if load_game_scene:
		load_game_scene.visible = false
	if not SaveManager.load_completed.is_connected(_on_load_completed):
		SaveManager.load_completed.connect(_on_load_completed)
	SaveManager.load_slot(slot_id)

func _on_main_menu_button_pressed() -> void:
	# Show confirmation dialog before returning to main menu
	if not main_menu_confirmation_dialog:
		main_menu_confirmation_dialog = ConfirmationDialogScene.instantiate()
		add_child(main_menu_confirmation_dialog)
		main_menu_confirmation_dialog.confirmed.connect(_on_main_menu_confirmed)
		main_menu_confirmation_dialog.cancelled.connect(_on_main_menu_cancelled)
	
	var message = "Return to main menu?\nAny unsaved progress will be lost."
	main_menu_confirmation_dialog.show_confirmation(message, "Yes", "Cancel")

func _on_main_menu_confirmed():
	# Return to main menu without saving
	hide_menu()
	
	# Stop any active activity without saving
	if PlayerData and PlayerData.is_activity_active:
		PlayerData.stop_activity(false)  # false = not due to stamina exhaustion
	
	# Change to main menu scene
	var main_menu_path = "res://scenes/main/start_scene.tscn"
	
	if ResourceLoader.exists(main_menu_path):
		if GameManager and GameManager.has_method("change_to_scene"):
			GameManager.change_to_scene(main_menu_path)
		else:
			get_tree().change_scene_to_file(main_menu_path)
	else:
		printerr("PauseMenu: Main menu scene not found at path: ", main_menu_path)
		show_error_dialog("Error: Main menu scene not found!")

func _on_main_menu_cancelled():
	# User cancelled returning to main menu
	pass

func _on_load_game_requested(file_path: String):
	if not PlayerData or not SaveManager:
		printerr("PauseMenu: PlayerData or SaveManager not found!")
		if UIManager:
			UIManager.show_notification("Error: Game systems not available", 5.0)
		return
	
	if load_game_scene:
		load_game_scene.visible = false
	panel_container.visible = false
	
	if not SaveManager.is_connected("load_completed", _on_load_completed):
		SaveManager.connect("load_completed", _on_load_completed)
	SaveManager.load_game(file_path)
	
func _on_load_completed(success: bool, message: String):
	if SaveManager.is_connected("load_completed", _on_load_completed):
		SaveManager.disconnect("load_completed", _on_load_completed)
	
	if success:
		if UIManager:
			UIManager.show_notification(message, 5.0)
		_handle_successful_load()
	else:
		printerr("PauseMenu: Load failed: %s" % message)
		if UIManager:
			UIManager.show_notification("Load failed: %s" % message, 5.0)
		# Make sure the pause menu is shown again
		panel_container.visible = true
		if is_instance_valid(backdrop):
			backdrop.visible = true

func _on_load_back_requested() -> void:
	if load_game_scene:
		load_game_scene.visible = false
		# Make sure it no longer receives input
		load_game_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Bring the pause menu back
	if is_instance_valid(panel_container):
		panel_container.visible = true
		panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if is_instance_valid(backdrop):
		backdrop.visible = true
	
	# Force the pause menu to process input again
	set_process_input(true)

func _handle_successful_load():
	if LocationManager and PlayerData.current_location.has("scene_path"):
		var scene_path = PlayerData.current_location.scene_path
		if scene_path and scene_path != get_tree().current_scene.scene_file_path and ResourceLoader.exists(scene_path):
			# Set restoration metadata before scene change
			if UIManager:
				UIManager.set_meta("_should_restore_activity", PlayerData.is_activity_active)
				if PlayerData.is_activity_active and not PlayerData.current_activity_data.is_empty():
					UIManager.set_meta("_activity_data_to_restore", PlayerData.current_activity_data.duplicate())
					UIManager.set_meta("_stat_accum", PlayerData._current_activity_stat_accumulated_display)
					UIManager.set_meta("_money_accum", PlayerData._current_activity_money_accumulated_display)
					print("PauseMenu: Set activity restoration metadata on UIManager")
			
			if GameManager:
				GameManager.change_to_scene(scene_path)
			else:
				get_tree().change_scene_to_file(scene_path)
		else:
			if UIManager:
				UIManager._update_ui_visibility()  # Force UI update
			PlayerData.player_data_loaded.emit()
	else:
		if UIManager:
			UIManager._update_ui_visibility()
		PlayerData.player_data_loaded.emit()

func _on_exit_button_pressed() -> void:
	# Save before quitting if there's unsaved progress
	if PlayerData and PlayerData.is_activity_active:
		# Auto-save current progress
		var result = SaveManager.save_game(PlayerData, true)
		if result.success and UIManager:
			UIManager.show_notification("Progress auto-saved before exit.")
	
	if GameManager and GameManager.has_method("quit_game"):
		GameManager.quit_game()
	else:
		get_tree().quit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Auto-save when the game is being closed
		if PlayerData and PlayerData.is_activity_active:
			var result = SaveManager.save_game(PlayerData, true)
			if result.success:
				print("Auto-saved progress before closing game.")

# Clean up resources
func _exit_tree():
	if confirmation_dialog:
		confirmation_dialog.queue_free()
	if load_game_scene:
		load_game_scene.queue_free()
	if main_menu_confirmation_dialog:
		main_menu_confirmation_dialog.queue_free()
		
func show_error_dialog(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = message
	dialog.ok_button_text = "OK"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
