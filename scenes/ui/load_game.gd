extends Control

signal create_slot_requested(slot_id: int)
signal continue_slot_requested(slot_id: int)
signal back_requested

@onready var close_button: Button = %CloseButton
@onready var save_list: VBoxContainer = %SaveList
@onready var no_saves_label: Label = %NoSavesLabel
@onready var refresh_button: Button = %RefreshButton
@onready var back_button: Button = %BackButton
@onready var confirmation_dialog: Control = %ConfirmationDialog
@onready var delete_confirm_dialog: Control = %DeleteConfirmDialog

var _pending_continue_slot: int = 0
var _pending_delete_slot: int = 0

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_back_pressed)
	if refresh_button:
		refresh_button.pressed.connect(refresh_save_list)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if confirmation_dialog:
		confirmation_dialog.confirmed.connect(_on_continue_confirmed)
	if delete_confirm_dialog:
		delete_confirm_dialog.confirmed.connect(_on_delete_confirmed)
	
	# Title
	var title = get_node_or_null("MainPanel/VBoxContainer/HeaderContainer/TitleLabel")
	if title:
		title.text = "Character Select"
	var list_label = get_node_or_null("MainPanel/VBoxContainer/SaveListContainer/SaveListLabel")
	if list_label:
		list_label.text = "Choose a slot:"
	
	refresh_save_list()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func refresh_save_list() -> void:
	for child in save_list.get_children():
		child.queue_free()
	
	if no_saves_label:
		no_saves_label.visible = false
	
	for slot_info in SaveManager.get_all_slots():
		save_list.add_child(_create_slot_card(slot_info))

func _create_slot_card(info: Dictionary) -> Control:
	var slot_id = int(info.get("slot_id", 0))
	var empty = info.get("empty", true)
	
	var item = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.78, 0.4, 0.58, 0.9) if not empty else Color(0.35, 0.22, 0.4, 0.85)
	style.set_corner_radius_all(14)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 0.8, 0.88, 0.35)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	item.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	item.add_child(hbox)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.97, 1))
	if empty:
		name_label.text = "Slot %d — Empty" % slot_id
	else:
		name_label.text = "Slot %d — %s  ·  %s" % [
			slot_id,
			info.get("player_name", "?"),
			info.get("current_location_name", "?")
		]
	info_vbox.add_child(name_label)
	
	if not empty:
		var details = Label.new()
		details.add_theme_font_size_override("font_size", 14)
		details.add_theme_color_override("font_color", Color(0.97, 0.9, 0.95, 0.85))
		details.text = "Money: $%.2f   ·   Stats: %.0f   ·   %s" % [
			float(info.get("money", 0.0)),
			float(info.get("total_stats", 0.0)),
			SaveManager.format_time_ago(float(info.get("modified_time", 0.0)))
		]
		info_vbox.add_child(details)
	
	var buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	hbox.add_child(buttons)
	
	if empty:
		var create_btn = Button.new()
		create_btn.text = "CREATE"
		create_btn.custom_minimum_size = Vector2(100, 35)
		_style_card_button(create_btn, Color(0.95, 0.35, 0.55, 1.0), Color(1.0, 0.5, 0.65, 1.0))
		create_btn.pressed.connect(func(): create_slot_requested.emit(slot_id))
		buttons.add_child(create_btn)
	else:
		var cont_btn = Button.new()
		cont_btn.text = "CONTINUE"
		cont_btn.custom_minimum_size = Vector2(100, 35)
		_style_card_button(cont_btn, Color(0.95, 0.35, 0.55, 1.0), Color(1.0, 0.5, 0.65, 1.0))
		cont_btn.pressed.connect(_on_continue_pressed.bind(slot_id, str(info.get("player_name", ""))))
		buttons.add_child(cont_btn)
		
		var del_btn = Button.new()
		del_btn.text = "DELETE"
		del_btn.custom_minimum_size = Vector2(100, 35)
		_style_card_button(del_btn, Color(0.5, 0.2, 0.35, 1.0), Color(0.65, 0.25, 0.4, 1.0))
		del_btn.pressed.connect(_on_delete_pressed.bind(slot_id, str(info.get("player_name", ""))))
		buttons.add_child(del_btn)
	
	return item

func _style_card_button(btn: Button, base_color: Color, hover_color: Color) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(10)
	var hover = normal.duplicate()
	hover.bg_color = hover_color
	var pressed = normal.duplicate()
	pressed.bg_color = base_color.darkened(0.15)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _on_continue_pressed(slot_id: int, player_name: String) -> void:
	_pending_continue_slot = slot_id
	confirmation_dialog.show_confirmation(
		"Continue as '%s'?" % player_name,
		"Continue",
		"Cancel"
	)

func _on_delete_pressed(slot_id: int, player_name: String) -> void:
	_pending_delete_slot = slot_id
	delete_confirm_dialog.show_confirmation(
		"Delete '%s' (Slot %d)?\nThis cannot be undone." % [player_name, slot_id],
		"Delete",
		"Cancel"
	)

func _on_continue_confirmed() -> void:
	if _pending_continue_slot > 0:
		continue_slot_requested.emit(_pending_continue_slot)
		_pending_continue_slot = 0

func _on_delete_confirmed() -> void:
	if _pending_delete_slot > 0:
		var result = SaveManager.delete_slot(_pending_delete_slot)
		if UIManager:
			UIManager.show_notification(result.message)
		_pending_delete_slot = 0
		refresh_save_list()

func _on_back_pressed() -> void:
	back_requested.emit()
