extends Node

const STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY: float = 100.0 / (4.0 * 3600.0)

# Signals
signal player_stat_changed(stat_name: String, new_value: float)
signal player_name_changed(new_name: String)
signal player_data_loaded
signal player_location_changed(new_location_data: Dictionary)
signal player_activity_started(activity_data: Dictionary)
signal player_activity_progress(activity_data: Dictionary)
signal player_activity_stopped(stopped_activity_data: Dictionary, was_stamina_exhausted: bool)
signal player_stamina_changed(current_stamina: float, max_stamina: float)
signal player_money_changed(current_money: float)
signal player_relationship_stage_changed(character_id: String, new_stage: String)
signal offline_progress_calculated(progress_data: Dictionary)

# Player Identity
var player_name: String = "DefaultPlayer"

# Resources
var _money: float = 0.0
var money: float:
	get:
		return _money
	set(value):
		_money = max(0.0, value)
		player_money_changed.emit(_money)

var max_stamina: float = 100.0
var stamina: float = 100.0:
	set(value):
		stamina = clamp(value, 0.0, max_stamina)
		player_stamina_changed.emit(stamina, max_stamina)

# Player Stats
var _physical_stats: Dictionary = {
	"strength": 1.0, "agility": 1.0, "endurance": 1.0, "balance": 1.0
}
var _mental_stats: Dictionary = {
	"knowledge": 1.0, "wisdom": 1.0, "intelligence": 1.0, "logic": 1.0
}
var _social_stats: Dictionary = {
	"leadership": 1.0, "persuasion": 1.0, "charisma": 1.0, "communication": 1.0
}

# Location and Activity Tracking
var current_location: Dictionary = {
	"name": "Start Screen",
	"type": "start",
	"scene_path": "res://scenes/start_screen.tscn",
	"activities": []
}
var is_activity_active: bool = false
var current_activity_data: Dictionary = {}
var last_activity_timestamp: float = 0.0  # Unix timestamp for activity start/save
var _current_activity_stat_accumulated_display: float = 0.0
var _current_activity_money_accumulated_display: float = 0.0

# Job Progression Tracking
var job_hours_worked: Dictionary = {}

# Relationship Tracking
var relationships: Dictionary = {}
var character_date_progress: Dictionary = {}
var last_date_times: Dictionary = {}
var completed_dates: Dictionary = {}

const RELATIONSHIP_STAGES = {
	0: "Stranger", 50: "Acquaintance", 150: "Friend", 300: "Good Friend",
	600: "Crush", 1000: "Dating", 1500: "Soulmate"
}

func _ready() -> void:
	self.stamina = max_stamina
	self.money = 0.0
	player_location_changed.emit(current_location)
	player_stamina_changed.emit(stamina, max_stamina)
	player_money_changed.emit(_money)
	player_data_loaded.emit()
	if not _notification_queue.is_empty() and UIManager:
		for progress_data in _notification_queue:
			_show_offline_progress_notification(progress_data)
		_notification_queue.clear()
	var timer = Timer.new()
	timer.wait_time = 300.0  # Auto-save every 5 minutes
	timer.autostart = true
	timer.timeout.connect(_auto_save)
	add_child(timer)
	
func _auto_save() -> void:
	if SaveManager:
		var result = SaveManager.save_game(self, true)
		if result.success and UIManager:
			UIManager.show_notification("Game auto-saved!", 3.0)

