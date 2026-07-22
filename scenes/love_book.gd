extends Control

@onready var pages_container: HBoxContainer = %PagesContainer
@onready var stats_label: Label = %Stats
@onready var detail_panel: Panel = %CharacterDetailPanel
@onready var character_name_label: Label = %CharacterName
@onready var details_container: VBoxContainer = %DetailsContainer
@onready var left_arrow: Button = %LeftArrow
@onready var right_arrow: Button = %RightArrow
@onready var page_indicator: Label = %PageIndicator

var current_page: int = 0
var hover_tweens: Dictionary = {}

const MAX_RELATIONSHIP_POINTS = 1500
const PLACEHOLDER_TEXTURE = preload("res://images/placeholder_portrait.png")
const DATE_PLACEHOLDER_TEXTURE = preload("res://images/placeholder_date.png")

const DATE_ORDER = ["dinner", "park", "beach", "home", "kiss"]
const DATE_DISPLAY_NAMES = {
	"dinner": "Dinner",
	"park": "Park", 
	"beach": "Beach",
	"home": "Home",
	"kiss": "Kiss"
}

func _ready() -> void:
	visible = false
	left_arrow.pressed.connect(_on_left_arrow_pressed)
	right_arrow.pressed.connect(_on_right_arrow_pressed)
	
	populate_love_book()
	update_stats()
	update_navigation()
	
	# Hide scrollbars after everything is set up
	call_deferred("_hide_scrollbars")

func _hide_scrollbars() -> void:
	# Find all scroll containers and hide their scrollbars
	var scroll_containers = find_children("*", "ScrollContainer", true, false)
	for scroll_container in scroll_containers:
		if scroll_container is ScrollContainer:
			var v_scrollbar = scroll_container.get_v_scroll_bar()
			var h_scrollbar = scroll_container.get_h_scroll_bar()
			if v_scrollbar:
				v_scrollbar.modulate.a = 0.0  # Make invisible but keep functionality
			if h_scrollbar:
				h_scrollbar.modulate.a = 0.0

func show_love_book() -> void:
	visible = true

func hide_love_book() -> void:
	visible = false

func populate_love_book() -> void:
	for child in pages_container.get_children():
		child.queue_free()
	
	var all_characters = LocationManager.get_all_characters()
	print("DEBUG: Number of characters from LocationManager: ", all_characters.size())
	
	var location_groups: Dictionary = {}
	for char_data in all_characters:
		var location = extract_location(char_data.get("id", ""))
		if not location_groups.has(location):
			location_groups[location] = []
		location_groups[location].append(char_data)
	
	var locations = location_groups.keys()
	for location in locations:
		location_groups[location].sort_custom(func(a, b): return a.get("name", "").naturalnocasecmp_to(b.get("name", "")) < 0)
		
		# Simple page container with hidden scrollbar
		var page_scroll = ScrollContainer.new()
		page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page_scroll.custom_minimum_size = Vector2(1100, 550)
		
		# Allow vertical scrolling but disable horizontal
		page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		
		var content_container = VBoxContainer.new()
		content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page_scroll.add_child(content_container)
		
		# Simple location header
		var location_label = Label.new()
		location_label.text = location.capitalize()
		location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		location_label.add_theme_font_size_override("font_size", 22)
		location_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35, 1))
		location_label.custom_minimum_size = Vector2(0, 40)
		content_container.add_child(location_label)
		
		# Spacing
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		content_container.add_child(spacer)
		
		# Simple grid
		var grid = GridContainer.new()
		grid.columns = 4
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 35)
		grid.add_theme_constant_override("v_separation", 40)
		content_container.add_child(grid)
		
		# Add characters with simple styling
		for char_data in location_groups[location]:
			create_simple_character_entry(grid, char_data)
		
		pages_container.add_child(page_scroll)

