extends Node

signal save_completed(success: bool, message: String)
signal load_completed(success: bool, message: String)

const SAVE_EXTENSION := ".json"
const SAVES_DIR := "user://saves/"
const SLOT_COUNT := 2

func _ready() -> void:
	ensure_saves_dir()

func ensure_saves_dir() -> void:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)

func get_slot_path(slot_id: int) -> String:
	return SAVES_DIR + "slot_%d%s" % [slot_id, SAVE_EXTENSION]

func slot_exists(slot_id: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot_id))

func get_slot_info(slot_id: int) -> Dictionary:
	var path = get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {
			"slot_id": slot_id,
			"empty": true,
			"file_path": path,
			"player_name": "",
			"money": 0.0,
			"current_location_name": "",
			"is_activity_active": false,
			"current_activity_name": "",
			"modified_time": 0,
			"total_stats": 0.0
		}
	
	var info = get_save_file_info(path)
	info["slot_id"] = slot_id
	info["empty"] = false
	return info

func get_all_slots() -> Array:
	var slots: Array = []
	for i in range(1, SLOT_COUNT + 1):
		slots.append(get_slot_info(i))
	return slots

func get_save_file_info(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		return {}
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	
	var modified_time = FileAccess.get_modified_time(file_path)
	return {
		"file_path": file_path,
		"file_name": file_path.get_file().trim_suffix(SAVE_EXTENSION),
		"player_name": data.get("player_name", "Unknown"),
		"money": data.get("money", 0.0),
		"current_location_name": data.get("current_location", {}).get("name", "Unknown"),
		"is_activity_active": data.get("is_activity_active", false),
		"current_activity_name": data.get("current_activity_data", {}).get("name", ""),
		"save_timestamp": data.get("save_timestamp", modified_time),
		"modified_time": modified_time,
		"total_stats": _calculate_total_stats(data),
		"current_slot_id": data.get("current_slot_id", 0)
	}

func _calculate_total_stats(data: Dictionary) -> float:
	var total = 0.0
	for stat in ["strength", "agility", "endurance", "balance",
			"knowledge", "wisdom", "intelligence", "logic",
			"leadership", "persuasion", "charisma", "communication"]:
		total += float(data.get(stat, 1.0))
	return total

func save_to_slot(slot_id: int, player_data_node: Node) -> Dictionary:
	if not player_data_node:
		save_completed.emit(false, "PlayerData not found!")
		return {"success": false, "message": "PlayerData not found!"}
	if slot_id < 1 or slot_id > SLOT_COUNT:
		save_completed.emit(false, "Invalid slot id")
		return {"success": false, "message": "Invalid slot id"}

	ensure_saves_dir()
	if player_data_node.get("current_slot_id") != null:
		player_data_node.current_slot_id = slot_id

	var save_data = player_data_node.save_data()
	save_data["save_timestamp"] = Time.get_unix_time_from_system()
	save_data["game_version"] = "1.1"
	save_data["current_slot_id"] = slot_id

	var path = get_slot_path(slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var err_msg = "Failed to write slot %d" % slot_id
		save_completed.emit(false, err_msg)
		return {"success": false, "message": err_msg}

	file.store_string(JSON.stringify(save_data, " "))
	file.close()

	save_completed.emit(true, "Save successful.")
	var player_name = str(save_data.get("player_name", "Player"))
	return {
		"success": true,
		"message": "Saved %s (Slot %d)" % [player_name, slot_id],
		"file_path": path,
		"slot_id": slot_id
	}

## Used by pause / autosave – saves into the active slot
func save_game(player_data_node: Node, _force_overwrite: bool = true) -> Dictionary:
	if not player_data_node:
		return {"success": false, "message": "PlayerData not found!"}
	
	var slot_id = int(player_data_node.get("current_slot_id") if player_data_node.get("current_slot_id") != null else 0)
	if slot_id < 1 or slot_id > SLOT_COUNT:
		# Fallback: first empty slot, or slot 1
		slot_id = 1
		for i in range(1, SLOT_COUNT + 1):
			if not slot_exists(i):
				slot_id = i
				break
		player_data_node.current_slot_id = slot_id
	
	return save_to_slot(slot_id, player_data_node)

func load_slot(slot_id: int) -> void:
	var path = get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		load_completed.emit(false, "Slot %d is empty." % slot_id)
		return
	load_game(path)

func load_game(save_path: String) -> void:
	if not FileAccess.file_exists(save_path):
		load_completed.emit(false, "Save file not found.")
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		load_completed.emit(false, "Failed to open save file.")
		return
	
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if data and PlayerData:
		PlayerData.load_data(data)
		# Ensure slot id from path if missing
		if PlayerData.current_slot_id < 1:
			var fname = save_path.get_file()
			if fname.begins_with("slot_"):
				PlayerData.current_slot_id = int(fname.get_basename().replace("slot_", ""))
		load_completed.emit(true, "Load successful.")
	else:
		load_completed.emit(false, "Corrupted save or PlayerData missing.")

func delete_slot(slot_id: int) -> Dictionary:
	var path = get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {"success": false, "message": "Slot already empty"}
	
	var err = DirAccess.remove_absolute(path)
	if err != OK:
		return {"success": false, "message": "Failed to delete slot %d" % slot_id}
	return {"success": true, "message": "Slot %d deleted" % slot_id}

func delete_save_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {"success": false, "message": "Save file not found"}
	var err = DirAccess.remove_absolute(file_path)
	if err != OK:
		return {"success": false, "message": "Failed to delete save file"}
	return {"success": true, "message": "Save file deleted successfully"}

func format_time_ago(timestamp: float) -> String:
	if timestamp <= 0.0:
		return ""
	var diff = Time.get_unix_time_from_system() - timestamp
	if diff < 60:
		return "Just now"
	elif diff < 3600:
		return str(int(diff / 60)) + " minutes ago"
	elif diff < 86400:
		return str(int(diff / 3600)) + " hours ago"
	return str(int(diff / 86400)) + " days ago"
