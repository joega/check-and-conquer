extends Control

const DEBUG_SCENES := {
	"CombatLab": "res://scenes/debug/DebugCombatLab.tscn",
	"AnimationBrowser": "res://scenes/debug/DebugAnimationBrowser.tscn",
	"PositionLoader": "res://scenes/debug/DebugPositionLoader.tscn",
}


func _ready() -> void:
	$Margin/Content/PlayLocal.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/app/GameScreen.tscn"))
	for button_name: String in DEBUG_SCENES:
		get_node("Margin/Content/%s" % button_name).pressed.connect(_open_debug_scene.bind(DEBUG_SCENES[button_name]))


func _open_debug_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