func create_simple_character_entry(grid: GridContainer, char_data: Dictionary) -> void:
	# Main container
	var entry_container = Control.new()
	entry_container.custom_minimum_size = Vector2(260, 320)
	entry_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	entry_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Simple card background
	var card_bg = Panel.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.25, 0.2, 0.15, 0.8)
	card_style.set_corner_radius_all(12)
	card_style.set_border_width_all(1)
	card_style.set_border_color(Color(0.8, 0.6, 0.2, 0.4))
	card_bg.add_theme_stylebox_override("panel", card_style)
	card_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Content container
	var content_vbox = VBoxContainer.new()
	content_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_vbox.add_theme_constant_override("separation", 8)
	
	# Portrait container
	var portrait_margin = MarginContainer.new()
	portrait_margin.add_theme_constant_override("margin_left", 15)
	portrait_margin.add_theme_constant_override("margin_right", 15)
	portrait_margin.add_theme_constant_override("margin_top", 15)
	portrait_margin.add_theme_constant_override("margin_bottom", 5)
	
	var portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(220, 220)
	
	# Simple portrait border
	var portrait_style = StyleBoxFlat.new()
	portrait_style.set_border_width_all(3)
	portrait_style.set_corner_radius_all(8)
	
	var points = PlayerData.get_relationship_points(char_data.get("id", ""))
	var is_unlocked = points > 0
	
	if is_unlocked:
		portrait_style.set_border_color(Color(0.85, 0.65, 0.2, 1))
		if char_data.has("image_path"):
			var texture = load(char_data.image_path)
			portrait.texture = texture if texture else PLACEHOLDER_TEXTURE
		else:
			portrait.texture = PLACEHOLDER_TEXTURE
	else:
		portrait_style.set_border_color(Color(0.5, 0.5, 0.5, 0.6))
		portrait.texture = PLACEHOLDER_TEXTURE
		portrait.modulate = Color(0.4, 0.4, 0.4, 0.8)
	
	portrait.add_theme_stylebox_override("normal", portrait_style)
	portrait_margin.add_child(portrait)
	content_vbox.add_child(portrait_margin)
	
	# Name label
	var name_margin = MarginContainer.new()
	name_margin.add_theme_constant_override("margin_left", 10)
	name_margin.add_theme_constant_override("margin_right", 10)
	name_margin.add_theme_constant_override("margin_bottom", 5)
	
	var name_label = Label.new()
	name_label.text = char_data.get("name", "Unknown")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.55, 1))
	else:
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	
	name_margin.add_child(name_label)
	content_vbox.add_child(name_margin)
	
	# Simple relationship status bar
	var status_margin = MarginContainer.new()
	status_margin.add_theme_constant_override("margin_bottom", 15)
	status_margin.add_theme_constant_override("margin_left", 15)
	status_margin.add_theme_constant_override("margin_right", 15)
	
	var status_bar = ProgressBar.new()
	status_bar.custom_minimum_size = Vector2(180, 8)
	status_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	status_bar.max_value = MAX_RELATIONSHIP_POINTS
	status_bar.value = max(points, 0)
	
	var progress_style = StyleBoxFlat.new()
	progress_style.set_corner_radius_all(4)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.25, 0.2, 0.6)
	bg_style.set_corner_radius_all(4)
	status_bar.add_theme_stylebox_override("background", bg_style)
	
	if is_unlocked:
		progress_style.bg_color = Color(0.85, 0.65, 0.2, 0.8)
	else:
		progress_style.bg_color = Color(0.5, 0.5, 0.5, 0.4)
	
	status_bar.add_theme_stylebox_override("fill", progress_style)
	status_margin.add_child(status_bar)
	content_vbox.add_child(status_margin)
	
	# Add everything to the card
	card_bg.add_child(content_vbox)
	entry_container.add_child(card_bg)
	
	# Simple interactive button
	var button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.custom_minimum_size = Vector2(260, 320)
	
	# Invisible button styles
	var empty_style = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	
	entry_container.add_child(button)
	
	# Connect signals with hover effects
	button.pressed.connect(_on_character_clicked.bind(char_data))
	button.mouse_entered.connect(_on_character_hover.bind(entry_container, true, is_unlocked))
	button.mouse_exited.connect(_on_character_hover.bind(entry_container, false, is_unlocked))
	
	grid.add_child(entry_container)

