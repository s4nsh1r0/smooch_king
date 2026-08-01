extends Node

func get_characters() -> Dictionary:
	return {
		"marina_mall": {
			"id": "marina_mall",
			"name": "Marina",
			"location": "Mall",
			"image_path": "res://assets/images/characters/mall/marina/marina_main.png",
			"stats_required": {"persuasion": 1, "charisma": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/mall/marina/marina_dinner.png",
				"park": "res://assets/images/characters/mall/marina/marina_park.png",
				"beach": "res://assets/images/characters/mall/marina/marina_beach.png",
				"home": "res://assets/images/characters/mall/marina/marina_home.png",
				"kiss": "res://assets/images/characters/mall/marina/marina_kiss.png"
			},
			"dialogue_by_stage": { }
		},
		"louisa_mall": {
			"id": "louisa_mall",
			"name": "Louisa",
			"location": "Mall",
			"image_path": "res://assets/images/characters/mall/louisa/louisa_main.png",
			"stats_required": {"persuasion": 10, "leadership": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/mall/louisa/louisa_dinner.png",
				"park": "res://assets/images/characters/mall/louisa/louisa_park.png",
				"beach": "res://assets/images/characters/mall/louisa/louisa_beach.png",
				"home": "res://assets/images/characters/mall/louisa/louisa_home.png",
				"kiss": "res://assets/images/characters/mall/louisa/louisa_kiss.png"
			},
			"dialogue_by_stage": { }
		},
		"annita_mall": {
			"id": "annita_mall",
			"name": "Annita",
			"location": "Mall",
			"image_path": "res://assets/images/characters/mall/annita/annita_main.png",
			"stats_required": {"persuasion": 10, "leadership": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/mall/annita/annita_dinner.jpeg",
				"park": "res://assets/images/characters/mall/annita/annita_park.jpeg",
				"beach": "res://assets/images/characters/mall/annita/annita_beach.jpeg",
				"home": "res://assets/images/characters/mall/annita/annita_home.jpeg",
				"kiss": "res://assets/images/characters/mall/annita/annita_kiss.jpeg"
			},
			"dialogue_by_stage": { }
		}
	}
