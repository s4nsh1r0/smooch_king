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
const UI_UPDATE_INTERVAL: float = 0.5  # Update UI every 0.5 seconds for smoother display

func _ready():
	# Check critical nodes
	if not is_instance_valid(activity_name_label):
		printerr("ActivityIndicator: ActivityNameLabel not found!")
	if not is_instance_valid(minute_timer_progress_bar):
		printerr("ActivityIndicator: MinuteTimerProgressBar not found!")
	
	visible = false
	if PlayerData:
		PlayerData.player_activity_started.connect(_on_player_activity_started)
		PlayerData.player_activity_stopped.connect(_on_player_activity_stopped)
		PlayerData.player_activity_progress.connect(_on_player_activity_progress)
		if PlayerData.is_activity_active:
			_on_player_activity_started(PlayerData.get_current_activity_data())
	else:
		printerr("ActivityIndicator: PlayerData autoload not found!")
	
	if is_instance_valid(minute_timer_progress_bar):
		minute_timer_progress_bar.min_value = 0
		minute_timer_progress_bar.max_value = ONE_MINUTE
		minute_timer_progress_bar.value = 0
		minute_timer_progress_bar.show_percentage = false

func _process(delta: float) -> void:
	if not _is_active_activity:
		return
		
	_local_elapsed_time += delta
	_last_ui_update_time += delta
	
	if is_instance_valid(minute_timer_progress_bar):
		if _local_elapsed_time >= ONE_MINUTE:
			_local_elapsed_time = fmod(_local_elapsed_time, ONE_MINUTE)
		minute_timer_progress_bar.value = _local_elapsed_time
	
	# Update UI more frequently for smoother stat display
	if _last_ui_update_time >= UI_UPDATE_INTERVAL:
		update_ui()
		_last_ui_update_time = 0.0

func _on_player_activity_started(activity_data: Dictionary):
	_current_activity_data = activity_data
	_is_active_activity = not activity_data.is_empty()
	_local_elapsed_time = 0.0
	_last_ui_update_time = 0.0
	
	if _is_active_activity:
		visible = true
		modulate.a = 1.0
		update_ui()
	else:
		_stop_indicator()

func _on_player_activity_progress(_activity_data: Dictionary):
	# Update immediately when we receive progress signals for smoother display
	if _is_active_activity:
		update_ui()

func _on_player_activity_stopped(_activity_data: Dictionary, was_stamina_exhausted: bool):
	_stop_indicator()
	if was_stamina_exhausted and UIManager:
		UIManager.show_notification("Activity stopped due to stamina exhaustion!")

func update_ui():
	if not PlayerData or not _is_active_activity:
		return
	
	var activity_name = PlayerData.get_current_activity_name()
	var stat_name = PlayerData.get_current_activity_stat_raised()
	var stat_gain = PlayerData.get_current_activity_accumulated_display()
	var money_gain = PlayerData.get_current_activity_money_accumulated_display()
	
	if is_instance_valid(activity_name_label):
		activity_name_label.text = "Activity: %s" % (activity_name if activity_name else "None")
	
	if is_instance_valid(stat_effect_label):
		stat_effect_label.text = "Stat Gain: %s +%.2f" % [stat_name.capitalize(), stat_gain] if stat_name else "No stat change"
	
	if is_instance_valid(money_progress_label):
		money_progress_label.text = "Money Earned: $%.2f" % money_gain if money_gain > 0 else ""

func _stop_indicator():
	_is_active_activity = false
	_current_activity_data = {}
	_local_elapsed_time = 0.0
	_last_ui_update_time = 0.0
	visible = false
	
	if is_instance_valid(activity_name_label):
		activity_name_label.text = ""
	if is_instance_valid(stat_effect_label):
		stat_effect_label.text = ""
	if is_instance_valid(money_progress_label):
		money_progress_label.text = ""
	if is_instance_valid(minute_timer_progress_bar):
		minute_timer_progress_bar.value = 0
