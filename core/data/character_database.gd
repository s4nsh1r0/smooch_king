extends Node

var characters: Dictionary = {}

func _ready() -> void:
	load_all_character_data()

func load_all_character_data() -> void:
	var location_files = [
		"cafeteria_characters.gd",
		"gym_characters.gd",
		"library_characters.gd",
		"mall_characters.gd",
		"nightclub_characters.gd",
		"park_characters.gd",
		"university_characters.gd",
		"cinema_characters.gd",
		"jobcenter_characters.gd"
	]
	
	for filename in location_files:
		var path = "res://core/data/characters/" + filename
		if ResourceLoader.exists(path):
			var loader = load(path)
			if loader:
				var data = loader.new()
				if data.has_method("get_characters"):
					characters.merge(data.get_characters())
					print("Loaded: ", filename)
				data.queue_free()
		else:
			print("File not found: ", path)
	
	print("CharacterDatabase: Total characters loaded: ", characters.size())

func get_character(id: String) -> Dictionary:
	return characters.get(id, {})

func get_characters_by_location(location: String) -> Array:
	var result = []
	var location_lower = location.to_lower()
	for char_id in characters:
		var char_location = characters[char_id].get("location", "").to_lower()
		if char_location == location_lower:
			result.append(characters[char_id])
	return result
	
func get_all_characters() -> Array:
	var result = []
	for char_id in characters:
		result.append(characters[char_id])
	return result
