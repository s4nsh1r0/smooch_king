extends LineEdit

# Export variables for different StyleBoxFlat resources.
# It's recommended to create these StyleBoxFlat resources directly in the Godot editor
# and assign them here for easier visual customization.
@export var normal_style: StyleBoxFlat = null
@export var hover_glow_style: StyleBoxFlat = null
@export var focus_glow_style: StyleBoxFlat = null

var debug_mode: bool = false # Toggle for debug prints
var original_placeholder_text: String = "" # Store the initial placeholder text

func _ready():
	print("InputBox _ready() called. Instance path: ", get_path())
	_initialize_styles() # Call to ensure styles are set up
	mouse_filter = MOUSE_FILTER_STOP # Ensure the LineEdit receives mouse events

	# Store the original placeholder text
	original_placeholder_text = placeholder_text

	# Apply initial style based on current focus
	if has_focus():
		add_theme_stylebox_override("normal", focus_glow_style)
		# If focused on ready, hide placeholder
		placeholder_text = ""
	else:
		add_theme_stylebox_override("normal", normal_style)
		# If not focused on ready, ensure placeholder is visible
		placeholder_text = original_placeholder_text


func _initialize_styles():
	# If styles are not assigned in the editor, create default ones with glow properties.
	# It's generally better to set these up as resources in the editor for reusability
	# and visual tweaking, but this provides a programmatic fallback.

	# Normal Style: Subtle border, no glow
	if normal_style == null:
		normal_style = StyleBoxFlat.new()
		normal_style.set_bg_color(Color(0.15, 0.15, 0.15, 0.6)) # Dark background
		normal_style.set_border_width_all(2)
		normal_style.set_border_color(Color(0.3, 0.3, 0.3, 1.0)) # Grey border
		normal_style.set_corner_radius_all(8) # Rounded corners
		normal_style.set_expand_margin_all(2) # Margin for text

	# Hover Glow Style: Purple border with a soft purple shadow glow
	if hover_glow_style == null:
		hover_glow_style = StyleBoxFlat.new()
		hover_glow_style.set_bg_color(Color(0.15, 0.15, 0.15, 0.6))
		hover_glow_style.set_border_width_all(2)
		hover_glow_style.set_border_color(Color(0.6, 0.4, 0.8, 1.0)) # Brighter purple border
		hover_glow_style.set_corner_radius_all(8)
		hover_glow_style.set_expand_margin_all(2)

		# Crucial for the glow effect:
		hover_glow_style.set_shadow_size(8) # Size of the shadow (spread)
		hover_glow_style.set_shadow_color(Color(0.6, 0.4, 0.8, 0.5)) # Semi-transparent purple shadow
		hover_glow_style.set_shadow_offset(Vector2(0, 0)) # Centered shadow

	# Focus Glow Style: More intense purple border with a stronger purple shadow glow
	if focus_glow_style == null:
		focus_glow_style = StyleBoxFlat.new()
		focus_glow_style.set_bg_color(Color(0.15, 0.15, 0.15, 0.6))
		focus_glow_style.set_border_width_all(2)
		focus_glow_style.set_border_color(Color(0.8, 0.6, 1.0, 1.0)) # Even brighter purple border
		focus_glow_style.set_corner_radius_all(8)
		focus_glow_style.set_expand_margin_all(2)

		# More intense glow for focus:
		focus_glow_style.set_shadow_size(12) # Larger shadow spread
		focus_glow_style.set_shadow_color(Color(0.8, 0.6, 1.0, 0.7)) # More opaque purple shadow
		focus_glow_style.set_shadow_offset(Vector2(0, 0))

	# If you want focus_glow_style to default to hover_glow_style if not set, keep this:
	# if focus_glow_style == null:
	# 	focus_glow_style = hover_glow_style


# This function will be called when the mouse cursor enters the LineEdit's area.
func _on_mouse_entered() -> void:
	# Only apply hover style if the input box is not currently focused.
	# If it's focused, we want the focus style to persist.
	if not has_focus() and hover_glow_style:
		add_theme_stylebox_override("normal", hover_glow_style)
	if debug_mode:
		print("InputBox: Mouse entered. Has focus: ", has_focus())

# This function will be called when the mouse cursor exits the LineEdit's area.
func _on_mouse_exited() -> void:
	# Only revert to normal style if the input box is not currently focused.
	# If it's focused, we want the focus style to persist.
	if not has_focus() and normal_style:
		add_theme_stylebox_override("normal", normal_style)
	if debug_mode:
		print("InputBox: Mouse exited. Has focus: ", has_focus())

# This function will be called when the LineEdit gains focus.
func _on_focus_entered() -> void:
	if focus_glow_style:
		add_theme_stylebox_override("normal", focus_glow_style)
	# Hide placeholder text when focused
	placeholder_text = ""
	if debug_mode:
		print("InputBox: Focus entered.")

# This function will be called when the LineEdit loses focus.
func _on_focus_exited() -> void:
	# Check if the mouse is still over the LineEdit after losing focus.
	# If so, revert to hover style; otherwise, revert to normal style.
	var mouse_over = get_global_rect().has_point(get_global_mouse_position())
	if mouse_over and hover_glow_style:
		add_theme_stylebox_override("normal", hover_glow_style)
	elif normal_style:
		add_theme_stylebox_override("normal", normal_style)

	# Restore placeholder text if the LineEdit is empty after losing focus
	if text.is_empty():
		placeholder_text = original_placeholder_text

	if debug_mode:
		print("InputBox: Focus exited. Mouse over: ", mouse_over)
