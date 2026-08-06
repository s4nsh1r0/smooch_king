extends Node

func get_characters() -> Dictionary:
	return {
		"mrsanderson_jobcenter": {
			"id": "mrsanderson_jobcenter",
			"name": "Mrs. Anderson",
			"location": "Job Center",
			"image_path": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_main.png",
			"stats_required": {"persuasion": 1, "logic": 1},
			
			# Love Book profile
			"age": "34",
			"height": "168 cm",
			"weight": "72 kg",
			"hair": "Dark brown with a few soft grey strands, shoulder-length and wavy",
			"eyes": "Deep brown",
			"body": "Curvy and full-figured",
			"skin": "White",
			"bust": "E",
			"personality": "Nurturing",
			"profession": "Secretary",
			"hobby": "Gardening",
			
			"date_images": {
				"dinner": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_dinner.jpg",
				"park": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_park.jpg",
				"beach": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_beach.jpg",
				"home": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_home.jpg",
				"special": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_special.jpg"
			},
			"dialogue_by_stage": { }
		},
		"julia_jobcenter": {
			"id": "julia_jobcenter",
			"name": "Julia",
			"location": "Job Center",
			"image_path": "res://assets/images/characters/jobcenter/julia/julia_main.png",
			"stats_required": {"persuasion": 1, "logic": 1},
			
			# Love Book profile
			"age": "39",
			"height": "176 cm",
			"weight": "68 kg",
			"hair": "Deep auburn, long and thick with loose waves",
			"eyes": "Golden hazel",
			"body": "Tall, mature, and full-figured",
			"skin": "Warm beige",
			"bust": "E",
			"personality": "Confident",
			"profession": "Lawyer",
			"hobby": "Wine Tasting",
			
			"date_images": {
				"dinner": "res://assets/images/characters/jobcenter/julia/julia_dinner.png",
				"park": "res://assets/images/characters/jobcenter/julia/julia_park.png",
				"beach": "res://assets/images/characters/jobcenter/julia/julia_beach.png",
				"home": "res://assets/images/characters/jobcenter/julia/julia_home.png",
				"special": "res://assets/images/characters/jobcenter/julia/julia_special.png"
			},
			"dialogue_by_stage": { }
		}
	}