func _process(_delta: float) -> void:
	if is_activity_active:
		var current_time = Time.get_unix_time_from_system()
		var elapsed = current_time - last_activity_timestamp
		var effects = current_activity_data.get("effects", {})
		var drain_rate = current_activity_data.get("stamina_drain_per_second", STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY)
		var total_stamina_drain = drain_rate * elapsed
		
		if stamina >= total_stamina_drain:
			# Apply stamina drain
			self.stamina -= total_stamina_drain
			
			# Apply stat gains
			for stat_name in effects:
				var gain = effects[stat_name] * elapsed
				if _physical_stats.has(stat_name):
					set_physical_stat(stat_name, _physical_stats[stat_name] + gain)
				elif _mental_stats.has(stat_name):
					set_mental_stat(stat_name, _mental_stats[stat_name] + gain)
				elif _social_stats.has(stat_name):
					set_social_stat(stat_name, _social_stats[stat_name] + gain)
				_current_activity_stat_accumulated_display += gain
			
			# Apply job money gains
			if current_activity_data.get("is_job", false):
				var money_gain = current_activity_data.get("money_gain_per_second", 0.0) * elapsed
				self.money += money_gain
				_current_activity_money_accumulated_display += money_gain
				var job_id = current_activity_data.get("job_id", "")
				if not job_id.is_empty():
					job_hours_worked[job_id] = job_hours_worked.get(job_id, 0.0) + elapsed / 3600.0
			
			# Update timestamp
			last_activity_timestamp = current_time
			player_activity_progress.emit(current_activity_data)
		else:
			# Calculate time until stamina exhaustion
			var time_to_exhaust = stamina / drain_rate
			var remaining_stamina = stamina - (drain_rate * time_to_exhaust)
			self.stamina = remaining_stamina
			
			# Apply partial stat gains
			for stat_name in effects:
				var gain = effects[stat_name] * time_to_exhaust
				if _physical_stats.has(stat_name):
					set_physical_stat(stat_name, _physical_stats[stat_name] + gain)
				elif _mental_stats.has(stat_name):
					set_mental_stat(stat_name, _mental_stats[stat_name] + gain)
				elif _social_stats.has(stat_name):
					set_social_stat(stat_name, _social_stats[stat_name] + gain)
				_current_activity_stat_accumulated_display += gain
			
			# Apply partial job money gains
			if current_activity_data.get("is_job", false):
				var money_gain = current_activity_data.get("money_gain_per_second", 0.0) * time_to_exhaust
				self.money += money_gain
				_current_activity_money_accumulated_display += money_gain
				var job_id = current_activity_data.get("job_id", "")
				if not job_id.is_empty():
					job_hours_worked[job_id] = job_hours_worked.get(job_id, 0.0) + time_to_exhaust / 3600.0
			
			# Stop activity
			stop_activity(true)
			if UIManager:
				UIManager.show_notification("Activity stopped due to stamina exhaustion!")
	else:
		if LocationManager:
			var current_time = Time.get_unix_time_from_system()
			var elapsed = current_time - last_activity_timestamp
			var regen_rate = LocationManager.STAMINA_REGEN_PER_SECOND
			self.stamina += regen_rate * elapsed
			last_activity_timestamp = current_time

# Enhanced save/load with better offline progress calculation
func save_data() -> Dictionary:
	var saved_data = {
		"player_name": player_name,
		"money": _money,
		"max_stamina": max_stamina,
		"stamina": stamina,
		"current_location": current_location,
		"is_activity_active": is_activity_active,
		"current_activity_data": current_activity_data,
		"last_activity_timestamp": Time.get_unix_time_from_system(),
		"relationships": relationships,
		"character_date_progress": character_date_progress,
		"last_date_times": last_date_times,
		"job_hours_worked": job_hours_worked,
		"accumulated_stat_display": _current_activity_stat_accumulated_display,
		"accumulated_money_display": _current_activity_money_accumulated_display,
		"completed_dates": completed_dates,
	}
	saved_data.merge(get_all_stats())
	return saved_data

