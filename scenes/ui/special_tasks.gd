extends PanelContainer

signal panel_closed

@onready var special_tasks_title: Label = %SpecialTasksTitle
@onready var special_tasks_subtitle: Label = %SpecialTasksSubtitle
@onready var special_tasks_scroll: ScrollContainer = %SpecialTasksScroll
@onready var special_tasks_vbox: VBoxContainer = %SpecialTasksVBox
@onready var back_button: Button = %BackButton

@export var fade_duration: float = 0.15
@export var emoji_font: Font = preload("res://assets/fonts/NotoSans-Regular.ttf")

var current_fade_tween: Tween = null
var active_button_tweens: Dictionary = {}
var _special_task_button_map: Dictionary = {}
var _current_location: String = ""

var _is_task_running: bool = false
var _task_timer: float = 0.0
var _task_duration: float = 0.0
var _running_task: Dictionary = {}
var _task_overlay: CanvasLayer = null
var _task_time_label: Label = null
var _task_progress: ProgressBar = null

const AP_COST: int = 20
const TASK_DURATION: float = 180.0  # 3 minutes

var special_tasks_data: Dictionary = {
	"Home": {
		"name": "Do Chores",
		"description": "Clean, organize and take care of your place.",
		"stat": "balance",
		"reward": 15.0,
		"requirements": {}
	},
	"Gym": {
		"name": "Power Lifting",
		"description": "Push yourself through a heavy lifting session.",
		"stat": "strength",
		"reward": 15.0,
		"requirements": {"strength": 100.0, "endurance": 100.0}
	},
	"Library": {
		"name": "Deep Study",
		"description": "Focus on dense material without distractions.",
		"stat": "knowledge",
		"reward": 15.0,
		"requirements": {"knowledge": 100.0, "intelligence": 80.0}
	},
	"Park": {
		"name": "Long Run",
		"description": "A steady endurance run around the park.",
		"stat": "endurance",
		"reward": 15.0,
		"requirements": {"endurance": 100.0, "agility": 80.0}
	},
	"Cafeteria": {
		"name": "Social Hour",
		"description": "Chat with regulars and practice your charm.",
		"stat": "charisma",
		"reward": 15.0,
		"requirements": {"charisma": 100.0, "communication": 80.0}
	},
	"Mall": {
		"name": "Sales Pitch Practice",
		"description": "Help at a booth and practice persuasion.",
		"stat": "persuasion",
		"reward": 15.0,
		"requirements": {"persuasion": 100.0, "charisma": 80.0}
	},
	"Nightclub": {
		"name": "Dance Floor Presence",
		"description": "Own the floor and work the crowd.",
		"stat": "communication",
		"reward": 15.0,
		"requirements": {"communication": 100.0, "charisma": 80.0}
	},
	"Cinema": {
		"name": "Film Analysis",
		"description": "Watch carefully and reflect on the story.",
		"stat": "wisdom",
		"reward": 15.0,
		"requirements": {"wisdom": 100.0, "intelligence": 80.0}
	},
	"University": {
		"name": "Problem Sets",
		"description": "Solve a tough set of academic problems.",
		"stat": "intelligence",
		"reward": 15.0,
		"requirements": {"intelligence": 100.0, "logic": 80.0}
	},
	"Job Center": {
		"name": "Leadership Workshop",
		"description": "Lead a short group exercise and guide others.",
		"stat": "leadership",
		"reward": 15.0,
		"requirements": {"leadership": 100.0, "persuasion": 80.0}
	}
}

func _ready() -> void:
	modulate.a = 0.0
	visible = false
	_setup_styling()
	if is_instance_valid(back_button):
		back_button.pressed.connect(_on_back_button_pressed)
	set_process(false)

func _process(delta: float) -> void:
	if not _is_task_running:
		return
	_task_timer += delta
	var remaining = max(0.0, _task_duration - _task_timer)
	if _task_time_label:
		_task_time_label.text = "⏱  %s" % _format_time(remaining)
	if _task_progress:
		_task_progress.value = (_task_timer / _task_duration) * 100.0
	if _task_timer >= _task_duration:
		_complete_task()

func _input(event: InputEvent) -> void:
	if not _is_task_running:
		return
	if event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()

