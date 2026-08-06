extends Node

signal mood_changed(
	character_id: String,
	old_mood: String,
	new_mood: String
)

const MOOD_CHANGE_INTERVAL_SECONDS := 3600
const DEFAULT_MOOD := "neutral"

const MOOD_ORDER: Array[String] = [
	"angry",
	"upset",
	"neutral",
	"happy",
	"excited"
]

const MOODS: Dictionary = {
	"angry": {
		"display_name": "Angry",
		"multiplier": 0.0,
		"weight": 5
	},
	"upset": {
		"display_name": "Upset",
		"multiplier": 0.5,
		"weight": 15
	},
	"neutral": {
		"display_name": "Neutral",
		"multiplier": 1.0,
		"weight": 40
	},
	"happy": {
		"display_name": "Happy",
		"multiplier": 1.5,
		"weight": 30
	},
	"excited": {
		"display_name": "Excited",
		"multiplier": 2.0,
		"weight": 10
	}
}

# Saved runtime state:
# {
#     "hikari_cafeteria": {
#         "mood": "happy",
#         "mood_changed_at": 1785800000
#     }
# }
var character_moods: Dictionary = {}

# Runtime-only personality weights registered from character data:
# {
#     "hikari_cafeteria": {
#         "angry": 2,
#         "upset": 8,
#         "neutral": 30,
#         "happy": 40,
#         "excited": 20
#     }
# }
var character_mood_weights: Dictionary = {}


func _ready() -> void:
	randomize()


# -------------------------------------------------------------------
# Character registration
# -------------------------------------------------------------------

func register_character(character_data: Dictionary) -> void:
	var character_id := str(character_data.get("id", ""))

	if character_id.is_empty():
		return

	var custom_weights = character_data.get("mood_weights", {})

	if custom_weights is Dictionary and not custom_weights.is_empty():
		character_mood_weights[character_id] = (
			_sanitize_weights(custom_weights)
		)
	else:
		character_mood_weights.erase(character_id)

	_ensure_character_mood(character_id)


func initialize_characters(characters: Dictionary) -> void:
	for character_key in characters:
		var character_data = characters[character_key]

		if not character_data is Dictionary:
			continue

		var registered_data: Dictionary = character_data.duplicate(true)

		if str(registered_data.get("id", "")).is_empty():
			registered_data["id"] = str(character_key)

		register_character(registered_data)


func unregister_character(character_id: String) -> void:
	character_mood_weights.erase(character_id)


# -------------------------------------------------------------------
# Public mood access
# -------------------------------------------------------------------

func get_mood(character_id: String) -> String:
	if character_id.is_empty():
		return DEFAULT_MOOD

	_ensure_character_mood(character_id)
	_refresh_mood_if_needed(character_id)

	var state: Dictionary = character_moods.get(character_id, {})
	var mood_name := str(state.get("mood", DEFAULT_MOOD))

	if not MOODS.has(mood_name):
		mood_name = DEFAULT_MOOD

	return mood_name


func get_mood_data(character_id: String) -> Dictionary:
	var mood_name := get_mood(character_id)
	var mood_data: Dictionary = MOODS.get(
		mood_name,
		MOODS[DEFAULT_MOOD]
	)

	var result := mood_data.duplicate(true)
	result["id"] = mood_name
	return result


func get_mood_display_name(character_id: String) -> String:
	var mood_data := get_mood_data(character_id)
	return str(mood_data.get("display_name", "Neutral"))


func get_mood_multiplier(character_id: String) -> float:
	var mood_data := get_mood_data(character_id)
	return float(mood_data.get("multiplier", 1.0))


func get_mood_changed_at(character_id: String) -> int:
	_ensure_character_mood(character_id)

	var state: Dictionary = character_moods.get(character_id, {})
	return int(state.get("mood_changed_at", 0))


func get_seconds_until_mood_change(character_id: String) -> int:
	_ensure_character_mood(character_id)
	_refresh_mood_if_needed(character_id)

	var changed_at := get_mood_changed_at(character_id)
	var next_change_at := (
		changed_at + MOOD_CHANGE_INTERVAL_SECONDS
	)

	return maxi(
		0,
		next_change_at - _get_current_timestamp()
	)


func get_minutes_until_mood_change(character_id: String) -> int:
	var seconds_remaining := get_seconds_until_mood_change(
		character_id
	)

	if seconds_remaining <= 0:
		return 0

	return int(ceil(float(seconds_remaining) / 60.0))