func load_data(data: Dictionary) -> void:
	player_name = data.get("player_name", "DefaultPlayer")
	self.money = data.get("money", 0.0)
	max_stamina = data.get("max_stamina", 100.0)
	self.stamina = data.get("stamina", max_stamina)

	# Load stats
	for stat in ["strength", "agility", "endurance", "balance"]:
		set_physical_stat(stat, data.get(stat, 1.0))
	for stat in ["knowledge", "wisdom", "intelligence", "logic"]:
		set_mental_stat(stat, data.get(stat, 1.0))
	for stat in ["leadership", "persuasion", "charisma", "communication"]:
		set_social_stat(stat, data.get(stat, 1.0))

	current_location = data.get("current_location", {
		"name": "Start Screen", "type": "start", "scene_path": "res://scenes/start_screen.tscn", "activities": []
	})
	
	# Load relationship data
	relationships = {}
	for char_id in data.get("relationships", {}):
		relationships[char_id] = int(data["relationships"][char_id])
	character_date_progress = data.get("character_date_progress", {})
	last_date_times = data.get("last_date_times", {})
	job_hours_worked = data.get("job_hours_worked", {})
	completed_dates = data.get("completed_dates", {})
	
	# Load activity state and calculate offline progress
	is_activity_active = data.get("is_activity_active", false)
	current_activity_data = data.get("current_activity_data", {})
	var saved_timestamp = data.get("last_activity_timestamp", Time.get_unix_time_from_system())
	_current_activity_stat_accumulated_display = data.get("accumulated_stat_display", 0.0)
	_current_activity_money_accumulated_display = data.get("accumulated_money_display", 0.0)
	
	# Calculate offline progress
	var offline_progress = _calculate_offline_progress(saved_timestamp)
	
	if offline_progress.has_progress:
		# Show offline progress notification
		_show_offline_progress_notification(offline_progress)
	
	# Set the current timestamp
	last_activity_timestamp = Time.get_unix_time_from_system()
	
	# Emit signals
	player_data_loaded.emit()
	player_location_changed.emit(current_location)
	player_stamina_changed.emit(stamina, max_stamina)
	player_money_changed.emit(_money)
	
	if offline_progress.has_progress:
		offline_progress_calculated.emit(offline_progress)

func _calculate_offline_progress(saved_timestamp: float) -> Dictionary:
	var current_time = Time.get_unix_time_from_system()
	var offline_time = current_time - saved_timestamp
	var progress_data = {
		"has_progress": false,
		"offline_time": offline_time,
		"offline_time_formatted": _format_duration(offline_time),
		"stamina_regenerated": 0.0,
		"stat_gains": {},
		"money_gained": 0.0,
		"activity_stopped": false,
		"activity_time": 0.0
	}
	
	# Only calculate if offline for more than 30 seconds
	if offline_time < 30.0:
		return progress_data
	
	progress_data.has_progress = true
	
	if is_activity_active and not current_activity_data.is_empty():
		# Calculate activity progress
		var effects = current_activity_data.get("effects", {})
		var drain_rate = current_activity_data.get("stamina_drain_per_second", STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY)
		var total_stamina_drain = drain_rate * offline_time
		
		if stamina >= total_stamina_drain:
			# Activity continued for the entire offline duration
			progress_data.activity_time = offline_time
			
			# Apply stamina drain
			self.stamina -= total_stamina_drain
			
			# Apply stat gains
			for stat_name in effects:
				var gain = effects[stat_name] * offline_time
				if _physical_stats.has(stat_name):
					set_physical_stat(stat_name, _physical_stats[stat_name] + gain)
				elif _mental_stats.has(stat_name):
					set_mental_stat(stat_name, _mental_stats[stat_name] + gain)
				elif _social_stats.has(stat_name):
					set_social_stat(stat_name, _social_stats[stat_name] + gain)
				
				progress_data.stat_gains[stat_name] = gain
				_current_activity_stat_accumulated_display += gain
			
			# Apply job money gains
			if current_activity_data.get("is_job", false):
				var money_gain = current_activity_data.get("money_gain_per_second", 0.0) * offline_time
				self.money += money_gain
				progress_data.money_gained = money_gain
				_current_activity_money_accumulated_display += money_gain
				
				var job_id = current_activity_data.get("job_id", "")
				if not job_id.is_empty():
					job_hours_worked[job_id] = job_hours_worked.get(job_id, 0.0) + offline_time / 3600.0
		else:
			# Activity stopped due to stamina exhaustion
			var time_to_exhaust = stamina / drain_rate
			progress_data.activity_time = time_to_exhaust
			progress_data.activity_stopped = true
			
			# Apply progress until stamina exhaustion
			self.stamina = 0.0
			
			for stat_name in effects:
				var gain = effects[stat_name] * time_to_exhaust
				if _physical_stats.has(stat_name):
					set_physical_stat(stat_name, _physical_stats[stat_name] + gain)
				elif _mental_stats.has(stat_name):
					set_mental_stat(stat_name, _mental_stats[stat_name] + gain)
				elif _social_stats.has(stat_name):
					set_social_stat(stat_name, _social_stats[stat_name] + gain)
				
				progress_data.stat_gains[stat_name] = gain
				_current_activity_stat_accumulated_display += gain
			
			if current_activity_data.get("is_job", false):
				var money_gain = current_activity_data.get("money_gain_per_second", 0.0) * time_to_exhaust
				self.money += money_gain
				progress_data.money_gained = money_gain
				_current_activity_money_accumulated_display += money_gain
				
				var job_id = current_activity_data.get("job_id", "")
				if not job_id.is_empty():
					job_hours_worked[job_id] = job_hours_worked.get(job_id, 0.0) + time_to_exhaust / 3600.0
			
			# Stop the activity
			stop_activity(true)
			
			# Calculate stamina regeneration for remaining time
			var remaining_time = offline_time - time_to_exhaust
			if remaining_time > 0 and LocationManager:
				var regen_rate = LocationManager.STAMINA_REGEN_PER_SECOND
				var stamina_regen = regen_rate * remaining_time
				self.stamina += stamina_regen
				progress_data.stamina_regenerated = stamina_regen
	else:
		# No activity was running, just calculate stamina regeneration
		if LocationManager:
			var regen_rate = LocationManager.STAMINA_REGEN_PER_SECOND
			var stamina_regen = regen_rate * offline_time
			var old_stamina = stamina
			self.stamina += stamina_regen
			progress_data.stamina_regenerated = stamina - old_stamina
	
	return progress_data

