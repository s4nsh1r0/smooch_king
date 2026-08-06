extends Node

# Signals
signal player_stat_changed(stat_name: String, new_value: float)
signal player_name_changed(new_name: String)
signal player_data_loaded
signal player_location_changed(new_location_data: Dictionary)
signal player_activity_started(activity_data: Dictionary)
signal player_activity_progress(activity_data: Dictionary)
signal player_activity_stopped(stopped_activity_data: Dictionary, was_exhausted: bool)
signal player_ap_changed(current_ap: int)
signal player_ap_progress_changed(current: float, maximum: float)
signal player_money_changed(current_money: float)
signal player_relationship_stage_changed(character_id: String, new_stage: String)
signal offline_progress_calculated(progress_data: Dictionary)
signal inventory_changed

# Identity
var player_name: String = "DefaultPlayer"
var current_slot_id: int = 0

# Money
var _money: float = 0.0
var money: float:
	get:
		return _money
	set(value):
		_money = max(0.0, value)
		player_money_changed.emit(_money)

# Action Points — 1 AP / 10 min, uncapped
const AP_STARTING: int = 150
const AP_INTERVAL_SECONDS: float = 600.0

var _action_points: int = AP_STARTING
var action_points: int:
	get:
		return _action_points
	set(value):
		_action_points = max(0, value)
		player_ap_changed.emit(_action_points)

var ap_progress: float = 0.0
var last_ap_progress_tick: float = 0.0

var inventory: Dictionary = {}

# Stats
var _physical_stats: Dictionary = {
	"strength": 1.0, "agility": 1.0, "endurance": 1.0, "balance": 1.0
}
var _mental_stats: Dictionary = {
	"knowledge": 1.0, "wisdom": 1.0, "intelligence": 1.0, "logic": 1.0
}
var _social_stats: Dictionary = {
	"leadership": 1.0, "persuasion": 1.0, "charisma": 1.0, "communication": 1.0
}

# Location
var current_location: Dictionary = {
	"name": "Start Screen",
	"type": "start",
	"scene_path": "res://scenes/main/start_scene.tscn",
	"activities": []
}

# Activity slot
var is_activity_active: bool = false
var current_activity_data: Dictionary = {}
var activity_started_at: float = 0.0
var activity_full_rate_until: float = 0.0
var activity_last_tick_at: float = 0.0
var _session_stat_gains: Dictionary = {}
var _session_money_gained: float = 0.0
var _pending_continue_activity: Dictionary = {}
var _completing_job_shift: bool = false

const FULL_RATE_DURATION: float = 24.0 * 3600.0
const HALF_RATE_MULTIPLIER: float = 0.5

const JOB_SHIFTS := {
	"4h":  {"seconds": 4 * 3600.0,  "label": "4 hours",  "bonus_mult": 1.0, "ap": 8},
	"8h":  {"seconds": 8 * 3600.0,  "label": "8 hours",  "bonus_mult": 1.5, "ap": 16},
	"12h": {"seconds": 12 * 3600.0, "label": "12 hours", "bonus_mult": 2.0, "ap": 24}
}

var job_hours_worked: Dictionary = {}
var relationships: Dictionary = {}
var character_date_progress: Dictionary = {}
var last_date_times: Dictionary = {}
var completed_dates: Dictionary = {}

const RELATIONSHIP_STAGES = {
	0: "Stranger",
	50: "Acquaintance",
	150: "Friend",
	300: "Good Friend",
	600: "Crush",
	1000: "Dating",
	1500: "Soulmate"
}

var _notification_queue: Array = []

func _ready() -> void:
	_money = 0.0
	_action_points = AP_STARTING
	ap_progress = 0.0
	last_ap_progress_tick = Time.get_unix_time_from_system()

	player_location_changed.emit(current_location)
	player_ap_changed.emit(_action_points)
	player_ap_progress_changed.emit(ap_progress, AP_INTERVAL_SECONDS)
	player_money_changed.emit(_money)
	player_data_loaded.emit()

	if not _notification_queue.is_empty() and UIManager:
		for progress_data in _notification_queue:
			_show_offline_progress_notification(progress_data)
		_notification_queue.clear()

	var timer = Timer.new()
	timer.wait_time = 300.0
	timer.autostart = true
	timer.timeout.connect(_auto_save)
	add_child(timer)

