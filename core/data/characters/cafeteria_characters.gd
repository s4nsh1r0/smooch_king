extends Node

func get_characters() -> Dictionary:
	return {
		"hikari_cafeteria": {
			"id": "hikari_cafeteria",
			"name": "Hikari",
			"location": "Cafeteria",
			"image_path": "res://assets/images/characters/cafeteria/hikari/hikari_main.png",
			"stats_required": {"charisma": 1, "communication": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/cafeteria/hikari/hikari_dinner.png",
				"park": "res://assets/images/characters/cafeteria/hikari/hikari_park.png",
				"beach": "res://assets/images/characters/cafeteria/hikari/hikari_beach.png",
				"home": "res://assets/images/characters/cafeteria/hikari/hikari_home.png",
				"kiss": "res://assets/images/characters/cafeteria/hikari/hikari_kiss.png"
			},
			"dialogue_by_stage": {
				"Stranger": ["What can I get for you today?", "First time here? The special’s a great choice!", "Careful with the hot coffee—it’s fresh!", "The cafeteria’s buzzing today, isn’t it?"],
				"Acquaintance": ["Hey, you’re back! Usual order or something new?", "Getting the hang of the cafeteria’s menu yet?", "Nice to see you again—keeps my day bright!", "Any food cravings today? I’ve got recommendations."],
				"Friend": ["Yo, good to see you! Hungry for something awesome?", "You’re starting to make this place feel lively!", "Wanna try the chef’s secret dish today?", "Your smile’s making my shift way better."],
				"Good Friend": ["My favorite customer! What’s the mood today?", "I love how you always bring good vibes here.", "Let’s pick something delicious to share, yeah?", "You make my day behind the counter so fun!", "Saved you the best dessert on the menu."],
				"Crush": ["*smiles shyly* Was hoping you’d swing by today.", "You look... great. I mean, ready for a great meal!", "I might’ve watched you pick your tray... just curious.", "Wanna hang out here sometime, just us?", "How about a milkshake after my shift? My treat."],
				"Dating": ["*grins* There’s my favorite person! *quick wink*", "Serving you is the highlight of my day, love.", "*teasing* Bet I can guess your order today, babe.", "We’re the best team, in the cafeteria and out.", "Fancy a cozy dinner at home after my shift?"],
				"Soulmate": ["*beaming* My heart’s here! Ready for our daily catch-up?", "Your presence makes every dish taste sweeter.", "We’re perfect together, sharing meals and moments.", "You inspire me, from the counter to forever.", "*softly* You’re my favorite part of every day, always."]
			}
		},
		"victoria_cafeteria": {
			"id": "victoria_cafeteria",
			"name": "Victoria",
			"location": "Cafeteria",
			"image_path": "res://assets/images/characters/cafeteria/victoria/victoria_main.png",
			"stats_required": {"charisma": 10, "communication": 10},
			"date_images": {
				"dinner": "res://assets/images/characters/cafeteria/victoria/victoria_dinner.png",
				"park": "res://assets/images/characters/cafeteria/victoria/victoria_park.png",
				"beach": "res://assets/images/characters/cafeteria/victoria/victoria_beach.png",
				"home": "res://assets/images/characters/cafeteria/victoria/victoria_home.png",
				"kiss": "res://assets/images/characters/cafeteria/victoria/victoria_kiss.png"
			},
			"dialogue_by_stage": { # Add dialogue if you want, or leave empty for now
			}
		},
		"lola_cafeteria": {
			"id": "lola_cafeteria",
			"name": "Lola",
			"location": "Cafeteria",
			"image_path": "res://assets/images/characters/cafeteria/lola/lola_main.png",
			"stats_required": {"charisma": 1, "communication": 1},
			"date_images": {
				"dinner": "res://assets/images/characters/cafeteria/lola/lola_dinner.jpeg",
				"park": "res://assets/images/characters/cafeteria/lola/lola_park.jpeg",
				"beach": "res://assets/images/characters/cafeteria/lola/lola_beach.jpeg",
				"home": "res://assets/images/characters/cafeteria/lola/lola_home.jpeg",
				"kiss": "res://assets/images/characters/cafeteria/lola/lola_kiss.jpeg"
			},
			"dialogue_by_stage": { }
		}
	}
