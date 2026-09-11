extends Control

const DEBUG_SCENES := {
	"CombatLab": "res://scenes/debug/DebugCombatLab.tscn",
	"AnimationBrowser": "res://scenes/debug/DebugAnimationBrowser.tscn",
	"PositionLoader": "res://scenes/debug/DebugPositionLoader.tscn",
}
const GAME_SCREEN := "res://scenes/app/GameScreen.tscn"
const CAMPAIGN_MAP := "res://scenes/app/CampaignMap.tscn"
const SessionSettings = preload("res://scripts/game/session_settings.gd")

var _loading_scene_path := ""
var _loading_started_at_msec := 0


func _ready() -> void:
	$Margin/Content/PlayLocal.pressed.connect(_begin_practice)
	$Margin/Content/Campaign.pressed.connect(_begin_campaign)
	for button_name: String in DEBUG_SCENES:
		get_node("Margin/Content/%s" % button_name).pressed.connect(_begin_loading.bind(DEBUG_SCENES[button_name]))
	$LoadingOverlay.visible = false
	# Make the first action immediately available from a keyboard/controller.
	# This also makes a fresh launch feel responsive before a pointer is moved.
	$Margin/Content/Campaign.grab_focus()


func _begin_loading(scene_path: String) -> void:
	if not _loading_scene_path.is_empty():
		return
	_loading_scene_path = scene_path
	_loading_started_at_msec = Time.get_ticks_msec()
	$LoadingOverlay.visible = true
	$LoadingOverlay/Panel/Message.text = "Preparing the battlefield…"
	$LoadingOverlay/Panel/Progress.value = 4.0
	for button_name: String in ["PlayLocal", "Campaign", "CombatLab", "AnimationBrowser", "PositionLoader"]:
		get_node("Margin/Content/%s" % button_name).disabled = true
	var request_error := ResourceLoader.load_threaded_request(scene_path)
	if request_error != OK:
		$LoadingOverlay/Panel/Message.text = "Unable to load this scene. Please try again."
		_loading_scene_path = ""
		for button_name: String in ["PlayLocal", "Campaign", "CombatLab", "AnimationBrowser", "PositionLoader"]:
			get_node("Margin/Content/%s" % button_name).disabled = false


func _begin_practice() -> void:
	var settings := SessionSettings.load_values()
	settings.campaign_enabled = false
	SessionSettings.save_values(settings)
	_begin_loading(GAME_SCREEN)


func _begin_campaign() -> void:
	var settings := SessionSettings.load_values()
	settings.campaign_enabled = true
	SessionSettings.save_values(settings)
	_begin_loading(CAMPAIGN_MAP)


func _process(_delta: float) -> void:
	if _loading_scene_path.is_empty():
		return
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(_loading_scene_path, progress)
	var displayed_progress := maxf(float(progress[0]) * 100.0 if not progress.is_empty() else 0.0, 4.0)
	$LoadingOverlay/Panel/Progress.value = displayed_progress
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		# Keep the acknowledgement on screen for a short beat, even if the scene
		# was cached, so a first-time player never interprets a click as ignored.
		if Time.get_ticks_msec() - _loading_started_at_msec < 250:
			return
		var packed_scene := ResourceLoader.load_threaded_get(_loading_scene_path) as PackedScene
		_loading_scene_path = ""
		if packed_scene != null:
			get_tree().change_scene_to_packed(packed_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		$LoadingOverlay/Panel/Message.text = "Unable to load this scene. Please try again."
		_loading_scene_path = ""
		for button_name: String in ["PlayLocal", "Campaign", "CombatLab", "AnimationBrowser", "PositionLoader"]:
			get_node("Margin/Content/%s" % button_name).disabled = false