func _auto_save() -> void:
	if SaveManager:
		var result = SaveManager.save_game(self, true)
		if result.success and UIManager:
			UIManager.show_notification("Game auto-saved!", 3.0)

func _process(_delta: float) -> void:
	_tick_ap_progress()
	if is_activity_active:
		_tick_activity_gains()

# ---------- Action Points ----------

func has_ap(amount: int) -> bool:
	return _action_points >= amount

func consume_ap(amount: int) -> bool:
	if amount <= 0:
		return true
	if _action_points < amount:
		return false
	action_points = _action_points - amount
	return true

func add_ap(amount: int) -> void:
	if amount > 0:
		action_points = _action_points + amount

func _tick_ap_progress() -> void:
	var now = Time.get_unix_time_from_system()
	if last_ap_progress_tick <= 0.0:
		last_ap_progress_tick = now
		return
	var elapsed = now - last_ap_progress_tick
	if elapsed <= 0.0:
		return
	last_ap_progress_tick = now
	_add_ap_progress(elapsed)

func _add_ap_progress(seconds: float) -> void:
	if seconds <= 0.0:
		return
	ap_progress += seconds
	var gained := 0
	while ap_progress >= AP_INTERVAL_SECONDS:
		ap_progress -= AP_INTERVAL_SECONDS
		gained += 1
	if gained > 0:
		add_ap(gained)
	player_ap_progress_changed.emit(ap_progress, AP_INTERVAL_SECONDS)

func get_ap_progress() -> float:
	return ap_progress

func get_ap_interval() -> float:
	return AP_INTERVAL_SECONDS

# ---------- Activity slot ----------

func start_activity(activity_data: Dictionary, preserve_session_display: bool = false) -> bool:
	if activity_data.is_empty():
		return false
	if is_activity_active and current_activity_data.get("name") == activity_data.get("name"):
		return false
	if is_activity_active:
		stop_activity(false)

	is_activity_active = true
	current_activity_data = activity_data.duplicate(true)

	var now = Time.get_unix_time_from_system()
	activity_started_at = now
	if current_activity_data.get("is_job", false):
		activity_full_rate_until = now + float(current_activity_data.get("shift_seconds", FULL_RATE_DURATION)) + 1.0
	else:
		activity_full_rate_until = now + FULL_RATE_DURATION
	activity_last_tick_at = now

	if not preserve_session_display:
		_session_stat_gains.clear()
		_session_money_gained = 0.0

	player_activity_started.emit(current_activity_data)
	return true

func start_job_shift(job_data: Dictionary, shift_key: String) -> bool:
	if not job_data.get("is_job", false):
		return start_activity(job_data)
	if not JOB_SHIFTS.has(shift_key):
		return false

	var data = job_data.duplicate(true)
	var shift = JOB_SHIFTS[shift_key]
	var now = Time.get_unix_time_from_system()
	data["shift_key"] = shift_key
	data["shift_seconds"] = shift.seconds
	data["shift_ends_at"] = now + shift.seconds
	data["shift_completed"] = false
	data["is_job"] = true
	return start_activity(data)

func stop_activity(_was_exhausted: bool = false) -> void:
	if not is_activity_active:
		return

	if not _completing_job_shift:
		_tick_activity_gains()

	var ended = current_activity_data.duplicate(true)

	is_activity_active = false
	current_activity_data = {}
	activity_started_at = 0.0
	activity_full_rate_until = 0.0
	activity_last_tick_at = Time.get_unix_time_from_system()
	_completing_job_shift = false

	player_activity_stopped.emit(ended, false)
	_session_stat_gains.clear()
	_session_money_gained = 0.0

func _tick_activity_gains() -> void:
	if not is_activity_active or current_activity_data.is_empty():
		return
	if _completing_job_shift:
		return

	var now = Time.get_unix_time_from_system()

	if current_activity_data.get("is_job", false):
		var ends = float(current_activity_data.get("shift_ends_at", 0.0))
		if ends > 0.0 and now >= ends:
			if activity_last_tick_at < ends:
				var gains = _compute_gains_for_interval(activity_last_tick_at, ends)
				_apply_gain_result(gains)
				activity_last_tick_at = ends
			_complete_job_shift()
			return

	if now - activity_last_tick_at <= 0.0:
		return
	var gains2 = _compute_gains_for_interval(activity_last_tick_at, now)
	_apply_gain_result(gains2)
	activity_last_tick_at = now
	player_activity_progress.emit(current_activity_data)

