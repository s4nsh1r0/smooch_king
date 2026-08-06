extends Node

const MENU_INTRO_MUSIC: AudioStream = preload(
	"res://assets/audio/music/intro_music.mp3"
)
const MUSIC_FADE_DURATION := 1.5

signal location_data_updated(location_data_dict: Dictionary)

@onready var CharacterDatabase = get_node("/root/CharacterDatabase")

var location_data: Dictionary = {
	"Start Scene": {
		"name": "Start Scene",
		"type": "menu",
		"scene_path": "res://scenes/main/start_scene.tscn",
		"music": preload("res://assets/audio/music/intro_music.mp3"),
		"activities": [],
		"characters": []
	},

	"Intro Screen": {
		"name": "Intro Scene",
		"type": "intro",
		"scene_path": "res://scenes/main/intro_scene.tscn",
		"music": preload("res://assets/audio/music/intro_music.mp3"),
		"activities": [],
		"characters": []
	},

	"Home": {
		"name": "Home",
		"type": "normal",
		"scene_path": "res://scenes/locations/home_scene.tscn",
		"activities": [
			{"name": "Cook", "description": "Prepare a meal. Raises Intelligence.", "effects": {"intelligence": 0.005}},
			{"name": "Watch TV", "description": "Relax on the couch. Raises Persuasion.", "effects": {"persuasion": 0.003}},
			{"name": "Read Magazine", "description": "Browse articles. Raises Knowledge.", "effects": {"knowledge": 0.004}},
			{"name": "Work Out", "description": "Train at home. Raises Strength.", "effects": {"strength": 0.006}},
			{"name": "Use Internet", "description": "Explore the web. Raises Wisdom.", "effects": {"wisdom": 0.002}},
		] as Array[Dictionary],
		"characters": []
	},

	"Gym": {
		"name": "Gym",
		"type": "normal",
		"scene_path": "res://scenes/locations/gym_scene.tscn",
		"activities": [
			{"name": "Lift Weights", "description": "Heavy lifting. Raises Strength.", "effects": {"strength": 0.007}},
			{"name": "Treadmill", "description": "Cardio session. Raises Endurance.", "effects": {"endurance": 0.005}},
			{"name": "Stretch", "description": "Flexibility work. Raises Agility.", "effects": {"agility": 0.004}},
			{"name": "Yoga", "description": "Balance and focus. Raises Balance.", "effects": {"balance": 0.004}},
		] as Array[Dictionary],
		"characters": []
	},

	"Library": {
		"name": "Library",
		"type": "normal",
		"scene_path": "res://scenes/locations/library_scene.tscn",
		"activities": [
			{"name": "Read", "description": "Deep dive into a book. Raises Knowledge.", "effects": {"knowledge": 0.005}},
			{"name": "Research Online", "description": "Study online sources. Raises Intelligence.", "effects": {"intelligence": 0.004}},
			{"name": "Solve Puzzles", "description": "Logic challenges. Raises Logic.", "effects": {"logic": 0.006}},
			{"name": "Philosophy Debate", "description": "Deep discussion. Raises Wisdom.", "effects": {"wisdom": 0.007}},
		] as Array[Dictionary],
		"characters": []
	},

	"Cafeteria": {
		"name": "Cafeteria",
		"type": "normal",
		"scene_path": "res://scenes/locations/cafeteria_scene.tscn",
		"activities": [
			{"name": "Order Coffee", "description": "Quick caffeine boost. Raises Endurance.", "effects": {"endurance": 0.002}},
			{"name": "Chat with Friends", "description": "Casual conversation. Raises Communication.", "effects": {"communication": 0.005}},
			{"name": "People Watch", "description": "Observe social cues. Raises Persuasion.", "effects": {"persuasion": 0.003}},
		] as Array[Dictionary],
		"characters": []
	},

	"Park": {
		"name": "Park",
		"type": "normal",
		"scene_path": "res://scenes/locations/park_scene.tscn",
		"activities": [
			{"name": "Jogging", "description": "A steady run. Raises Endurance.", "effects": {"endurance": 0.006}},
			{"name": "Meditate", "description": "Quiet reflection. Raises Wisdom.", "effects": {"wisdom": 0.004}},
			{"name": "Stroll around", "description": "Enjoy the scenery. Raises Charisma.", "effects": {"charisma": 0.002}},
			{"name": "Picnic", "description": "Organize a picnic. Raises Leadership.", "effects": {"leadership": 0.005}},
		] as Array[Dictionary],
		"characters": []
	},

	"Mall": {
		"name": "Mall",
		"type": "normal",
		"scene_path": "res://scenes/locations/mall_scene.tscn",
		"activities": [
			{"name": "Window Shopping", "description": "Browse without buying. Raises Persuasion.", "effects": {"persuasion": 0.003}},
			{"name": "Browse Electronics", "description": "Check out new tech. Raises Intelligence.", "effects": {"intelligence": 0.004}},
			{"name": "Try on Clothes", "description": "Experiment with style. Raises Charisma.", "effects": {"charisma": 0.002}},
			{"name": "Eat Food Court", "description": "A solid meal. Raises Endurance.", "effects": {"endurance": 0.005}},
		] as Array[Dictionary],
		"characters": []
	},

	"Nightclub": {
		"name": "Nightclub",
		"type": "normal",
		"scene_path": "res://scenes/locations/nightclub_scene.tscn",
		"activities": [
			{"name": "Dance", "description": "Move on the floor. Raises Endurance.", "effects": {"endurance": 0.003}},
			{"name": "Flirt", "description": "Practice charm. Raises Intelligence.", "effects": {"intelligence": 0.004}},
			{"name": "Karaoke", "description": "Sing for the crowd. Raises Charisma.", "effects": {"charisma": 0.002}},
			{"name": "Drink", "description": "Socialize at the bar. Raises Leadership.", "effects": {"leadership": 0.005}},
		] as Array[Dictionary],
		"characters": []
	},

	"University": {
		"name": "University",
		"type": "normal",
		"scene_path": "res://scenes/locations/university_scene.tscn",
		"activities": [
			{"name": "Attend lecture", "description": "Sit through a class. Raises Knowledge.", "effects": {"knowledge": 0.003}},
			{"name": "Club activity", "description": "Join club work. Raises Intelligence.", "effects": {"intelligence": 0.004}},
			{"name": "Give exams", "description": "Take a test. Raises Logic.", "effects": {"logic": 0.02}},
			{"name": "Socialize", "description": "Network on campus. Raises Communication.", "effects": {"communication": 0.005}},
		] as Array[Dictionary],
		"characters": []
	},

	"Cinema": {
		"name": "Cinema",
		"type": "normal",
		"scene_path": "res://scenes/locations/cinema_scene.tscn",
		"activities": [
			{"name": "Watch Movie", "description": "Catch a film. Raises Knowledge.", "effects": {"knowledge": 0.005}},
			{"name": "Discuss Film", "description": "Talk about the plot. Raises Communication.", "effects": {"communication": 0.003}},
		] as Array[Dictionary],
		"characters": []
	},

	"Job Center": {
		"name": "Job Center",
		"type": "normal",
		"scene_path": "res://scenes/locations/jobcenter_scene.tscn",
		"activities": [],
		"characters": []
	},

	"Map": {
		"name": "Map",
		"type": "map",
		"scene_path": "res://scenes/main/map_scene.tscn",
		"activities": [],
		"characters": []
	}
}