func _format_duration(seconds: float) -> String:
	var total_seconds = int(seconds)
	var hours = float(total_seconds) / 3600
	var minutes = float(total_seconds % 3600) / 60
	var secs = total_seconds % 60
	
	if hours > 0:
		return "%dh %dm %ds" % [hours, minutes, secs]
	elif minutes > 0:
		return "%dm %ds" % [minutes, secs]
	else:
		return "%ds" % secs

var _notification_queue: Array = []

func _show_offline_progress_notification(progress_data: Dictionary):
	if not UIManager:
		_notification_queue.append(progress_data)
		return
	
	var message = "Welcome back! You were offline for %s.\n" % progress_data.offline_time_formatted
	if progress_data.activity_time > 0:
		var activity_name = current_activity_data.get("name", "Unknown Activity")
		message += "\n%s continued for %s." % [activity_name, _format_duration(progress_data.activity_time)]
		if not progress_data.stat_gains.is_empty():
			message += "\nStats gained:"
			for stat_name in progress_data.stat_gains:
				message += "\n  +%.2f %s" % [progress_data.stat_gains[stat_name], stat_name.capitalize()]
		if progress_data.money_gained > 0:
			message += "\n  +$%.2f money" % progress_data.money_gained
		if progress_data.activity_stopped:
			message += "\n\nActivity stopped due to stamina exhaustion."
	if progress_data.stamina_regenerated > 0:
		message += "\nStamina regenerated: +%.1f" % progress_data.stamina_regenerated
	UIManager.show_notification(message, 8.0)

# Player Name Methods
func set_player_name(new_name: String) -> void:
	player_name = new_name.strip_edges() if new_name.strip_edges() else "DefaultPlayer"
	player_name_changed.emit(player_name)

func get_player_name() -> String:
	return player_name

# Stamina Methods
func consume_stamina(amount: float) -> bool:
	if stamina >= amount:
		self.stamina -= amount
		return true
	return false

func restore_stamina(amount: float) -> void:
	self.stamina += amount

func is_stamina_full() -> bool:
	return stamina >= max_stamina

func get_stamina_percentage() -> float:
	return stamina / max_stamina

# Money Methods
func add_money(amount: float) -> void:
	self.money += amount

func spend_money(amount: float) -> bool:
	if money >= amount:
		self.money -= amount
		return true
	return false

func has_money(amount: float) -> bool:
	return money >= amount