func _on_character_hover(card_container: Control, is_hovering: bool, is_unlocked: bool) -> void:
	# Kill any existing tween for this card
	if hover_tweens.has(card_container):
		hover_tweens[card_container].kill()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	hover_tweens[card_container] = tween
	
	if is_hovering:
		# Scale and glow effects
		tween.tween_property(card_container, "scale", Vector2(1.05, 1.05), 0.2)
		
		if is_unlocked:
			# Golden glow for unlocked characters
			tween.tween_property(card_container, "modulate", Color(1.3, 1.2, 1.0, 1), 0.2)
		else:
			# Subtle glow for locked characters
			tween.tween_property(card_container, "modulate", Color(1.2, 1.2, 1.2, 1), 0.2)
	else:
		# Return to normal
		tween.tween_property(card_container, "scale", Vector2(1.0, 1.0), 0.2)
		tween.tween_property(card_container, "modulate", Color.WHITE, 0.2)

func create_date_button(container: GridContainer, char_data: Dictionary, date_name: String) -> void:
	var date_button_container = Control.new()
	date_button_container.custom_minimum_size = Vector2(140, 140)
	
	# Create button background panel
	var date_bg = Panel.new()
	var date_style = StyleBoxFlat.new()
	date_style.bg_color = Color(0.2, 0.15, 0.1, 0.9)
	date_style.set_corner_radius_all(8)
	date_style.set_border_width_all(2)
	
	# Check if this date has been completed
	var char_id = char_data.get("id", "")
	var date_completed = has_completed_date(char_id, date_name)
	
	if date_completed:
		date_style.set_border_color(Color(0.85, 0.65, 0.2, 1))  # Golden border for completed
	else:
		date_style.set_border_color(Color(0.5, 0.4, 0.3, 0.6))  # Dim border for incomplete
	
	date_bg.add_theme_stylebox_override("panel", date_style)
	date_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create content container
	var date_content = VBoxContainer.new()
	date_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	date_content.add_theme_constant_override("separation", 5)
	
	# Date image
	var date_image_margin = MarginContainer.new()
	date_image_margin.add_theme_constant_override("margin_left", 8)
	date_image_margin.add_theme_constant_override("margin_right", 8)
	date_image_margin.add_theme_constant_override("margin_top", 8)
	date_image_margin.add_theme_constant_override("margin_bottom", 5)
	
	var date_image = TextureRect.new()
	date_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	date_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	date_image.custom_minimum_size = Vector2(100, 80)
	
	# Load appropriate image
	if date_completed:
		var date_image_path = get_date_image_path(char_id, date_name)
		print("Loading date image: ", date_image_path)  # Debug print
		
		# Try to load the texture, with error handling
		var texture = null
		if date_image_path != "" and ResourceLoader.exists(date_image_path):
			texture = load(date_image_path)
		
		if texture:
			date_image.texture = texture
		else:
			print("Date image not found, using placeholder: ", date_image_path)
			date_image.texture = DATE_PLACEHOLDER_TEXTURE
	else:
		date_image.texture = DATE_PLACEHOLDER_TEXTURE
		date_image.modulate = Color(0.5, 0.5, 0.5, 0.7)
	
	date_image_margin.add_child(date_image)
	date_content.add_child(date_image_margin)
	
	# Date label
	var date_label_margin = MarginContainer.new()
	date_label_margin.add_theme_constant_override("margin_left", 5)
	date_label_margin.add_theme_constant_override("margin_right", 5)
	date_label_margin.add_theme_constant_override("margin_bottom", 8)
	
	var date_label = Label.new()
	var display_name = DATE_DISPLAY_NAMES.get(date_name, date_name.capitalize())
	
	if date_completed:
		date_label.text = "%s ✓" % display_name  # Add checkmark for completed dates
		date_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5, 1))
	else:
		date_label.text = display_name
		date_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4, 1))
	
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 12)
	
	date_label_margin.add_child(date_label)
	date_content.add_child(date_label_margin)
	
	# Add everything to the panel
	date_bg.add_child(date_content)
	date_button_container.add_child(date_bg)
	
	# Create invisible button for interaction
	var date_button = Button.new()
	date_button.flat = true
	date_button.focus_mode = Control.FOCUS_NONE
	date_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Invisible button styles
	var empty_style = StyleBoxEmpty.new()
	date_button.add_theme_stylebox_override("normal", empty_style)
	date_button.add_theme_stylebox_override("hover", empty_style)
	date_button.add_theme_stylebox_override("pressed", empty_style)
	date_button.add_theme_stylebox_override("focus", empty_style)
	
	date_button_container.add_child(date_button)
	
	# Connect button signals
	date_button.pressed.connect(_on_date_button_clicked.bind(char_data, date_name))
	date_button.mouse_entered.connect(_on_date_button_hover.bind(date_button_container, true))
	date_button.mouse_exited.connect(_on_date_button_hover.bind(date_button_container, false))
	
	container.add_child(date_button_container)

