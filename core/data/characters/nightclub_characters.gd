extends Node

func get_characters() -> Dictionary:
	return {
		"maya_nightclub": {
			"id": "maya_nightclub",
			"name": "Maya",
			"location": "Nightclub",
			"image_path": "res://assets/images/characters/nightclub/maya/maya_main.png",
			"stats_required": {"charisma": 1, "endurance": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/nightclub/maya/maya_dinner.png",
				"park": "res://assets/images/characters/nightclub/maya/maya_park.png",
				"beach": "res://assets/images/characters/nightclub/maya/maya_beach.png",
				"home": "res://assets/images/characters/nightclub/maya/maya_home.png",
				"kiss": "res://assets/images/characters/nightclub/maya/maya_kiss.png"
			},
			"dialogue_by_stage": { }
		},
		"melina_nightclub": {
			"id": "melina_nightclub",
			"name": "Melina",
			"location": "Nightclub",
			"image_path": "res://assets/images/characters/nightclub/melina/melina_main.png",
			"stats_required": {"charisma": 5, "endurance": 5},
			"date_images": {
				"dinner": "res://assets/images/characters/nightclub/melina/melina_dinner.png",
				"park": "res://assets/images/characters/nightclub/melina/melina_park.png",
				"beach": "res://assets/images/characters/nightclub/melina/melina_beach.png",
				"home": "res://assets/images/characters/nightclub/melina/melina_home.png",
				"kiss": "res://assets/images/characters/nightclub/melina/melina_kiss.png"
			},
			"dialogue_by_stage": { }
		},
		"alice_nightclub": {
			"id": "alice_nightclub",
			"name": "Alice",
			"location": "Nightclub",
			"image_path": "res://assets/images/characters/nightclub/alice/alice_main.png",
			"stats_required": {"charisma": 25, "endurance": 25, "balance": 25},
			"date_images": {
				"dinner": "res://assets/images/characters/nightclub/alice/alice_dinner.png",
				"park": "res://assets/images/characters/nightclub/alice/alice_park.png",
				"beach": "res://assets/images/characters/nightclub/alice/alice_beach.png",
				"home": "res://assets/images/characters/nightclub/alice/alice_home.png",
				"kiss": "res://assets/images/characters/nightclub/alice/alice_kiss.png"
			},
			"dialogue_by_stage": { }
		}
	}