func _complete_job_shift() -> void:
	if not is_activity_active or not current_activity_data.get("is_job", false):
		return
	if current_activity_data.get("shift_completed", false):
		return

	_completing_job_shift = true
	current_activity_data["shift_completed"] = true

	var shift_key = str(current_activity_data.get("shift_key", "8h"))
	var shift = JOB_SHIFTS.get(shift_key, JOB_SHIFTS["8h"])
	var mult = float(shift.get("bonus_mult", 1.0))
	var ap_reward = int(shift.get("ap", 0))

	var effects: Dictionary = current_activity_data.get("effects", {})
	for stat_name in effects:
		var bonus = max(0.5, abs(float(effects[stat_name])) * 60.0 * mult)
		_add_stat(stat_name, bonus)
		_session_stat_gains[stat_name] = _session_stat_gains.get(stat_name, 0.0) + bonus

	if ap_reward > 0:
		add_ap(ap_reward)

	if UIManager:
		var msg = "Shift complete: %s\n+$%.2f" % [
			current_activity_data.get("name", "Job"),
			_session_money_gained
		]
		if ap_reward > 0:
			msg += "  |  +%d AP" % ap_reward
		UIManager.show_notification(msg, 6.0)

	stop_activity(false)

func _compute_gains_for_interval(from_time: float, to_time: float) -> Dictionary:
	var result = {
		"stat_gains": {},
		"money_gained": 0.0,
		"seconds_full": 0.0,
		"seconds_half": 0.0,
		"total_seconds": max(0.0, to_time - from_time)
	}
	if to_time <= from_time or current_activity_data.is_empty():
		return result

	var effects: Dictionary = current_activity_data.get("effects", {})
	var money_per_sec: float = float(current_activity_data.get("money_gain_per_second", 0.0))
	var is_job: bool = current_activity_data.get("is_job", false)
	var full_end = activity_full_rate_until
	var t0 = from_time
	var t1 = to_time
	var seconds_full = 0.0
	var seconds_half = 0.0

	if t1 <= full_end:
		seconds_full = t1 - t0
	elif t0 >= full_end:
		seconds_half = t1 - t0
	else:
		seconds_full = full_end - t0
		seconds_half = t1 - full_end

	result.seconds_full = seconds_full
	result.seconds_half = seconds_half

	if not is_job:
		for stat_name in effects:
			var rate = float(effects[stat_name])
			var gain = rate * seconds_full + rate * HALF_RATE_MULTIPLIER * seconds_half
			if gain != 0.0:
				result.stat_gains[stat_name] = gain

	if is_job and money_per_sec != 0.0:
		result.money_gained = money_per_sec * result.total_seconds

	return result

func _apply_gain_result(gains: Dictionary) -> void:
	var stat_gains: Dictionary = gains.get("stat_gains", {})
	for stat_name in stat_gains:
		var gain = float(stat_gains[stat_name])
		_add_stat(stat_name, gain)
		_session_stat_gains[stat_name] = _session_stat_gains.get(stat_name, 0.0) + gain

	var money_gain = float(gains.get("money_gained", 0.0))
	if money_gain > 0.0:
		self.money += money_gain
		_session_money_gained += money_gain
		var job_id = str(current_activity_data.get("job_id", ""))
		if not job_id.is_empty():
			var hours = float(gains.get("total_seconds", 0.0)) / 3600.0
			job_hours_worked[job_id] = job_hours_worked.get(job_id, 0.0) + hours

func _add_stat(stat_name: String, amount: float) -> void:
	if amount == 0.0:
		return
	if _physical_stats.has(stat_name):
		set_physical_stat(stat_name, _physical_stats[stat_name] + amount)
	elif _mental_stats.has(stat_name):
		set_mental_stat(stat_name, _mental_stats[stat_name] + amount)
	elif _social_stats.has(stat_name):
		set_social_stat(stat_name, _social_stats[stat_name] + amount)

func stop_activity_for_location_change() -> Dictionary:
	var summary = get_activity_session_summary()
	if is_activity_active:
		stop_activity(false)
	return summary

func get_activity_session_summary() -> Dictionary:
	return {
		"active": is_activity_active,
		"name": current_activity_data.get("name", ""),
		"stat_gains": _session_stat_gains.duplicate(),
		"money_gained": _session_money_gained,
		"elapsed": get_current_activity_elapsed_time(),
		"is_half_rate": is_activity_active and Time.get_unix_time_from_system() >= activity_full_rate_until,
		"is_job": current_activity_data.get("is_job", false)
	}