func has_completed_date(char_id: String, date_name: String) -> bool:
	return PlayerData.has_completed_date(char_id, date_name)

func get_date_image_path(char_id: String, date_name: String) -> String:
	# Get the character data from LocationManager
	var char_data = LocationManager.get_character_data(char_id)
	if not char_data:
		return ""
	
	# Get the date images dictionary
	var date_images = char_data.get("date_images", {})
	return date_images.get(date_name, "")

func _on_date_button_clicked(char_data: Dictionary, date_name: String) -> void:
	var char_id = char_data.get("id", "")
	var date_completed = has_completed_date(char_id, date_name)
	var display_name = DATE_DISPLAY_NAMES.get(date_name, date_name.capitalize())
	
	if date_completed:
		# Show the full date image or start a date replay
		if UIManager:
			UIManager.show_notification("Viewing %s date with %s" % [display_name, char_data.get("name", "Unknown")])
		
		# Show a full-screen image viewer
		show_date_image_fullscreen(char_id, date_name)
	else:
		# Show that this date hasn't been unlocked yet
		if UIManager:
			UIManager.show_notification("%s date not yet experienced with %s!" % [display_name, char_data.get("name", "Unknown")])

func _on_date_button_hover(button_container: Control, is_hovering: bool) -> void:
	# Simple hover effect for date buttons
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if is_hovering:
		tween.tween_property(button_container, "scale", Vector2(1.1, 1.1), 0.15)
		tween.tween_property(button_container, "modulate", Color(1.1, 1.1, 1.1, 1), 0.15)
	else:
		tween.tween_property(button_container, "scale", Vector2(1.0, 1.0), 0.15)
		tween.tween_property(button_container, "modulate", Color.WHITE, 0.15)
		
