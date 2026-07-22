extends Node

const STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY: float = 100.0 / (4.0 * 3600.0)
const STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY: float = 100.0 / (8.0 * 3600.0)
const STAMINA_REGEN_PER_SECOND: float = 100.0 / 3600.0

signal location_data_updated(location_data_dict: Dictionary)

var location_data: Dictionary = {
	"Start Scene": {
		"name": "Start Scene",
		"type": "menu",
		"scene_path": "res://scenes/start_scene.tscn",
		"activities": [],
		"characters": []
	},
	"Intro Screen": {
		"name": "Intro Scene",
		"type": "intro",
		"scene_path": "res://scenes/intro_scene.tscn",
		"activities": [],
		"characters": []
	},
	"Home": {
		"name": "Home",
		"type": "normal",
		"scene_path": "res://scenes/locations/home_scene.tscn",
		"activities": [
			{"name": "Cook", "description": "Prepare a meal and improve intelligence.", "effects": {"intelligence": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Watch TV", "description": "Relax and improve persuasion.", "effects": {"persuasion": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Read Magazine", "description": "Gain knowledge from articles.", "effects": {"knowledge": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Work Out", "description": "Increase your strength at home.", "effects": {"strength": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Use Internet", "description": "Explore the web and gain wisdom.", "effects": {"wisdom": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": [] as Array[Dictionary]
	},
	"Gym": {
		"name": "Gym",
		"type": "normal",
		"scene_path": "res://scenes/locations/gym_scene.tscn",
		"activities": [
			{"name": "Lift Weights", "description": "Intense strength training.", "effects": {"strength": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Treadmill", "description": "Cardio for endurance.", "effects": {"endurance": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Stretch", "description": "Improve agility and flexibility.", "effects": {"agility": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Yoga", "description": "Improve balance", "effects": {"balance": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY}
		] as Array[Dictionary],
		"characters": [
			{
				"id": "gigi_gym",
				"name": "Gigi",
				"dialogue_by_stage": {
					"Stranger": [
						"Spot me?",
						"First time here? Don't be shy!",
						"That form needs work... but we all start somewhere.",
						"Safety first - always warm up before lifting!"
					],
					"Acquaintance": [
						"Oh, you're back! I remember you from last time.",
						"Getting familiar with the gym layout yet?",
						"I see you around here often now. That's dedication!",
						"Need any tips on the equipment? I'm happy to help.",
						"You're starting to look more confident in here!"
					],
					"Friend": [
						"Hey there! Ready for a good workout?",
						"You're getting stronger! I can see the improvement.",
						"Want to try a new exercise today?",
						"Push yourself! You've got this.",
						"Nice technique! You've been practicing."
					],
					"Good Friend": [
						"There's my workout buddy! How are you feeling today?",
						"I've been looking forward to training with you!",
						"You're really dedicated - I admire that about you.",
						"Let's crush this workout together!",
						"I saved the good equipment for us to use.",
						"Your progress has been incredible to watch!"
					],
					"Crush": [
						"*blushes slightly* Oh hey... I was hoping you'd come by today.",
						"You look... really good today. I mean, ready for a great workout!",
						"I may have been watching your form... for training purposes, of course.",
						"Want to be workout partners? We could... motivate each other.",
						"*giggles nervously* Maybe we could grab a protein shake after?",
						"You make working out so much more fun!"
					],
					"Dating": [
						"There's my favorite person! *gives you a quick kiss*",
						"Working out with my partner is the best part of my day.",
						"*playfully flexes* Think you can keep up with me today, babe?",
						"I love how we push each other to be our best selves.",
						"After this, want to go home and... cool down together?",
						"You're not just strong physically, you're strong for me too."
					],
					"Soulmate": [
						"My everything! Ready to conquer the world together today?",
						"*deep loving gaze* I fall more in love with your determination every day.",
						"We're not just workout partners, we're life partners in everything.",
						"Your strength inspires me in the gym and in life.",
						"*whispers lovingly* You're my perfect match in every rep and every breath.",
						"Together we're unstoppable - in fitness and in love!"
					]
				},
				"dialogue_points": {
					"Stranger": 3,
					"Acquaintance": 3,
					"Friend": 4,
					"Good Friend": 5,
					"Crush": 6,
					"Dating": 7,
					"Soulmate": 8
				},
				"image_path": "res://images/characters/gym/gigi/gigi_main.png",
				"stats_required": {"strength": 1, "endurance": 1},
				"date_images": {
					"dinner": "res://images/characters/gym/gigi/gigi_dinner.png",
					"park": "res://images/characters/gym/gigi/gigi_park.png",
					"beach": "res://images/characters/gym/gigi/gigi_beach.png",
					"home": "res://images/characters/gym/gigi/gigi_home.png",
					"kiss": "res://images/characters/gym/gigi/gigi_kiss.png"
				}
			},
			{
				  "id": "sasha_gym",
				  "name": "Sasha",
				  "dialogue_by_stage": {
					"Stranger": [
					  "Hey, you new here? Need a spot?",
					  "Don't be intimidated, everyone's gotta start somewhere!",
					  "Good effort, but let’s focus on form next time.",
					  "Warm-ups are key—don’t skip ‘em!"
					],
					"Acquaintance": [
					  "Back for more, huh? I’m starting to recognize you.",
					  "You finding your groove in the gym yet?",
					  "Nice to see you again—keep showing up!",
					  "Got questions about the machines? I’m around."
					],
					"Friend": [
					  "Yo, good to see you! Ready to crush it today?",
					  "You’re getting the hang of this—nice progress!",
					  "Wanna try a new lift? I’ll show you the ropes.",
					  "Keep pushing, you’re stronger than you think!"
					],
					"Good Friend": [
					  "My gym partner! What’s the vibe today?",
					  "I love how consistent you are—keeps me motivated!",
					  "Let’s tackle a tough set together, deal?",
					  "You’re killing it—proud to train with you!",
					  "Saved you a spot on the best bench."
					],
					"Crush": [
					  "*smiles warmly* Was hoping you’d show up today.",
					  "You’re looking... strong. I mean, great form!",
					  "Mind if I watch your set? For, uh, technique.",
					  "How about we team up for workouts more often?",
					  "Maybe post-workout smoothies? Just you and me?"
					],
					"Dating": [
					  "*grins* There’s my favorite workout partner! *quick hug*",
					  "Training with you makes my day, babe.",
					  "Let’s see who can lift more today—loser buys dinner!",
					  "I love how we vibe in and out of the gym.",
					  "Post-workout cuddles at home sound good?"
					],
					"Soulmate": [
					  "*beaming* My love, ready to conquer this workout together?",
					  "Your drive in here? It’s why I’m so in love with you.",
					  "We’re a team—in the gym, in life, in everything.",
					  "Your strength lifts me up, every single day.",
					  "*softly* You’re my forever workout and life partner."
					]
				  },
				  "dialogue_points": {
					"Stranger": 3,
					"Acquaintance": 3,
					"Friend": 4,
					"Good Friend": 5,
					"Crush": 6,
					"Dating": 7,
					"Soulmate": 8
				  },
				  "image_path": "res://images/characters/gym/sasha/sasha_main.png",
				  "stats_required": {"strength": 1, "endurance": 1},
				  "date_images": {
					"dinner": "res://images/characters/gym/sasha/sasha_dinner.png",
					"park": "res://images/characters/gym/sasha/sasha_park.png",
					"beach": "res://images/characters/gym/sasha/sasha_beach.png",
					"home": "res://images/characters/gym/sasha/sasha_home.png",
					"kiss": "res://images/characters/gym/sasha/sasha_kiss.png"
				  }
			},
			{
				  "id": "emma_gym",
				  "name": "Emma",
				  "dialogue_by_stage": {
					"Stranger": [
					  "Hey, need a spotter? I'm right here.",
					  "New to the gym? No worries, we all start somewhere!",
					  "Keep your form tight—prevents injuries!",
					  "Warming up is non-negotiable, got it?"
					],
					"Acquaintance": [
					  "You again! Starting to become a regular, huh?",
					  "Getting comfy with the weights yet?",
					  "I like your consistency—keep it up!",
					  "Need a rundown on any equipment? Just ask."
					],
					"Friend": [
					  "Hey, good to see you! Ready for a solid session?",
					  "Your progress is showing—nice work!",
					  "Wanna mix it up with a new routine today?",
					  "You’re tougher than you look—keep grinding!"
					],
					"Good Friend": [
					  "There’s my gym buddy! What’s the plan today?",
					  "Your dedication is legit—it’s inspiring.",
					  "Let’s hit a personal best together, yeah?",
					  "I’m pumped to train with you!",
					  "Got the best treadmill reserved for us."
					],
					"Crush": [
					  "*smiles shyly* Was kinda hoping you’d be here.",
					  "You’re looking... really focused today. It’s cute.",
					  "I might’ve been checking your form... just saying.",
					  "How about we partner up for workouts regularly?",
					  "Post-gym coffee? My treat."
					],
					"Dating": [
					  "*grins* My favorite person’s here! *quick peck*",
					  "Workouts with you are my daily highlight.",
					  "*teasing* Bet I can outlift you today, love.",
					  "We make the best team, in and out of the gym.",
					  "Wanna head home after for some... downtime?"
					],
					"Soulmate": [
					  "*warm smile* My forever gym partner—ready for today?",
					  "Your strength, your heart—I’m in love with it all.",
					  "We’re unstoppable, together in life and lifts.",
					  "You inspire me every rep, every day.",
					  "*softly* You’re my everything, in the gym and always."
					]
				  },
				  "dialogue_points": {
					"Stranger": 3,
					"Acquaintance": 3,
					"Friend": 4,
					"Good Friend": 5,
					"Crush": 6,
					"Dating": 7,
					"Soulmate": 8
				  },
				  "image_path": "res://images/characters/gym/emma/emma_main.png",
				  "stats_required": {"strength": 1, "endurance": 1},
				  "date_images": {
					"dinner": "res://images/characters/gym/emma/emma_dinner.png",
					"park": "res://images/characters/gym/emma/emma_park.png",
					"beach": "res://images/characters/gym/emma/emma_beach.png",
					"home": "res://images/characters/gym/emma/emma_home.png",
					"kiss": "res://images/characters/gym/emma/emma_kiss.png"
				  }
			},
			{
				"id": "naomi_gym",
				"name": "Naomi",
				"dialogue_by_stage": {
					"Stranger": [
						"Spot me?",
						"First time here? Don't be shy!",
						"That form needs work... but we all start somewhere.",
						"Safety first - always warm up before lifting!"
					],
					"Acquaintance": [
						"Oh, you're back! I remember you from last time.",
						"Getting familiar with the gym layout yet?",
						"I see you around here often now. That's dedication!",
						"Need any tips on the equipment? I'm happy to help.",
						"You're starting to look more confident in here!"
					],
					"Friend": [
						"Hey there! Ready for a good workout?",
						"You're getting stronger! I can see the improvement.",
						"Want to try a new exercise today?",
						"Push yourself! You've got this.",
						"Nice technique! You've been practicing."
					],
					"Good Friend": [
						"There's my workout buddy! How are you feeling today?",
						"I've been looking forward to training with you!",
						"You're really dedicated - I admire that about you.",
						"Let's crush this workout together!",
						"I saved the good equipment for us to use.",
						"Your progress has been incredible to watch!"
					],
					"Crush": [
						"*blushes slightly* Oh hey... I was hoping you'd come by today.",
						"You look... really good today. I mean, ready for a great workout!",
						"I may have been watching your form... for training purposes, of course.",
						"Want to be workout partners? We could... motivate each other.",
						"*giggles nervously* Maybe we could grab a protein shake after?",
						"You make working out so much more fun!"
					],
					"Dating": [
						"There's my favorite person! *gives you a quick kiss*",
						"Working out with my partner is the best part of my day.",
						"*playfully flexes* Think you can keep up with me today, babe?",
						"I love how we push each other to be our best selves.",
						"After this, want to go home and... cool down together?",
						"You're not just strong physically, you're strong for me too."
					],
					"Soulmate": [
						"My everything! Ready to conquer the world together today?",
						"*deep loving gaze* I fall more in love with your determination every day.",
						"We're not just workout partners, we're life partners in everything.",
						"Your strength inspires me in the gym and in life.",
						"*whispers lovingly* You're my perfect match in every rep and every breath.",
						"Together we're unstoppable - in fitness and in love!"
					]
				},
				"dialogue_points": {
					"Stranger": 20,
					"Acquaintance": 20,
					"Friend": 20,
					"Good Friend": 20,
					"Crush": 20,
					"Dating": 20,
					"Soulmate": 20
				},
				"image_path": "res://images/characters/gym/naomi/naomi_main.png",
				"stats_required": {"strength": 1, "endurance": 1},
				"date_images": {
					"dinner": "res://images/characters/gym/naomi/naomi_dinner.jpeg",
					"park": "res://images/characters/gym/naomi/naomi_park.jpeg",
					"beach": "res://images/characters/gym/naomi/naomi_beach.jpeg",
					"home": "res://images/characters/gym/naomi/naomi_home.jpeg",
					"kiss": "res://images/characters/gym/naomi/naomi_kiss.jpeg"
				}
			},
		] as Array[Dictionary]
	},
	"Library": {
		"name": "Library",
		"type": "normal",
		"scene_path": "res://scenes/locations/library_scene.tscn",
		"activities": [
			{"name": "Read", "description": "Deep dive into a book.", "effects": {"knowledge": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Research Online", "description": "Boost your intelligence with online research.", "effects": {"intelligence": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Solve Puzzles", "description": "Challenge your logic.", "effects": {"logic": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Philosophy Debate", "description": "Engage in deep thought.", "effects": {"wisdom": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": [
			{
			"id": "annabelle_library",
			"name": "Annabelle",
			"age": 19,
			"height": "158 cm",
			"weight": "49 kg",
			"hair": "Black",
			"eyes": "Dark Brown",
			"body": "Petite",
			"bust": "Small",
			"profession": "Literature student",
			"hobby": "Poetry",
			"dialogue_by_stage": {
				  "Stranger": [
					"Oh, um… h-hi. Are you looking for something specific?",
					"This… section is kind of quiet. I like it here.",
					"You’re new, right? I-I think I’ve seen everyone else before.",
				    "If you need help, I-I can try… though I’m still learning my way around."
				  ],
				  "Acquaintance": [
					"Oh, you’re back! Found any good reads yet?",
					"Starting to know your way around the stacks?",
					"Oh, you came back! I-I didn’t think you would.",
				    "Um… you read fast! I’m still on the same page as last time."
				  ],
				  "Friend": [
					"Hey, good to see you! Found any hidden gems today?",
					"You’re getting sharper—those books are paying off!",
					"Want to explore a new section together?",
				    "Your curiosity is contagious, you know!"
				  ],
				  "Good Friend": [
					"There’s my favorite library buddy! Ready to dive in?",
					"I love how you light up when you find a good book.",
					"Let’s hunt for a rare manuscript today, deal?",
					"Your passion for learning is so inspiring!",
				    "I saved us a spot in the quiet reading nook."
				  ],
				  "Crush": [
					"*smiles softly* I was hoping you’d stop by today.",
					"You make these dusty books seem... exciting.",
					"I might’ve been watching you read... it’s captivating.",
					"Want to share a table and study together sometime?",
				    "How about coffee after? We could talk books."
				  ],
				  "Dating": [
					"*beaming* My favorite scholar! *gentle hug*",
					"Reading with you is the best part of my day.",
					"*teasing* Think you can outsmart me in trivia today?",
					"We’re the perfect pair, lost in books and each other.",
				    "Want to cozy up at home with a novel tonight?"
				  ],
				  "Soulmate": [
					"*warm gaze* My heart’s here—ready for our next chapter?",
					"Your mind, your soul—I’m in love with every part.",
					"We’re a story written together, page by page.",
					"You inspire me to learn, to love, to live fully.",
				    "*whispers* You’re my forever, in libraries and life."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/annabelle/annabelle_main.png",
			  "stats_required": {"knowledge": 1, "intelligence": 1},
			  "date_images": {
				"dinner": "res://images/characters/library/annabelle/annabelle_dinner.jpeg",
				"park": "res://images/characters/library/annabelle/annabelle_park.jpeg",
				"beach": "res://images/characters/library/annabelle/annabelle_beach.jpeg",
				"home": "res://images/characters/library/annabelle/annabelle_home.jpeg",
				"kiss": "res://images/characters/library/annabelle/annabelle_kiss.jpeg"
			  }
			},
			{
			"id": "matilda_library",
			"name": "Matilda",
			"age": 27,
			"height": "172 cm",
			"weight": "67 kg",
			"hair": "Chestnut brown",
			"eyes": "Hazel",
			"body": "Curvy",
			"bust": "Large",
			"profession": "Librarian",
			"hobby": "Old books",
			"dialogue_by_stage": {
				  "Stranger": [
					"Welcome to the library—let me know if you need a guiding hand.",
					"That shelf is tricky, but it hides the best treasures.",
					"Careful with those—some of these books are older than both of us.",
				    "New here? Don’t worry, I know every corner of this place."
				  ],
				  "Acquaintance": [
					"Back again? That makes me happy to see.",
					"You’re getting more confident finding your way around.",
					"I like that you always head straight for the interesting shelves.",
				    "Need a suggestion? I’ve got plenty of favorites."
				  ],
				  "Friend": [
					"There you are! I was hoping you’d stop by today.",
					"You’ve got an eye for good reading material.",
					"How about we explore the history section together?",
				    "I love how eager you are—it’s refreshing."
				  ],
				  "Good Friend": [
					"My favorite library companion! Ready for another dive into knowledge?",
					"The way your face lights up over a good book is beautiful.",
					"Let’s track down that rare title we talked about.",
					"I’m so glad we can share this passion for learning.",
				    "Saved us the best table by the big window."
				  ],
				  "Crush": [
					"*soft laugh* I was secretly hoping you’d be here today.",
					"You make this library feel warmer just by being in it.",
					"I keep finding myself watching you read… it’s charming.",
					"Would you sit with me for a while in the quiet corner?",
				    "Maybe after this we could get some tea together?"
				  ],
				  "Dating": [
					"*smiling brightly* There’s my favorite partner in knowledge and life.",
					"Exploring these shelves with you feels magical every time.",
					"*playful grin* Let’s see who finds the most obscure book today.",
					"You make even dusty old tomes exciting.",
				    "How about a cozy night in, with books and maybe some wine?"
				  ],
				  "Soulmate": [
					"*tender gaze* You’re my heart, on and off these shelves.",
					"Your mind and your warmth inspire me every day.",
					"We’re like two volumes of the same story—meant to be together.",
					"Every moment with you feels like finding a rare treasure.",
				    "*whispers* You’ll always be my greatest discovery."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/matilda/matilda_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/matilda/matilda_dinner.jpeg",
				"park": "res://images/characters/library/matilda/matilda_park.jpeg",
				"beach": "res://images/characters/library/matilda/matilda_beach.jpeg",
				"home": "res://images/characters/library/matilda/matilda_home.jpeg",
				"kiss": "res://images/characters/library/matilda/matilda_kiss.jpeg"
			  }
			},
			{
			"id": "hanah_library",
			"name": "Hanah",
			"age": 22,
			"height": "165 cm",
			"weight": "55 kg",
			"hair": "Silver",
			"eyes": "Grey-Blue",
			"body": "Athletic",
			"bust": "Medium",
			"profession": "Manga artist",
			"hobby": "Sketching",
			"dialogue_by_stage": {
				  "Stranger": [
					"Oh, hey… didn’t expect to see you here.",
					"Sorry, I might smell like coffee beans—I just got off shift.",
					"You’ve got that curious look… are you an art person too?",
				    "If you’re lost, I can point you toward the best study spots."
				  ],
				  "Acquaintance": [
					"Back again? That’s cool—I like running into you.",
					"You’re starting to feel like part of the scenery here.",
					"I doodled a little sketch between classes… wanna see?",
				    "So, what’s fueling you today—books, art, or caffeine?"
				  ],
				  "Friend": [
					"Hey! You always brighten the vibe when you walk in.",
					"Check this out—I’ve been working on a new painting.",
					"Want to hit the café later? I’ll make you something special.",
				    "It’s fun hanging out with someone who just… gets it."
				  ],
				  "Good Friend": [
					"There you are! I was hoping to catch you today.",
					"You inspire me—like, I create better when you’re around.",
					"Let’s sneak away after class and find a quiet spot to sketch.",
					"You’re more fun than half my art club combined.",
				    "I saved you a seat by the window—it’s perfect light."
				  ],
				  "Crush": [
					"*playful grin* You always show up when I need a little spark.",
					"You make me nervous… in a really good way.",
					"I caught myself sketching you instead of my assignment…",
					"Want to be my model sometime? Don’t worry—I’ll make you look amazing.",
				    "How about a late-night coffee run, just us?"
				  ],
				  "Dating": [
					"*beaming* My muse is here! Come sit with me.",
					"Every latte tastes sweeter when I share it with you.",
					"*teasing* Careful, or I’ll paint a mural of you across campus.",
					"You’ve become my favorite subject… and my favorite person.",
				    "Let’s spend the night painting, laughing, and drinking coffee."
				  ],
				  "Soulmate": [
					"*soft smile* You’re my forever canvas.",
					"Every brushstroke, every color—I see you in it all.",
					"You’ve turned my messy little world into a masterpiece.",
					"With you, life feels like art in motion.",
				    "*whispers* You’re everything I ever dreamed of creating."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/hanah/hanah_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/hanah/hanah_dinner.jpeg",
				"park": "res://images/characters/library/hanah/hanah_park.jpeg",
				"beach": "res://images/characters/library/hanah/hanah_beach.jpeg",
				"home": "res://images/characters/library/hanah/hanah_home.jpeg",
				"kiss": "res://images/characters/library/hanah/hanah_kiss.jpeg"
			  }
			},
			{
			"id": "laura_library",
			"name": "Laura",
			"age": 45,
			"height": "169 cm",
			"weight": "68 kg",
			"hair": "Brown",
			"eyes": "Gold",
			"body": "Curvy",
			"bust": "Large",
			"profession": "Professor",
			"hobby": "Stamp collector",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Oh, a new face in the library. What brings you here?",
				  "This corner holds some rare manuscripts—handle with care.",
				  "First time in this section? It’s a goldmine of knowledge.",
				  "Curiosity is a great start. What are you researching?"
				],
				"Acquaintance": [
				  "You’re back! Found anything intriguing in the stacks yet?",
				  "Navigating the library’s labyrinth getting easier?",
				  "I admire your persistence—keep exploring these tomes.",
				  "Need a recommendation for a good read? I’ve got plenty."
				],
				"Friend": [
				  "Hey, great to see you! Ready to uncover some wisdom?",
				  "Your knack for finding obscure texts is impressive!",
				  "Want to dive into a new subject together today?",
				  "Your questions always spark the best discussions."
				],
				"Good Friend": [
				  "My favorite scholar! What knowledge are we chasing today?",
				  "Your passion for learning lights up this dusty place.",
				  "Let’s track down that elusive book we talked about!",
				  "I’m so glad we share this love for the library.",
				  "Saved us the best table in the rare books room."
				],
				"Crush": [
				  "*soft smile* I was hoping you’d be here today.",
				  "You make even the driest texts seem... fascinating.",
				  "I might’ve been watching you study. It’s kind of adorable.",
				  "Care to share a quiet corner for some deep reading?",
				  "How about tea after? We could discuss our favorite books."
				],
				"Dating": [
				  "*warm grin* There’s my favorite mind! *gentle squeeze*",
				  "Exploring these shelves with you is pure magic.",
				  "*playful nudge* Bet I can find a rarer book than you today.",
				  "We’re perfect together, unraveling mysteries page by page.",
				  "Fancy a cozy night at home with some poetry?"
				],
				"Soulmate": [
				  "*tender gaze* My heart, ready for our next intellectual adventure?",
				  "Your brilliance inspires me, in books and in love.",
				  "We’re bound together, like the pages of a timeless story.",
				  "Every moment with you feels like discovering a rare manuscript.",
				  "*whispers* You’re my greatest discovery, now and always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/laura/laura_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/laura/laura_dinner.jpeg",
				"park": "res://images/characters/library/laura/laura_park.jpeg",
				"beach": "res://images/characters/library/laura/laura_beach.jpeg",
				"home": "res://images/characters/library/laura/laura_home.jpeg",
				"kiss": "res://images/characters/library/laura/laura_kiss.jpeg"
			  }
			},
			{
			"id": "lucia_library",
			"name": "Lucia",
			"age": 18,
			"height": "150 cm",
			"weight": "42 kg",
			"hair": "Blonde",
			"eyes": "Green",
			"body": "Petite",
			"bust": "Small",
			"profession": "History student",
			"hobby": "Museums",
			"dialogue_by_stage": {
				  "Stranger": [
					"Oh, um… h-hi. Are you looking for something specific?",
					"This… section is kind of quiet. I like it here.",
					"You’re new, right? I-I think I’ve seen everyone else before.",
				    "If you need help, I-I can try… though I’m still learning my way around."
				  ],
				  "Acquaintance": [
					"Oh, you’re back! Found any good reads yet?",
					"Starting to know your way around the stacks?",
					"Oh, you came back! I-I didn’t think you would.",
				    "Um… you read fast! I’m still on the same page as last time."
				  ],
				  "Friend": [
					"Hey, good to see you! Found any hidden gems today?",
					"You’re getting sharper—those books are paying off!",
					"Want to explore a new section together?",
				    "Your curiosity is contagious, you know!"
				  ],
				  "Good Friend": [
					"There’s my favorite library buddy! Ready to dive in?",
					"I love how you light up when you find a good book.",
					"Let’s hunt for a rare manuscript today, deal?",
					"Your passion for learning is so inspiring!",
				    "I saved us a spot in the quiet reading nook."
				  ],
				  "Crush": [
					"*smiles softly* I was hoping you’d stop by today.",
					"You make these dusty books seem... exciting.",
					"I might’ve been watching you read... it’s captivating.",
					"Want to share a table and study together sometime?",
				    "How about coffee after? We could talk books."
				  ],
				  "Dating": [
					"*beaming* My favorite scholar! *gentle hug*",
					"Reading with you is the best part of my day.",
					"*teasing* Think you can outsmart me in trivia today?",
					"We’re the perfect pair, lost in books and each other.",
				    "Want to cozy up at home with a novel tonight?"
				  ],
				  "Soulmate": [
					"*warm gaze* My heart’s here—ready for our next chapter?",
					"Your mind, your soul—I’m in love with every part.",
					"We’re a story written together, page by page.",
					"You inspire me to learn, to love, to live fully.",
				    "*whispers* You’re my forever, in libraries and life."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/lucia/lucia_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/lucia/lucia_dinner.jpeg",
				"park": "res://images/characters/library/lucia/lucia_park.jpeg",
				"beach": "res://images/characters/library/lucia/lucia_beach.jpeg",
				"home": "res://images/characters/library/lucia/lucia_home.jpeg",
				"kiss": "res://images/characters/library/lucia/lucia_kiss.jpeg"
			  }
			},
			{
			"id": "vicky_library",
			"name": "Vicky",
			"age": 24,
			"height": "168 cm",
			"weight": "59 kg",
			"hair": "Midnight blue",
			"eyes": "Violet",
			"body": "Slim",
			"bust": "Medium",
			"profession": "Lawyer",
			"hobby": "Puzzles",
			"dialogue_by_stage": {
				  "Stranger": [
					"Oh, hello. Are you searching for something in particular?",
					"This section has a certain charm, don’t you think?",
					"You must be new here—I don’t recall seeing you before.",
				    "If you’re lost, I could point you toward the classics."
				  ],
				  "Acquaintance": [
					"Ah, back again? You’re developing good taste.",
					"I noticed you lingering near the poetry shelves.",
					"It’s nice to see someone else who enjoys this atmosphere.",
				    "Do you often spend your time with books, too?"
				  ],
				  "Friend": [
					"There you are. Care to browse the literature with me?",
					"Your insights last time stayed with me—I’d love to hear more.",
					"I found a beautiful passage earlier. Want me to share it?",
				    "Reading with you feels… more refined, somehow."
				  ],
				  "Good Friend": [
					"My favorite reading companion—shall we indulge in the classics?",
					"Your presence makes even dull volumes sparkle with life.",
					"I saved us a quiet seat by the poetry corner.",
					"Your passion elevates this place into something magical.",
				    "Let’s discover something timeless together today."
				  ],
				  "Crush": [
					"*soft laugh* I was hoping you’d come today.",
					"You make even the dustiest shelves feel romantic.",
					"I kept glancing your way—it’s hard not to.",
					"Would you join me for tea after we’re done here?",
				    "I think we’d make quite the elegant pair, don’t you?"
				  ],
				  "Dating": [
					"*smiles warmly* There you are, my dearest reader.",
					"Exploring these shelves together is my greatest delight.",
					"*teasing* Shall we race to see who finds the rarest gem?",
					"With you, every page feels like a love letter.",
				    "I’d adore a cozy evening of novels with you tonight."
				  ],
				  "Soulmate": [
					"*gazes tenderly* You are my muse, in books and in life.",
					"Every story pales compared to the one we’re writing together.",
					"We’re a poem, eternal and beautifully composed.",
					"Your mind, your heart… they are my greatest treasures.",
				    "*whispers* You are my forever, my timeless romance."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/vicky/vicky_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/vicky/vicky_dinner.jpeg",
				"park": "res://images/characters/library/vicky/vicky_park.jpeg",
				"beach": "res://images/characters/library/vicky/vicky_beach.jpeg",
				"home": "res://images/characters/library/vicky/vicky_home.jpeg",
				"kiss": "res://images/characters/library/vicky/vicky_kiss.jpeg"
			  }
			},
			{
			"id": "alina_library",
			"name": "Alina",
			"age": 30,
			"height": "160 cm",
			"weight": "54 kg",
			"hair": "Auburn",
			"eyes": "Amber",
			"body": "Curvy",
			"bust": "Large",
			"profession": "Journal",
			"hobby": "Short stories",
			"dialogue_by_stage": {
				  "Stranger": [
					"Oh, hello there. Can I help you find something?",
					"This is one of my favorite sections—it’s so peaceful.",
					"I don’t believe we’ve met before. New to the library?",
				    "Careful with that one—it’s delicate, but worth the read."
				  ],
				  "Acquaintance": [
					"Oh, you’re back! That makes me happy to see.",
					"Did you enjoy the book you borrowed last time?",
					"I’ve set aside a few recommendations you might like.",
				    "You’re starting to feel like a familiar face around here."
				  ],
				  "Friend": [
					"It’s so good to see you again! Found anything special?",
					"You always brighten up the shelves when you’re here.",
					"Want me to share some of my personal favorites?",
				    "You make this quiet place feel a little more alive."
				  ],
				  "Good Friend": [
					"There’s my favorite visitor. Ready to get lost in stories?",
					"I love how you get absorbed when you’re reading—it’s endearing.",
					"I saved us a spot with the comfiest chairs.",
					"Your company makes my day better every time.",
				    "Let’s go on a little book hunt together, shall we?"
				  ],
				  "Crush": [
					"*smiles warmly* I was hoping you’d walk in today.",
					"You somehow make this place feel… warmer.",
					"I caught myself watching you read—it’s charming.",
					"Would you like to share a corner with me for a while?",
				    "Maybe after this, we could grab a quiet cup of tea?"
				  ],
				  "Dating": [
					"*soft laugh* There’s my favorite part of the day.",
					"Reading with you is always so cozy and comforting.",
					"*playfully* Think you can finish your book before I do?",
					"We just fit perfectly—like books and shelves.",
				    "How about a lazy evening with hot chocolate and novels?"
				  ],
				  "Soulmate": [
					"*gentle gaze* My love, ready for another story together?",
					"You’re my safe place, in this library and in life.",
					"Every book feels brighter when I share it with you.",
					"You’re my forever story—the one I’ll never put down.",
				    "*whispers* You are the love I always dreamed I’d find."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/alina/alina_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/alina/alina_dinner.jpeg",
				"park": "res://images/characters/library/alina/alina_park.jpeg",
				"beach": "res://images/characters/library/alina/alina_beach.jpeg",
				"home": "res://images/characters/library/alina/alina_home.jpeg",
				"kiss": "res://images/characters/library/alina/alina_kiss.jpeg"
			  }
			},
			{
			"id": "nami_library",
			"name": "Nami",
			"age": 25,
			"height": "177 cm",
			"weight": "68 kg",
			"hair": "Platinum",
			"eyes": "Ice blue",
			"body": "Slim",
			"bust": "Small",
			"profession": "Fashion designer",
			"hobby": "Drawing clothes",
			"dialogue_by_stage": {
				  "Stranger": [
					"Hmm… you don’t seem like the usual visitor.",
					"Careful—some of these books are… darker than they appear.",
					"New, aren’t you? I notice everything in this place.",
				    "If you’re drawn to mysteries, you’re in the right corner."
				  ],
				  "Acquaintance": [
					"Ah, you’ve returned. Curious. I like that.",
					"You’ve got good instincts—most people avoid these shelves.",
					"So, what did you uncover last time?",
				    "Not many people come back after their first visit here."
				  ],
				  "Friend": [
					"You again. I must admit, I was hoping for that.",
					"You seem to be developing a taste for the obscure.",
					"Shall we dig into something deliciously twisted together?",
				    "I enjoy our little exchanges—they break the monotony."
				  ],
				  "Good Friend": [
					"There’s my favorite seeker of shadows. Found anything intriguing?",
					"You make this place… less lonely, in a good way.",
					"I saved a seat in the quietest corner, just for us.",
					"Your curiosity keeps me entertained—and that’s not easy.",
				    "Let’s chase down something forbidden today, shall we?"
				  ],
				  "Crush": [
					"*smirks* I wondered if you’d wander in again.",
					"You give these shelves a different kind of spark.",
					"I might have been watching you read… it was hard not to.",
					"Care to share my corner? It’s more fun together.",
				    "We could grab a drink later… something stronger than tea."
				  ],
				  "Dating": [
					"*playful grin* There’s my favorite distraction.",
					"Reading with you almost makes me forget the world outside.",
					"Bet I can find something darker than your last pick.",
					"We’re a perfect pair—ink and shadow, mind and heart.",
				    "How about we curl up later with something wickedly good?"
				  ],
				  "Soulmate": [
					"*low voice* You are my greatest story, my rarest find.",
					"With you, even the darkest tales feel beautiful.",
					"We’re bound together, like fate written in ink.",
					"You’re the only light I let into my shadows.",
				    "*whispers* You’re mine, always—page after page, life after life."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/nami/nami_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/nami/nami_dinner.jpeg",
				"park": "res://images/characters/library/nami/nami_park.jpeg",
				"beach": "res://images/characters/library/nami/nami_beach.jpeg",
				"home": "res://images/characters/library/nami/nami_home.jpeg",
				"kiss": "res://images/characters/library/nami/nami_kiss.jpeg"
			  }
			},
			{
			"id": "emma_library",
			"name": "Emma",
			"age": 21,
			"height": "155 cm",
			"weight": "46 kg",
			"hair": "Dark red",
			"eyes": "Golden brown",
			"body": "Slim curvy",
			"bust": "Medium",
			"profession": "Graphics designer",
			"hobby": "Comics",
			"dialogue_by_stage": {
				  "Stranger": [
					"Excuse me—are you treating those books with care?",
					"You’re new here, I assume. Try not to get lost.",
					"History rewards patience. Do you have any?",
				    "If you’re serious about research, I can point you in the right direction."
				  ],
				  "Acquaintance": [
					"Ah, you’ve returned. That shows commitment.",
					"Did you find the material useful last time?",
					"You’re starting to look less lost in these halls.",
				    "I appreciate someone who keeps coming back—it shows discipline."
				  ],
				  "Friend": [
					"Good, you’re here. Ready to dive deeper today?",
					"You have potential. Let’s see how far you’ll go.",
					"I found something that might interest you—want a look?",
				    "You’re learning fast, and I can’t help but be impressed."
				  ],
				  "Good Friend": [
					"There’s my diligent companion. Shall we get to work?",
					"Your persistence is admirable—it’s what I respect most.",
					"I saved a quiet table for us to study properly.",
					"I enjoy these sessions with you—they sharpen my mind too.",
				    "You make this library feel more alive, even to me."
				  ],
				  "Crush": [
					"*softens tone* I was hoping you’d come today.",
					"You make these long hours feel… pleasant, surprisingly.",
					"I caught myself watching you read—it’s endearing.",
					"Would you like to join me? I don’t often share my space.",
				    "Perhaps afterward, we could discuss over dinner?"
				  ],
				  "Dating": [
					"*smiles warmly* There you are. My favorite student of life.",
					"Studying together has become my favorite routine.",
					"*teasing* Careful—you might surpass me at this rate.",
					"We’re an excellent pair—serious minds with warm hearts.",
				    "How about tonight we skip the books and just enjoy each other?"
				  ],
				  "Soulmate": [
					"*gazes fondly* You are my greatest lesson, my timeless discovery.",
					"With you, every day feels like history worth remembering.",
					"We’re writing our own chapter together, page by page.",
					"You inspire me to love as much as you inspire me to think.",
				    "*whispers* You are the one I never knew I was searching for."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/emma/emma_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/emma/emma_dinner.jpeg",
				"park": "res://images/characters/library/emma/emma_park.jpeg",
				"beach": "res://images/characters/library/emma/emma_beach.jpeg",
				"home": "res://images/characters/library/emma/emma_home.jpeg",
				"kiss": "res://images/characters/library/emma/emma_kiss.jpeg"
			  }
			},
			{
			"id": "donna_library",
			"name": "Donna",
			"age": 32,
			"height": "163 cm",
			"weight": "52 kg",
			"hair": "Jet black",
			"eyes": "Deep blue",
			"body": "Slim",
			"bust": "Small",
			"profession": "Violinist",
			"hobby": "Composing music",
			"dialogue_by_stage": {
				  "Stranger": [
					"Hey there, looking for something chic to read?",
					"You must be new here—I don’t usually see faces like yours around.",
					"Careful with those books—they’re classics, not accessories.",
				    "If you want guidance, I can show you some hidden gems."
				  ],
				  "Acquaintance": [
					"Ah, you’re back! I like seeing familiar faces.",
					"You’re starting to find your rhythm navigating these shelves.",
					"I have a few recommendations that match your style.",
				    "You’ve got good taste—it’s noticeable."
				  ],
				  "Friend": [
					"There you are! Found anything fabulous today?",
					"I love how you explore—so confident and curious.",
					"Want to check out some rare editions together?",
				    "Being around you makes this library feel lively."
				  ],
				  "Good Friend": [
					"My favorite trendsetter in the stacks! Shall we explore?",
					"I saved us the best spot by the window—it’s perfect light.",
					"You always bring energy wherever you go.",
					"Let’s discover something rare and inspiring today.",
				    "Your style and taste make even dusty books exciting."
				  ],
				  "Crush": [
					"*smiles playfully* I hoped I’d see you again today.",
					"You make the quiet of this place feel electric.",
					"I caught myself glancing at you more than the pages…",
					"Would you like to sit together? It’ll be fun.",
				    "Afterwards, maybe a coffee? I’d love your company."
				  ],
				  "Dating": [
					"*grinning* There’s my favorite muse!",
					"Exploring these shelves with you is always a highlight.",
					"*teasing* Bet I can find something even more stylish than your pick.",
					"We’re perfect together—intellect and flair combined.",
				    "How about a cozy evening with books and tea tonight?"
				  ],
				  "Soulmate": [
					"*soft gaze* You’re my greatest inspiration, in style and life.",
					"Every moment we share feels like a curated masterpiece.",
					"We’re a story no one else could ever write.",
					"Your presence brightens even the quietest corners.",
				    "*whispers* You are my forever, in fashion, in books, in heart."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/donna/donna_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/donna/donna_dinner.jpeg",
				"park": "res://images/characters/library/donna/donna_park.jpeg",
				"beach": "res://images/characters/library/donna/donna_beach.jpeg",
				"home": "res://images/characters/library/donna/donna_home.jpeg",
				"kiss": "res://images/characters/library/donna/donna_kiss.jpeg"
			  }
			},
			{
			"id": "evelyn_library",
			"name": "Evelyn",
			"age": 43,
			"height": "164 cm",
			"weight": "54 kg",
			"hair": "Ash brown",
			"eyes": "Grey",
			"body": "Balanced",
			"bust": "Large",
			"profession": "Archivist",
			"hobby": "Bouquet making",
			"dialogue_by_stage": {
				  "Stranger": [
					"Welcome, dear. Can I help you find something special?",
					"This section holds some hidden treasures—take your time.",
					"You must be new here. Let me know if you need guidance.",
				    "Careful with these older volumes—they’ve seen many hands."
				  ],
				  "Acquaintance": [
					"Ah, back again! I’m glad to see a familiar face.",
					"I saved a few titles you might enjoy since last time.",
					"You’re beginning to know your way around nicely.",
				    "It’s wonderful to see your curiosity blossom."
				  ],
				  "Friend": [
					"There you are! Found any captivating stories today?",
					"I love how eagerly you explore the shelves.",
					"Would you like me to share some of my personal favorites?",
				    "Your presence brings warmth to this quiet space."
				  ],
				  "Good Friend": [
					"My dear friend, ready to dive into some treasures together?",
					"I saved the coziest spot for us—perfect for reading.",
					"You have such a keen eye for books—it’s delightful.",
					"I always look forward to our library sessions.",
				    "Let’s discover something memorable today, shall we?"
				  ],
				  "Crush": [
					"*soft smile* I was hoping you’d stop by today.",
					"You make even ordinary books feel extraordinary.",
					"I found myself glancing at you more than the shelves.",
					"Shall we share this table and enjoy the quiet together?",
				    "Perhaps afterward we could enjoy a warm drink together?"
				  ],
				  "Dating": [
					"*gentle laugh* There’s my favorite companion.",
					"Reading together has become a cherished part of my day.",
					"*playful* Careful, or I’ll assign you a mountain of books!",
					"We’re a perfect pair—wisdom and heart intertwined.",
				    "How about a cozy evening with tea and stories tonight?"
				  ],
				  "Soulmate": [
					"*warm gaze* You are my greatest joy, in books and in life.",
					"Every story we share feels more meaningful together.",
					"We’re writing a timeless tale, hand in hand.",
					"Your heart and mind inspire me endlessly.",
				    "*whispers* You are my forever companion, my ultimate story."
				  ]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/library/evelyn/evelyn_main.png",
			  "stats_required": {"knowledge": 10, "intelligence": 10},
			  "date_images": {
				"dinner": "res://images/characters/library/evelyn/evelyn_dinner.jpeg",
				"park": "res://images/characters/library/evelyn/evelyn_park.jpeg",
				"beach": "res://images/characters/library/evelyn/evelyn_beach.jpeg",
				"home": "res://images/characters/library/evelyn/evelyn_home.jpeg",
				"kiss": "res://images/characters/library/evelyn/evelyn_kiss.jpeg"
			  }
			}
		] as Array[Dictionary]
	},
	"Cafeteria": {
		"name": "Cafeteria",
		"type": "normal",
		"scene_path": "res://scenes/locations/cafeteria_scene.tscn",
		"activities": [
			{"name": "Order Coffee", "description": "Quick energy boost.", "effects": {"endurance": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Chat with Friends", "description": "Improve your communication skills.", "effects": {"communication": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "People Watch", "description": "Observe and learn social cues.", "effects": {"persuasion": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": [
			{
			  "id": "hikari_cafeteria",
			  "name": "Hikari",
			  "dialogue_by_stage": {
				"Stranger": [
				  "What can I get for you today?",
				  "First time here? The special’s a great choice!",
				  "Careful with the hot coffee—it’s fresh!",
				  "The cafeteria’s buzzing today, isn’t it?"
				],
				"Acquaintance": [
				  "Hey, you’re back! Usual order or something new?",
				  "Getting the hang of the cafeteria’s menu yet?",
				  "Nice to see you again—keeps my day bright!",
				  "Any food cravings today? I’ve got recommendations."
				],
				"Friend": [
				  "Yo, good to see you! Hungry for something awesome?",
				  "You’re starting to make this place feel lively!",
				  "Wanna try the chef’s secret dish today?",
				  "Your smile’s making my shift way better."
				],
				"Good Friend": [
				  "My favorite customer! What’s the mood today?",
				  "I love how you always bring good vibes here.",
				  "Let’s pick something delicious to share, yeah?",
				  "You make my day behind the counter so fun!",
				  "Saved you the best dessert on the menu."
				],
				"Crush": [
				  "*smiles shyly* Was hoping you’d swing by today.",
				  "You look... great. I mean, ready for a great meal!",
				  "I might’ve watched you pick your tray... just curious.",
				  "Wanna hang out here sometime, just us?",
				  "How about a milkshake after my shift? My treat."
				],
				"Dating": [
				  "*grins* There’s my favorite person! *quick wink*",
				  "Serving you is the highlight of my day, love.",
				  "*teasing* Bet I can guess your order today, babe.",
				  "We’re the best team, in the cafeteria and out.",
				  "Fancy a cozy dinner at home after my shift?"
				],
				"Soulmate": [
				  "*beaming* My heart’s here! Ready for our daily catch-up?",
				  "Your presence makes every dish taste sweeter.",
				  "We’re perfect together, sharing meals and moments.",
				  "You inspire me, from the counter to forever.",
				  "*softly* You’re my favorite part of every day, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/cafeteria/hikari/hikari_main.png",
			  "stats_required": {"charisma": 1, "communication": 1},
			  "date_images": {
				"dinner": "res://images/characters/cafeteria/hikari/hikari_dinner.png",
				"park": "res://images/characters/cafeteria/hikari/hikari_park.png",
				"beach": "res://images/characters/cafeteria/hikari/hikari_beach.png",
				"home": "res://images/characters/cafeteria/hikari/hikari_home.png",
				"kiss": "res://images/characters/cafeteria/hikari/hikari_kiss.png"
			  }
			},
			{
			  "id": "victoria_cafeteria",
			  "name": "Victoria",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Oh, haven’t seen you at this table before!",
				  "The specials here are always worth a try.",
				  "New to this café? It’s got a great vibe.",
				  "Try the latte—it’s my go-to every morning."
				],
				"Acquaintance": [
				  "Hey, you’re becoming a café regular like me!",
				  "Found a favorite spot to sit yet?",
				  "Nice to see you again—makes this place cozier.",
				  "Got a favorite dish here? I’m curious."
				],
				"Friend": [
				  "Yo, great to see you! Grabbing your usual today?",
				  "You make this café feel like a second home!",
				  "Wanna try a new menu item with me today?",
				  "Your energy really livens up this place."
				],
				"Good Friend": [
				  "My café buddy! What’s the plan today?",
				  "I love how we always have the best chats here.",
				  "Let’s grab our favorite booth and catch up!",
				  "You make every coffee run so much fun.",
				  "Saved us a spot by the window—best view!"
				],
				"Crush": [
				  "*smiles warmly* Was hoping you’d show up today.",
				  "You make this café look... even better somehow.",
				  "Caught myself glancing at you over my coffee.",
				  "Wanna share a table more often? It’s nice.",
				  "How about we stay for dessert together?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick hug*",
				  "Chatting with you over coffee is my daily joy.",
				  "*teasing* Bet I can pick a better pastry than you.",
				  "We’re the perfect café duo, you and me.",
				  "Wanna head to my place for a cozy evening?"
				],
				"Soulmate": [
				  "*beaming* My heart’s here! Ready for our café date?",
				  "Every moment with you feels like a warm sip.",
				  "We’re a perfect blend, like coffee and sunrise.",
				  "You make my world brighter, from café to forever.",
				  "*softly* You’re my favorite part of every day."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/cafeteria/victoria/victoria_main.png",
			  "stats_required": {"charisma": 10, "communication": 10},
			  "date_images": {
				"dinner": "res://images/characters/cafeteria/victoria/victoria_dinner.png",
				"park": "res://images/characters/cafeteria/victoria/victoria_park.png",
				"beach": "res://images/characters/cafeteria/victoria/victoria_beach.png",
				"home": "res://images/characters/cafeteria/victoria/victoria_home.png",
				"kiss": "res://images/characters/cafeteria/victoria/victoria_kiss.png"
			  }
			},
			{
			  "id": "lola_cafeteria",
			  "name": "Lola",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Hey, new face! What’s your go-to café order?",
				  "This place has the best pastries—try one!",
				  "First time here? The vibe’s pretty chill.",
				  "The coffee’s fresh—perfect for a quick boost!"
				],
				"Acquaintance": [
				  "Back again? You’re starting to fit right in!",
				  "Found a favorite table in the café yet?",
				  "Good to see you—makes my day a bit brighter!",
				  "Any menu items catching your eye today?"
				],
				"Friend": [
				  "Hey, great to see you! Ready for a coffee break?",
				  "You’re making this café my favorite hangout!",
				  "Wanna try something new off the menu today?",
				  "Your energy’s always a pick-me-up in here."
				],
				"Good Friend": [
				  "My café pal! What’s the plan for today?",
				  "I love our little chats over coffee—best part of my day.",
				  "Let’s grab that cozy corner booth together!",
				  "You make every café visit so much fun.",
				  "Saved us the best spot by the window."
				],
				"Crush": [
				  "*smiles softly* Kinda hoped you’d drop by today.",
				  "You make this place feel... extra special.",
				  "Caught myself sneaking a glance at you earlier.",
				  "Wanna share a table and chat more often?",
				  "How about sticking around for dessert with me?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick squeeze*",
				  "Hanging with you makes every coffee taste better.",
				  "*teasing* Bet I can pick a tastier dessert than you!",
				  "We’re the perfect pair, in the café and out.",
				  "Wanna head home for a cozy night after this?"
				],
				"Soulmate": [
				  "*warm smile* My heart’s here—ready for our café moment?",
				  "Every sip with you feels like pure happiness.",
				  "We’re a perfect match, like coffee and morning light.",
				  "You light up my life, from this café to forever.",
				  "*softly* You’re my everything, every day, every sip."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/cafeteria/lola/lola_main.png",
			  "stats_required": {"charisma": 1, "communication": 1},
			  "date_images": {
				"dinner": "res://images/characters/cafeteria/lola/lola_dinner.jpeg",
				"park": "res://images/characters/cafeteria/lola/lola_park.jpeg",
				"beach": "res://images/characters/cafeteria/lola/lola_beach.jpeg",
				"home": "res://images/characters/cafeteria/lola/lola_home.jpeg",
				"kiss": "res://images/characters/cafeteria/lola/lola_kiss.jpeg"
			  }
			}
		] as Array[Dictionary]
	},
	"Park": {
		"name": "Park",
		"type": "normal",
		"scene_path": "res://scenes/locations/park_scene.tscn",
		"activities": [
			{"name": "Jogging", "description": "Build endurance with a run.", "effects": {"endurance": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Meditate", "description": "Find inner peace and wisdom.", "effects": {"wisdom": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Stroll around", "description": "Enjoy the scenery and boost charisma.", "effects": {"charisma": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Picnic", "description": "Organize a fun outing.", "effects": {"leadership": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": [
			{
			  "id": "bridget_park",
			  "name": "Bridget",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Beautiful day for a walk, isn’t it?",
				  "First time in the park? It’s a great spot to unwind!",
				  "The fresh air here always lifts my spirits.",
				  "Careful on the trails—some spots are a bit uneven!"
				],
				"Acquaintance": [
				  "Hey, you’re back! Another park day, huh?",
				  "Getting to know the best paths around here yet?",
				  "Nice to see you again—it’s like the park’s brighter!",
				  "Got a favorite spot here? I’m curious."
				],
				"Friend": [
				  "Yo, great to see you! Ready for a park adventure?",
				  "You’re starting to make this place feel like home!",
				  "Wanna explore a new trail together today?",
				  "Your energy makes these walks so much fun."
				],
				"Good Friend": [
				  "My park buddy! What’s the vibe today?",
				  "I love how you make every stroll so enjoyable.",
				  "Let’s find a quiet spot to hang out, yeah?",
				  "You make the park my favorite place to be!",
				  "Saved us a great spot by the lake."
				],
				"Crush": [
				  "*smiles softly* Was hoping I’d run into you here.",
				  "You make this park look... even more beautiful.",
				  "Caught myself watching you by the fountain earlier.",
				  "Wanna walk these paths together more often?",
				  "How about we grab ice cream after our stroll?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick hug*",
				  "Walking with you makes every path perfect.",
				  "*teasing* Bet I can race you to the oak tree!",
				  "We’re the best team, in the park and out.",
				  "Fancy a cozy picnic at home after this?"
				],
				"Soulmate": [
				  "*warm smile* My heart’s here—ready for our park date?",
				  "Every step with you feels like pure joy.",
				  "We’re a perfect pair, like sunlight and open trails.",
				  "You make my world brighter, from park to forever.",
				  "*softly* You’re my favorite adventure, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/park/bridget/bridget_main.png",
			  "stats_required": {"endurance": 1},
			  "date_images": {
				"dinner": "res://images/characters/park/bridget/bridget_dinner.png",
				"park": "res://images/characters/park/bridget/bridget_park.png",
				"beach": "res://images/characters/park/bridget/bridget_beach.png",
				"home": "res://images/characters/park/bridget/bridget_home.png",
				"kiss": "res://images/characters/park/bridget/bridget_kiss.png"
			  }
			},
			{
			  "id": "rikka_park",
			  "name": "Rikka",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Nice day for a walk, don’t you think?",
				  "New around here? This park’s got some great trails.",
				  "The air’s so crisp today—perfect for a stroll.",
				  "Watch your step on the paths; they can be tricky."
				],
				"Acquaintance": [
				  "Back for another park day? Good to see you!",
				  "Finding your favorite spots in the park yet?",
				  "You’re starting to blend in with the regulars!",
				  "Got any trail recommendations? I’m all ears."
				],
				"Friend": [
				  "Hey, you’re here! Ready for a park adventure?",
				  "You’re getting good at navigating these trails!",
				  "Wanna check out a new path together today?",
				  "Your vibe makes these walks way more fun."
				],
				"Good Friend": [
				  "My park partner! What’s up for today?",
				  "I love how you make every stroll exciting.",
				  "Let’s find a cool spot to chill, yeah?",
				  "You make this park my favorite place to be!",
				  "Saved us a prime bench by the pond."
				],
				"Crush": [
				  "*small smile* Hoped I’d catch you here today.",
				  "You make this park feel... kinda special.",
				  "Might’ve glanced at you by the trees earlier.",
				  "Wanna wander these trails together more often?",
				  "How about grabbing a smoothie after our walk?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick nudge*",
				  "Strolling with you is the best part of my day.",
				  "*teasing* Think you can keep up with me today?",
				  "We’re perfect together, on trails or anywhere.",
				  "Wanna head home for a cozy night after?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our park day?",
				  "Every step with you feels like a dream.",
				  "We’re a perfect match, like breeze and open paths.",
				  "You light up my life, from park trails to forever.",
				  "*softly* You’re my greatest adventure, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/park/rikka/rikka_main.png",
			  "stats_required": {"endurance": 10, "balance": 10},
			  "date_images": {
				"dinner": "res://images/characters/park/rikka/rikka_dinner.png",
				"park": "res://images/characters/park/rikka/rikka_park.png",
				"beach": "res://images/characters/park/rikka/rikka_beach.png",
				"home": "res://images/characters/park/rikka/rikka_home.png",
				"kiss": "res://images/characters/park/rikka/rikka_kiss.png"
			  }
			}
		] as Array[Dictionary]
	},
	"Mall": {
		"name": "Mall",
		"type": "normal",
		"scene_path": "res://scenes/locations/mall_scene.tscn",
		"activities": [
			{"name": "Window Shopping", "description": "Practice persuasion skills.", "effects": {"persuasion": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Browse Electronics", "description": "Learn about new tech.", "effects": {"intelligence": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Try on Clothes", "description": "Boost your charisma.", "effects": {"charisma": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Eat Food Court", "description": "Recharge with a tasty meal.", "effects": {"endurance": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": [
			{
			  "id": "marina_mall",
			  "name": "Marina",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Found anything good in the stores today?",
				  "New around here? The mall’s got some great deals!",
				  "I’m always hunting for a bargain—any tips?",
				  "This place is huge—don’t get lost in the shops!"
				],
				"Acquaintance": [
				  "Hey, you’re back! Snagged any cool finds yet?",
				  "Getting the hang of navigating this mall?",
				  "Nice to see you again—makes shopping more fun!",
				  "Spotted any good sales? I’m all about the deals."
				],
				"Friend": [
				  "Yo, good to see you! Ready for a shopping spree?",
				  "You’re starting to know all the best stores!",
				  "Wanna check out a new shop with me today?",
				  "Your style’s on point—love your mall vibe."
				],
				"Good Friend": [
				  "My shopping buddy! What’s the plan today?",
				  "I love how you make these mall trips a blast.",
				  "Let’s hit up that new boutique together, yeah?",
				  "You make every store visit so much better!",
				  "Saved us a spot at the food court’s best table."
				],
				"Crush": [
				  "*smiles shyly* Was hoping I’d bump into you here.",
				  "You make this mall look... way more interesting.",
				  "Caught myself glancing at you by the storefront.",
				  "Wanna shop together more often? It’s fun with you.",
				  "How about grabbing a smoothie after we’re done?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick hug*",
				  "Shopping with you is the best part of my day.",
				  "*teasing* Bet I can find a better deal than you!",
				  "We’re the perfect team, in stores and out.",
				  "Fancy a cozy night at home after this?"
				],
				"Soulmate": [
				  "*warm smile* My heart’s here—ready for our mall date?",
				  "Every moment with you feels like a treasure find.",
				  "We’re a perfect pair, like a sale and a steal.",
				  "You light up my world, from mall to forever.",
				  "*softly* You’re my best find, every day, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/mall/marina/marina_main.png",
			  "stats_required": {"persuasion": 1, "charisma": 1},
			  "date_images": {
				"dinner": "res://images/characters/mall/marina/marina_dinner.png",
				"park": "res://images/characters/mall/marina/marina_park.png",
				"beach": "res://images/characters/mall/marina/marina_beach.png",
				"home": "res://images/characters/mall/marina/marina_home.png",
				"kiss": "res://images/characters/mall/marina/marina_kiss.png"
			  }
			},
			{
			  "id": "louisa_mall",
			  "name": "Louisa",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Spotted any good deals today?",
				  "New to this mall? It’s a shopper’s paradise!",
				  "I’m always on the hunt for a steal—found anything?",
				  "This place can be a maze—stick to the main stores!"
				],
				"Acquaintance": [
				  "Hey, you’re back! Scored any great finds yet?",
				  "Getting the lay of the mall’s best shops?",
				  "Good to see you again—makes these trips fun!",
				  "Know any hidden gem stores? I’m curious."
				],
				"Friend": [
				  "Yo, great to see you! Ready for a shopping haul?",
				  "You’re practically a pro at this mall now!",
				  "Wanna hit up a new store together today?",
				  "Your flair for style totally elevates this place."
				],
				"Good Friend": [
				  "My shopping partner! What’s the plan today?",
				  "I love how you make these mall runs epic.",
				  "Let’s scope out that trendy shop together, yeah?",
				  "You make every store stop so much better!",
				  "Grabbed us a prime spot at the food court."
				],
				"Crush": [
				  "*smiles warmly* Hoped I’d run into you here.",
				  "You make this mall seem... way more exciting.",
				  "Might’ve caught myself staring at you by the display.",
				  "Wanna team up for shopping sprees more often?",
				  "How about coffee after we’re done browsing?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick nudge*",
				  "Hunting deals with you is my favorite adventure.",
				  "*teasing* Bet I can spot a better sale than you!",
				  "We’re the ultimate team, in shops and beyond.",
				  "Fancy a cozy night in after this?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our mall day?",
				  "Every moment with you feels like a perfect find.",
				  "We’re a flawless match, like a sale and a steal.",
				  "You light up my life, from mall aisles to forever.",
				  "*softly* You’re my greatest treasure, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/mall/louisa/louisa_main.png",
			  "stats_required": {"persuasion": 10, "leadership": 10},
			  "date_images": {
				"dinner": "res://images/characters/mall/louisa/louisa_dinner.png",
				"park": "res://images/characters/mall/louisa/louisa_park.png",
				"beach": "res://images/characters/mall/louisa/louisa_beach.png",
				"home": "res://images/characters/mall/louisa/louisa_home.png",
				"kiss": "res://images/characters/mall/louisa/louisa_kiss.png"
			  }
			},
			{
			  "id": "annita_mall",
			  "name": "Annita",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Spotted any good deals today?",
				  "New to this mall? It’s a shopper’s paradise!",
				  "I’m always on the hunt for a steal—found anything?",
				  "This place can be a maze—stick to the main stores!"
				],
				"Acquaintance": [
				  "Hey, you’re back! Scored any great finds yet?",
				  "Getting the lay of the mall’s best shops?",
				  "Good to see you again—makes these trips fun!",
				  "Know any hidden gem stores? I’m curious."
				],
				"Friend": [
				  "Yo, great to see you! Ready for a shopping haul?",
				  "You’re practically a pro at this mall now!",
				  "Wanna hit up a new store together today?",
				  "Your flair for style totally elevates this place."
				],
				"Good Friend": [
				  "My shopping partner! What’s the plan today?",
				  "I love how you make these mall runs epic.",
				  "Let’s scope out that trendy shop together, yeah?",
				  "You make every store stop so much better!",
				  "Grabbed us a prime spot at the food court."
				],
				"Crush": [
				  "*smiles warmly* Hoped I’d run into you here.",
				  "You make this mall seem... way more exciting.",
				  "Might’ve caught myself staring at you by the display.",
				  "Wanna team up for shopping sprees more often?",
				  "How about coffee after we’re done browsing?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick nudge*",
				  "Hunting deals with you is my favorite adventure.",
				  "*teasing* Bet I can spot a better sale than you!",
				  "We’re the ultimate team, in shops and beyond.",
				  "Fancy a cozy night in after this?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our mall day?",
				  "Every moment with you feels like a perfect find.",
				  "We’re a flawless match, like a sale and a steal.",
				  "You light up my life, from mall aisles to forever.",
				  "*softly* You’re my greatest treasure, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/mall/annita/annita_main.png",
			  "stats_required": {"persuasion": 10, "leadership": 10},
			  "date_images": {
				"dinner": "res://images/characters/mall/annita/annita_dinner.jpeg",
				"park": "res://images/characters/mall/annita/annita_park.jpeg",
				"beach": "res://images/characters/mall/annita/annita_beach.jpeg",
				"home": "res://images/characters/mall/annita/annita_home.jpeg",
				"kiss": "res://images/characters/mall/annita/annita_kiss.jpeg"
			  }
			}
		] as Array[Dictionary]
	},
	"Nightclub": {
		"name": "Nightclub",
		"type": "normal",
		"scene_path": "res://scenes/locations/nightclub_scene.tscn",
		"activities": [
			{"name": "Dance", "description": "Burn energy on the dance floor.", "effects": {"endurance": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Flirt", "description": "Practice your social charm.", "effects": {"intelligence": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Karaoke", "description": "Show off your singing skills.", "effects": {"charisma": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Drink", "description": "Socialize and unwind.", "effects": {"leadership": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": [
			{
			  "id": "maya_nightclub",
			  "name": "Maya",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Hey, you having fun out there on the dance floor?",
				  "First time at this club? It’s got a killer vibe!",
				  "This song’s my jam—wanna dance to it?",
				  "The energy here’s electric, isn’t it?"
				],
				"Acquaintance": [
				  "Yo, you’re back! Getting into the club groove yet?",
				  "Spotted you dancing—you’re not bad!",
				  "Good to see you again—makes the night better!",
				  "Got a favorite song to request tonight?"
				],
				"Friend": [
				  "Hey, great to see you! Ready to light up the floor?",
				  "You’re starting to own this nightclub vibe!",
				  "Wanna hit the dance floor together tonight?",
				  "Your energy’s making this place pop!"
				],
				"Good Friend": [
				  "My dance buddy! What’s the mood tonight?",
				  "I love how you bring the party wherever you go.",
				  "Let’s own the floor with some epic moves, yeah?",
				  "You make every night here unforgettable!",
				  "Saved us a spot by the DJ booth—prime location!"
				],
				"Crush": [
				  "*smiles playfully* Was hoping you’d show up tonight.",
				  "You look... amazing under these club lights.",
				  "Caught myself watching you dance... it’s mesmerizing.",
				  "Wanna dance closer together for the next song?",
				  "How about grabbing a drink after this set?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick twirl*",
				  "Dancing with you is the highlight of my night.",
				  "*teasing* Think you can keep up with my moves, babe?",
				  "We’re the hottest duo on this dance floor.",
				  "Wanna head home for a chill night after this?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our dance?",
				  "Every beat with you feels like pure magic.",
				  "We’re a perfect rhythm, in the club and in life.",
				  "You light up my world, from dance floor to forever.",
				  "*softly* You’re my favorite song, now and always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/nightclub/maya/maya_main.png",
			  "stats_required": {"charisma": 1, "endurance": 1},
			  "date_images": {
				"dinner": "res://images/characters/nightclub/maya/maya_dinner.png",
				"park": "res://images/characters/nightclub/maya/maya_park.png",
				"beach": "res://images/characters/nightclub/maya/maya_beach.png",
				"home": "res://images/characters/nightclub/maya/maya_home.png",
				"kiss": "res://images/characters/nightclub/maya/maya_kiss.png"
			  }
			},
			{
			  "id": "melina_nightclub",
			  "name": "Melina",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Hey, you enjoying the vibe tonight?",
				  "First time here? This club’s got killer energy!",
				  "This track’s my jam—makes me wanna dance!",
				  "The dance floor’s calling—ready to join in?"
				],
				"Acquaintance": [
				  "Back for more? You’re catching the club fever!",
				  "Noticed you moving out there—nice rhythm!",
				  "Good to see you again—lights up the night!",
				  "Got a go-to dance move yet? Show me sometime."
				],
				"Friend": [
				  "Yo, you’re here! Ready to tear up the dance floor?",
				  "You’re getting that nightclub glow—love it!",
				  "Wanna try some new moves together tonight?",
				  "Your energy’s infectious—makes this place pop!"
				],
				"Good Friend": [
				  "My dance partner! What’s the beat tonight?",
				  "I love how you make every night here epic.",
				  "Let’s steal the spotlight on the floor, yeah?",
				  "You make dancing here so much more fun!",
				  "Saved us a prime spot near the stage."
				],
				"Crush": [
				  "*smiles playfully* Hoped I’d see you here tonight.",
				  "You look... incredible under these lights.",
				  "Might’ve been watching your moves... they’re fire.",
				  "Wanna dance a little closer for the next song?",
				  "How about a drink after we burn up the floor?"
				],
				"Dating": [
				  "*grins* My favorite dancer’s here! *quick spin*",
				  "Hitting the floor with you is my night’s highlight.",
				  "*teasing* Think you can match my moves, love?",
				  "We’re the hottest duo in this club, hands down.",
				  "Wanna chill at home after we dance the night away?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our dance?",
				  "Every move with you feels like pure magic.",
				  "We’re in perfect sync, on the floor and in life.",
				  "You light up my world, from nightclub to forever.",
				  "*softly* You’re my rhythm, my love, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/nightclub/melina/melina_main.png",
			  "stats_required": {"charisma": 5, "endurance": 5},
			  "date_images": {
				"dinner": "res://images/characters/nightclub/melina/melina_dinner.png",
				"park": "res://images/characters/nightclub/melina/melina_park.png",
				"beach": "res://images/characters/nightclub/melina/melina_beach.png",
				"home": "res://images/characters/nightclub/melina/melina_home.png",
				"kiss": "res://images/characters/nightclub/melina/melina_kiss.png"
			  }
			},
			{
			  "id": "alice_nightclub",
			  "name": "Alice",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Hey, you vibing with the music tonight?",
				  "New to this club? It’s got an unreal energy!",
				  "This track’s a banger—makes me wanna move!",
				  "The dance floor’s alive—gonna join the party?"
				],
				"Acquaintance": [
				  "Yo, you’re back! Starting to feel the club’s pulse?",
				  "Caught you grooving out there—not bad at all!",
				  "Good to see you—makes the night more electric!",
				  "Got a favorite beat to dance to yet?"
				],
				"Friend": [
				  "Hey, great to see you! Ready to own the dance floor?",
				  "You’re totally getting the nightclub rhythm now!",
				  "Wanna try some slick moves together tonight?",
				  "Your vibe’s lighting up this whole place!"
				],
				"Good Friend": [
				  "My dance floor partner! What’s the energy tonight?",
				  "I love how you make every club night epic.",
				  "Let’s steal the show with some killer moves, yeah?",
				  "You make this place feel like the ultimate party!",
				  "Saved us a sweet spot right by the speakers."
				],
				"Crush": [
				  "*smiles slyly* Was hoping you’d light up the club tonight.",
				  "You look... unreal under these neon lights.",
				  "Might’ve been staring at your moves... they’re fire.",
				  "Wanna dance a bit closer for this next track?",
				  "How about a drink to cool off after dancing?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick spin*",
				  "Dancing with you makes my night complete.",
				  "*teasing* Bet I can outdance you tonight, love!",
				  "We’re the hottest pair on this floor, no contest.",
				  "Wanna head home for a cozy vibe after this?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our night?",
				  "Every move with you feels like a perfect beat.",
				  "We’re in sync, on the dance floor and in life.",
				  "You light up my world, from club lights to forever.",
				  "*softly* You’re my favorite rhythm, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/nightclub/alice/alice_main.png",
			  "stats_required": {"charisma": 25, "endurance": 25, "balance": 25},
			  "date_images": {
				"dinner": "res://images/characters/nightclub/alice/alice_dinner.png",
				"park": "res://images/characters/nightclub/alice/alice_park.png",
				"beach": "res://images/characters/nightclub/alice/alice_beach.png",
				"home": "res://images/characters/nightclub/alice/alice_home.png",
				"kiss": "res://images/characters/nightclub/alice/alice_kiss.png"
			  }
			}
		] as Array[Dictionary]
	},
	"University": {
		"name": "University",
		"type": "normal",
		"scene_path": "res://scenes/locations/university_scene.tscn",
		"activities": [
			{"name": "Attend lecture", "description": "Gain knowledge from academics.", "effects": {"knowledge": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Club activity", "description": "Engage in extracurriculars.", "effects": {"intelligence": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Give exams", "description": "Test your knowledge.", "effects": {"logic": 0.02}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Socialize", "description": "Network and build connections.", "effects": {"communication": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": [
			{
			  "id": "sofia_university",
			  "name": "Sofia",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Another day, another class—what’s your schedule like?",
				  "New around campus? The library’s a lifesaver!",
				  "What’s your major? I’m curious about you.",
				  "This lecture hall’s always packed—grab a seat early!"
				],
				"Acquaintance": [
				  "Hey, you’re back! Surviving those uni deadlines?",
				  "Getting the hang of navigating campus yet?",
				  "Nice to see you again—makes classes less dull!",
				  "Need study tips? I’ve got a few up my sleeve."
				],
				"Friend": [
				  "Yo, great to see you! Ready to ace today’s lecture?",
				  "You’re killing it with those study sessions!",
				  "Wanna hit the library for a group study later?",
				  "Your brain’s on fire—love your class insights!"
				],
				"Good Friend": [
				  "My study buddy! What’s the plan for today?",
				  "I love how you make even tough classes fun.",
				  "Let’s grab a coffee and cram for that exam, yeah?",
				  "You make uni life so much brighter!",
				  "Saved us a spot in the best study lounge."
				],
				"Crush": [
				  "*smiles softly* Was hoping I’d see you on campus today.",
				  "You make these lecture halls feel... kinda special.",
				  "Caught myself glancing at you during class.",
				  "Wanna study together more often? It’s better with you.",
				  "How about coffee after class, just us?"
				],
				"Dating": [
				  "*grins* My favorite scholar’s here! *quick hug*",
				  "Studying with you is the best part of my day.",
				  "*teasing* Bet I can ace this quiz faster than you!",
				  "We’re the perfect team, in class and out.",
				  "Wanna chill at home with some notes tonight?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our uni adventure?",
				  "Every moment with you feels like a perfect lesson.",
				  "We’re a brilliant pair, in studies and in life.",
				  "You inspire me, from lecture halls to forever.",
				  "*softly* You’re my favorite subject, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/university/sofia/sofia_main.png",
			  "stats_required": {"intelligence": 1, "knowledge": 1},
			  "date_images": {
				"dinner": "res://images/characters/university/sofia/sofia_dinner.png",
				"park": "res://images/characters/university/sofia/sofia_park.png",
				"beach": "res://images/characters/university/sofia/sofia_beach.png",
				"home": "res://images/characters/university/sofia/sofia_home.png",
				"kiss": "res://images/characters/university/sofia/sofia_kiss.png"
			  }
			},
			{
			  "id": "tania_university",
			  "name": "Tania",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Another day, another class—what’s your major?",
				  "New to campus? The library’s a great spot to start.",
				  "This place can be intense—found your groove yet?",
				  "The coffee shop’s a lifesaver during midterms!"
				],
				"Acquaintance": [
				  "Hey, you’re back! Surviving those uni assignments?",
				  "Getting used to the campus chaos yet?",
				  "Nice to see you again—makes lectures less boring!",
				  "Need a study hack? I’ve got a few tricks."
				],
				"Friend": [
				  "Yo, good to see you! Ready to tackle today’s class?",
				  "Your notes are on point—mind sharing sometime?",
				  "Wanna join a study group at the library later?",
				  "Your ideas in class always spark something cool!"
				],
				"Good Friend": [
				  "My study partner! What’s on the uni agenda today?",
				  "I love how you make even tough classes fun.",
				  "Let’s hit the café and prep for that quiz, yeah?",
				  "You make this campus feel like home!",
				  "Saved us a spot in the best study room."
				],
				"Crush": [
				  "*smiles softly* Was hoping I’d see you around today.",
				  "You make these lecture halls way more interesting.",
				  "Might’ve caught myself staring during discussion.",
				  "Wanna team up for studying more often? It’s nice.",
				  "How about grabbing tea after class, just us?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick hug*",
				  "Cramming with you is the best part of uni.",
				  "*teasing* Bet I can outsmart you in this debate!",
				  "We’re a perfect duo, in class and beyond.",
				  "Wanna relax at home with some books tonight?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our campus day?",
				  "Every moment with you feels like a masterclass in joy.",
				  "We’re a brilliant team, in studies and in life.",
				  "You inspire me, from lecture notes to forever.",
				  "*softly* You’re my favorite lesson, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/university/tania/tania_main.png",
			  "stats_required": {"intelligence": 1, "knowledge": 1},
			  "date_images": {
				"dinner": "res://images/characters/university/tania/tania_dinner.png",
				"park": "res://images/characters/university/tania/tania_park.png",
				"beach": "res://images/characters/university/tania/tania_beach.png",
				"home": "res://images/characters/university/tania/tania_home.png",
				"kiss": "res://images/characters/university/tania/tania_kiss.png"
			  }
			},
			{
			  "id": "trinity_university",
			  "name": "Trinity",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Another day, another class—what’s your schedule like?",
				  "New around campus? The library’s a lifesaver!",
				  "What’s your major? I’m curious about you.",
				  "This lecture hall’s always packed—grab a seat early!"
				],
				"Acquaintance": [
				  "Hey, you’re back! Surviving those uni deadlines?",
				  "Getting the hang of navigating campus yet?",
				  "Nice to see you again—makes classes less dull!",
				  "Need study tips? I’ve got a few up my sleeve."
				],
				"Friend": [
				  "Yo, great to see you! Ready to ace today’s lecture?",
				  "You’re killing it with those study sessions!",
				  "Wanna hit the library for a group study later?",
				  "Your brain’s on fire—love your class insights!"
				],
				"Good Friend": [
				  "My study buddy! What’s the plan for today?",
				  "I love how you make even tough classes fun.",
				  "Let’s grab a coffee and cram for that exam, yeah?",
				  "You make uni life so much brighter!",
				  "Saved us a spot in the best study lounge."
				],
				"Crush": [
				  "*smiles softly* Was hoping I’d see you on campus today.",
				  "You make these lecture halls feel... kinda special.",
				  "Caught myself glancing at you during class.",
				  "Wanna study together more often? It’s better with you.",
				  "How about coffee after class, just us?"
				],
				"Dating": [
				  "*grins* My favorite scholar’s here! *quick hug*",
				  "Studying with you is the best part of my day.",
				  "*teasing* Bet I can ace this quiz faster than you!",
				  "We’re the perfect team, in class and out.",
				  "Wanna chill at home with some notes tonight?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our uni adventure?",
				  "Every moment with you feels like a perfect lesson.",
				  "We’re a brilliant pair, in studies and in life.",
				  "You inspire me, from lecture halls to forever.",
				  "*softly* You’re my favorite subject, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/university/trinity/trinity_main.png",
			  "stats_required": {"intelligence": 1, "knowledge": 1},
			  "date_images": {
				"dinner": "res://images/characters/university/trinity/trinity_dinner.jpeg",
				"park": "res://images/characters/university/trinity/trinity_park.jpeg",
				"beach": "res://images/characters/university/trinity/trinity_beach.jpeg",
				"home": "res://images/characters/university/trinity/trinity_home.jpeg",
				"kiss": "res://images/characters/university/trinity/trinity_kiss.jpeg"
			  }
			}
		] as Array[Dictionary]
	},
	"Cinema": {
		"name": "Cinema",
		"type": "normal",
		"scene_path": "res://scenes/locations/cinema_scene.tscn",
		"activities": [
			{"name": "Watch Movie", "description": "Enjoy a film.", "effects": {"knowledge": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
			{"name": "Discuss Film", "description": "Analyze and share thoughts.", "effects": {"communication": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_REGULAR_ACTIVITY},
		] as Array[Dictionary],
		"characters": [
			{
			  "id": "aria_cinema",
			  "name": "Aria",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Which movie are you seeing today?",
				  "New to this cinema? They’ve got the best popcorn!",
				  "I hope this one’s a blockbuster—any bets?",
				  "The seats in the back row are prime—trust me!"
				],
				"Acquaintance": [
				  "Hey, you’re back! Catch any good films lately?",
				  "Getting the hang of picking the best showtimes?",
				  "Nice to see you again—makes movie nights better!",
				  "Got a favorite genre? I’m curious about your taste."
				],
				"Friend": [
				  "Yo, great to see you! Ready for a cinematic adventure?",
				  "You’re starting to know all the best theater spots!",
				  "Wanna catch a new release together today?",
				  "Your movie picks always make for a fun time!"
				],
				"Good Friend": [
				  "My movie buddy! What’s the vibe for today’s screening?",
				  "I love how you make every film feel like an event.",
				  "Let’s grab the best seats and share some popcorn, yeah?",
				  "You make these cinema trips so much fun!",
				  "Saved us a spot in the perfect row."
				],
				"Crush": [
				  "*smiles softly* Was hoping I’d see you at the cinema today.",
				  "You make these movie nights feel... extra special.",
				  "Caught myself glancing at you in the lobby earlier.",
				  "Wanna share a movie and snacks more often?",
				  "How about coffee after the credits roll?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick hug*",
				  "Watching movies with you is my favorite date.",
				  "*teasing* Bet I can guess the plot twist before you!",
				  "We’re the perfect pair, in theaters and out.",
				  "Wanna cozy up at home for a movie marathon later?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our movie date?",
				  "Every film with you feels like a blockbuster moment.",
				  "We’re a perfect match, like popcorn and a great plot.",
				  "You light up my life, from cinema screens to forever.",
				  "*softly* You’re my favorite story, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/cinema/aria/aria_main.png",
			  "stats_required": {"communication": 1},
			  "date_images": {
				"dinner": "res://images/characters/cinema/aria/aria_dinner.png",
				"park": "res://images/characters/cinema/aria/aria_park.png",
				"beach": "res://images/characters/cinema/aria/aria_beach.png",
				"home": "res://images/characters/cinema/aria/aria_home.png",
				"kiss": "res://images/characters/cinema/aria/aria_kiss.png"
			  }
			},
			{
			  "id": "hilda_cinema",
			  "name": "Hilda",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Which movie are you catching today?",
				  "First time at this theater? It’s got great vibes!",
				  "Hoping this film’s a blockbuster—any guesses?",
				  "The popcorn here’s top-notch—don’t skip it!"
				],
				"Acquaintance": [
				  "Hey, you’re back! Seen any awesome movies lately?",
				  "Getting the knack for picking the best seats?",
				  "Good to see you—makes movie nights more fun!",
				  "Got a favorite film genre? I’m all ears."
				],
				"Friend": [
				  "Yo, great to see you! Ready for a cinematic escape?",
				  "You’re practically a pro at these movie outings!",
				  "Wanna check out a new release with me today?",
				  "Your taste in films always makes things exciting!"
				],
				"Good Friend": [
				  "My movie buddy! What’s the pick for today?",
				  "I love how you turn every screening into a blast.",
				  "Let’s snag the best seats and share some snacks, yeah?",
				  "You make these cinema trips absolutely awesome!",
				  "Saved us a spot in the prime viewing row."
				],
				"Crush": [
				  "*smiles warmly* Was hoping you’d be here tonight.",
				  "You make these movie nights feel... extra special.",
				  "Might’ve glanced at you in the ticket line.",
				  "Wanna watch movies together more often?",
				  "How about a soda after the credits roll?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick hug*",
				  "Movie dates with you are my favorite thing.",
				  "*teasing* Bet I can predict the ending before you!",
				  "We’re the perfect pair, in theaters and beyond.",
				  "Wanna cozy up at home for a movie night later?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our film date?",
				  "Every movie with you feels like a perfect story.",
				  "We’re a flawless match, like a film and its sequel.",
				  "You light up my life, from cinema screens to forever.",
				  "*softly* You’re my favorite plot twist, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/cinema/hilda/hilda_main.png",
			  "stats_required": {"communication": 10},
			  "date_images": {
				"dinner": "res://images/characters/cinema/hilda/hilda_dinner.png",
				"park": "res://images/characters/cinema/hilda/hilda_park.png",
				"beach": "res://images/characters/cinema/hilda/hilda_beach.png",
				"home": "res://images/characters/cinema/hilda/hilda_home.png",
				"kiss": "res://images/characters/cinema/hilda/hilda_kiss.png"
			  }
			}
		] as Array[Dictionary]
	},
	"Job Center": {
		"name": "Job Center",
		"type": "normal",
		"scene_path": "res://scenes/locations/jobcenter_scene.tscn",
		"activities": [
			# --- Tier 1 Jobs (Starting Jobs) ---
			{"name": "Waiter Job", "job_id": "job_waiter", "description": "Work as a waiter and earn money.", "effects": {"endurance": 0.02, "communication": 0.01}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 1.0 / 60.0},
			{"name": "Retail Assistant Job", "job_id": "job_retail_assistant", "description": "Help customers in retail.", "effects": {"persuasion": 0.03, "charisma": 0.01}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 1.2 / 60.0},
			{"name": "Office Clerk Job", "job_id": "job_office_clerk", "description": "Perform administrative tasks.", "effects": {"intelligence": 0.01, "logic": 0.01}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 0.8 / 60.0},
			# --- Tier 2 Jobs (Branching Jobs - Requires Tier 1 Hours + Stats) ---
			{"name": "Bartender", "job_id": "job_bartender", "description": "Mix drinks and charm customers.", "effects": {"charisma": 0.05, "communication": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 2.5 / 60.0,
				"job_requirements": {"job_waiter": 10},
				"stat_requirements": {"charisma": 5, "communication": 5}
			},
			{"name": "Head Waiter", "job_id": "job_head_waiter", "description": "Lead the service team.", "effects": {"leadership": 0.04, "persuasion": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 2.8 / 60.0,
				"job_requirements": {"job_waiter": 10},
				"stat_requirements": {"leadership": 5, "persuasion": 5}
			},
			{"name": "Sales Associate", "job_id": "job_sales_associate", "description": "Master the art of selling.", "effects": {"persuasion": 0.05, "communication": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 2.7 / 60.0,
				"job_requirements": {"job_retail_assistant": 10},
				"stat_requirements": {"persuasion": 5, "communication": 5}
			},
			{"name": "Visual Merchandiser", "job_id": "job_visual_merchandiser", "description": "Design captivating displays.", "effects": {"agility": 0.04, "charisma": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 2.6 / 60.0,
				"job_requirements": {"job_retail_assistant": 10},
				"stat_requirements": {"agility": 5, "charisma": 5}
			},
			{"name": "Junior Analyst", "job_id": "job_junior_analyst", "description": "Assist with data and reports.", "effects": {"logic": 0.05, "knowledge": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 3.0 / 60.0,
				"job_requirements": {"job_office_clerk": 10},
				"stat_requirements": {"logic": 5, "knowledge": 5}
			},
			{"name": "Administrative Assistant", "job_id": "job_administrative_assistant", "description": "Support office operations.", "effects": {"communication": 0.04, "wisdom": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 2.9 / 60.0,
				"job_requirements": {"job_office_clerk": 10},
				"stat_requirements": {"communication": 5, "wisdom": 5}
			},
			# --- Tier 3 Jobs (Further Specialization - Requires Tier 2 Hours + Higher Stats) ---
			{"name": "Mixologist", "job_id": "job_mixologist", "description": "Craft complex and creative cocktails.", "effects": {"charisma": 0.07, "knowledge": 0.05, "logic": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 5.0 / 60.0,
				"job_requirements": {"job_bartender": 20},
				"stat_requirements": {"charisma": 10, "knowledge": 10}
			},
			{"name": "Event Coordinator", "job_id": "job_event_coordinator", "description": "Plan and execute successful events.", "effects": {"communication": 0.06, "leadership": 0.05, "persuasion": 0.04}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 5.5 / 60.0,
				"job_requirements": {"job_bartender": 20},
				"stat_requirements": {"communication": 10, "leadership": 10}
			},
			{"name": "Restaurant Manager", "job_id": "job_restaurant_manager", "description": "Oversee all restaurant operations.", "effects": {"leadership": 0.07, "logic": 0.05, "communication": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 6.0 / 60.0,
				"job_requirements": {"job_head_waiter": 20},
				"stat_requirements": {"leadership": 10, "logic": 10}
			},
			{"name": "Sommelier", "job_id": "job_sommelier", "description": "Become an expert in wine and spirits.", "effects": {"wisdom": 0.06, "knowledge": 0.05, "persuasion": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 5.8 / 60.0,
				"job_requirements": {"job_head_waiter": 20},
				"stat_requirements": {"wisdom": 10, "knowledge": 10}
			},
			{"name": "Store Manager", "job_id": "job_store_manager", "description": "Manage a retail store's success.", "effects": {"leadership": 0.06, "persuasion": 0.05, "logic": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 5.7 / 60.0,
				"job_requirements": {"job_sales_associate": 20},
				"stat_requirements": {"leadership": 10, "persuasion": 10}
			},
			{"name": "Data Analyst", "job_id": "job_data_analyst", "description": "Interpret data to inform business decisions.", "effects": {"logic": 0.07, "intelligence": 0.05, "knowledge": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 6.5 / 60.0,
				"job_requirements": {"job_junior_analyst": 20},
				"stat_requirements": {"logic": 10, "intelligence": 10}
			},
			{"name": "Executive Assistant", "job_id": "job_executive_assistant", "description": "Provide high-level support to executives.", "effects": {"communication": 0.06, "wisdom": 0.05, "organization": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 6.3 / 60.0,
				"job_requirements": {"job_administrative_assistant": 20},
				"stat_requirements": {"communication": 10, "wisdom": 10}
			},
			{"name": "Project Coordinator", "job_id": "job_project_coordinator", "description": "Organize and manage project timelines.", "effects": {"leadership": 0.05, "logic": 0.04, "communication": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 6.1 / 60.0,
				"job_requirements": {"job_junior_analyst": 20, "job_administrative_assistant": 20},
				"stat_requirements": {"leadership": 10, "logic": 10}
			},
			{"name": "HR Specialist", "job_id": "job_hr_specialist", "description": "Handle human resources and employee relations.", "effects": {"communication": 0.06, "persuasion": 0.04, "wisdom": 0.03}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 6.0 / 60.0,
				"job_requirements": {"job_administrative_assistant": 20},
				"stat_requirements": {"communication": 10, "wisdom": 10}
			},
			# --- Tier 4 Jobs (Advanced Roles - Requires Tier 3 Hours + Even Higher Stats) ---
			{"name": "Luxury Bartender", "job_id": "job_luxury_bartender", "description": "Serve in high-end establishments.", "effects": {"charisma": 0.10, "knowledge": 0.08, "intelligence": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 10.0 / 60.0,
				"job_requirements": {"job_mixologist": 40},
				"stat_requirements": {"charisma": 20, "knowledge": 20}
			},
			{"name": "Celebrity Event Planner", "job_id": "job_celebrity_event_planner", "description": "Organize exclusive events for VIPs.", "effects": {"leadership": 0.10, "communication": 0.09, "persuasion": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 11.0 / 60.0,
				"job_requirements": {"job_event_coordinator": 40},
				"stat_requirements": {"leadership": 20, "communication": 20}
			},
			{"name": "Hotel General Manager", "job_id": "job_hotel_general_manager", "description": "Oversee an entire hotel's operations.", "effects": {"leadership": 0.11, "logic": 0.09, "wisdom": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 12.0 / 60.0,
				"job_requirements": {"job_restaurant_manager": 40},
				"stat_requirements": {"leadership": 20, "logic": 20}
			},
			{"name": "Master Sommelier", "job_id": "job_master_sommelier", "description": "Attain the highest level of wine expertise.", "effects": {"wisdom": 0.10, "knowledge": 0.09, "persuasion": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 11.5 / 60.0,
				"job_requirements": {"job_sommelier": 40},
				"stat_requirements": {"wisdom": 20, "knowledge": 20}
			},
			{"name": "Cruise Ship Director", "job_id": "job_cruise_ship_director", "description": "Manage all entertainment and guest services on a cruise.", "effects": {"leadership": 0.10, "charisma": 0.08, "communication": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 11.8 / 60.0,
				"job_requirements": {"job_event_coordinator": 40, "job_restaurant_manager": 40},
				"stat_requirements": {"leadership": 25, "communication": 25}
			},
			{"name": "Michelin Star Chef", "job_id": "job_michelin_star_chef", "description": "Lead a world-renowned kitchen.", "effects": {"intelligence": 0.10, "logic": 0.08, "strength": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 13.0 / 60.0,
				"job_requirements": {"job_restaurant_manager": 40, "job_mixologist": 40},
				"stat_requirements": {"intelligence": 25, "endurance": 25}
			},
			{"name": "Hospitality Consultant", "job_id": "job_hospitality_consultant", "description": "Advise businesses on service excellence.", "effects": {"wisdom": 0.11, "logic": 0.09, "persuasion": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 12.5 / 60.0,
				"job_requirements": {"job_mixologist": 40, "job_sommelier": 40},
				"stat_requirements": {"wisdom": 25, "knowledge": 25}
			},
			{"name": "Food Critic", "job_id": "job_food_critic", "description": "Review and influence the culinary world.", "effects": {"knowledge": 0.10, "wisdom": 0.08, "communication": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 10.5 / 60.0,
				"job_requirements": {"job_sommelier": 40},
				"stat_requirements": {"knowledge": 20, "communication": 20}
			},
			{"name": "National Sales Director", "job_id": "job_national_sales_director", "description": "Oversee sales for an entire country.", "effects": {"leadership": 0.11, "persuasion": 0.10, "communication": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 12.5 / 60.0,
				"job_requirements": {"job_regional_sales_manager": 40},
				"stat_requirements": {"leadership": 20, "persuasion": 20}
			},
			{"name": "E-commerce Head", "job_id": "job_e_commerce_head", "description": "Lead online retail strategies.", "effects": {"logic": 0.10, "intelligence": 0.09, "knowledge": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 12.0 / 60.0,
				"job_requirements": {"job_store_manager": 40},
				"stat_requirements": {"logic": 20, "intelligence": 20}
			},
			{"name": "Luxury Brand Manager", "job_id": "job_luxury_brand_manager", "description": "Cultivate the image of high-end brands.", "effects": {"charisma": 0.11, "persuasion": 0.09, "wisdom": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 13.0 / 60.0,
				"job_requirements": {"job_brand_ambassador": 40},
				"stat_requirements": {"charisma": 20, "persuasion": 20}
			},
			{"name": "Global Buyer", "job_id": "job_global_buyer", "description": "Source products from around the world.", "effects": {"knowledge": 0.10, "logic": 0.08, "wisdom": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 12.8 / 60.0,
				"job_requirements": {"job_fashion_buyer": 40},
				"stat_requirements": {"knowledge": 20, "logic": 20}
			},
			{"name": "Retail Chain CEO", "job_id": "job_retail_chain_ceo", "description": "Lead a major retail corporation.", "effects": {"leadership": 0.12, "logic": 0.10, "communication": 0.08}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 14.0 / 60.0,
				"job_requirements": {"job_store_manager": 40, "job_regional_sales_manager": 40},
				"stat_requirements": {"leadership": 30, "logic": 30}
			},
			{"name": "Franchise Developer", "job_id": "job_franchise_developer", "description": "Expand a brand by opening new franchises.", "effects": {"persuasion": 0.11, "leadership": 0.09, "communication": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 13.5 / 60.0,
				"job_requirements": {"job_sales_associate": 40, "job_brand_ambassador": 40},
				"stat_requirements": {"persuasion": 25, "leadership": 25}
			},
			{"name": "Marketing Director", "job_id": "job_marketing_director", "description": "Shape public perception and drive sales.", "effects": {"charisma": 0.10, "communication": 0.08, "intelligence": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 12.7 / 60.0,
				"job_requirements": {"job_visual_merchandiser": 40, "job_brand_ambassador": 40},
				"stat_requirements": {"charisma": 25, "intelligence": 25}
			},
			{"name": "Supply Chain Head", "job_id": "job_supply_chain_head", "description": "Optimize product flow from source to customer.", "effects": {"logic": 0.11, "knowledge": 0.09, "endurance": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 13.2 / 60.0,
				"job_requirements": {"job_fashion_buyer": 40, "job_store_manager": 40},
				"stat_requirements": {"logic": 25, "knowledge": 25}
			},
			{"name": "Senior Data Scientist", "job_id": "job_senior_data_scientist", "description": "Develop advanced analytical models.", "effects": {"logic": 0.11, "intelligence": 0.10, "knowledge": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 13.5 / 60.0,
				"job_requirements": {"job_data_analyst": 40},
				"stat_requirements": {"logic": 20, "intelligence": 20}
			},
			{"name": "Chief of Staff", "job_id": "job_chief_of_staff", "description": "Act as a right hand to a top executive.", "effects": {"leadership": 0.11, "communication": 0.10, "wisdom": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 13.0 / 60.0,
				"job_requirements": {"job_executive_assistant": 40},
				"stat_requirements": {"leadership": 20, "communication": 20}
			},
			{"name": "Program Manager", "job_id": "job_program_manager", "description": "Oversee multiple projects within a program.", "effects": {"leadership": 0.10, "logic": 0.09, "communication": 0.06}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 12.8 / 60.0,
				"job_requirements": {"job_project_coordinator": 40},
				"stat_requirements": {"leadership": 20, "logic": 20}
			},
			{"name": "HR Director", "job_id": "job_hr_director", "description": "Lead the human resources department.", "effects": {"communication": 0.10, "persuasion": 0.09, "wisdom": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 12.7 / 60.0,
				"job_requirements": {"job_hr_specialist": 40},
				"stat_requirements": {"communication": 20, "persuasion": 20}
			},
			{"name": "Financial Analyst", "job_id": "job_financial_analyst", "description": "Evaluate investment opportunities and financial performance.", "effects": {"logic": 0.11, "knowledge": 0.10, "intelligence": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 13.3 / 60.0,
				"job_requirements": {"job_data_analyst": 40},
				"stat_requirements": {"logic": 25, "knowledge": 25}
			},
			{"name": "Legal Counsel", "job_id": "job_legal_counsel", "description": "Provide legal guidance to a corporation.", "effects": {"logic": 0.12, "knowledge": 0.11, "communication": 0.08}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 14.0 / 60.0,
				"job_requirements": {"job_executive_assistant": 40, "job_hr_specialist": 40},
				"stat_requirements": {"logic": 30, "knowledge": 30}
			},
			{"name": "IT Manager", "job_id": "job_it_manager", "description": "Manage technology infrastructure and teams.", "effects": {"intelligence": 0.11, "logic": 0.10, "leadership": 0.07}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 13.8 / 60.0,
				"job_requirements": {"job_project_coordinator": 40, "job_data_analyst": 40},
				"stat_requirements": {"intelligence": 25, "leadership": 25}
			},
			{"name": "Communications Specialist", "job_id": "job_communications_specialist", "description": "Craft and disseminate public messages.", "effects": {"communication": 0.11, "charisma": 0.09, "persuasion": 0.08}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 13.1 / 60.0,
				"job_requirements": {"job_hr_specialist": 40, "job_executive_assistant": 40},
				"stat_requirements": {"communication": 25, "charisma": 25}
			},
			# --- Tier 5 Jobs (Ultimate Goal Jobs) ---
			{"name": "Hospitality Empire CEO", "job_id": "job_hospitality_ceo", "description": "Lead a global hospitality conglomerate. The pinnacle!", "effects": {"leadership": 0.20, "charisma": 0.18, "wisdom": 0.15, "money_gain_passive": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 50.0 / 60.0,
				"job_requirements": {
					"job_luxury_bartender": 80,
					"job_celebrity_event_planner": 80,
					"job_hotel_general_manager": 80,
					"job_master_sommelier": 80,
					"job_cruise_ship_director": 80,
					"job_michelin_star_chef": 80,
					"job_hospitality_consultant": 80,
					"job_food_critic": 80
				},
				"stat_requirements": {"leadership": 50, "communication": 50, "persuasion": 50, "charisma": 50, "knowledge": 50, "wisdom": 50, "intelligence": 50, "logic": 50}
			},
			{"name": "Global Retail Magnate", "job_id": "job_retail_magnate", "description": "Command an international retail empire. The ultimate sales guru!", "effects": {"leadership": 0.20, "persuasion": 0.18, "logic": 0.15, "money_gain_passive": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 50.0 / 60.0,
				"job_requirements": {
					"job_national_sales_director": 80,
					"job_e_commerce_head": 80,
					"job_luxury_brand_manager": 80,
					"job_global_buyer": 80,
					"job_retail_chain_ceo": 80,
					"job_franchise_developer": 80,
					"job_marketing_director": 80,
					"job_supply_chain_head": 80
				},
				"stat_requirements": {"leadership": 50, "communication": 50, "persuasion": 50, "charisma": 50, "knowledge": 50, "wisdom": 50, "intelligence": 50, "logic": 50}
			},
			{"name": "Corporate Mogul", "job_id": "job_corporate_mogul", "description": "Control a vast corporate conglomerate. The ultimate professional!", "effects": {"intelligence": 0.20, "logic": 0.18, "leadership": 0.15, "money_gain_passive": 0.05}, "stamina_drain_per_second": STAMINA_DRAIN_PER_SECOND_JOB_ACTIVITY, "is_job": true, "money_gain_per_second": 50.0 / 60.0,
				"job_requirements": {
					"job_senior_data_scientist": 80,
					"job_chief_of_staff": 80,
					"job_program_manager": 80,
					"job_hr_director": 80,
					"job_financial_analyst": 80,
					"job_legal_counsel": 80,
					"job_it_manager": 80,
					"job_communications_specialist": 80
				},
				"stat_requirements": {"leadership": 50, "communication": 50, "persuasion": 50, "charisma": 50, "knowledge": 50, "wisdom": 50, "intelligence": 50, "logic": 50}
			}
		] as Array[Dictionary],
		"characters": [
			{
			  "id": "mrs_anderson_jobcenter",
			  "name": "Mrs. Anderson",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Looking for work, are we? Plenty of options here.",
				  "New to the job center? Let’s find you a good fit.",
				  "Motivated folks always find great opportunities!",
				  "Got a resume ready? It’s the first step to success."
				],
				"Acquaintance": [
				  "Back again? Still hunting for that perfect job?",
				  "Getting familiar with the job boards yet?",
				  "Nice to see you—your drive keeps this place lively!",
				  "Need advice on interviews? I’ve got some tips."
				],
				"Friend": [
				  "Good to see you! Ready to land that dream job?",
				  "Your persistence is paying off—I can tell!",
				  "Wanna review some job listings together today?",
				  "Your ambition makes my day here brighter!"
				],
				"Good Friend": [
				  "My favorite job seeker! What’s the goal today?",
				  "I love how you keep pushing forward with such focus.",
				  "Let’s find that perfect career move together, yeah?",
				  "You make my work at the job center so rewarding!",
				  "Saved you a slot for the best career workshop."
				],
				"Crush": [
				  "*smiles warmly* Was hoping you’d stop by today.",
				  "You make this job center feel... more exciting.",
				  "Caught myself watching you at the job board.",
				  "Wanna team up for career planning more often?",
				  "How about coffee after we sort some listings?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick hug*",
				  "Job hunting with you is the best part of my day.",
				  "*teasing* Bet I can find you a better gig than you can!",
				  "We’re a great team, in careers and in life.",
				  "Wanna relax at home after we nail this job search?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our next step?",
				  "Every moment with you feels like a career win.",
				  "We’re a perfect match, in work and in love.",
				  "You inspire me, from job searches to forever.",
				  "*softly* You’re my greatest success, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/jobcenter/mrsanderson/mrsanderson_main.png",
			  "stats_required": {"persuasion": 1, "logic": 1},
			  "date_images": {
				"dinner": "res://images/characters/jobcenter/mrsanderson/mrsanderson_dinner.png",
				"park": "res://images/characters/jobcenter/mrsanderson/mrsanderson_park.png",
				"beach": "res://images/characters/jobcenter/mrsanderson/mrsanderson_beach.png",
				"home": "res://images/characters/jobcenter/mrsanderson/mrsanderson_home.png",
				"kiss": "res://images/characters/jobcenter/mrsanderson/mrsanderson_kiss.png"
			  }
			},
			{
			  "id": "julia_jobcenter",
			  "name": "Julia",
			  "dialogue_by_stage": {
				"Stranger": [
				  "Looking for work, are we? Lots of options here!",
				  "New to the job center? I can point you to some great leads.",
				  "Plenty of opportunities if you’ve got the drive!",
				  "Got your resume polished? It’s key to standing out."
				],
				"Acquaintance": [
				  "Hey, you’re back! Still chasing that dream job?",
				  "Starting to get the feel of the job listings?",
				  "Good to see you again—keeps this place lively!",
				  "Need help tweaking your cover letter? I’m game."
				],
				"Friend": [
				  "Yo, great to see you! Ready to score that perfect gig?",
				  "Your hustle’s inspiring—keep it up!",
				  "Wanna sift through some job postings together?",
				  "Your energy makes my day here so much better!"
				],
				"Good Friend": [
				  "My job-hunt buddy! What’s the plan today?",
				  "I love how you stay so focused on your goals.",
				  "Let’s nail down a killer job app together, yeah?",
				  "You make working here feel like a breeze!",
				  "Saved you a spot at the career fair booth."
				],
				"Crush": [
				  "*smiles softly* Was hoping you’d swing by today.",
				  "You make this job center feel... kinda special.",
				  "Might’ve noticed you at the resume workshop.",
				  "Wanna team up for job hunting more often?",
				  "How about a coffee break after we check some listings?"
				],
				"Dating": [
				  "*grins* My favorite person’s here! *quick hug*",
				  "Job hunting with you is the highlight of my day.",
				  "*teasing* Bet I can spot a better job lead than you!",
				  "We’re a dream team, in careers and in life.",
				  "Wanna chill at home after we crush this job search?"
				],
				"Soulmate": [
				  "*warm gaze* My heart’s here—ready for our next goal?",
				  "Every moment with you feels like a career high.",
				  "We’re unstoppable, in work and in love.",
				  "You inspire me, from job boards to forever.",
				  "*softly* You’re my greatest achievement, always."
				]
			  },
			  "dialogue_points": {
				"Stranger": 3,
				"Acquaintance": 3,
				"Friend": 4,
				"Good Friend": 5,
				"Crush": 6,
				"Dating": 7,
				"Soulmate": 8
			  },
			  "image_path": "res://images/characters/jobcenter/julia/julia_main.png",
			  "stats_required": {"persuasion": 1, "logic": 1},
			  "date_images": {
				"dinner": "res://images/characters/jobcenter/julia/julia_dinner.png",
				"park": "res://images/characters/jobcenter/julia/julia_park.png",
				"beach": "res://images/characters/jobcenter/julia/julia_beach.png",
				"home": "res://images/characters/jobcenter/julia/julia_home.png",
				"kiss": "res://images/characters/jobcenter/julia/julia_kiss.png"
			  }
			}
		] as Array[Dictionary]
	},
	"Map": {
		"name": "Map",
		"type": "map",
		"scene_path": "res://scenes/map_scene.tscn",
		"activities": [] as Array[Dictionary],
		"characters": [] as Array[Dictionary]
	}
}

var current_location: Dictionary = {
	"name": "Unknown",
	"type": "unknown",
	"scene_path": ""
}

func _ready() -> void:
	if GameManager:
		GameManager.scene_changed.connect(_on_scene_changed)
	else:
		printerr("LocationManager: GameManager autoload not found!")
	
	if get_tree().current_scene:
		_on_scene_changed(get_tree().current_scene.scene_file_path)
	else:
		printerr("LocationManager: No current scene found in _ready().")

func get_location_data_by_name(location_name: String) -> Dictionary:
	if location_data.has(location_name):
		return location_data[location_name]
	else:
		printerr("LocationManager: No data found for location name: ", location_name)
		return {}

func set_current_location(location: Dictionary) -> void:
	if location.has("name") and location.has("type") and location.has("scene_path"):
		# Ensure full location data is used
		var full_location_data = get_location_data_by_name(location["name"])
		if not full_location_data.is_empty():
			current_location = full_location_data
		else:
			current_location = location
		if PlayerData:
			PlayerData.set_current_location(current_location)
		else:
			printerr("LocationManager: PlayerData autoload not found!")
		emit_signal("location_data_updated", current_location)
	else:
		printerr("LocationManager: Invalid location data, missing required keys: ", location)

func _on_scene_changed(new_scene_path: String) -> void:
	var found_location_data = {}
	for key in location_data:
		var loc_entry = location_data[key]
		if loc_entry.get("scene_path") == new_scene_path:
			found_location_data = loc_entry
			break
	
	if not found_location_data.is_empty():
		current_location = found_location_data
		if PlayerData:
			PlayerData.set_current_location(current_location)
		else:
			printerr("LocationManager: PlayerData autoload not found!")
	else:
		current_location = {
			"scene_path": new_scene_path,
			"name": new_scene_path.get_file().get_basename(),
			"type": "normal",
			"activities": [],
			"characters": []
		}
		printerr("LocationManager: Scene path '", new_scene_path, "' not found in location_data. Defaulting to type 'normal'.")
		if PlayerData:
			PlayerData.set_current_location(current_location)
		else:
			printerr("LocationManager: PlayerData autoload not found!")
	
	emit_signal("location_data_updated", current_location)

func get_current_location_data() -> Dictionary:
	return get_current_location()

func get_activities_for_location(location_name: String) -> Array[Dictionary]:
	var loc_data = get_location_data_by_name(location_name)
	return loc_data.get("activities", [])

func get_characters_for_location(location_name: String) -> Array[Dictionary]:
	var loc_data = get_location_data_by_name(location_name)
	return loc_data.get("characters", [])
	
func get_current_location() -> Dictionary:
	# Fetch location data based on current scene path
	var scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	for key in location_data:
		if location_data[key].get("scene_path") == scene_path:
			return location_data[key]
	return current_location if not current_location.is_empty() else {
		"name": "Unknown",
		"type": "unknown",
		"scene_path": scene_path,
		"activities": [],
		"characters": []
	}

func get_current_location_type() -> String:
	return get_current_location().get("type", "unknown")

func get_current_location_name() -> String:
	return get_current_location().get("name", "Unknown")
	
func get_character_data(character_id: String) -> Dictionary:
	for location in location_data.values():
		for char in location.get("characters", []):
			if char.get("id") == character_id:
				return char
	printerr("LocationManager: No character found with id: ", character_id)
	return {}
	
func get_all_characters() -> Array[Dictionary]:
	var all_characters: Array[Dictionary] = []
	for location in location_data.values():
		all_characters.append_array(location.get("characters", []))
	return all_characters
