extends Node

const DEFAULT_FADE_DURATION := 1.0
const SILENT_VOLUME_DB := -40.0
const NORMAL_VOLUME_DB := 0.0
const SETTINGS_PATH := "user://audio_settings.cfg"
const SAMPLE_RATE := 44100

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var music_tween: Tween
var click_sound: AudioStreamWAV
var panel_open_sound: AudioStreamWAV
var panel_close_sound: AudioStreamWAV
var notification_sound: AudioStreamWAV


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_players()


func _ready() -> void:
	_ensure_audio_players()
	_create_synthesized_sounds()
	_load_settings()
	get_tree().node_added.connect(_on_node_added)
	_connect_buttons_recursive(get_tree().root)

func play_music(
	track: AudioStream,
	fade_duration: float = DEFAULT_FADE_DURATION,
	restart_if_same: bool = false
) -> void:
	_ensure_audio_players()

	if track == null:
		push_warning("SoundManager received a null music track.")
		return

	if track is AudioStreamMP3:
		track.loop = true
	elif track is AudioStreamOggVorbis:
		track.loop = true
	elif track is AudioStreamWAV:
		track.loop_mode = AudioStreamWAV.LOOP_FORWARD

	if (
		music_player.stream == track
		and music_player.playing
		and not restart_if_same
	):
		music_player.stream_paused = false
		return

	_kill_music_tween()

	if music_player.playing:
		await _fade_music_out(fade_duration)

	music_player.stream = track
	music_player.stream_paused = false
	music_player.volume_db = SILENT_VOLUME_DB
	music_player.play()

	_fade_music_in(fade_duration)


func stop_music(fade_duration: float = DEFAULT_FADE_DURATION) -> void:
	_ensure_audio_players()

	if not music_player.playing:
		return

	_kill_music_tween()
	await _fade_music_out(fade_duration)

	music_player.stop()
	music_player.stream = null
	music_player.volume_db = NORMAL_VOLUME_DB


func play_sound(sound: AudioStream, volume_db: float = 0.0) -> void:
	_ensure_audio_players()

	if sound == null:
		return

	var player := _get_available_sfx_player()
	player.stream = sound
	player.volume_db = volume_db
	player.play()


func play_click() -> void:
	play_sound(click_sound, -7.0)


func play_panel_open() -> void:
	play_sound(panel_open_sound, -5.0)


func play_panel_close() -> void:
	play_sound(panel_close_sound, -6.0)


func play_notification() -> void:
	play_sound(notification_sound, -5.0)


func set_master_volume(value: float) -> void:
	var linear_value := clampf(value, 0.0, 1.0)
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value) if linear_value > 0.0 else -80.0)
		AudioServer.set_bus_mute(bus_index, is_zero_approx(linear_value))
	_save_settings(linear_value)


func get_master_volume() -> float:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0 or AudioServer.is_bus_mute(bus_index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))


func pause_music() -> void:
	music_player.stream_paused = true


func resume_music() -> void:
	music_player.stream_paused = false


func _fade_music_in(duration: float) -> void:
	_kill_music_tween()

	if duration <= 0.0:
		music_player.volume_db = NORMAL_VOLUME_DB
		return

	music_tween = create_tween()
	music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	music_tween.set_trans(Tween.TRANS_SINE)
	music_tween.set_ease(Tween.EASE_OUT)
	music_tween.tween_property(
		music_player,
		"volume_db",
		NORMAL_VOLUME_DB,
		duration
	)


func _fade_music_out(duration: float) -> void:
	_kill_music_tween()

	if duration <= 0.0:
		music_player.volume_db = SILENT_VOLUME_DB
		return

	music_tween = create_tween()
	music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	music_tween.set_trans(Tween.TRANS_SINE)
	music_tween.set_ease(Tween.EASE_IN)
	music_tween.tween_property(
		music_player,
		"volume_db",
		SILENT_VOLUME_DB,
		duration
	)

	await music_tween.finished


func _kill_music_tween() -> void:
	if music_tween and music_tween.is_valid():
		music_tween.kill()

	music_tween = null
	
func _ensure_audio_players() -> void:
	if not is_instance_valid(music_player):
		music_player = AudioStreamPlayer.new()
		music_player.name = "MusicPlayer"
		music_player.bus = "Music"
		music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(music_player)

	if sfx_players.is_empty():
		for index in 4:
			var player := AudioStreamPlayer.new()
			player.name = "SFXPlayer%d" % (index + 1)
			player.bus = "SFX"
			player.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(player)
			sfx_players.append(player)


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]


func _create_synthesized_sounds() -> void:
	click_sound = _make_tone([720.0], 0.055, 0.38)
	panel_open_sound = _make_tone([420.0, 680.0], 0.16, 0.34)
	panel_close_sound = _make_tone([650.0, 360.0], 0.14, 0.30)
	notification_sound = _make_tone([660.0, 880.0], 0.22, 0.32)


func _make_tone(frequencies: Array[float], duration: float, amplitude: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for sample_index in sample_count:
		var progress := float(sample_index) / float(maxi(sample_count - 1, 1))
		var frequency_index := mini(int(progress * frequencies.size()), frequencies.size() - 1)
		var local_progress := fmod(progress * frequencies.size(), 1.0)
		var envelope := minf(local_progress / 0.08, 1.0) * pow(1.0 - local_progress, 2.2)
		var sample := sin(TAU * frequencies[frequency_index] * float(sample_index) / SAMPLE_RATE)
		bytes.encode_s16(sample_index * 2, int(sample * envelope * amplitude * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _on_node_added(node: Node) -> void:
	if node is Button:
		_connect_button.call_deferred(node)


func _connect_buttons_recursive(node: Node) -> void:
	if node is Button:
		_connect_button(node)
	for child in node.get_children():
		_connect_buttons_recursive(child)


func _connect_button(button: Button) -> void:
	if not is_instance_valid(button) or button.has_meta("sfx_click_connected"):
		return
	button.pressed.connect(play_click)
	button.set_meta("sfx_click_connected", true)


func _load_settings() -> void:
	var config := ConfigFile.new()
	var volume := 0.8
	if config.load(SETTINGS_PATH) == OK:
		volume = float(config.get_value("audio", "master_volume", volume))
	set_master_volume(volume)


func _save_settings(volume: float) -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", volume)
	config.save(SETTINGS_PATH)