# -------------------------------------------------------------------
# Mood creation and timed refresh
# -------------------------------------------------------------------

func _ensure_character_mood(character_id: String) -> void:
	if character_moods.has(character_id):
		_validate_character_state(character_id)
		return

	var now := _get_current_timestamp()

	# Backdate the starting timestamp by a random amount.
	# This makes every character's next mood change happen
	# independently within the next hour.
	var random_elapsed := randi_range(
		0,
		MOOD_CHANGE_INTERVAL_SECONDS - 1
	)

	character_moods[character_id] = {
		"mood": _roll_mood_for_character(character_id),
		"mood_changed_at": now - random_elapsed
	}


func _validate_character_state(character_id: String) -> void:
	var state = character_moods.get(character_id)

	if not state is Dictionary:
		character_moods.erase(character_id)
		_ensure_character_mood(character_id)
		return

	var mood_name := str(state.get("mood", DEFAULT_MOOD))

	if not MOODS.has(mood_name):
		state["mood"] = DEFAULT_MOOD

	var changed_at := int(state.get("mood_changed_at", 0))

	if changed_at <= 0:
		state["mood_changed_at"] = _get_current_timestamp()

	character_moods[character_id] = state


func _refresh_mood_if_needed(character_id: String) -> void:
	_ensure_character_mood(character_id)

	var state: Dictionary = character_moods[character_id]
	var now := _get_current_timestamp()
	var changed_at := int(
		state.get("mood_changed_at", now)
	)

	if changed_at > now:
		state["mood_changed_at"] = now
		character_moods[character_id] = state
		return

	var elapsed_seconds := now - changed_at

	if elapsed_seconds < MOOD_CHANGE_INTERVAL_SECONDS:
		return

	var elapsed_hours := int(
		floor(
			float(elapsed_seconds)
			/ float(MOOD_CHANGE_INTERVAL_SECONDS)
		)
	)
	elapsed_hours = maxi(1, elapsed_hours)

	var old_mood := str(
		state.get("mood", DEFAULT_MOOD)
	)
	var new_mood := old_mood

	for _hour in range(elapsed_hours):
		new_mood = _roll_mood_for_character(character_id)

	state["mood"] = new_mood
	state["mood_changed_at"] = (
		changed_at
		+ elapsed_hours * MOOD_CHANGE_INTERVAL_SECONDS
	)

	character_moods[character_id] = state

	if old_mood != new_mood:
		mood_changed.emit(
			character_id,
			old_mood,
			new_mood
		)


func refresh_all_moods() -> void:
	var character_ids := character_moods.keys()

	for character_id_variant in character_ids:
		_refresh_mood_if_needed(
			str(character_id_variant)
		)


# -------------------------------------------------------------------
# Weighted mood rolling
# -------------------------------------------------------------------

func _roll_mood_for_character(character_id: String) -> String:
	var weights := _get_weights_for_character(character_id)
	return _roll_random_mood(weights)


func _get_weights_for_character(
	character_id: String
) -> Dictionary:
	if character_mood_weights.has(character_id):
		var custom = character_mood_weights[character_id]

		if custom is Dictionary and not custom.is_empty():
			return custom

	return _get_default_weights()


func _roll_random_mood(weights: Dictionary) -> String:
	var total_weight := 0

	for mood_name in MOOD_ORDER:
		total_weight += maxi(
			0,
			int(weights.get(mood_name, 0))
		)

	if total_weight <= 0:
		return DEFAULT_MOOD

	var roll := randi_range(1, total_weight)
	var accumulated_weight := 0

	for mood_name in MOOD_ORDER:
		accumulated_weight += maxi(
			0,
			int(weights.get(mood_name, 0))
		)

		if roll <= accumulated_weight:
			return mood_name

	return DEFAULT_MOOD


func _get_default_weights() -> Dictionary:
	var weights: Dictionary = {}

	for mood_name in MOOD_ORDER:
		var mood_data: Dictionary = MOODS.get(
			mood_name,
			{}
		)

		weights[mood_name] = int(
			mood_data.get("weight", 0)
		)

	return weights


func _sanitize_weights(raw_weights: Dictionary) -> Dictionary:
	var result: Dictionary = {}

	for mood_name in MOOD_ORDER:
		result[mood_name] = maxi(
			0,
			int(raw_weights.get(mood_name, 0))
		)

	var total := 0

	for mood_name in MOOD_ORDER:
		total += int(result[mood_name])

	if total <= 0:
		return _get_default_weights()

	return result


