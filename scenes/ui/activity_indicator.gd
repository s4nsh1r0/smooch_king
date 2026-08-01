extends PanelContainer
class_name ActivityIndicator

@onready var activity_name_label: Label = %ActivityNameLabel
@onready var stat_effect_label: Label = %StatEffectLabel
@onready var money_progress_label: Label = %MoneyProgressLabel
@onready var minute_timer_progress_bar: ProgressBar = %MinuteTimerProgressBar

var _current_activity_data: Dictionary = {}
var _is_active_activity: bool = false
var _local_elapsed_time: float = 0.0
var _last_ui_update_time: float = 0.0

const ONE_MINUTE: float = 60.0
const UI_UPDATE_INTERVAL: float = 0.5

func _ready() -> void:
	if not is_instance_valid(activity_name_label):
		printerr("ActivityIndicator: ActivityNameLabel not found!")
	if not is_instance_valid(minute_timer_progress_bar):
		printerr("ActivityIndicator: MinuteTimerProgressBar not found!")

	visible = false
	_setup_modern_styling()

	if PlayerData:
		PlayerData.player_activity_started.connect(_on_player_activity_started)
		PlayerData.player_activity_progress.connect(_on_player_activity_progress)
		PlayerData.player_activity_stopped.connect(_on_player_activity_stopped)
		if PlayerData.is_activity_active:
			_on_player_activity_started(PlayerData.get_current_activity_data())
	else:
		printerr("ActivityIndicator: PlayerData autoload not found!")

	if is_instance_valid(minute_timer_progress_bar):
		minute_timer_progress_bar.min_value = 0
		minute_timer_progress_bar.max_value = ONE_MINUTE
		minute_timer_progress_bar.value = 0
		minute_timer_progress_bar.show_percentage = false

func _setup_modern_styling() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.22, 0.14, 0.32, 0.92)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.85, 0.6, 1.0, 0.85)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0.45, 0.2, 0.7, 0.45)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0, 4)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", panel_style)

	if activity_name_label:
		activity_name_label.add_theme_color_override("font_color", Color(0.98, 0.92, 1.0, 1))
		activity_name_label.add_theme_font_size_override("font_size", 17)

	if stat_effect_label:
		stat_effect_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.95, 1))
		stat_effect_label.add_theme_font_size_override("font_size", 14)

	if money_progress_label:
		money_progress_label.add_theme_color_override("font_color", Color(0.7, 0.95, 0.75, 1))
		money_progress_label.add_theme_font_size_override("font_size", 14)

	if minute_timer_progress_bar:
		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0.15, 0.1, 0.22, 0.9)
		bg.set_corner_radius_all(8)

		var fill = StyleBoxFlat.new()
		fill.bg_color = Color(0.9, 0.5, 0.95, 0.95)
		fill.set_corner_radius_all(8)

		minute_timer_progress_bar.add_theme_stylebox_override("background", bg)
		minute_timer_progress_bar.add_theme_stylebox_override("fill", fill)
		minute_timer_progress_bar.custom_minimum_size = Vector2(0, 10)

func _process(delta: float) -> void:
	if not _is_active_activity:
		return

	_local_elapsed_time += delta
	_last_ui_update_time += delta

	if is_instance_valid(minute_timer_progress_bar):
		var is_job = _current_activity_data.get("is_job", false)
		if is_job and PlayerData:
			var total = float(_current_activity_data.get("shift_seconds", 0.0))
			var remaining = PlayerData.get_job_shift_remaining()
			if total > 0.0:
				minute_timer_progress_bar.max_value = total
				minute_timer_progress_bar.value = clamp(total - remaining, 0.0, total)
			else:
				minute_timer_progress_bar.value = 0
		else:
			if _local_elapsed_time >= ONE_MINUTE:
				_local_elapsed_time = fmod(_local_elapsed_time, ONE_MINUTE)
			minute_timer_progress_bar.max_value = ONE_MINUTE
			minute_timer_progress_bar.value = _local_elapsed_time

	if _last_ui_update_time >= UI_UPDATE_INTERVAL:
		update_ui()
		_last_ui_update_time = 0.0