# Stat Methods
func set_physical_stat(stat_name: String, value: float) -> void:
	if _physical_stats.has(stat_name):
		_physical_stats[stat_name] = max(0.0, value)
		player_stat_changed.emit(stat_name, _physical_stats[stat_name])
	else:
		push_warning("Unknown physical stat: %s" % stat_name)

func set_mental_stat(stat_name: String, value: float) -> void:
	if _mental_stats.has(stat_name):
		_mental_stats[stat_name] = max(0.0, value)
		player_stat_changed.emit(stat_name, _mental_stats[stat_name])
	else:
		push_warning("Unknown mental stat: %s" % stat_name)

func set_social_stat(stat_name: String, value: float) -> void:
	if _social_stats.has(stat_name):
		_social_stats[stat_name] = max(0.0, value)
		player_stat_changed.emit(stat_name, _social_stats[stat_name])
	else:
		push_warning("Unknown social stat: %s" % stat_name)

func get_stat(stat_name: String) -> float:
	for stats in [_physical_stats, _mental_stats, _social_stats]:
		if stats.has(stat_name):
			return stats[stat_name]
	return 0.0

# Additional Stat Getters
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

# Location Management
func set_current_location(location_data: Dictionary) -> void:
	if is_activity_active:
		stop_activity(false)
	current_location = location_data
	player_location_changed.emit(current_location)

# Activity Management - FIXED VERSION
func start_activity(activity_data: Dictionary, preserve_accumulated_progress: bool = false) -> bool:
	if is_activity_active:
		if current_activity_data.get("name") == activity_data.get("name"):
			return false
		stop_activity(false)

	var stamina_cost = activity_data.get("stamina_cost_start", 0.0)
	var money_cost = activity_data.get("money_cost_start", 0.0)

	if stamina < stamina_cost or money < money_cost:
		if UIManager:
			UIManager.show_notification("Not enough %s to start %s!" % [
				"stamina" if stamina < stamina_cost else "money",
				activity_data.get("name", "activity")
			])
		return false

	self.stamina -= stamina_cost
	self.money -= money_cost
	is_activity_active = true
	current_activity_data = activity_data
	last_activity_timestamp = Time.get_unix_time_from_system()
	
	# FIXED: Only reset accumulated progress if not preserving it
	if not preserve_accumulated_progress:
		_current_activity_stat_accumulated_display = 0.0
		_current_activity_money_accumulated_display = 0.0
	
	player_activity_started.emit(current_activity_data)
	print("PlayerData: Started activity %s (preserve_progress: %s)" % [
		activity_data.get("name", "Unknown"), preserve_accumulated_progress
	])
	return true

func restart_activity_with_progress() -> bool:
	if not is_activity_active or current_activity_data.is_empty():
		print("PlayerData: Cannot restart activity - no active activity or empty data")
		return false
	
	print("PlayerData: Restarting activity %s with preserved progress (stats: %.2f, money: %.2f)" % [
		current_activity_data.get("name", "Unknown"),
		_current_activity_stat_accumulated_display,
		_current_activity_money_accumulated_display
	])
	
	# Store the current data
	var activity_data = current_activity_data.duplicate()
	var preserved_stat_progress = _current_activity_stat_accumulated_display
	var preserved_money_progress = _current_activity_money_accumulated_display
	
	# Temporarily stop the activity
	is_activity_active = false
	current_activity_data = {}
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Restart with preserved progress
	var success = start_activity(activity_data, true)  # Pass true to preserve progress
	if success:
		_current_activity_stat_accumulated_display = preserved_stat_progress
		_current_activity_money_accumulated_display = preserved_money_progress
		print("PlayerData: Activity restarted successfully")
	else:
		print("PlayerData: Failed to restart activity - insufficient stamina or money")
	
	return success

func stop_activity(was_stamina_exhausted: bool = false) -> void:
	if is_activity_active:
		print("PlayerData: Stopping activity %s (stamina_exhausted: %s)" % [
			current_activity_data.get("name", "None"), was_stamina_exhausted
		])
		var activity_that_ended = current_activity_data
		is_activity_active = false
		current_activity_data = {}
		last_activity_timestamp = Time.get_unix_time_from_system()
		_current_activity_stat_accumulated_display = 0.0
		_current_activity_money_accumulated_display = 0.0
		player_activity_stopped.emit(activity_that_ended, was_stamina_exhausted)