func _setup_styling() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.22, 0.14, 0.32, 0.95)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.95, 0.7, 1.0, 0.9)
	panel_style.set_corner_radius_all(22)
	panel_style.shadow_color = Color(0.5, 0.2, 0.7, 0.5)
	panel_style.shadow_size = 16
	panel_style.shadow_offset = Vector2(0, 6)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 24
	add_theme_stylebox_override("panel", panel_style)

	if special_tasks_title:
		special_tasks_title.add_theme_color_override("font_color", Color(1.0, 0.95, 1.0))
		special_tasks_title.add_theme_font_size_override("font_size", 24)
	if special_tasks_subtitle:
		special_tasks_subtitle.add_theme_color_override("font_color", Color(0.85, 0.75, 0.95))
	if back_button:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.55, 0.3, 0.7, 0.95)
		style.set_corner_radius_all(14)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.95, 0.7, 1.0, 0.85)
		var hover = style.duplicate()
		hover.bg_color = Color(0.7, 0.4, 0.85, 1.0)
		back_button.add_theme_stylebox_override("normal", style)
		back_button.add_theme_stylebox_override("hover", hover)
		back_button.add_theme_color_override("font_color", Color.WHITE)

func show_panel_animated(location_name: String) -> void:
	_kill_all_tweens()
	_current_location = location_name
	if special_tasks_title:
		special_tasks_title.text = "⭐  %s Special Tasks" % location_name
	modulate.a = 0.0
	visible = true
	current_fade_tween = create_tween().set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	current_fade_tween.tween_property(self, "scale", Vector2.ONE, fade_duration).from(Vector2(0.98, 0.98))
	current_fade_tween.tween_callback(func():
		_populate_special_tasks(location_name)
		current_fade_tween = null
	)

func hide_panel_animated() -> void:
	_hide_req_tooltip()
	if _is_task_running:
		return
	_kill_all_tweens()
	current_fade_tween = create_tween().set_parallel(true)
	current_fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	current_fade_tween.tween_property(self, "scale", Vector2(0.98, 0.98), fade_duration)
	current_fade_tween.tween_callback(func():
		visible = false
		current_fade_tween = null
		_clear_special_tasks()
		panel_closed.emit()
	)

func _kill_all_tweens() -> void:
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()
		current_fade_tween = null
	for node in active_button_tweens.keys():
		var tween = active_button_tweens[node]
		if tween and tween.is_valid():
			tween.kill()
	active_button_tweens.clear()

func _populate_special_tasks(location_name: String) -> void:
	_clear_special_tasks()
	var task = special_tasks_data.get(location_name, {})
	if task.is_empty():
		for key in special_tasks_data.keys():
			if key.to_lower() == location_name.to_lower():
				task = special_tasks_data[key]
				break
	if task.is_empty():
		var label = Label.new()
		label.text = "No special tasks available here yet."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.95))
		special_tasks_vbox.add_child(label)
		return
	special_tasks_vbox.add_child(_create_task_card(task))

func _create_task_card(task: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.32, 0.2, 0.45, 0.9)
	bg.set_corner_radius_all(16)
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(0.9, 0.65, 1.0, 0.7)
	bg.content_margin_left = 18
	bg.content_margin_right = 18
	bg.content_margin_top = 14
	bg.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", bg)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var unlocked = _are_requirements_met(task)
	var btn = Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(320, 48)

	if unlocked:
		btn.text = "⭐  %s" % task.get("name", "Task")
		btn.disabled = false
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.72, 0.38, 0.72, 0.95)
		normal.set_corner_radius_all(14)
		normal.border_width_left = 2
		normal.border_width_top = 2
		normal.border_width_right = 2
		normal.border_width_bottom = 2
		normal.border_color = Color(0.95, 0.7, 0.95, 0.85)
		var hover = normal.duplicate()
		hover.bg_color = Color(0.85, 0.48, 0.85, 1.0)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.pressed.connect(_on_task_pressed.bind(task))
	else:
		btn.text = "🔒  %s" % task.get("name", "Task")
		btn.disabled = true
		var locked = StyleBoxFlat.new()
		locked.bg_color = Color(0.3, 0.2, 0.35, 0.7)
		locked.set_corner_radius_all(14)
		locked.border_width_left = 2
		locked.border_width_top = 2
		locked.border_width_right = 2
		locked.border_width_bottom = 2
		locked.border_color = Color(0.5, 0.35, 0.55, 0.5)
		btn.add_theme_stylebox_override("disabled", locked)
		btn.add_theme_color_override("font_disabled_color", Color(0.7, 0.65, 0.75))
		btn.mouse_entered.connect(_show_req_tooltip.bind(task, btn))
		btn.mouse_exited.connect(_hide_req_tooltip)

	btn.add_theme_font_size_override("font_size", 16)
	vbox.add_child(btn)

	var desc = Label.new()
	desc.text = task.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.9, 0.82, 0.95))
	desc.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc)

	var info = Label.new()
	info.text = "⚡ %d AP   •   ⏱ 3 min   •   📈 +%.0f %s" % [
		AP_COST,
		task.get("reward", 0),
		str(task.get("stat", "")).capitalize()
	]
	info.add_theme_color_override("font_color", Color(0.8, 0.7, 0.95))
	info.add_theme_font_size_override("font_size", 13)
	vbox.add_child(info)

	_special_task_button_map[task] = btn
	return panel

