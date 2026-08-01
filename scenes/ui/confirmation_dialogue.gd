extends Control

# Confirmation Dialog Script
signal confirmed
signal cancelled

@onready var message_label: Label = %MessageLabel
@onready var cancel_button: Button = %CancelButton
@onready var overwrite_button: Button = %OverwriteButton
@onready var dialog_panel: PanelContainer = %DialogPanel
@onready var background: ColorRect = $Background

var callback_data: Dictionary = {}
var _is_animating: bool = false

func _ready():
	# Connect button signals
	if cancel_button:
		cancel_button.connect("pressed", _on_cancel_pressed)
	if overwrite_button:
		overwrite_button.connect("pressed", _on_confirm_pressed)

	# Initially hide the dialog
	visible = false
	if dialog_panel:
		dialog_panel.scale = Vector2(0.85, 0.85)
	if background:
		background.color.a = 0.0

func show_confirmation(message: String, confirm_text: String = "Confirm", cancel_text: String = "Cancel", data: Dictionary = {}):
	callback_data = data

	if message_label:
		message_label.text = message
	if overwrite_button:
		overwrite_button.text = confirm_text
	if cancel_button:
		cancel_button.text = cancel_text

	visible = true
	_animate_in()

	# Focus on cancel button by default
	if cancel_button:
		cancel_button.grab_focus()

func hide_dialog():
	_animate_out(func():
		visible = false
		callback_data.clear()
	)

func _animate_in() -> void:
	if not dialog_panel or not background:
		return
	_is_animating = true
	dialog_panel.scale = Vector2(0.85, 0.85)
	background.color.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(background, "color:a", 0.55, 0.15)
	tween.tween_property(dialog_panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(func(): _is_animating = false)

func _animate_out(on_complete: Callable) -> void:
	if not dialog_panel or not background:
		on_complete.call()
		return
	_is_animating = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dialog_panel, "scale", Vector2(0.85, 0.85), 0.15) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(background, "color:a", 0.0, 0.15)
	tween.set_parallel(false)
	tween.tween_callback(func():
		_is_animating = false
		on_complete.call()
	)

func _on_confirm_pressed():
	confirmed.emit()
	hide_dialog()

func _on_cancel_pressed():
	cancelled.emit()
	hide_dialog()

func _input(event):
	if visible and not _is_animating and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_cancel_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER:
			_on_confirm_pressed()
			get_viewport().set_input_as_handled()
