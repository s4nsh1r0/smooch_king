extends Node

func get_characters() -> Dictionary:
	return {
		"bridget_park": {
			"id": "bridget_park",
			"name": "Bridget",
			"location": "Park",
			"image_path": "res://assets/images/characters/park/bridget/bridget_main.png",
			"stats_required": {"endurance": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/park/bridget/bridget_dinner.png",
				"park": "res://assets/images/characters/park/bridget/bridget_park.png",
				"beach": "res://assets/images/characters/park/bridget/bridget_beach.png",
				"home": "res://assets/images/characters/park/bridget/bridget_home.png",
				"kiss": "res://assets/images/characters/park/bridget/bridget_kiss.png"
			},
			"dialogue_by_stage": { }
		},
		"rikka_park": {
			"id": "rikka_park",
			"name": "Rikka",
			"location": "Park",
			"image_path": "res://assets/images/characters/park/rikka/rikka_main.png",
			"stats_required": {"endurance": 10, "balance": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/park/rikka/rikka_dinner.png",
				"park": "res://assets/images/characters/park/rikka/rikka_park.png",
				"beach": "res://assets/images/characters/park/rikka/rikka_beach.png",
				"home": "res://assets/images/characters/park/rikka/rikka_home.png",
				"kiss": "res://assets/images/characters/park/rikka/rikka_kiss.png"
			},
			"dialogue_by_stage": { }
		}
	}
