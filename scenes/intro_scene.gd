extends Control

@onready var rolling_text: RichTextLabel = $RollingText
@onready var skip_message: Label = $SkipMessage
@onready var animation_player: AnimationPlayer = $TextRoller

const TEXT_LINES = [
	"You just moved in from your small village to the big city!",
	"Ok ok, Paradise City is not that big, but it's certainly bigger and livelier than your birthplace",
	"You can see a new girl at every corner",
	"Go {player_name}, the world is yours!"
]

const ANIMATION_DURATION = 15.0
const FINAL_SCENE_PATH = "res://scenes/locations/home_scene.tscn"

var is_animation_complete = false

func _ready() -> void:
	if is_instance_valid(rolling_text):
		rolling_text.modulate.a = 0.0
	
	if not _validate_nodes():
		return
	
	if LocationManager:
		LocationManager.set_current_location({
			"name": "Intro Screen",
			"type": "intro",
			"scene_path": "res://scenes/intro_scene.tscn"
		})
		print("IntroScene: Notified LocationManager of current scene type 'intro'.")
	else:
		push_error("IntroScene: LocationManager autoload not found!")
	
	await _setup_ui()
	await _setup_text()
	_create_rolling_animation()

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

func _setup_ui() -> void:
	if is_instance_valid(skip_message):
		skip_message.modulate.a = 0
		skip_message.text = "Press any key to skip..."
		var tween = create_tween()
		if tween:
			tween.tween_property(skip_message, "modulate:a", 0.7, 0.5)
	
	if is_instance_valid(rolling_text):
		rolling_text.fit_content = false
		rolling_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rolling_text.clip_contents = false
		rolling_text.scroll_active = false
		rolling_text.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		
		var viewport_size = get_viewport_rect().size
		var target_size = Vector2(viewport_size.x * 0.8, viewport_size.y)
		var target_x = viewport_size.x * 0.1
		rolling_text.set_deferred("size", target_size)
		rolling_text.set_deferred("position", Vector2(target_x, 0))
		await get_tree().process_frame

func _setup_text() -> void:
	if not is_instance_valid(rolling_text):
		push_error("IntroScene: RollingText is invalid in _setup_text.")
		return
	
	rolling_text.clear()
	var player_name = PlayerData.get_player_name() if PlayerData else "Player"
	for i in range(TEXT_LINES.size()):
		var line = TEXT_LINES[i].replace("{player_name}", player_name)
		rolling_text.append_text(line)
		if i < TEXT_LINES.size() - 1:
			rolling_text.append_text("\n\n")
	
	await get_tree().process_frame

func _create_rolling_animation() -> void:
	if not is_instance_valid(rolling_text) or not is_instance_valid(animation_player):
		push_error("IntroScene: Missing rolling_text or animation_player in _create_rolling_animation.")
		return
	
	var viewport_size = get_viewport_rect().size
	var content_height = rolling_text.get_content_height()
	if content_height <= 0:
		content_height = TEXT_LINES.size() * 80
		push_warning("IntroScene: Content height is 0, using fallback estimate: ", content_height)
	
	var start_y = viewport_size.y + 50
	var end_y = -content_height - 100
	rolling_text.set_deferred("position", Vector2(rolling_text.position.x, start_y))
	
	var anim = Animation.new()
	anim.length = ANIMATION_DURATION
	anim.set_loop_mode(Animation.LOOP_NONE)
	
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, NodePath("RollingText:position:y"))
	anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_LINEAR)
	anim.track_insert_key(track_idx, 0.0, start_y)
	anim.track_insert_key(track_idx, ANIMATION_DURATION, end_y)
	
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("roll_text", anim)
	for lib_name in animation_player.get_animation_library_list():
		animation_player.remove_animation_library(lib_name)
	animation_player.add_animation_library("default", anim_library)
	
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	
	rolling_text.modulate.a = 1.0
	animation_player.play("default/roll_text")
	
	await get_tree().create_timer(0.1).timeout
	if animation_player.is_playing():
		print("IntroScene: Animation started successfully")
	else:
		push_error("IntroScene: Animation failed to start!")

func _input(event: InputEvent) -> void:
	if not is_animation_complete and (
		(event is InputEventKey and event.is_pressed()) or
		(event is InputEventMouseButton and event.is_pressed())
	):
		_skip_intro()

func _skip_intro() -> void:
	if is_animation_complete:
		return
	is_animation_complete = true
	if is_instance_valid(animation_player):
		animation_player.stop()
	if is_instance_valid(rolling_text):
		rolling_text.visible = false
	if is_instance_valid(skip_message):
		skip_message.visible = false
	_transition_to_final_scene()

func _on_animation_finished(anim_name: StringName) -> void:
	print("IntroScene: Animation finished: ", anim_name)
	if anim_name == "default/roll_text" and not is_animation_complete:
		is_animation_complete = true
		await get_tree().create_timer(1.0).timeout
		_transition_to_final_scene()

func _transition_to_final_scene() -> void:
	print("IntroScene: Transitioning to final scene: ", FINAL_SCENE_PATH)
	if is_instance_valid(animation_player):
		animation_player.stop()
	
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		await tween.finished
	
	
	if GameManager:
		GameManager.change_to_scene(FINAL_SCENE_PATH)
	else:
		push_error("IntroScene: GameManager autoload not found!")
