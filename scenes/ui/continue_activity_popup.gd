extends CanvasLayer

@onready var panel: PanelContainer = $Center/Panel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton

func _ready() -> void:
	yes_button.pressed.connect(_on_yes)
	no_button.pressed.connect(_on_no)
	_style()
	_fill_text()

func _style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.14, 0.32, 0.97)
	style.set_corner_radius_all(20)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.95, 0.7, 1.0, 0.9)
	style.shadow_color = Color(0.4, 0.15, 0.6, 0.5)
	style.shadow_size = 16
	panel.add_theme_stylebox_override("panel", style)
	
	_style_button(yes_button, Color(0.72, 0.38, 0.72, 0.95), Color(0.85, 0.48, 0.85, 1.0))
	_style_button(no_button, Color(0.45, 0.28, 0.5, 0.9), Color(0.55, 0.35, 0.6, 1.0))

func _style_button(btn: Button, normal_col: Color, hover_col: Color) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = normal_col
	normal.set_corner_radius_all(12)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.95, 0.7, 0.95, 0.8)
	
	var hover = normal.duplicate()
	hover.bg_color = hover_col
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.focus_mode = Control.FOCUS_NONE

func _fill_text() -> void:
	if not PlayerData:
		return
	var data = PlayerData.get_pending_continue_activity()
	var _activity_name = str(data.get("name", "your activity"))

	if data.get("is_job", false):
		title_label.text = "Continue shift?"
		var ends = float(data.get("shift_ends_at", 0.0))
		var left = max(0.0, ends - Time.get_unix_time_from_system())
		if left > 0.0:
			var t = int(left)
			var h = int(t / 3600.0)
			var m = int((t % 3600) / 60.0)
			var left_str = "%dh %dm" % [h, m] if h > 0 else ("%dm" % m if m > 0 else "%ds" % t)
			body_label.text = "You were working:\n%s\n\n~%s left on this shift.\nContinue?" % [name, left_str]
		else:
			body_label.text = "You were working:\n%s\n\nContinue?" % name
	else:
		title_label.text = "Continue activity?"
		body_label.text = "You were doing:\n%s\n\nContinue?" % name

func _on_yes() -> void:
	if PlayerData:
		PlayerData.continue_pending_activity()
	queue_free()

func _on_no() -> void:
	if PlayerData:
		PlayerData.decline_pending_activity()
	queue_free()
