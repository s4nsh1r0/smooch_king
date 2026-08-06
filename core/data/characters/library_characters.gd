extends Node

func get_characters() -> Dictionary:
	return {
		"annabelle_library": {
			"id": "annabelle_library",
			"name": "Annabelle",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/annabelle/annabelle_main.png",
			"stats_required": {"knowledge": 1, "intelligence": 1},
			
			# Love Book profile
			"age": "20",
			"height": "160 cm",
			"weight": "49 kg",
			"hair": "Deep burgundy, shoulder-length and straight",
			"eyes": "Golden brown",
			"body": "Slim and delicate",
			"skin": "White",
			"bust": "C",
			"personality": "Thoughtful",
			"profession": "Library Assistant",
			"hobby": "Writing Poetry",
			
			"date_images": {
				"dinner": "res://assets/images/characters/library/annabelle/annabelle_dinner.jpg",
				"park": "res://assets/images/characters/library/annabelle/annabelle_park.jpg",
				"beach": "res://assets/images/characters/library/annabelle/annabelle_beach.jpg",
				"home": "res://assets/images/characters/library/annabelle/annabelle_home.jpg",
				"special": "res://assets/images/characters/library/annabelle/annabelle_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		"matilda_library": {
			"id": "matilda_library",
			"name": "Matilda",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/matilda/matilda_main.png",
			"stats_required": {"knowledge": 10, "intelligence": 10},
			
			# Love Book profile
			"age": "32",
			"height": "158 cm",
			"weight": "54 kg",
			"hair": "Soft grey, short pixie cut",
			"eyes": "Green",
			"body": "Petite and wiry",
			"skin": "Olive",
			"bust": "B",
			"personality": "Sharp",
			"profession": "Journalist",
			"hobby": "Photography",
			
			"date_images": {
				"dinner": "res://assets/images/characters/library/matilda/matilda_dinner.jpg",
				"park": "res://assets/images/characters/library/matilda/matilda_park.jpg",
				"beach": "res://assets/images/characters/library/matilda/matilda_beach.jpg",
				"home": "res://assets/images/characters/library/matilda/matilda_home.jpg",
				"special": "res://assets/images/characters/library/matilda/matilda_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		"lucia_library": {
			"id": "lucia_library",
			"name": "Lucia",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/lucia/lucia_main.png",
			"stats_required": {"knowledge": 10, "intelligence": 10},
			
			# Love Book profile
			"age": "19",
			"height": "164 cm",
			"weight": "52 kg",
			"hair": "Jet black, long and straight with heavy bangs",
			"eyes": "Dark grey",
			"body": "Slim",
			"skin": "Very pale",
			"bust": "C",
			"personality": "Mysterious",
			"profession": "Art Student",
			"hobby": "Occult and Magic",
			
			"date_images": {
				"dinner": "res://assets/images/characters/library/lucia/lucia_dinner.jpg",
				"park": "res://assets/images/characters/library/lucia/lucia_park.jpg",
				"beach": "res://assets/images/characters/library/lucia/lucia_beach.jpg",
				"home": "res://assets/images/characters/library/lucia/lucia_home.jpg",
				"special": "res://assets/images/characters/library/lucia/lucia_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		"laura_library": {
			"id": "laura_library",
			"name": "Laura",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/laura/laura_main.png",
			"stats_required": {"wisdom": 100, "logic": 100},
			
			# Love Book profile
			"age": "28",
			"height": "170 cm",
			"weight": "68 kg",
			"hair": "Chestnut brown, medium length with soft layers",
			"eyes": "Hazel",
			"body": "Chubby",
			"skin": "Fair",
			"bust": "D",
			"personality": "Sweet",
			"profession": "Kindergarden Teacher",
			"hobby": "Knitting",
			
			"date_images": {
				"dinner": "res://assets/images/characters/library/laura/laura_dinner.jpg",
				"park": "res://assets/images/characters/library/laura/laura_park.jpg",
				"beach": "res://assets/images/characters/library/laura/laura_beach.jpg",
				"home": "res://assets/images/characters/library/laura/laura_home.jpg",
				"special": "res://assets/images/characters/library/laura/laura_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		"hanah_library": {
			"id": "hanah_library",
			"name": "Hanah",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/hanah/hanah_main.png",
			"stats_required": {"knowledge": 50, "wisdom": 50},
			
			# Love Book profile
			"age": "19",
			"height": "152 cm",
			"weight": "44 kg",
			"hair": "Soft black, long and straight with neat bangs",
			"eyes": "Dark brown",
			"body": "Very petite and delicate",
			"skin": "Fair",
			"bust": "B",
			"personality": "Reserved",
			"profession": "Literature Student",
			"hobby": "Reading romance novels",
			
			"date_images": {
				"dinner": "res://assets/images/characters/library/hanah/hanah_dinner.jpg",
				"park": "res://assets/images/characters/library/hanah/hanah_park.jpg",
				"beach": "res://assets/images/characters/library/hanah/hanah_beach.jpg",
				"home": "res://assets/images/characters/library/hanah/hanah_home.jpg",
				"special": "res://assets/images/characters/library/hanah/hanah_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		
		"vicky_library": {
			"id": "vicky_library",
			"name": "Vicky",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/vicky/vicky_main.png",
			"stats_required": {"knowledge": 10, "intelligence": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/library/vicky/vicky_dinner.jpeg",
				"park": "res://assets/images/characters/library/vicky/vicky_park.jpeg",
				"beach": "res://assets/images/characters/library/vicky/vicky_beach.jpeg",
				"home": "res://assets/images/characters/library/vicky/vicky_home.jpeg",
				"special": "res://assets/images/characters/library/vicky/vicky_special.jpeg"
			},
			"dialogue_by_stage": { }
		},
		"alina_library": {
			"id": "alina_library",
			"name": "Alina",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/alina/alina_main.png",
			"stats_required": {"knowledge": 10, "intelligence": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/library/alina/alina_dinner.jpeg",
				"park": "res://assets/images/characters/library/alina/alina_park.jpeg",
				"beach": "res://assets/images/characters/library/alina/alina_beach.jpeg",
				"home": "res://assets/images/characters/library/alina/alina_home.jpeg",
				"special": "res://assets/images/characters/library/alina/alina_special.jpeg"
			},
			"dialogue_by_stage": { }
		},
		"nami_library": {
			"id": "nami_library",
			"name": "Nami",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/nami/nami_main.png",
			"stats_required": {"knowledge": 10, "intelligence": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/library/nami/nami_dinner.jpeg",
				"park": "res://assets/images/characters/library/nami/nami_park.jpeg",
				"beach": "res://assets/images/characters/library/nami/nami_beach.jpeg",
				"home": "res://assets/images/characters/library/nami/nami_home.jpeg",
				"special": "res://assets/images/characters/library/nami/nami_special.jpeg"
			},
			"dialogue_by_stage": { }
		},
		"emma_library": {
			"id": "emma_library",
			"name": "Emma",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/emma/emma_main.png",
			"stats_required": {"knowledge": 10, "intelligence": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/library/emma/emma_dinner.jpeg",
				"park": "res://assets/images/characters/library/emma/emma_park.jpeg",
				"beach": "res://assets/images/characters/library/emma/emma_beach.jpeg",
				"home": "res://assets/images/characters/library/emma/emma_home.jpeg",
				"special": "res://assets/images/characters/library/emma/emma_special.jpeg"
			},
			"dialogue_by_stage": { }
		},
		"donna_library": {
			"id": "donna_library",
			"name": "Donna",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/donna/donna_main.png",
			"stats_required": {"knowledge": 10, "intelligence": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/library/donna/donna_dinner.jpeg",
				"park": "res://assets/images/characters/library/donna/donna_park.jpeg",
				"beach": "res://assets/images/characters/library/donna/donna_beach.jpeg",
				"home": "res://assets/images/characters/library/donna/donna_home.jpeg",
				"special": "res://assets/images/characters/library/donna/donna_special.jpeg"
			},
			"dialogue_by_stage": { }
		},
		"evelyn_library": {
			"id": "evelyn_library",
			"name": "Evelyn",
			"location": "Library",
			"image_path": "res://assets/images/characters/library/evelyn/evelyn_main.png",
			"stats_required": {"knowledge": 10, "intelligence": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/library/evelyn/evelyn_dinner.jpeg",
				"park": "res://assets/images/characters/library/evelyn/evelyn_park.jpeg",
				"beach": "res://assets/images/characters/library/evelyn/evelyn_beach.jpeg",
				"home": "res://assets/images/characters/library/evelyn/evelyn_home.jpeg",
				"special": "res://assets/images/characters/library/evelyn/evelyn_special.jpeg"
			},
			"dialogue_by_stage": { }
		}
	}
