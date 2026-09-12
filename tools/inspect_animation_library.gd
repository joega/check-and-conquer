extends SceneTree


func _init() -> void:
	call_deferred("_inspect")


func _inspect() -> void:
	for scene_path: String in [
		"res://assets/characters/quaternius/Superhero_Male_FullBody.gltf",
		"res://assets/animations/quaternius/UAL1_Standard.glb",
		"res://assets/animations/quaternius/UAL2_Standard.glb",
	]:
		var packed_scene := load(scene_path) as PackedScene
		assert(packed_scene != null, "Could not load: %s" % scene_path)
		var root := packed_scene.instantiate()
		print("SCENE: %s" % scene_path)
		_print_tree(root)
		var animation_player := root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if animation_player != null:
			for library_name: StringName in animation_player.get_animation_library_list():
				var library := animation_player.get_animation_library(library_name)
				for animation_name: StringName in library.get_animation_list():
					print("ANIMATION: %s%s" % [library_name, animation_name])
		root.free()
	quit(0)


func _print_tree(node: Node, indent := "") -> void:
	print("%s%s <%s>" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_print_tree(child, indent + "  ")
