extends Node

func get_characters() -> Dictionary:
	return {
		"marina_mall": {
			"id": "marina_mall",
			"name": "Marina",
			"location": "Mall",
			"image_path": "res://assets/images/characters/mall/marina/marina_main.png",
			"stats_required": {"persuasion": 1, "charisma": 1},
			
			# Love Book profile
			"age": "29",
			"height": "180 cm",
			"weight": "74 kg",
			"hair": "Jet black, long and thick with a slight wave",
			"eyes": "Dark brown",
			"body": "Tall and voluptuous",
			"skin": "White",
			"bust": "F",
			"personality": "Bold",
			"profession": "Store assistant",
			"hobby": "Sculpting",
			
			"date_images": {
				"dinner": "res://assets/images/characters/mall/marina/marina_dinner.jpg",
				"park": "res://assets/images/characters/mall/marina/marina_park.jpg",
				"beach": "res://assets/images/characters/mall/marina/marina_beach.jpg",
				"home": "res://assets/images/characters/mall/marina/marina_home.jpg",
				"special": "res://assets/images/characters/mall/marina/marina_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		"louisa_mall": {
			"id": "louisa_mall",
			"name": "Louisa",
			"location": "Mall",
			"image_path": "res://assets/images/characters/mall/louisa/louisa_main.png",
			"stats_required": {"balance": 20, "leadership": 20},
			
			# Love Book profile
			"age": "20",
			"height": "166 cm",
			"weight": "51 kg",
			"hair": "Honey blonde, long and perfectly styled with soft curls",
			"eyes": "Bright green",
			"body": "Slim and polished",
			"skin": "Fair with a healthy glow",
			"bust": "C",
			"personality": "Bratty",
			"profession": "Socialite",
			"hobby": "High Fashion",
			
			"date_images": {
				"dinner": "res://assets/images/characters/mall/louisa/louisa_dinner.png",
				"park": "res://assets/images/characters/mall/louisa/louisa_park.jpg",
				"beach": "res://assets/images/characters/mall/louisa/louisa_beach.jpg",
				"home": "res://assets/images/characters/mall/louisa/louisa_home.png",
				"special": "res://assets/images/characters/mall/louisa/louisa_special.png"
			},
			"dialogue_by_stage": { }
		},
		"annita_mall": {
			"id": "annita_mall",
			"name": "Annita",
			"location": "Mall",
			"image_path": "res://assets/images/characters/mall/annita/annita_main.png",
			"stats_required": {"agility": 100, "charisma": 80},
			"date_images": {
				"dinner": "res://assets/images/characters/mall/annita/annita_dinner.jpeg",
				"park": "res://assets/images/characters/mall/annita/annita_park.jpeg",
				"beach": "res://assets/images/characters/mall/annita/annita_beach.jpeg",
				"home": "res://assets/images/characters/mall/annita/annita_home.jpeg",
				"special": "res://assets/images/characters/mall/annita/annita_special.jpeg"
			},
			"dialogue_by_stage": { }
		}
	}
