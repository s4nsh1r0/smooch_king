extends Node

func get_characters() -> Dictionary:
	return {
		"aria_cinema": {
			"id": "aria_cinema",
			"name": "Aria",
			"location": "Cinema",
			"image_path": "res://assets/images/characters/cinema/aria/aria_main.png",
			"stats_required": {"communication": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/cinema/aria/aria_dinner.png",
				"park": "res://assets/images/characters/cinema/aria/aria_park.png",
				"beach": "res://assets/images/characters/cinema/aria/aria_beach.png",
				"home": "res://assets/images/characters/cinema/aria/aria_home.png",
				"kiss": "res://assets/images/characters/cinema/aria/aria_kiss.png"
			},
			"dialogue_by_stage": { }
		},
		"hilda_cinema": {
			"id": "hilda_cinema",
			"name": "Hilda",
			"location": "Cinema",
			"image_path": "res://assets/images/characters/cinema/hilda/hilda_main.png",
			"stats_required": {"communication": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/cinema/hilda/hilda_dinner.png",
				"park": "res://assets/images/characters/cinema/hilda/hilda_park.png",
				"beach": "res://assets/images/characters/cinema/hilda/hilda_beach.png",
				"home": "res://assets/images/characters/cinema/hilda/hilda_home.png",
				"kiss": "res://assets/images/characters/cinema/hilda/hilda_kiss.png"
			},
			"dialogue_by_stage": { }
		}
	}
