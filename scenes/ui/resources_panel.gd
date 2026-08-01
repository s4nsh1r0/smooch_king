extends PanelContainer

@onready var money_label: Label = %MoneyLabel
@onready var ap_label: Label = %APLabel
@onready var ap_progress_bar: ProgressBar = %APProgressBar

func _ready() -> void:
	if PlayerData:
		if not PlayerData.player_money_changed.is_connected(_on_money_changed):
			PlayerData.player_money_changed.connect(_on_money_changed)
		if not PlayerData.player_ap_changed.is_connected(_on_ap_changed):
			PlayerData.player_ap_changed.connect(_on_ap_changed)
		if not PlayerData.player_ap_progress_changed.is_connected(_on_ap_progress):
			PlayerData.player_ap_progress_changed.connect(_on_ap_progress)
		if ap_progress_bar:
			ap_progress_bar.tooltip_text = "Action Points increase by 1 every 10 minutes"

		_on_money_changed(PlayerData.money)
		_on_ap_changed(PlayerData.action_points)
		_on_ap_progress(PlayerData.ap_progress, PlayerData.AP_INTERVAL_SECONDS)
	else:
		printerr("ResourcesPanel: PlayerData not found")
		

func _on_money_changed(current_money: float) -> void:
	if money_label:
		money_label.text = "Money: $%.2f" % current_money

func _on_ap_changed(current_ap: int) -> void:
	if ap_label:
		ap_label.text = "⚡  AP: %d" % current_ap

func _on_ap_progress(current: float, maximum: float) -> void:
	if not ap_progress_bar:
		return
	ap_progress_bar.max_value = maximum
	ap_progress_bar.value = clamp(current, 0.0, maximum)
