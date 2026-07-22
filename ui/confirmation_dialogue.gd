extends Control

# Confirmation Dialog Script
signal confirmed
signal cancelled

@onready var message_label: Label = %MessageLabel
@onready var cancel_button: Button = %CancelButton
@onready var overwrite_button: Button = %OverwriteButton
@onready var dialog_panel: PanelContainer = %DialogPanel

var callback_data: Dictionary = {}

func _ready():
	# Connect button signals
	if cancel_button:
		cancel_button.connect("pressed", _on_cancel_pressed)
	if overwrite_button:
		overwrite_button.connect("pressed", _on_confirm_pressed)
	
	# Initially hide the dialog
	visible = false

func show_confirmation(message: String, confirm_text: String = "Confirm", cancel_text: String = "Cancel", data: Dictionary = {}):
	callback_data = data
	
	if message_label:
		message_label.text = message
	if overwrite_button:
		overwrite_button.text = confirm_text
	if cancel_button:
		cancel_button.text = cancel_text
	
	visible = true
	
	# Focus on cancel button by default
	if cancel_button:
		cancel_button.grab_focus()

func hide_dialog():
	visible = false
	callback_data.clear()

func _on_confirm_pressed():
	confirmed.emit()
	hide_dialog()

func _on_cancel_pressed():
	cancelled.emit()
	hide_dialog()

func _input(event):
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_cancel_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER:
			_on_confirm_pressed()
			get_viewport().set_input_as_handled()