func resolve_offline_activity_on_load(saved_timestamp: float) -> Dictionary:
	var now = Time.get_unix_time_from_system()
	var offline_time = now - saved_timestamp
	var progress = {
		"has_progress": false,
		"offline_time": offline_time,
		"offline_time_formatted": _format_duration(offline_time),
		"stat_gains": {},
		"money_gained": 0.0,
		"activity_time": 0.0,
		"activity_name": "",
		"was_activity_active": is_activity_active,
		"can_continue": false,
		"ap_granted": 0
	}

	if not is_activity_active or current_activity_data.is_empty():
		return progress

	if offline_time < 30.0:
		activity_last_tick_at = now
		return progress

	if current_activity_data.get("is_job", false):
		var ends = float(current_activity_data.get("shift_ends_at", 0.0))
		var apply_until = now
		var finished = false
		if ends > 0.0 and now >= ends:
			apply_until = ends
			finished = true

		progress.has_progress = true
		activity_last_tick_at = saved_timestamp
		var gains = _compute_gains_for_interval(saved_timestamp, apply_until)
		_apply_gain_result(gains)
		progress.stat_gains = gains.get("stat_gains", {}).duplicate()
		progress.money_gained = gains.get("money_gained", 0.0)
		progress.activity_time = gains.get("total_seconds", 0.0)
		progress.activity_name = current_activity_data.get("name", "")

		if finished:
			_complete_job_shift()
			progress.can_continue = false
		else:
			activity_last_tick_at = now
			progress.can_continue = true
			_pending_continue_activity = current_activity_data.duplicate(true)
			stop_activity(false)
		return progress

	progress.has_progress = true
	activity_last_tick_at = saved_timestamp
	var gains2 = _compute_gains_for_interval(saved_timestamp, now)
	_apply_gain_result(gains2)
	progress.stat_gains = gains2.get("stat_gains", {}).duplicate()
	progress.money_gained = gains2.get("money_gained", 0.0)
	progress.activity_time = gains2.get("total_seconds", 0.0)
	progress.activity_name = current_activity_data.get("name", "")
	progress.can_continue = true
	_pending_continue_activity = current_activity_data.duplicate(true)
	stop_activity(false)
	return progress

func continue_pending_activity() -> bool:
	if _pending_continue_activity.is_empty():
		return false
	var data = _pending_continue_activity.duplicate(true)
	_pending_continue_activity.clear()
	var ok = start_activity(data, false)
	if ok and not data.get("is_job", false):
		activity_full_rate_until = Time.get_unix_time_from_system() + FULL_RATE_DURATION
	return ok

func decline_pending_activity() -> void:
	_pending_continue_activity.clear()

func has_pending_continue() -> bool:
	return not _pending_continue_activity.is_empty()

func get_pending_continue_activity() -> Dictionary:
	return _pending_continue_activity.duplicate(true)

func get_job_shift_remaining() -> float:
	if not is_activity_active or not current_activity_data.get("is_job", false):
		return 0.0
	return max(0.0, float(current_activity_data.get("shift_ends_at", 0.0)) - Time.get_unix_time_from_system())

# ---------- Save / Load ----------

func save_data() -> Dictionary:
	if is_activity_active:
		_tick_activity_gains()
	_tick_ap_progress()

	var saved_data = {
		"player_name": player_name,
		"money": _money,
		"action_points": _action_points,
		"ap_progress": ap_progress,
		"last_ap_progress_tick": last_ap_progress_tick,
		"current_location": current_location,
		"is_activity_active": is_activity_active,
		"current_activity_data": current_activity_data,
		"activity_started_at": activity_started_at,
		"activity_full_rate_until": activity_full_rate_until,
		"activity_last_tick_at": activity_last_tick_at,
		"session_stat_gains": _session_stat_gains,
		"session_money_gained": _session_money_gained,
		"last_save_timestamp": Time.get_unix_time_from_system(),
		"relationships": relationships,
		"character_date_progress": character_date_progress,
		"last_date_times": last_date_times,
		"job_hours_worked": job_hours_worked,
		"completed_dates": completed_dates,
		"inventory": inventory,
		"current_slot_id": current_slot_id,
	}
	saved_data.merge(get_all_stats())
	return saved_data

