extends Node

const STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY: float = 100.0 / (4.0 * 3600.0)
const STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY: float = 100.0 / (8.0 * 3600.0)
const STAMINA_REGEN_PER_SECOND: float = 100.0 / 3600.0

signal location_data_updated(location_data_dict: Dictionary)

@onready var CharacterDatabase = get_node("/root/CharacterDatabase")

var location_data: Dictionary = {
	"Start Scene": {
		"name": "Start Scene",
		"type": "menu",
		"scene_path": "res://scenes/main/start_scene.tscn",
		"activities": [],
		"characters": []
	},
	
	"Intro Screen": {
		"name": "Intro Scene",
		"type": "intro",
		"scene_path": "res://scenes/main/intro_scene.tscn",
		"activities": [],
		"characters": []
	},
	
	"Home": {
		"name": "Home",
		"type": "normal",
		"scene_path": "res://scenes/locations/home_scene.tscn",
		"activities": [
			{"name": "Cook", "description": "Prepare a meal and improve intelligence.", "effects": {"intelligence": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Watch TV", "description": "Relax and improve persuasion.", "effects": {"persuasion": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Read Magazine", "description": "Gain knowledge from articles.", "effects": {"knowledge": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Work Out", "description": "Increase your strength at home.", "effects": {"strength": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Use Internet", "description": "Explore the web and gain wisdom.", "effects": {"wisdom": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": []
	},
	
	"Gym": {
		"name": "Gym",
		"type": "normal",
		"scene_path": "res://scenes/locations/gym_scene.tscn",
		"activities": [
			{"name": "Lift Weights", "description": "Intense strength training.", "effects": {"strength": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Treadmill", "description": "Cardio for endurance.", "effects": {"endurance": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Stretch", "description": "Improve agility and flexibility.", "effects": {"agility": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Yoga", "description": "Improve balance", "effects": {"balance": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY}
		] as Array[Dictionary],
		"characters": []
	},
	
	"Library": {
		"name": "Library",
		"type": "normal",
		"scene_path": "res://scenes/locations/library_scene.tscn",
		"activities": [
			{"name": "Read", "description": "Deep dive into a book.", "effects": {"knowledge": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Research Online", "description": "Boost your intelligence with online research.", "effects": {"intelligence": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Solve Puzzles", "description": "Challenge your logic.", "effects": {"logic": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Philosophy Debate", "description": "Engage in deep thought.", "effects": {"wisdom": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": []
	},
	
	"Cafeteria": {
		"name": "Cafeteria",
		"type": "normal",
		"scene_path": "res://scenes/locations/cafeteria_scene.tscn",
		"activities": [
			{"name": "Order Coffee", "description": "Quick energy boost.", "effects": {"endurance": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Chat with Friends", "description": "Improve your communication skills.", "effects": {"communication": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "People Watch", "description": "Observe and learn social cues.", "effects": {"persuasion": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": []
	},
	
	"Park": {
		"name": "Park",
		"type": "normal",
		"scene_path": "res://scenes/locations/park_scene.tscn",
		"activities": [
			{"name": "Jogging", "description": "Build endurance with a run.", "effects": {"endurance": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Meditate", "description": "Find inner peace and wisdom.", "effects": {"wisdom": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Stroll around", "description": "Enjoy the scenery and boost charisma.", "effects": {"charisma": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Picnic", "description": "Organize a fun outing.", "effects": {"leadership": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": []
	},
	
	"Mall": {
		"name": "Mall",
		"type": "normal",
		"scene_path": "res://scenes/locations/mall_scene.tscn",
		"activities": [
			{"name": "Window Shopping", "description": "Practice persuasion skills.", "effects": {"persuasion": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Browse Electronics", "description": "Learn about new tech.", "effects": {"intelligence": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Try on Clothes", "description": "Boost your charisma.", "effects": {"charisma": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Eat Food Court", "description": "Recharge with a tasty meal.", "effects": {"endurance": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": []
	},
	
	"Nightclub": {
		"name": "Nightclub",
		"type": "normal",
		"scene_path": "res://scenes/locations/nightclub_scene.tscn",
		"activities": [
			{"name": "Dance", "description": "Burn energy on the dance floor.", "effects": {"endurance": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Flirt", "description": "Practice your social charm.", "effects": {"intelligence": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Karaoke", "description": "Show off your singing skills.", "effects": {"charisma": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Drink", "description": "Socialize and unwind.", "effects": {"leadership": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": []
	},
	
	"University": {
		"name": "University",
		"type": "normal",
		"scene_path": "res://scenes/locations/university_scene.tscn",
		"activities": [
			{"name": "Attend lecture", "description": "Gain knowledge from academics.", "effects": {"knowledge": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Club activity", "description": "Engage in extracurriculars.", "effects": {"intelligence": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Give exams", "description": "Test your knowledge.", "effects": {"logic": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Socialize", "description": "Network and build connections.", "effects": {"communication": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": []
	},
	
	"Cinema": {
		"name": "Cinema",
		"type": "normal",
		"scene_path": "res://scenes/locations/cinema_scene.tscn",
		"activities": [
			{"name": "Watch Movie", "description": "Enjoy a film.", "effects": {"knowledge": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Discuss Film", "description": "Analyze and share thoughts.", "effects": {"communication": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
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
	if get_tree().current_scene:
		_on_scene_changed(get_tree().current_scene.scene_file_path)

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
		if location_data[key].get("scene_path") == new_scene_path:
			current_location = location_data[key]
			if PlayerData:
				PlayerData.set_current_location(current_location)
			emit_signal("location_data_updated", current_location)
			return
	
	# Fallback
	current_location = {
		"scene_path": new_scene_path,
		"name": new_scene_path.get_file().get_basename(),
		"type": "normal",
		"activities": [],
		"characters": []
	}
	if PlayerData:
		PlayerData.set_current_location(current_location)
	emit_signal("location_data_updated", current_location)

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
