extends TextureButton

@export var raise_amount: float = -12.0
@export var anim_duration: float = 0.18

var original_position: Vector2
var is_active: bool = false
var current_tween: Tween = null

func _ready() -> void:
	await get_tree().process_frame
	original_position = position
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_active(active: bool) -> void:
	is_active = active
	_animate_to(raise_amount if active else 0.0)

func _on_mouse_entered() -> void:
	if not is_active:
		_animate_to(raise_amount)

func _on_mouse_exited() -> void:
	if not is_active:
		_animate_to(0.0)

func _animate_to(offset_y: float) -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	current_tween = create_tween()
	current_tween.tween_property(self, "position:y", original_position.y + offset_y, anim_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
