extends Control

# Load Game Scene Script
signal load_game_requested(file_path: String)
signal back_requested

@onready var close_button: Button = %CloseButton
@onready var save_list: VBoxContainer = %SaveList
@onready var no_saves_label: Label = %NoSavesLabel
@onready var refresh_button: Button = %RefreshButton
@onready var back_button: Button = %BackButton
@onready var confirmation_dialog: AcceptDialog = %ConfirmationDialog
@onready var delete_confirm_dialog: AcceptDialog = %DeleteConfirmDialog

var selected_save_file: String = ""
var save_file_to_delete: String = ""


func _ready():
	# Connect signals
	if close_button:
		close_button.connect("pressed", _on_close_pressed)
	if refresh_button:
		refresh_button.connect("pressed", _on_refresh_pressed)
	if back_button:
		back_button.connect("pressed", _on_back_pressed)
	if confirmation_dialog:
		confirmation_dialog.connect("confirmed", _on_load_confirmed)
	if delete_confirm_dialog:
		delete_confirm_dialog.connect("confirmed", _on_delete_confirmed)
	
	# Load save files
	refresh_save_list()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_back_pressed()
			get_viewport().set_input_as_handled()

func refresh_save_list():
	# Clear existing items
	for child in save_list.get_children():
		child.queue_free()
	
	# Get all save files
	var save_files = SaveManager.get_all_save_files()
	
	if save_files.is_empty():
		no_saves_label.visible = true
		return
	
	no_saves_label.visible = false
	
	# Create save file items
	for save_info in save_files:
		var item = create_save_file_item(save_info)
		save_list.add_child(item)

func create_save_file_item(save_info: Dictionary) -> Control:
	var item_container = PanelContainer.new()
	
	# Style the container
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 1)
	style_box.border_width_left = 1
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.4, 0.4, 0.4, 1)
	style_box.corner_radius_top_left = 3
	style_box.corner_radius_top_right = 3
	style_box.corner_radius_bottom_right = 3
	style_box.corner_radius_bottom_left = 3
	item_container.add_theme_stylebox_override("panel", style_box)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	item_container.add_child(hbox)
	
	# Main info container
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Player name and location
	var name_label = Label.new()
	name_label.text = save_info.player_name + " - " + save_info.current_location_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(name_label)
	
	# Details container
	var details_hbox = HBoxContainer.new()
	info_vbox.add_child(details_hbox)
	
	# Money and stats
	var money_label = Label.new()
	money_label.text = "Money: $%.2f" % save_info.money
	money_label.add_theme_font_size_override("font_size", 14)
	money_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	details_hbox.add_child(money_label)
	
	var separator1 = VSeparator.new()
	details_hbox.add_child(separator1)
	
	var stats_label = Label.new()
	stats_label.text = "Total Stats: %.1f" % save_info.total_stats
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	details_hbox.add_child(stats_label)
	
	# Activity status
	if save_info.is_activity_active and not save_info.current_activity_name.is_empty():
		var separator2 = VSeparator.new()
		details_hbox.add_child(separator2)
		
		var activity_label = Label.new()
		activity_label.text = "Activity: " + save_info.current_activity_name
		activity_label.add_theme_font_size_override("font_size", 14)
		activity_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6, 1))
		details_hbox.add_child(activity_label)
	
	# Time info
	var time_label = Label.new()
	time_label.text = SaveManager.format_time_ago(save_info.modified_time)
	time_label.add_theme_font_size_override("font_size", 12)
	time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	info_vbox.add_child(time_label)
	
	# Buttons container
	var button_vbox = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(button_vbox)
	
	# Load button
	var load_button = Button.new()
	load_button.text = "LOAD"
	load_button.custom_minimum_size = Vector2(80, 35)
	load_button.add_theme_font_size_override("font_size", 14)
	load_button.connect("pressed", _on_load_button_pressed.bind(save_info.file_path))
	button_vbox.add_child(load_button)
	
	# Delete button
	var delete_button = Button.new()
	delete_button.text = "DELETE"
	delete_button.custom_minimum_size = Vector2(80, 35)
	delete_button.add_theme_font_size_override("font_size", 14)
	delete_button.add_theme_color_override("font_color", Color.RED)
	delete_button.connect("pressed", _on_delete_button_pressed.bind(save_info.file_path, save_info.player_name))
	button_vbox.add_child(delete_button)
	
	return item_container

func _on_load_button_pressed(file_path: String):
	selected_save_file = file_path
	var save_info = SaveManager.get_save_file_info(file_path)
	if save_info:
		confirmation_dialog.dialog_text = "Load save for '%s'?\nAny unsaved progress will be lost." % save_info.player_name
		confirmation_dialog.popup_centered()

func _on_delete_button_pressed(file_path: String, player_name: String):
	save_file_to_delete = file_path
	delete_confirm_dialog.dialog_text = "Delete save for '%s'?\nThis action cannot be undone." % player_name
	delete_confirm_dialog.popup_centered()

func _on_load_confirmed():
	if not selected_save_file.is_empty():
		load_game_requested.emit(selected_save_file)

func _on_delete_confirmed():
	if not save_file_to_delete.is_empty():
		var result = SaveManager.delete_save_file(save_file_to_delete)
		if result.success:
			if UIManager:
				UIManager.show_notification("Save file deleted successfully!")
			refresh_save_list()
		else:
			if UIManager:
				UIManager.show_notification("Failed to delete save file: " + result.message)
		save_file_to_delete = ""

func _on_close_pressed():
	back_requested.emit()

func _on_refresh_pressed():
	refresh_save_list()

func _on_back_pressed():
	back_requested.emit()