func load_data(data: Dictionary) -> void:
	player_name = data.get("player_name", "DefaultPlayer")
	self.money = data.get("money", 0.0)

	if data.has("action_points"):
		_action_points = int(data.get("action_points", AP_STARTING))
	else:
		_action_points = AP_STARTING

	ap_progress = float(data.get("ap_progress", 0.0))
	var saved_ap_tick = float(data.get("last_ap_progress_tick", 0.0))
	var saved_timestamp = float(data.get(
		"last_save_timestamp",
		data.get("last_activity_timestamp", Time.get_unix_time_from_system())
	))
	if saved_ap_tick <= 0.0:
		saved_ap_tick = saved_timestamp

	for stat in ["strength", "agility", "endurance", "balance"]:
		set_physical_stat(stat, data.get(stat, 1.0))
	for stat in ["knowledge", "wisdom", "intelligence", "logic"]:
		set_mental_stat(stat, data.get(stat, 1.0))
	for stat in ["leadership", "persuasion", "charisma", "communication"]:
		set_social_stat(stat, data.get(stat, 1.0))

	current_location = data.get("current_location", {
		"name": "Start Screen", "type": "start",
		"scene_path": "res://scenes/main/start_scene.tscn", "activities": []
	})
	current_slot_id = int(data.get("current_slot_id", 0))

	relationships = {}
	for char_id in data.get("relationships", {}):
		relationships[char_id] = int(data["relationships"][char_id])
	character_date_progress = data.get("character_date_progress", {})
	last_date_times = data.get("last_date_times", {})
	job_hours_worked = data.get("job_hours_worked", {})
	completed_dates = data.get("completed_dates", {})
	inventory = data.get("inventory", {})

	is_activity_active = data.get("is_activity_active", false)
	current_activity_data = data.get("current_activity_data", {})
	activity_started_at = data.get("activity_started_at", 0.0)
	activity_full_rate_until = data.get("activity_full_rate_until", 0.0)
	activity_last_tick_at = data.get("activity_last_tick_at", 0.0)
	_session_stat_gains = data.get("session_stat_gains", {})
	_session_money_gained = data.get("session_money_gained", 0.0)

	var now = Time.get_unix_time_from_system()
	var offline_ap_seconds = max(0.0, now - saved_ap_tick)
	last_ap_progress_tick = now
	var ap_before = _action_points
	_add_ap_progress(offline_ap_seconds)
	var ap_from_time = _action_points - ap_before

	var offline_progress = resolve_offline_activity_on_load(saved_timestamp)
	if ap_from_time > 0:
		offline_progress["ap_granted"] = ap_from_time
		offline_progress["has_progress"] = true

	if offline_progress.get("has_progress", false):
		_show_offline_progress_notification(offline_progress)
		offline_progress_calculated.emit(offline_progress)

	player_data_loaded.emit()
	player_location_changed.emit(current_location)
	player_ap_changed.emit(_action_points)
	player_ap_progress_changed.emit(ap_progress, AP_INTERVAL_SECONDS)
	player_money_changed.emit(_money)

	if is_activity_active and not current_activity_data.is_empty():
		player_activity_started.emit(current_activity_data)
		activity_last_tick_at = now

func reset_for_new_character() -> void:
	player_name = "DefaultPlayer"
	_money = 100.0
	_action_points = AP_STARTING
	ap_progress = 0.0
	last_ap_progress_tick = Time.get_unix_time_from_system()
	inventory.clear()
	relationships.clear()
	character_date_progress.clear()
	last_date_times.clear()
	completed_dates.clear()
	job_hours_worked.clear()
	is_activity_active = false
	current_activity_data = {}
	activity_started_at = 0.0
	activity_full_rate_until = 0.0
	activity_last_tick_at = 0.0
	_session_stat_gains.clear()
	_session_money_gained = 0.0
	_pending_continue_activity.clear()
	_completing_job_shift = false
	for s in _physical_stats.keys():
		_physical_stats[s] = 1.0
	for s in _mental_stats.keys():
		_mental_stats[s] = 1.0
	for s in _social_stats.keys():
		_social_stats[s] = 1.0
	player_ap_changed.emit(_action_points)
	player_ap_progress_changed.emit(ap_progress, AP_INTERVAL_SECONDS)
	player_money_changed.emit(_money)