var current_location: Dictionary = {}

func _ready() -> void:
	location_data["Job Center"]["activities"] = JobDatabase.get_all_jobs()
	if GameManager and not GameManager.scene_changed.is_connected(_on_scene_changed):
		GameManager.scene_changed.connect(_on_scene_changed)
	call_deferred("_sync_initial_scene_music")
	call_deferred("_sync_initial_location")

func get_location_data_by_name(location_name: String) -> Dictionary:
	return location_data.get(location_name, {})

func set_current_location(location: Dictionary) -> void:
	var full_data = get_location_data_by_name(location.get("name", ""))
	if not full_data.is_empty():
		current_location = full_data
	else:
		current_location = location
	if PlayerData:
		PlayerData.set_current_location(current_location)
	emit_signal("location_data_updated", current_location)

func _on_scene_changed(new_scene_path: String) -> void:
	for key in location_data:
		var data: Dictionary = location_data[key]
		if data.get("scene_path", "") == new_scene_path:
			current_location = data
			if PlayerData:
				PlayerData.set_current_location(current_location)
			_update_scene_music(current_location)
			location_data_updated.emit(current_location)
			return

	current_location = {
		"scene_path": new_scene_path,
		"name": new_scene_path.get_file().get_basename(),
		"type": "normal",
		"music": null,
		"activities": [],
		"characters": []
	}
	if PlayerData:
		PlayerData.set_current_location(current_location)
	_update_scene_music(current_location)
	location_data_updated.emit(current_location)

func _update_scene_music(location: Dictionary) -> void:
	if not SoundManager:
		return
	var music: AudioStream = location.get("music", null)
	if music:
		SoundManager.play_music(music, 1.5)
	else:
		SoundManager.stop_music(1.5)

func _sync_initial_scene_music() -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene):
		return
	var scene_path := scene.scene_file_path
	for key in location_data:
		var data: Dictionary = location_data[key]
		if data.get("scene_path", "") == scene_path:
			current_location = data
			_update_scene_music(current_location)
			return

func get_characters_for_location(location_name: String) -> Array:
	return CharacterDatabase.get_characters_by_location(location_name)

func get_character_data(character_id: String) -> Dictionary:
	return CharacterDatabase.get_character(character_id)

func get_current_location() -> Dictionary:
	return current_location

func get_current_location_type() -> String:
	return get_current_location().get("type", "unknown")

func get_current_location_name() -> String:
	return get_current_location().get("name", "Unknown")

func _sync_initial_location() -> void:
	var scene := get_tree().current_scene
	if is_instance_valid(scene):
		_on_scene_changed(scene.scene_file_path)
