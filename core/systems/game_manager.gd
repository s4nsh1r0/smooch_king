extends Node

signal scene_changed(new_scene_path: String)

var current_scene: Node = null

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	

func change_to_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		printerr("GameManager: Scene path does not exist: ", scene_path)
		return
	call_deferred("_deferred_change_scene", scene_path)

func _deferred_change_scene(scene_path: String) -> void:
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
	
	var new_scene_resource = ResourceLoader.load(scene_path)
	if new_scene_resource:
		current_scene = new_scene_resource.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		scene_changed.emit(scene_path)
	else:
		printerr("GameManager: Failed to load scene: ", scene_path)