func show_date_image_fullscreen(char_id: String, date_name: String) -> void:
	var date_image_path = get_date_image_path(char_id, date_name)
	
	if date_image_path.is_empty() or not ResourceLoader.exists(date_image_path):
		print("Cannot show fullscreen - image not found: ", date_image_path)
		return
	
	# Create a separate CanvasLayer for the fullscreen overlay to ensure it appears on top
	var overlay_canvas = CanvasLayer.new()
	overlay_canvas.layer = 100  # Much higher than UIManager's layer (10)
	
	# Create the fullscreen overlay
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block all input below
	overlay_canvas.add_child(overlay)
	
	# Semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.85)  # Darker background for better contrast
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(background)
	
	# Create centered container for the image
	var image_container = Control.new()
	image_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	image_container.anchor_left = 0.5
	image_container.anchor_right = 0.5
	image_container.anchor_top = 0.5
	image_container.anchor_bottom = 0.5
	
	# Load and display the image
	var fullscreen_image = TextureRect.new()
	var texture = load(date_image_path)
	fullscreen_image.texture = texture
	fullscreen_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	fullscreen_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Calculate appropriate size - use most of the screen but leave some margin
	var screen_size = get_viewport().get_visible_rect().size
	var max_width = screen_size.x * 0.8  # 80% of screen width
	var max_height = screen_size.y * 0.8  # 80% of screen height
	
	# Get the original texture size to maintain aspect ratio
	var original_size = texture.get_size()
	var aspect_ratio = original_size.x / original_size.y
	
	# Calculate final size maintaining aspect ratio
	var final_width = min(max_width, max_height * aspect_ratio)
	var final_height = min(max_height, max_width / aspect_ratio)
	
	# Ensure minimum size even for very small images
	final_width = max(final_width, 600)
	final_height = max(final_height, 400)
	
	fullscreen_image.custom_minimum_size = Vector2(final_width, final_height)
	fullscreen_image.size = Vector2(final_width, final_height)
	
	# Center the image in the container
	fullscreen_image.position = Vector2(-final_width/2, -final_height/2)
	
	# Add a nice border around the image
	var image_frame = Panel.new()
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.1, 0.05, 0.02, 0.95)
	frame_style.set_corner_radius_all(15)
	frame_style.set_border_width_all(4)
	frame_style.set_border_color(Color(0.85, 0.65, 0.2, 1))  # Golden border
	image_frame.add_theme_stylebox_override("panel", frame_style)
	
	# Make frame slightly larger than image
	var frame_padding = 20
	image_frame.position = Vector2(-final_width/2 - frame_padding, -final_height/2 - frame_padding)
	image_frame.size = Vector2(final_width + frame_padding*2, final_height + frame_padding*2)
	
	# Add image to frame with margin
	var image_margin = MarginContainer.new()
	image_margin.add_theme_constant_override("margin_left", frame_padding)
	image_margin.add_theme_constant_override("margin_right", frame_padding)
	image_margin.add_theme_constant_override("margin_top", frame_padding)
	image_margin.add_theme_constant_override("margin_bottom", frame_padding)
	image_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_margin.add_child(fullscreen_image)
	image_frame.add_child(image_margin)
	
	image_container.add_child(image_frame)
	overlay.add_child(image_container)
	
	# Add close button in top-right corner
	var close_button = Button.new()
	close_button.text = "✕ Close"
	close_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_button.position = Vector2(-140, 20)
	close_button.custom_minimum_size = Vector2(120, 50)
	close_button.add_theme_font_size_override("font_size", 16)
	
	# Style the close button
	var close_button_style = StyleBoxFlat.new()
	close_button_style.bg_color = Color(0.8, 0.2, 0.2, 0.9)
	close_button_style.set_corner_radius_all(8)
	close_button_style.set_border_width_all(2)
	close_button_style.set_border_color(Color(1, 0.3, 0.3, 1))
	close_button.add_theme_stylebox_override("normal", close_button_style)
	close_button.add_theme_stylebox_override("hover", close_button_style)
	close_button.add_theme_stylebox_override("pressed", close_button_style)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	
	overlay.add_child(close_button)
	
	# Add instruction text
	var instruction_label = Label.new()
	instruction_label.text = "Click anywhere or press ESC to close"
	instruction_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	instruction_label.position = Vector2(20, -50)
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.8))
	overlay.add_child(instruction_label)
	
	# Add the overlay to the current scene as a child (this ensures it appears on top)
	get_tree().root.add_child(overlay_canvas)
	
	# Animate the appearance
	overlay.modulate.a = 0.0
	image_container.scale = Vector2(0.8, 0.8)
	
	var appear_tween = create_tween()
	appear_tween.set_parallel(true)
	appear_tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
	appear_tween.tween_property(image_container, "scale", Vector2(1.0, 1.0), 0.3)
	appear_tween.set_ease(Tween.EASE_OUT)
	appear_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Connect close events
	var close_overlay = func():
		var fade_tween = create_tween()
		fade_tween.set_parallel(true)
		fade_tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
		fade_tween.tween_property(image_container, "scale", Vector2(0.9, 0.9), 0.2)
		fade_tween.tween_callback(func(): 
			overlay_canvas.queue_free()  # This will clean up both the overlay and the canvas layer
		).set_delay(0.2)
	
	close_button.pressed.connect(close_overlay)
	background.gui_input.connect(func(event): 
		if event is InputEventMouseButton and event.pressed:
			close_overlay.call()
	)
	
	# Handle ESC key globally
	overlay.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			close_overlay.call()
	)
	
	# Make sure the overlay can receive input focus
	overlay.focus_mode = Control.FOCUS_ALL
	overlay.grab_focus()

