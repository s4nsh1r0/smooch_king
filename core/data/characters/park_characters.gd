extends Node

func get_characters() -> Dictionary:
	return {
		"christine_park": {
			"id": "christine_park",
			"name": "Christine",
			"location": "Park",
			"image_path": "res://assets/images/characters/park/christine/christine_main.png",
			"stats_required": {"endurance": 1},
			
			# Love Book profile
			"age": "22",
			"height": "168 cm",
			"weight": "54 kg",
			"hair": "Chestnut brown, shoulder-length with soft waves",
			"eyes": "Hazel",
			"body": "Slim-athletic",
			"skin": "White",
			"bust": "C",
			"personality": "Cheerful",
			"profession": "Graphic design",
			"hobby": "Collecting vinyl records",
			
			"date_images": {
				"dinner": "res://assets/images/characters/park/christine/christine_dinner.jpg",
				"park": "res://assets/images/characters/park/christine/christine_park.jpg",
				"beach": "res://assets/images/characters/park/christine/christine_beach.jpg",
				"home": "res://assets/images/characters/park/christine/christine_home.jpg",
				"special": "res://assets/images/characters/park/christine/christine_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		"rikka_park": {
			"id": "rikka_park",
			"name": "Rikka",
			"location": "Park",
			"image_path": "res://assets/images/characters/park/rikka/rikka_main.png",
			"stats_required": {"endurance": 10, "balance": 10},
			
			# Love Book profile
			"age": "23",
			"height": "158 cm",
			"weight": "47 kg",
			"hair": "Light ash blonde, medium length with loose curls",
			"eyes": "Blue-grey",
			"body": "Petite and slim",
			"skin": "White",
			"bust": "B",
			"personality": "Dreamy",
			"profession": "Musician",
			"hobby": "Playing guitar",
			
			"date_images": {
				"dinner": "res://assets/images/characters/park/rikka/rikka_dinner.jpg",
				"park": "res://assets/images/characters/park/rikka/rikka_park.jpg",
				"beach": "res://assets/images/characters/park/rikka/rikka_beach.jpg",
				"home": "res://assets/images/characters/park/rikka/rikka_home.jpg",
				"special": "res://assets/images/characters/park/rikka/rikka_special.jpg"
			},
			"dialogue_by_stage": { }
		}
	}