func get_current_activity_data() -> Dictionary:
	return current_activity_data

# Activity Info Getters (for UI)
func get_current_activity_name() -> String:
	return current_activity_data.get("name", "")

func get_current_activity_stat_raised() -> String:
	var effects = current_activity_data.get("effects", {})
	return effects.keys()[0] if not effects.is_empty() else ""

func get_current_activity_rate_per_second() -> float:
	var effects = current_activity_data.get("effects", {})
	return effects.values()[0] if not effects.is_empty() else 0.0

func get_current_activity_accumulated_display() -> float:
	return _current_activity_stat_accumulated_display

func get_current_activity_money_accumulated_display() -> float:
	return _current_activity_money_accumulated_display

func get_current_activity_elapsed_time() -> float:
	if is_activity_active:
		return Time.get_unix_time_from_system() - last_activity_timestamp
	return 0.0

# Job Hours Worked Methods
func get_job_hours_worked(job_id: String) -> float:
	return job_hours_worked.get(job_id, 0.0)

# Relationship Methods
func add_relationship_points(character_id: String, amount: int) -> void:
	var old_points = relationships.get(character_id, 0)
	var max_points = RELATIONSHIP_STAGES.keys().max()
	relationships[character_id] = min(old_points + amount, max_points)
	var new_stage = get_relationship_stage(character_id)
	if old_points == 0 or new_stage != get_relationship_stage_for_points(old_points):
		player_relationship_stage_changed.emit(character_id, new_stage)

func get_relationship_points(character_id: String) -> int:
	return relationships.get(character_id, 0)

func get_relationship_stage_for_points(points: int) -> String:
	var thresholds = RELATIONSHIP_STAGES.keys()
	thresholds.sort()
	thresholds.reverse()
	for threshold in thresholds:
		if points >= threshold:
			return RELATIONSHIP_STAGES[threshold]
	return "Stranger"

func get_relationship_stage(character_id: String) -> String:
	return get_relationship_stage_for_points(get_relationship_points(character_id))

func can_progress_relationship(character_id: String) -> bool:
	return get_relationship_points(character_id) < RELATIONSHIP_STAGES.keys().max()
	
func mark_date_completed(character_id: String, date_name: String) -> void:
	"""Mark a specific named date as completed"""
	if not completed_dates.has(character_id):
		completed_dates[character_id] = []
	
	var completed_list = completed_dates[character_id]
	if date_name not in completed_list:
		completed_list.append(date_name)
	
	print("PlayerData: Marked date '%s' as completed for %s" % [date_name, character_id])

func has_completed_date(character_id: String, date_name: String) -> bool:
	"""Check if a specific named date has been completed"""
	if not completed_dates.has(character_id):
		return false
	
	return date_name in completed_dates[character_id]

func get_completed_dates(character_id: String) -> Array:
	"""Get all completed date names for a character"""
	return completed_dates.get(character_id, [])

func get_total_completed_dates() -> int:
	"""Get the total number of completed dates across all characters"""
	var total = 0
	for char_dates in completed_dates.values():
		total += char_dates.size()
	return total


# Dating Methods
func set_date_progress(character_id: String, date_number: int) -> void:
	character_date_progress[character_id] = date_number

func get_date_progress(character_id: String) -> int:
	return character_date_progress.get(character_id, 0)

func set_last_date_time(character_id: String, time: float) -> void:
	last_date_times[character_id] = time

func get_last_date_time(character_id: String) -> float:
	return last_date_times.get(character_id, 0.0)

func can_date_character(character_id: String, current_time: float, cooldown_hours: float = 24.0) -> bool:
	return current_time - get_last_date_time(character_id) >= cooldown_hours * 3600.0

# Utility Methods
func get_total_relationship_points() -> int:
	var total = 0
	for points in relationships.values():
		total += points
	return total

func get_relationship_summary() -> Dictionary:
	var summary = {}
	for character_id in relationships:
		summary[character_id] = {
			"points": get_relationship_points(character_id),
			"stage": get_relationship_stage(character_id)
		}
	return summary
