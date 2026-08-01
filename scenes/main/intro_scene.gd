extends Control

@onready var rolling_text: RichTextLabel = $RollingText
@onready var skip_message: Label = $SkipMessage
@onready var animation_player: AnimationPlayer = $TextRoller

const TEXT_LINES = [
	"You just moved in from your small village to the big city!",
	"Ok ok, Paradise City is not that big, but it's certainly bigger and livelier than your birthplace.",
	"You can see a new girl at every corner...",
	"Go {player_name}, the world is yours!"
]

const ANIMATION_DURATION := 14.0
const FINAL_SCENE_PATH := "res://scenes/locations/home_scene.tscn"

var is_animation_complete := false

func _ready() -> void:
	if not _validate_nodes():
		return
	
	if LocationManager:
		LocationManager.set_current_location({
			"name": "Intro Screen",
			"type": "intro",
			"scene_path": "res://scenes/main/intro_scene.tscn"
		})
	
	# Start fully transparent
	modulate.a = 0.0
	rolling_text.modulate.a = 0.0
	skip_message.modulate.a = 0.0
	
	await _setup_text()
	_create_rolling_animation()
	
	# Fade the whole scene in
	var fade_in = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.8)
	
	# Fade text in a bit later
	await get_tree().create_timer(0.4).timeout
	var text_fade = create_tween()
	text_fade.tween_property(rolling_text, "modulate:a", 1.0, 0.6)
	
	# Show skip message after a short delay
	await get_tree().create_timer(1.5).timeout
	var skip_fade = create_tween()
	skip_fade.tween_property(skip_message, "modulate:a", 0.75, 0.6)

func _validate_nodes() -> bool:
	if not is_instance_valid(rolling_text):
		push_error("IntroScene: RollingText node not found!")
		return false
	if not is_instance_valid(animation_player):
		push_error("IntroScene: TextRoller AnimationPlayer not found!")
		return false
	if not is_instance_valid(skip_message):
		push_error("IntroScene: SkipMessage node not found!")
		return false
	return true

func _setup_text() -> void:
	rolling_text.clear()
	var player_name = "Player"
	if PlayerData:
		player_name = PlayerData.get_player_name()
	
	for i in range(TEXT_LINES.size()):
		var line = TEXT_LINES[i].replace("{player_name}", player_name)
		rolling_text.append_text(line)
		if i < TEXT_LINES.size() - 1:
			rolling_text.append_text("\n\n")
	
	await get_tree().process_frame

func _create_rolling_animation() -> void:
	var viewport_size = get_viewport_rect().size
	var content_height = rolling_text.get_content_height()
	if content_height <= 0:
		content_height = TEXT_LINES.size() * 90
	
	var start_y = viewport_size.y + 40
	var end_y = -content_height - 80
	
	rolling_text.position.y = start_y
	
	var anim = Animation.new()
	anim.length = ANIMATION_DURATION
	anim.loop_mode = Animation.LOOP_NONE
	
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, NodePath("RollingText:position:y"))
	anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(track_idx, 0.0, start_y)
	anim.track_insert_key(track_idx, ANIMATION_DURATION, end_y)
	
	# Clean previous libraries
	for lib_name in animation_player.get_animation_library_list():
		animation_player.remove_animation_library(lib_name)
	
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("roll_text", anim)
	animation_player.add_animation_library("default", anim_library)
	
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	
	animation_player.play("default/roll_text")

func _input(event: InputEvent) -> void:
	if is_animation_complete:
		return
	
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_skip_intro()

func _skip_intro() -> void:
	if is_animation_complete:
		return
	is_animation_complete = true
	
	if animation_player.is_playing():
		animation_player.stop()
	
	rolling_text.visible = false
	skip_message.visible = false
	_transition_to_final_scene()

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"default/roll_text" and not is_animation_complete:
		is_animation_complete = true
		await get_tree().create_timer(1.2).timeout
		_transition_to_final_scene()

func _transition_to_final_scene() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	await tween.finished
	
	if GameManager:
		GameManager.change_to_scene(FINAL_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(FINAL_SCENE_PATH)