func _on_player_activity_started(activity_data: Dictionary) -> void:
	_current_activity_data = activity_data.duplicate(true) if not activity_data.is_empty() else {}
	_is_active_activity = not activity_data.is_empty()
	_local_elapsed_time = 0.0
	_last_ui_update_time = 0.0

	if _is_active_activity:
		visible = true
		modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.25)
		update_ui()
	else:
		_stop_indicator()

func _on_player_activity_progress(activity_data: Dictionary) -> void:
	if not activity_data.is_empty():
		_current_activity_data = activity_data.duplicate(true)
	if _is_active_activity:
		update_ui()

func _on_player_activity_stopped(_activity_data: Dictionary, _was_exhausted: bool) -> void:
	_stop_indicator()

func update_ui() -> void:
	if not PlayerData or not _is_active_activity:
		return

	var activity_name = PlayerData.get_current_activity_name()
	var data = PlayerData.get_current_activity_data()
	var is_job = _current_activity_data.get("is_job", false) or data.get("is_job", false)
	var money_gain = PlayerData.get_current_activity_money_accumulated_display()

	# Title
	if is_instance_valid(activity_name_label):
		if is_job:
			var remaining = PlayerData.get_job_shift_remaining()
			activity_name_label.text = "💼  %s  ·  %s left" % [
				activity_name if activity_name else "Job",
				_format_remaining(remaining)
			]
		else:
			activity_name_label.text = "⚡  %s" % (activity_name if activity_name else "None")

	# Rate line (current rate only — halves automatically after 24h)
	if is_instance_valid(stat_effect_label):
		if is_job:
			var money_rate = float(data.get("money_gain_per_second", 0.0))
			if money_rate > 0.0:
				stat_effect_label.text = "Gain rate: $%.3f/sec" % money_rate
				stat_effect_label.visible = true
			else:
				stat_effect_label.visible = false
		else:
			var stat_name = PlayerData.get_current_activity_stat_raised()
			var rate = PlayerData.get_current_activity_rate_per_second()
			var gain = PlayerData.get_current_activity_accumulated_display()
			if not stat_name.is_empty():
				stat_effect_label.text = "Gain rate: %.3f %s/sec\n+%.2f" % [
				rate, stat_name.capitalize(), gain
			]
				stat_effect_label.visible = true
			else:
				stat_effect_label.visible = false

	# Money earned (jobs only)
	if is_instance_valid(money_progress_label):
		if is_job and money_gain > 0.0:
			money_progress_label.text = "💰  $%.2f" % money_gain
			money_progress_label.visible = true
		else:
			money_progress_label.visible = false

func _stop_indicator() -> void:
	_is_active_activity = false
	_current_activity_data = {}
	_local_elapsed_time = 0.0
	_last_ui_update_time = 0.0

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		if is_instance_valid(activity_name_label):
			activity_name_label.text = ""
		if is_instance_valid(stat_effect_label):
			stat_effect_label.text = ""
			stat_effect_label.visible = true
		if is_instance_valid(money_progress_label):
			money_progress_label.text = ""
			money_progress_label.visible = true
		if is_instance_valid(minute_timer_progress_bar):
			minute_timer_progress_bar.max_value = ONE_MINUTE
			minute_timer_progress_bar.value = 0
	)

func _format_remaining(seconds: float) -> String:
	var total = int(maxf(0.0, seconds))
	var h = int(total / 3600.0)
	var m = int((total % 3600) / 60.0)
	var s = total % 60
	if h > 0:
		return "%dh %dm" % [h, m]
	if m > 0:
		return "%dm %ds" % [m, s]
	return "%ds" % s
