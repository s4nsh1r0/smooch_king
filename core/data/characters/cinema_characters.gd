extends Node

func get_characters() -> Dictionary:
	return {
		"aria_cinema": {
			"id": "aria_cinema",
			"name": "Aria",
			"location": "Cinema",
			"image_path": "res://assets/images/characters/cinema/aria/aria_main.png",
			"stats_required": {"communication": 1},
			
			# Love Book profile
			"age": "24",
			"height": "165 cm",
			"weight": "51 kg",
			"hair": "Dark auburn, long and slightly wavy",
			"eyes": "Green",
			"body": "Slim with soft curves",
			"skin": "White",
			"bust": "C",
			"personality": "Gentle",
			"profession": "Illustrator",
			"hobby": "Watching movies",
			
			"date_images": {
				"dinner": "res://assets/images/characters/cinema/aria/aria_dinner.jpg",
				"park": "res://assets/images/characters/cinema/aria/aria_park.jpg",
				"beach": "res://assets/images/characters/cinema/aria/aria_beach.jpg",
				"home": "res://assets/images/characters/cinema/aria/aria_home.jpg",
				"special": "res://assets/images/characters/cinema/aria/aria_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		"hilda_cinema": {
			"id": "hilda_cinema",
			"name": "Hilda",
			"location": "Cinema",
			"image_path": "res://assets/images/characters/cinema/hilda/hilda_main.png",
			"stats_required": {"communication": 10},
			
			# Love Book profile
			"age": "45",
			"height": "173 cm",
			"weight": "65 kg",
			"hair": "Silver-white, long and elegant with a slight wave",
			"eyes": "Icy blue",
			"body": "Tall with mature curves",
			"skin": "Fair with a cool undertone",
			"bust": "D",
			"personality": "Elegant",
			"profession": "Classical Pianist",
			"hobby": "Composing Music",
			
			"date_images": {
				"dinner": "res://assets/images/characters/cinema/hilda/hilda_dinner.jpg",
				"park": "res://assets/images/characters/cinema/hilda/hilda_park.jpg",
				"beach": "res://assets/images/characters/cinema/hilda/hilda_beach.jpg",
				"home": "res://assets/images/characters/cinema/hilda/hilda_home.jpg",
				"special": "res://assets/images/characters/cinema/hilda/hilda_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		"amelia_cinema": {
			"id": "amelia_cinema",
			"name": "Amelia",
			"location": "Cinema",
			"image_path": "res://assets/images/characters/cinema/amelia/amelia_main.png",
			"stats_required": {"communication": 1},

			# Love Book profile
			"age": "25",
			"height": "168 cm",
			"weight": "55 kg",
			"hair": "Jet-black, very long with straight bangs",
			"eyes": "Deep red",
			"body": "Curvy and elegant",
			"skin": "Pale",
			"bust": "D",
			"personality": "Mysterious",
			"profession": "Cinema Curator",
			"hobby": "Gothic novels",

			"date_images": {
				"dinner": "res://assets/images/characters/cinema/amelia/amelia_dinner.jpg",
				"park": "res://assets/images/characters/cinema/amelia/amelia_park.jpg",
				"beach": "res://assets/images/characters/cinema/amelia/amelia_beach.jpg",
				"home": "res://assets/images/characters/cinema/amelia/amelia_home.jpg",
				"special": "res://assets/images/characters/cinema/amelia/amelia_special.jpg"
			},
			"dialogue_by_stage": { }
		}
	}
