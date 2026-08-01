extends Node

func get_characters() -> Dictionary:
	return {
		"mrsanderson_jobcenter": {
			"id": "mrsanderson_jobcenter",
			"name": "Mrs. Anderson",
			"location": "Job Center",
			"image_path": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_main.png",
			"stats_required": {"persuasion": 1, "logic": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_dinner.png",
				"park": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_park.png",
				"beach": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_beach.png",
				"home": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_home.png",
				"kiss": "res://assets/images/characters/jobcenter/mrsanderson/mrsanderson_kiss.png"
			},
			"dialogue_by_stage": { }
		},
		"julia_jobcenter": {
			"id": "julia_jobcenter",
			"name": "Julia",
			"location": "Job Center",
			"image_path": "res://assets/images/characters/jobcenter/julia/julia_main.png",
			"stats_required": {"persuasion": 1, "logic": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/jobcenter/julia/julia_dinner.png",
				"park": "res://assets/images/characters/jobcenter/julia/julia_park.png",
				"beach": "res://assets/images/characters/jobcenter/julia/julia_beach.png",
				"home": "res://assets/images/characters/jobcenter/julia/julia_home.png",
				"kiss": "res://assets/images/characters/jobcenter/julia/julia_kiss.png"
			},
			"dialogue_by_stage": { }
		}
	}