func extract_location(character_id: String) -> String:
	var parts = character_id.split("_")
	if parts.size() > 1:
		var location = parts[-1]
		if location == "jobcenter":
			return "Job Center"
		elif location == "anderson":
			return "Job Center"
		return location.capitalize()
	return "Unknown"

func update_stats() -> void:
	var all_characters = LocationManager.get_all_characters()
	var discovered = 0
	for char_data in all_characters:
		if PlayerData.get_relationship_points(char_data.get("id", "")) > 0:
			discovered += 1
	
	var progress_text = "Progress: %d/%d" % [discovered, all_characters.size()]
	var percentage = (discovered * 100) / all_characters.size() if all_characters.size() > 0 else 0
	stats_label.text = "%s (%d%% Complete)" % [progress_text, percentage]

func _on_character_clicked(char_data: Dictionary) -> void:
	var points = PlayerData.get_relationship_points(char_data.get("id", ""))
	if points > 0:
		show_character_details(char_data, points)
	else:
		if UIManager:
			UIManager.show_notification("Character not yet discovered!")

func show_character_details(char_data: Dictionary, points: int) -> void:
	detail_panel.visible = true
	character_name_label.text = char_data.get("name", "Unknown")
	
	# Clear previous details
	for child in details_container.get_children():
		child.queue_free()
	
	# Simple details
	var points_container = HBoxContainer.new()
	points_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var points_icon = Label.new()
	points_icon.text = "♥"
	points_icon.add_theme_font_size_override("font_size", 20)
	points_icon.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2, 1))
	points_container.add_child(points_icon)
	
	var percentage = (points * 100) / MAX_RELATIONSHIP_POINTS
	var points_label = Label.new()
	points_label.text = " %d Relationship Points (%d%%)" % [points, percentage]
	points_label.add_theme_font_size_override("font_size", 18)
	points_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.2, 1))
	points_container.add_child(points_label)
	
	details_container.add_child(points_container)
	
	# Create a margin container to center the portrait and details
	var portrait_and_details_margin = MarginContainer.new()
	portrait_and_details_margin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_and_details_margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_and_details_margin.add_theme_constant_override("margin_left", 20)
	portrait_and_details_margin.add_theme_constant_override("margin_right", 20)
	portrait_and_details_margin.add_theme_constant_override("margin_top", 10)
	portrait_and_details_margin.add_theme_constant_override("margin_bottom", 10)
	
	# Create a horizontal container for portrait and character details
	var portrait_and_details_container = HBoxContainer.new()
	portrait_and_details_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_and_details_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_and_details_container.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_and_details_container.add_theme_constant_override("separation", 20)
	
	# Character portrait
	var portrait_frame = Panel.new()
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.2, 0.15, 0.1, 0.8)
	frame_style.set_corner_radius_all(10)
	frame_style.set_border_width_all(3)
	frame_style.set_border_color(Color(0.85, 0.65, 0.2, 1))
	portrait_frame.add_theme_stylebox_override("panel", frame_style)
	portrait_frame.custom_minimum_size = Vector2(220, 240)
	portrait_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var portrait = TextureRect.new()
	var image_path = char_data.get("image_path", "")
	if image_path != "" and ResourceLoader.exists(image_path):
		var texture = load(image_path)
		portrait.texture = texture if texture else PLACEHOLDER_TEXTURE
	else:
		portrait.texture = PLACEHOLDER_TEXTURE
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.custom_minimum_size = Vector2(200, 200)  # Ensure minimum size
	portrait.modulate = Color.WHITE  # Ensure visibility
	
	var portrait_margin = MarginContainer.new()
	portrait_margin.add_theme_constant_override("margin_left", 10)
	portrait_margin.add_theme_constant_override("margin_right", 10)
	portrait_margin.add_theme_constant_override("margin_top", 10)
	portrait_margin.add_theme_constant_override("margin_bottom", 10)
	portrait_margin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_margin.add_child(portrait)
	portrait_frame.add_child(portrait_margin)
	
	portrait_and_details_container.add_child(portrait_frame)
	
	# Character details
	var details_vbox = VBoxContainer.new()
	details_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	details_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	details_vbox.add_theme_constant_override("separation", 8)
	details_vbox.custom_minimum_size = Vector2(300, 0)  # Ensure enough width for details
	
	# Define the details to display
	var detail_fields = [
		{"key": "age", "label": "Age"},
		{"key": "height", "label": "Height"},
		{"key": "weight", "label": "Weight"},
		{"key": "hair", "label": "Hair"},
		{"key": "eyes", "label": "Eyes"},
		{"key": "body", "label": "Body"},
		{"key": "bust", "label": "Bust"},
		{"key": "profession", "label": "Profession"},
		{"key": "hobby", "label": "Hobby"}
	]
	
	for field in detail_fields:
		var detail_hbox = HBoxContainer.new()
		detail_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		detail_hbox.add_theme_constant_override("separation", 10)
		
		var label = Label.new()
		label.text = field.label + ":"
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.55, 1))
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		label.custom_minimum_size = Vector2(100, 0)  # Ensure consistent width for labels
		detail_hbox.add_child(label)
		
		var value = Label.new()
		value.text = str(char_data.get(field.key, "Unknown"))
		value.add_theme_font_size_override("font_size", 14)
		value.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.custom_minimum_size = Vector2(150, 0)  # Ensure enough width for short text
		detail_hbox.add_child(value)
		
		details_vbox.add_child(detail_hbox)
	
	portrait_and_details_container.add_child(details_vbox)
	portrait_and_details_margin.add_child(portrait_and_details_container)
	
	details_container.add_child(portrait_and_details_margin)
	
	# Add spacing before date buttons
	var date_spacer = Control.new()
	date_spacer.custom_minimum_size = Vector2(0, 20)
	details_container.add_child(date_spacer)
	
	# Add date buttons section
	var date_section_title = Label.new()
	date_section_title.text = "Date Memories"
	date_section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_section_title.add_theme_font_size_override("font_size", 20)
	date_section_title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4, 1))
	details_container.add_child(date_section_title)
	
	# Create date buttons container
	var dates_container = GridContainer.new()
	dates_container.columns = 5
	dates_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dates_container.add_theme_constant_override("h_separation", 10)
	dates_container.add_theme_constant_override("v_separation", 10)
	
	# Create date buttons using the defined order
	for date_name in DATE_ORDER:
		create_date_button(dates_container, char_data, date_name)
	
	details_container.add_child(dates_container)
	
	var back_button = %BackButton
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	detail_panel.visible = false

func _on_left_arrow_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_navigation()

func _on_right_arrow_pressed() -> void:
	var total_pages = pages_container.get_child_count()
	if current_page < total_pages - 1:
		current_page += 1
		update_navigation()

func update_navigation() -> void:
	var total_pages = pages_container.get_child_count()
	
	# Simple page visibility update
	for i in range(total_pages):
		pages_container.get_child(i).visible = (i == current_page)
	
	left_arrow.disabled = (current_page == 0)
	right_arrow.disabled = (current_page == total_pages - 1)
	
	# Update page indicator
	if page_indicator:
		page_indicator.text = "Page %d of %d" % [current_page + 1, total_pages]
