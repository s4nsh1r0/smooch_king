extends Button

@export var hover_scale_factor: float = 1.1 # How much larger the button gets on hover
@export var animation_duration: float = 0.15 # Duration of the animation in seconds

var original_scale: Vector2
var current_tween: Tween = null # Initialize as null to ensure a clean state

func _ready():
	# Store the original scale of the button when it's ready.
	original_scale = scale

	# Connect the mouse_entered and mouse_exited signals to our functions.
	connect("mouse_entered", _on_Button_mouse_entered)
	connect("mouse_exited", _on_Button_mouse_exited)

	# Ensure the button can receive mouse input.
	mouse_filter = Control.MOUSE_FILTER_STOP


func _on_Button_mouse_entered():
	# If there's an existing tween and it's still valid, kill it to stop any ongoing animation.
	# Killing the tween also frees its tweeners and stops it from being processed.
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null # Explicitly set to null after killing to ensure a fresh start

	# Create a new tween for this specific animation.
	# 'create_tween()' automatically starts the tween when the first tweener is added.
	current_tween = create_tween()
	current_tween.tween_property(self, "scale", original_scale * hover_scale_factor, animation_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_Button_mouse_exited():
	# If there's an existing tween and it's still valid, kill it.
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null # Explicitly set to null after killing

	# Create a new tween for this specific animation.
	current_tween = create_tween()
	current_tween.tween_property(self, "scale", original_scale, animation_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
