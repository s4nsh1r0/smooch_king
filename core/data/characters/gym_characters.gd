extends Node

func get_characters() -> Dictionary:
	return {
		"gigi_gym": {
			"id": "gigi_gym",
			"name": "Gigi",
			"location": "Gym",
			"image_path": "res://assets/images/characters/gym/gigi/gigi_main.png",
			"stats_required": {"strength": 1, "endurance": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/gym/gigi/gigi_dinner.png",
				"park": "res://assets/images/characters/gym/gigi/gigi_park.png",
				"beach": "res://assets/images/characters/gym/gigi/gigi_beach.png",
				"home": "res://assets/images/characters/gym/gigi/gigi_home.png",
				"kiss": "res://assets/images/characters/gym/gigi/gigi_kiss.png"
			},
			"dialogue_by_stage": {
				"Stranger": ["Spot me?", "First time here? Don't be shy!", "That form needs work... but we all start somewhere.", "Safety first - always warm up before lifting!"],
				"Acquaintance": ["Oh, you're back! I remember you from last time.", "Getting familiar with the gym layout yet?", "I see you around here often now. That's dedication!", "Need any tips on the equipment? I'm happy to help.", "You're starting to look more confident in here!"],
				"Friend": ["Hey there! Ready for a good workout?", "You're getting stronger! I can see the improvement.", "Want to try a new exercise today?", "Push yourself! You've got this.", "Nice technique! You've been practicing."],
				"Good Friend": ["There's my workout buddy! How are you feeling today?", "I've been looking forward to training with you!", "You're really dedicated - I admire that about you.", "Let's crush this workout together!", "I saved the good equipment for us to use.", "Your progress has been incredible to watch!"],
				"Crush": ["*blushes slightly* Oh hey... I was hoping you'd come by today.", "You look... really good today. I mean, ready for a great workout!", "I may have been watching your form... for training purposes, of course.", "Want to be workout partners? We could... motivate each other.", "*giggles nervously* Maybe we could grab a protein shake after?", "You make working out so much more fun!"],
				"Dating": ["There's my favorite person! *gives you a quick kiss*", "Working out with my partner is the best part of my day.", "*playfully flexes* Think you can keep up with me today, babe?", "I love how we push each other to be our best selves.", "After this, want to go home and... cool down together?", "You're not just strong physically, you're strong for me too."],
				"Soulmate": ["My everything! Ready to conquer the world together today?", "*deep loving gaze* I fall more in love with your determination every day.", "We're not just workout partners, we're life partners in everything.", "Your strength inspires me in the gym and in life.", "*whispers lovingly* You're my perfect match in every rep and every breath.", "Together we're unstoppable - in fitness and in love!"]
			}
		},
		"sasha_gym": {
			"id": "sasha_gym",
			"name": "Sasha",
			"location": "Gym",
			"image_path": "res://assets/images/characters/gym/sasha/sasha_main.png",
			"stats_required": {"strength": 1, "endurance": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/gym/sasha/sasha_dinner.png",
				"park": "res://assets/images/characters/gym/sasha/sasha_park.png",
				"beach": "res://assets/images/characters/gym/sasha/sasha_beach.png",
				"home": "res://assets/images/characters/gym/sasha/sasha_home.png",
				"kiss": "res://assets/images/characters/gym/sasha/sasha_kiss.png"
			},
			"dialogue_by_stage": { }  # Fill later if needed
		},
		"emma_gym": {
			"id": "emma_gym",
			"name": "Emma",
			"location": "Gym",
			"image_path": "res://assets/images/characters/gym/emma/emma_main.png",
			"stats_required": {"strength": 1, "endurance": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/gym/emma/emma_dinner.png",
				"park": "res://assets/images/characters/gym/emma/emma_park.png",
				"beach": "res://assets/images/characters/gym/emma/emma_beach.png",
				"home": "res://assets/images/characters/gym/emma/emma_home.png",
				"kiss": "res://assets/images/characters/gym/emma/emma_kiss.png"
			},
			"dialogue_by_stage": { }
		},
		"naomi_gym": {
			"id": "naomi_gym",
			"name": "Naomi",
			"location": "Gym",
			"image_path": "res://assets/images/characters/gym/naomi/naomi_main.png",
			"stats_required": {"strength": 1, "endurance": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/gym/naomi/naomi_dinner.jpeg",
				"park": "res://assets/images/characters/gym/naomi/naomi_park.jpeg",
				"beach": "res://assets/images/characters/gym/naomi/naomi_beach.jpeg",
				"home": "res://assets/images/characters/gym/naomi/naomi_home.jpeg",
				"kiss": "res://assets/images/characters/gym/naomi/naomi_kiss.jpeg"
			},
			"dialogue_by_stage": { }
		}
	}