# -------------------------------------------------------------------
# Manual mood changes
# -------------------------------------------------------------------

func set_mood(
	character_id: String,
	mood_name: String,
	reset_timer: bool = true
) -> bool:
	if character_id.is_empty():
		return false

	mood_name = mood_name.to_lower()

	if not MOODS.has(mood_name):
		push_warning(
			"Unknown mood '%s' for character '%s'."
			% [mood_name, character_id]
		)
		return false

	_ensure_character_mood(character_id)

	var state: Dictionary = character_moods[character_id]
	var old_mood := str(
		state.get("mood", DEFAULT_MOOD)
	)

	state["mood"] = mood_name

	if reset_timer:
		state["mood_changed_at"] = (
			_get_current_timestamp()
		)

	character_moods[character_id] = state

	if old_mood != mood_name:
		mood_changed.emit(
			character_id,
			old_mood,
			mood_name
		)

	return true


func roll_new_mood(character_id: String) -> String:
	if character_id.is_empty():
		return DEFAULT_MOOD

	_ensure_character_mood(character_id)

	var new_mood := _roll_mood_for_character(character_id)
	set_mood(character_id, new_mood, true)

	return new_mood


func improve_mood(
	character_id: String,
	steps: int = 1
) -> bool:
	if character_id.is_empty() or steps <= 0:
		return false

	var current_mood := get_mood(character_id)
	var current_index := MOOD_ORDER.find(current_mood)

	if current_index < 0:
		current_index = MOOD_ORDER.find(DEFAULT_MOOD)

	var new_index := mini(
		current_index + steps,
		MOOD_ORDER.size() - 1
	)
	var new_mood := MOOD_ORDER[new_index]

	if new_mood == current_mood:
		return false

	return set_mood(character_id, new_mood, true)


func worsen_mood(
	character_id: String,
	steps: int = 1
) -> bool:
	if character_id.is_empty() or steps <= 0:
		return false

	var current_mood := get_mood(character_id)
	var current_index := MOOD_ORDER.find(current_mood)

	if current_index < 0:
		current_index = MOOD_ORDER.find(DEFAULT_MOOD)

	var new_index := maxi(current_index - steps, 0)
	var new_mood := MOOD_ORDER[new_index]

	if new_mood == current_mood:
		return false

	return set_mood(character_id, new_mood, true)


func try_improve_mood_from_gift(
	character_id: String,
	chance: float = 0.20,
	steps: int = 1
) -> bool:
	if character_id.is_empty():
		return false

	var normalized_chance := clampf(chance, 0.0, 1.0)

	if randf() > normalized_chance:
		return false

	return improve_mood(character_id, steps)


# -------------------------------------------------------------------
# Character-data helper
# -------------------------------------------------------------------

func add_mood_to_character_data(
	character_data: Dictionary
) -> Dictionary:
	register_character(character_data)

	var result := character_data.duplicate(true)
	var character_id := str(result.get("id", ""))

	result["mood"] = get_mood(character_id)
	result["mood_multiplier"] = get_mood_multiplier(
		character_id
	)
	result["mood_minutes_remaining"] = (
		get_minutes_until_mood_change(character_id)
	)

	return result


# -------------------------------------------------------------------
# Save and load
# -------------------------------------------------------------------

func get_save_data() -> Dictionary:
	refresh_all_moods()
	return character_moods.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	character_moods.clear()

	for character_id_variant in data:
		var character_id := str(character_id_variant)
		var saved_state = data[character_id_variant]

		if not saved_state is Dictionary:
			continue

		character_moods[character_id] = (
			saved_state.duplicate(true)
		)

		_validate_character_state(character_id)

	refresh_all_moods()


func reset_all_moods() -> void:
	# Keep registered personality weights, but discard saved moods.
	# Each character receives a fresh random mood the next time
	# it is registered or requested.
	character_moods.clear()


func remove_character_mood(character_id: String) -> void:
	character_moods.erase(character_id)


func has_character_mood(character_id: String) -> bool:
	return character_moods.has(character_id)


# -------------------------------------------------------------------
# Utility
# -------------------------------------------------------------------

func _get_current_timestamp() -> int:
	return int(Time.get_unix_time_from_system())