func _format_duration(seconds: float) -> String:
	var total_seconds = int(maxf(0.0, seconds))
	var hours = int(total_seconds / 3600.0)
	var minutes = int((total_seconds % 3600) / 60.0)
	var secs = total_seconds % 60
	if hours > 0:
		return "%dh %dm %ds" % [hours, minutes, secs]
	if minutes > 0:
		return "%dm %ds" % [minutes, secs]
	return "%ds" % secs

func _show_offline_progress_notification(progress_data: Dictionary) -> void:
	if not UIManager:
		_notification_queue.append(progress_data)
		return

	var message = "Welcome back! You were offline for %s." % progress_data.get("offline_time_formatted", "?")
	if progress_data.get("activity_time", 0.0) > 0.0:
		message += "\n\n%s ran for %s." % [
			progress_data.get("activity_name", "Activity"),
			_format_duration(progress_data.get("activity_time", 0.0))
		]
		var stat_gains = progress_data.get("stat_gains", {})
		if not stat_gains.is_empty():
			message += "\nStats gained:"
			for stat_name in stat_gains:
				message += "\n  +%.2f %s" % [stat_gains[stat_name], str(stat_name).capitalize()]
		if progress_data.get("money_gained", 0.0) > 0.0:
			message += "\n  +$%.2f money" % progress_data.money_gained
	if progress_data.get("ap_granted", 0) > 0:
		message += "\n\n+%d AP while away" % progress_data.ap_granted

	UIManager.show_notification(message, 6.0)

# ---------- Location ----------

func set_current_location(location_data: Dictionary) -> void:
	var new_name = str(location_data.get("name", ""))
	var old_name = str(current_location.get("name", ""))
	if is_activity_active and new_name != old_name:
		var summary = stop_activity_for_location_change()
		if UIManager and summary.get("name", "") != "":
			var msg = "Activity stopped: %s" % summary.name
			for stat_name in summary.get("stat_gains", {}):
				msg += " | +%.2f %s" % [summary.stat_gains[stat_name], str(stat_name).capitalize()]
			if summary.get("money_gained", 0.0) > 0.0:
				msg += " | +$%.2f" % summary.money_gained
			UIManager.show_notification(msg, 4.0)
	current_location = location_data
	player_location_changed.emit(current_location)

# ---------- Inventory / money / stats ----------

func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	inventory[item_id] = inventory.get(item_id, 0) + amount
	inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	var current = inventory.get(item_id, 0)
	if current < amount:
		return false
	inventory[item_id] = current - amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return inventory.get(item_id, 0) >= amount

func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

func get_inventory() -> Dictionary:
	return inventory.duplicate()

func set_player_name(new_name: String) -> void:
	player_name = new_name.strip_edges() if new_name.strip_edges() else "DefaultPlayer"
	player_name_changed.emit(player_name)

func get_player_name() -> String:
	return player_name

func add_money(amount: float) -> void:
	self.money += amount

func spend_money(amount: float) -> bool:
	if money >= amount:
		self.money -= amount
		return true
	return false

func has_money(amount: float) -> bool:
	return money >= amount

func set_physical_stat(stat_name: String, value: float) -> void:
	if _physical_stats.has(stat_name):
		_physical_stats[stat_name] = max(0.0, value)
		player_stat_changed.emit(stat_name, _physical_stats[stat_name])

func set_mental_stat(stat_name: String, value: float) -> void:
	if _mental_stats.has(stat_name):
		_mental_stats[stat_name] = max(0.0, value)
		player_stat_changed.emit(stat_name, _mental_stats[stat_name])

func set_social_stat(stat_name: String, value: float) -> void:
	if _social_stats.has(stat_name):
		_social_stats[stat_name] = max(0.0, value)
		player_stat_changed.emit(stat_name, _social_stats[stat_name])

func get_stat(stat_name: String) -> float:
	for stats in [_physical_stats, _mental_stats, _social_stats]:
		if stats.has(stat_name):
			return stats[stat_name]
	return 0.0

func get_physical_stats() -> Array:
	return _physical_stats.keys()

func get_mental_stats() -> Array:
	return _mental_stats.keys()

func get_social_stats() -> Array:
	return _social_stats.keys()

func get_all_stats() -> Dictionary:
	var all_stats = {}
	all_stats.merge(_physical_stats, true)
	all_stats.merge(_mental_stats, true)
	all_stats.merge(_social_stats, true)
	return all_stats

