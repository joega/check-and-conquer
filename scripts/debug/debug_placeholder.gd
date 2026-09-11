extends Control

@export var tool_title := "Debug Tool"
@export_multiline var tool_description := "This tool will be implemented in a later milestone."


func _ready() -> void:
	$Margin/Content/Title.text = tool_title
	$Margin/Content/Description.text = tool_description
	$Margin/Content/Back.pressed.connect(_return_to_menu)


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/app/CampaignMap.tscn")
