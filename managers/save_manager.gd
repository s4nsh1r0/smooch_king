extends Node

signal save_completed(success: bool, message: String)
signal load_completed(success: bool, message: String)
signal save_file_found(file_path: String)

const SAVE_EXTENSION = ".json"
const SAVE_DIRECTORY = "user://"

# Get all available save files
func get_all_save_files() -> Array[Dictionary]:
	var save_files: Array[Dictionary] = []
	var dir = DirAccess.open(SAVE_DIRECTORY)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(SAVE_EXTENSION) and not file_name.begins_with("."):
				var file_path = SAVE_DIRECTORY + file_name
				var save_info = get_save_file_info(file_path)
				if save_info:
					save_files.append(save_info)
			file_name = dir.get_next()
	else:
		push_error("Failed to access save directory")
	
	# Sort by last modified time (newest first)
	save_files.sort_custom(func(a, b): return a.modified_time > b.modified_time)
	return save_files

# Get information about a specific save file
func get_save_file_info(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		return {}
	
	var data = json.data
	var file_stats = FileAccess.get_file_as_bytes(file_path)
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
		"file_size": file_stats.size() if file_stats else 0,
		"total_stats": _calculate_total_stats(data)
	}

func _calculate_total_stats(data: Dictionary) -> float:
	var total = 0.0
	var stat_names = ["strength", "agility", "endurance", "balance", 
					  "knowledge", "wisdom", "intelligence", "logic",
					  "leadership", "persuasion", "charisma", "communication"]
	
	for stat in stat_names:
		total += data.get(stat, 1.0)
	
	return total

# Create safe filename from player name
func get_safe_filename(player_name: String) -> String:
	var safe_name = player_name.strip_edges()
	if safe_name.is_empty():
		safe_name = "DefaultPlayer"
	
	# Replace invalid characters
	var invalid_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|", "."]
	for char in invalid_chars:
		safe_name = safe_name.replace(char, "_")
	
	return safe_name

# Check if save file exists for player
func save_file_exists(player_name: String) -> bool:
	var safe_name = get_safe_filename(player_name)
	var file_path = SAVE_DIRECTORY + safe_name + SAVE_EXTENSION
	return FileAccess.file_exists(file_path)

# Save game data
func save_game(player_data_node: Node, force_overwrite: bool = false) -> Dictionary:
	if not player_data_node:
		return {"success": false, "message": "PlayerData node not found!"}
	
	var player_name = player_data_node.get_player_name()
	var safe_name = get_safe_filename(player_name)
	var file_path = SAVE_DIRECTORY + safe_name + SAVE_EXTENSION
	
	# Check if file exists and we're not forcing overwrite
	if not force_overwrite and FileAccess.file_exists(file_path):
		return {"success": false, "message": "Save file already exists!", "needs_confirmation": true, "file_path": file_path}
	
	# Get save data from PlayerData
	var save_data = player_data_node.save_data()
	save_data["save_timestamp"] = Time.get_unix_time_from_system()
	save_data["game_version"] = "1.0" # Add version for future compatibility
	
	# Write to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return {"success": false, "message": "Failed to create save file at: " + file_path}
	
	file.store_string(JSON.stringify(save_data, "  "))
	file.close()
	
	return {"success": true, "message": "Game saved successfully for " + player_name + "!", "file_path": file_path}

# Load game data
func load_game(save_path: String) -> void:
	if not FileAccess.file_exists(save_path):
		print("SaveManager: Save file not found at path: ", save_path)
		load_completed.emit(false, "Save file not found.")
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		print("SaveManager: Failed to open save file.")
		load_completed.emit(false, "Failed to open save file.")
		return

	var json_string = file.get_as_text()
	var data = JSON.parse_string(json_string)
	file.close()

	if data and PlayerData:
		PlayerData.load_data(data)
		print("SaveManager: Game data loaded successfully.")
		load_completed.emit(true, "Load successful.")
	else:
		print("SaveManager: Failed to parse JSON or PlayerData not found.")
		load_completed.emit(false, "Corrupted save data or singleton missing.")

# Delete save file
func delete_save_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {"success": false, "message": "Save file not found"}
	
	var dir = DirAccess.open(SAVE_DIRECTORY)
	if not dir:
		return {"success": false, "message": "Failed to access save directory"}
	
	var error = dir.remove(file_path.get_file())
	if error != OK:
		return {"success": false, "message": "Failed to delete save file"}
	
	return {"success": true, "message": "Save file deleted successfully"}

# Get formatted file size
func format_file_size(size_bytes: int) -> String:
	if size_bytes < 1024:
		return str(size_bytes) + " B"
	elif size_bytes < 1024 * 1024:
		return str(float(size_bytes) / 1024) + " KB"
	else:
		return str(float(size_bytes) / (1024 * 1024)) + " MB"

# Get formatted time difference
func format_time_ago(timestamp: float) -> String:
	var current_time = Time.get_unix_time_from_system()
	var diff = current_time - timestamp
	
	if diff < 60:
		return "Just now"
	elif diff < 3600:
		return str(int(diff / 60)) + " minutes ago"
	elif diff < 86400:
		return str(int(diff / 3600)) + " hours ago"
	else:
		return str(int(diff / 86400)) + " days ago"