func get_current_activity_data() -> Dictionary:
	return current_activity_data

func get_current_activity_name() -> String:
	return str(current_activity_data.get("name", ""))

func get_current_activity_stat_raised() -> String:
	var effects = current_activity_data.get("effects", {})
	return str(effects.keys()[0]) if not effects.is_empty() else ""

func get_current_activity_rate_per_second() -> float:
	var effects = current_activity_data.get("effects", {})
	if effects.is_empty():
		return 0.0
	var rate = float(effects.values()[0])
	if is_activity_active and Time.get_unix_time_from_system() >= activity_full_rate_until:
		return rate * HALF_RATE_MULTIPLIER
	return rate

func get_current_activity_accumulated_display() -> float:
	var total = 0.0
	for v in _session_stat_gains.values():
		total += float(v)
	return total

func get_current_activity_money_accumulated_display() -> float:
	return _session_money_gained

func get_current_activity_elapsed_time() -> float:
	if is_activity_active and activity_started_at > 0.0:
		return Time.get_unix_time_from_system() - activity_started_at
	return 0.0

func get_job_hours_worked(job_id: String) -> float:
	return float(job_hours_worked.get(job_id, 0.0))

# ---------- Relationships ----------

func add_relationship_points(character_id: String, amount: float) -> void:
	var old_points := float(relationships.get(character_id, 0.0))
	var max_points := float(RELATIONSHIP_STAGES.keys().max())

	relationships[character_id] = minf(
		old_points + amount,
		max_points
	)

	player_relationship_stage_changed.emit(
		character_id,
		get_relationship_stage(character_id)
	)


func add_talk_relationship_points(
	character_id: String,
	base_amount: float = 1.0
) -> float:
	if character_id.is_empty():
		return 0.0

	var multiplier := 1.0

	if CharacterMoodManager:
		multiplier = CharacterMoodManager.get_mood_multiplier(
			character_id
		)

	var gained_points := base_amount * multiplier

	if gained_points > 0.0:
		add_relationship_points(character_id, gained_points)

	return gained_points


func get_relationship_points(character_id: String) -> float:
	return float(relationships.get(character_id, 0.0))


func get_relationship_points_display(character_id: String) -> int:
	return int(floor(get_relationship_points(character_id)))


func get_relationship_stage_for_points(points: float) -> String:
	var thresholds := RELATIONSHIP_STAGES.keys()
	thresholds.sort()
	thresholds.reverse()

	for threshold in thresholds:
		if points >= float(threshold):
			return RELATIONSHIP_STAGES[threshold]

	return "Stranger"


func get_relationship_stage(character_id: String) -> String:
	return get_relationship_stage_for_points(
		get_relationship_points(character_id)
	)


func can_progress_relationship(character_id: String) -> bool:
	var max_points := float(RELATIONSHIP_STAGES.keys().max())
	return get_relationship_points(character_id) < max_points
	
func mark_date_completed(character_id: String, date_name: String) -> void:
	if not completed_dates.has(character_id):
		completed_dates[character_id] = []
	if date_name not in completed_dates[character_id]:
		completed_dates[character_id].append(date_name)

func has_completed_date(character_id: String, date_name: String) -> bool:
	return date_name in completed_dates.get(character_id, [])

func get_completed_dates(character_id: String) -> Array:
	return completed_dates.get(character_id, [])

func get_total_completed_dates() -> int:
	var total = 0
	for char_dates in completed_dates.values():
		total += char_dates.size()
	return total

func set_date_progress(character_id: String, date_number: int) -> void:
	character_date_progress[character_id] = date_number

func get_date_progress(character_id: String) -> int:
	return int(character_date_progress.get(character_id, 0))

func set_last_date_time(character_id: String, time: float) -> void:
	last_date_times[character_id] = time

func get_last_date_time(character_id: String) -> float:
	return float(last_date_times.get(character_id, 0.0))

func can_date_character(character_id: String, current_time: float, cooldown_hours: float = 24.0) -> bool:
	return current_time - get_last_date_time(character_id) >= cooldown_hours * 3600.0

func get_total_relationship_points() -> int:
	var total = 0
	for points in relationships.values():
		total += int(points)
	return total

func get_relationship_summary() -> Dictionary:
	var summary = {}
	for character_id in relationships:
		summary[character_id] = {
			"points": get_relationship_points(character_id),
			"stage": get_relationship_stage(character_id)
		}
	return summary