func _on_task_pressed(task: Dictionary) -> void:
	if _is_task_running:
		return
	if not PlayerData:
		return
	if not PlayerData.has_ap(AP_COST):
		if UIManager:
			UIManager.show_notification("Not enough AP! Need %d ⚡" % AP_COST)
		return
	PlayerData.consume_ap(AP_COST)
	_start_task(task)

func _start_task(task: Dictionary) -> void:
	_is_task_running = true
	_running_task = task
	_task_timer = 0.0
	_task_duration = TASK_DURATION
	set_process(true)
	_show_task_overlay(task)
	if UIManager:
		UIManager.show_notification("Special task started: %s" % task.get("name", "Task"))

func _show_task_overlay(task: Dictionary) -> void:
	_clear_task_overlay()
	_task_overlay = CanvasLayer.new()
	_task_overlay.layer = 130
	_task_overlay.name = "SpecialTaskOverlay"
	get_tree().root.add_child(_task_overlay)

	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_task_overlay.add_child(root)

	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.1, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.15, 0.35, 0.97)
	style.set_corner_radius_all(20)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.95, 0.7, 1.0, 0.9)
	style.shadow_color = Color(0.5, 0.2, 0.7, 0.5)
	style.shadow_size = 18
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "⭐  %s" % task.get("name", "Special Task")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 1.0))
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = task.get("description", "")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.85, 0.75, 0.95))
	vbox.add_child(desc)

	_task_time_label = Label.new()
	_task_time_label.text = "⏱  3:00"
	_task_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_task_time_label.add_theme_font_size_override("font_size", 42)
	_task_time_label.add_theme_color_override("font_color", Color(0.95, 0.85, 1.0))
	vbox.add_child(_task_time_label)

	_task_progress = ProgressBar.new()
	_task_progress.custom_minimum_size = Vector2(360, 22)
	_task_progress.max_value = 100
	_task_progress.value = 0
	_task_progress.show_percentage = false
	var pbg = StyleBoxFlat.new()
	pbg.bg_color = Color(0.15, 0.1, 0.22, 0.95)
	pbg.set_corner_radius_all(10)
	var pfill = StyleBoxFlat.new()
	pfill.bg_color = Color(0.9, 0.5, 0.95, 0.95)
	pfill.set_corner_radius_all(10)
	_task_progress.add_theme_stylebox_override("background", pbg)
	_task_progress.add_theme_stylebox_override("fill", pfill)
	vbox.add_child(_task_progress)

	var reward = Label.new()
	reward.text = "Reward: +%.0f %s" % [task.get("reward", 0), str(task.get("stat", "")).capitalize()]
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward.add_theme_font_size_override("font_size", 16)
	reward.add_theme_color_override("font_color", Color(0.7, 0.95, 0.75))
	vbox.add_child(reward)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel Task"
	cancel_btn.custom_minimum_size = Vector2(180, 44)
	cancel_btn.focus_mode = Control.FOCUS_NONE
	var cstyle = StyleBoxFlat.new()
	cstyle.bg_color = Color(0.65, 0.25, 0.4, 0.95)
	cstyle.set_corner_radius_all(12)
	cstyle.border_width_left = 2
	cstyle.border_width_top = 2
	cstyle.border_width_right = 2
	cstyle.border_width_bottom = 2
	cstyle.border_color = Color(1.0, 0.55, 0.7, 0.85)
	var chover = cstyle.duplicate()
	chover.bg_color = Color(0.8, 0.35, 0.5, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", cstyle)
	cancel_btn.add_theme_stylebox_override("hover", chover)
	cancel_btn.add_theme_color_override("font_color", Color.WHITE)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	vbox.add_child(cancel_btn)

	var warn = Label.new()
	warn.text = "Canceling gives no reward. AP is not refunded."
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.add_theme_font_size_override("font_size", 12)
	warn.add_theme_color_override("font_color", Color(0.85, 0.6, 0.7, 0.9))
	vbox.add_child(warn)

func _on_cancel_pressed() -> void:
	_cancel_task()

func _cancel_task() -> void:
	_is_task_running = false
	set_process(false)
	_running_task = {}
	_clear_task_overlay()
	if UIManager:
		UIManager.show_notification("Task canceled. No reward. AP not refunded.")

func _complete_task() -> void:
	_is_task_running = false
	set_process(false)
	var task = _running_task
	_running_task = {}
	_clear_task_overlay()
	if PlayerData and not task.is_empty():
		var stat = task.get("stat", "")
		var amount = task.get("reward", 0.0)
		if PlayerData.get_physical_stats().has(stat):
			PlayerData.set_physical_stat(stat, PlayerData.get_stat(stat) + amount)
		elif PlayerData.get_mental_stats().has(stat):
			PlayerData.set_mental_stat(stat, PlayerData.get_stat(stat) + amount)
		elif PlayerData.get_social_stats().has(stat):
			PlayerData.set_social_stat(stat, PlayerData.get_stat(stat) + amount)
		if UIManager:
			UIManager.show_notification("Task complete! +%.0f %s" % [amount, stat.capitalize()])

func _clear_task_overlay() -> void:
	if _task_overlay and is_instance_valid(_task_overlay):
		_task_overlay.queue_free()
	_task_overlay = null
	_task_time_label = null
	_task_progress = null

func _format_time(seconds: float) -> String:
	var s = int(ceil(seconds))
	var m = s / 60
	var r = s % 60
	return "%d:%02d" % [m, r]

func _clear_special_tasks() -> void:
	_special_task_button_map.clear()
	_hide_req_tooltip()
	if is_instance_valid(special_tasks_vbox):
		for child in special_tasks_vbox.get_children():
			child.queue_free()

func _on_back_button_pressed() -> void:
	hide_panel_animated()

func _are_requirements_met(task: Dictionary) -> bool:
	if not PlayerData:
		return false
	var reqs = task.get("requirements", {})
	if reqs.is_empty():
		return true
	for stat_name in reqs:
		if PlayerData.get_stat(stat_name) < reqs[stat_name]:
			return false
	return true

var _req_tooltip: PanelContainer = null

func _show_req_tooltip(task: Dictionary, button: Button) -> void:
	_hide_req_tooltip()
	var reqs = task.get("requirements", {})
	if reqs.is_empty():
		return
	var parts: PackedStringArray = ["[b][color=#f0c0ff]Requirements[/color][/b]"]
	for stat_name in reqs:
		var required = reqs[stat_name]
		var current = PlayerData.get_stat(stat_name) if PlayerData else 0.0
		if current >= required:
			parts.append("[color=#70ff90]✓ %s: %.0f / %.0f[/color]" % [stat_name.capitalize(), current, required])
		else:
			parts.append("[color=#ff7070]✗ %s: %.0f / %.0f[/color]" % [stat_name.capitalize(), current, required])

	var layer = CanvasLayer.new()
	layer.layer = 128
	layer.name = "SpecialTaskTooltipLayer"
	get_tree().root.add_child(layer)

	_req_tooltip = PanelContainer.new()
	_req_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.15, 0.38, 0.97)
	style.set_corner_radius_all(12)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.7, 1.0, 0.85)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.3, 0.1, 0.45, 0.55)
	style.shadow_size = 12
	_req_tooltip.add_theme_stylebox_override("panel", style)

	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(240, 0)
	label.add_theme_font_size_override("normal_font_size", 14)
	label.text = "\n".join(parts)
	_req_tooltip.add_child(label)
	layer.add_child(_req_tooltip)
	_req_tooltip.set_meta("tooltip_layer", layer)

	await get_tree().process_frame
	if not is_instance_valid(_req_tooltip) or not is_instance_valid(button):
		return
	var button_rect = button.get_global_rect()
	var tip_size = _req_tooltip.size
	var screen = get_viewport().get_visible_rect().size
	var pos = Vector2(
		button_rect.position.x - tip_size.x - 12,
		button_rect.position.y + (button_rect.size.y - tip_size.y) * 0.5
	)
	if pos.x < 10:
		pos.x = button_rect.position.x + button_rect.size.x + 12
	pos.y = clamp(pos.y, 10, screen.y - tip_size.y - 10)
	_req_tooltip.global_position = pos

func _hide_req_tooltip() -> void:
	if _req_tooltip and is_instance_valid(_req_tooltip):
		if _req_tooltip.has_meta("tooltip_layer"):
			var layer = _req_tooltip.get_meta("tooltip_layer")
			if is_instance_valid(layer):
				layer.queue_free()
		else:
			_req_tooltip.queue_free()
		_req_tooltip = null
