extends TextureButton

@export var hover_offset_y_max: float = -18.0 # Max upward offset (negative for up)
@export var hover_offset_y_min: float = -5.0 # Min upward offset (slight downward dip)
@export var animation_segment_duration: float = 0.12 # Slightly increased duration for smoother transitions
@export var return_duration: float = 0.3 # Duration for returning to original position
@export var hover_modulate_color: Color = Color(1.5, 0.8, 2.0, 1.0) # Subtle brighter color on hover

var original_position: Vector2 # Store original position
var original_modulate: Color # Store original modulate color
var current_bounce_tween: Tween = null # Tween for the continuous bounce
var current_return_tween: Tween = null # Tween for returning to original state

func _ready():
	# Wait one frame so the final position is correct
	await get_tree().process_frame
	original_position = position
	original_modulate = modulate
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _on_mouse_entered():
	# Kill any existing return tween to prevent conflicts
	if current_return_tween and current_return_tween.is_valid():
		current_return_tween.kill()
		current_return_tween = null

	# If a bounce tween is already running, do nothing (already bouncing)
	if current_bounce_tween and current_bounce_tween.is_valid() and current_bounce_tween.is_running():
		return

	_start_continuous_bounce()


func _on_mouse_exited():
	# Kill the continuous bounce tween
	if current_bounce_tween and current_bounce_tween.is_valid():
		current_bounce_tween.kill()
		current_bounce_tween = null # Clear reference

	_start_return_animation()


func _start_continuous_bounce():
	# Create a new tween for the continuous bounce
	current_bounce_tween = create_tween()
	current_bounce_tween.set_loops() # Make it loop indefinitely
	current_bounce_tween.set_trans(Tween.TRANS_SINE) # Apply a global sine transition for overall smoothness

	# Sequence for a more elastic/bouncy feel with modulate color change
	# 1. Move up
	current_bounce_tween.tween_property(self, "position:y", original_position.y + hover_offset_y_max, animation_segment_duration * 0.7)\
		.set_ease(Tween.EASE_OUT) # Faster ascent, eases out
	current_bounce_tween.tween_property(self, "modulate", hover_modulate_color, animation_segment_duration * 0.4) # Quicker modulate change on ascent

	# 2. Briefly dip down (overshoot effect)
	current_bounce_tween.tween_property(self, "position:y", original_position.y + hover_offset_y_min, animation_segment_duration * 0.3)\
		.set_ease(Tween.EASE_IN_OUT) # Quick dip and return
	current_bounce_tween.tween_property(self, "modulate", original_modulate, animation_segment_duration * 0.3) # Modulate returns quickly

	# 3. Return to original Y position, creating the "bounce"
	current_bounce_tween.tween_property(self, "position:y", original_position.y, animation_segment_duration * 0.7)\
		.set_ease(Tween.EASE_OUT) # Slower, smoother return to rest


func _start_return_animation():
	# Create a new tween specifically for returning to normal position and modulate
	current_return_tween = create_tween()
	current_return_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) # Set global transition for return

	# Animate Y position and modulate color back to original
	current_return_tween.tween_property(self, "position:y", original_position.y, return_duration)
	current_return_tween.tween_property(self, "modulate", original_modulate, return_duration)

	# Connect to the finished signal to clear the tween reference once it's done
	current_return_tween.finished.connect(func():
		if current_return_tween and current_return_tween.is_valid():
			current_return_tween = null # Clear reference after it finishes
	)
