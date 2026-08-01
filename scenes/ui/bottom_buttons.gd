extends HBoxContainer

@onready var stats_button: TextureButton = %StatsButton
@onready var social_hub_button: TextureButton = %SocialHubButton
@onready var love_book_button: TextureButton = %LoveBookButton
@onready var activities_button: TextureButton = %ActivitiesButton
@onready var map_button: TextureButton = %MapButton
@onready var tooltip_label: Label = %TooltipLabel  # Reference to TooltipLabel in TooltipContainer

# Get the global UIManager singleton
@onready var ui_manager = UIManager

func _ready():
	if not ui_manager:
		printerr("BottomButtonsHBox ERROR: UIManager Autoload not found! Please ensure UIManager.gd is in Project Settings > Autoload.")
		return

	if not tooltip_label:
		printerr("TooltipLabel not found! Ensure TooltipLabel is in the scene with unique name %TooltipLabel.")
		return

	tooltip_label.hide()  # Hide tooltip by default
	stats_button.pressed.connect(func(): print("Stats button clicked!"))

	# Connect button signals to UIManager functions and tooltip signals
	if is_instance_valid(activities_button):
		activities_button.pressed.connect(ui_manager.show_activities_panel)
		activities_button.mouse_entered.connect(_show_tooltip.bind("View Activities", activities_button))
		activities_button.mouse_exited.connect(_hide_tooltip)
	else:
		printerr("ActivitiesButton not found in BottomButtonsHBox! Check node name.")

	if is_instance_valid(stats_button):
		stats_button.pressed.connect(ui_manager.show_stats_panel)
		stats_button.mouse_entered.connect(_show_tooltip.bind("Player Statistics", stats_button))
		stats_button.mouse_exited.connect(_hide_tooltip)
	else:
		printerr("StatsButton not found in BottomButtonsHBox! Check node name.")

	if is_instance_valid(social_hub_button):
		social_hub_button.pressed.connect(ui_manager.show_social_hub_panel)
		social_hub_button.mouse_entered.connect(_show_tooltip.bind("Social Hub", social_hub_button))
		social_hub_button.mouse_exited.connect(_hide_tooltip)
	else:
		printerr("SocialHubButton not found in BottomButtonsHBox! Check node name.")

	if is_instance_valid(love_book_button):
		love_book_button.pressed.connect(ui_manager.show_love_book)
		love_book_button.mouse_entered.connect(_show_tooltip.bind("The Love Book", love_book_button))
		love_book_button.mouse_exited.connect(_hide_tooltip)
	else:
		printerr("LoveBookButton not found in BottomButtonsHBox! Check node name.")

	if is_instance_valid(map_button):
		map_button.pressed.connect(ui_manager.show_map)
		map_button.mouse_entered.connect(_show_tooltip.bind("Paradise city Map", map_button))
		map_button.mouse_exited.connect(_hide_tooltip)
	else:
		printerr("MapButton not found in BottomButtonsHBox! Check node name.")

func _show_tooltip(text: String, button: TextureButton):
	tooltip_label.text = text
	tooltip_label.add_theme_font_size_override("font_size", 16)
	# Force update layout to ensure tooltip size is accurate
	tooltip_label.update_minimum_size()
	await get_tree().process_frame  # Wait for layout update
	var button_pos = button.get_global_rect().position
	var button_size = button.size
	var tooltip_size = tooltip_label.size
	# Position tooltip above the button, centered horizontally
	tooltip_label.global_position = Vector2(
		button_pos.x + (button_size.x - tooltip_size.x) / 2,  # Center horizontally
		button_pos.y - tooltip_size.y - 10  # 10 pixels above the button
	)
	tooltip_label.show()

func _hide_tooltip():
	tooltip_label.hide()
