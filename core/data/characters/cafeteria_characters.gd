extends Node

func get_characters() -> Dictionary:
	return {
		"hikari_cafeteria": {
			"id": "hikari_cafeteria",
			"name": "Hikari",
			"location": "Cafeteria",
			"image_path": "res://assets/images/characters/cafeteria/hikari/hikari_main.png",
			"stats_required": {"charisma": 1, "communication": 1},
			
			"mood_weights": {
				"angry": 2,
				"upset": 8,
				"neutral": 30,
				"happy": 40,
				"excited": 20
			},
			
			# Love Book profile
			"age": "26",
			"height": "175 cm",
			"weight": "61 kg",
			"hair": "Warm chestnut, long with soft waves",
			"eyes": "Hazel-green",
			"body": "Tall and curvaceous",
			"skin": "White",
			"bust": "E",
			"personality": "Warm",
			"profession": "Barwoman",
			"hobby": "Baking",
			
			"date_images": {
				"dinner": "res://assets/images/characters/cafeteria/hikari/hikari_dinner.jpg",
				"park": "res://assets/images/characters/cafeteria/hikari/hikari_park.jpg",
				"beach": "res://assets/images/characters/cafeteria/hikari/hikari_beach.jpg",
				"home": "res://assets/images/characters/cafeteria/hikari/hikari_home.jpg",
				"special": "res://assets/images/characters/cafeteria/hikari/hikari_special.jpg"
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
			"stats_required": {"persuasion": 20, "communication": 20},
			
			# Love Book profile
			"age": "18",
			"height": "158 cm",
			"weight": "48 kg",
			"hair": "Soft pink, short and fluffy",
			"eyes": "Light blue",
			"body": "Petite and soft",
			"skin": "Fair",
			"bust": "B",
			"personality": "Shy",
			"profession": "Pet Shop Assistant",
			"hobby": "Animal Welfare",
			
			"date_images": {
				"dinner": "res://assets/images/characters/cafeteria/victoria/victoria_dinner.jpg",
				"park": "res://assets/images/characters/cafeteria/victoria/victoria_park.jpg",
				"beach": "res://assets/images/characters/cafeteria/victoria/victoria_beach.jpg",
				"home": "res://assets/images/characters/cafeteria/victoria/victoria_home.jpg",
				"special": "res://assets/images/characters/cafeteria/victoria/victoria_special.jpg"
			},
			"dialogue_by_stage": { # Add dialogue if you want, or leave empty for now
			}
		},
		"lola_cafeteria": {
			"id": "lola_cafeteria",
			"name": "Lola",
			"location": "Cafeteria",
			"image_path": "res://assets/images/characters/cafeteria/lola/lola_main.png",
			"stats_required": {"strength": 80, "leadership": 100},
			
			# Love Book profile
			"age": "22",
			"height": "170 cm",
			"weight": "58 kg",
			"hair": "Short dark brown, slightly messy undercut",
			"eyes": "Sharp amber",
			"body": "Athletic with subtle curves",
			"skin": "Lightly tanned",
			"bust": "B",
			"personality": "Straightforward",
			"profession": "Mechanic",
			"hobby": "Skateboard",
			
			"date_images": {
				"dinner": "res://assets/images/characters/cafeteria/lola/lola_dinner.jpeg",
				"park": "res://assets/images/characters/cafeteria/lola/lola_park.jpeg",
				"beach": "res://assets/images/characters/cafeteria/lola/lola_beach.jpeg",
				"home": "res://assets/images/characters/cafeteria/lola/lola_home.jpeg",
				"special": "res://assets/images/characters/cafeteria/lola/lola_special.jpeg"
			},
			"dialogue_by_stage": { }
		}
	}
	
