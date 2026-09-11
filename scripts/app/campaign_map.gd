## Player-facing route selection for the sequential five-arena campaign.
##
## The map only reads and writes campaign snapshots. Chess rules and arena
## rendering stay outside this Control so it can remain a light-weight menu.
extends Control

const CampaignProgress = preload("res://scripts/game/campaign_progress.gd")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const GAME_SCREEN := "res://scenes/app/GameScreen.tscn"
const DEBUG_SCENES := {
	"CombatLab": "res://scenes/debug/DebugCombatLab.tscn",
	"AnimationBrowser": "res://scenes/debug/DebugAnimationBrowser.tscn",
	"PositionLoader": "res://scenes/debug/DebugPositionLoader.tscn",
}

const ROUTE_NODE_NAMES := [
	"MountainFortress", "ArcaneSkyCitadel", "FrozenKeep", "LavaForge", "ForestRuins",
]
const ARENA_TITLES := [
	"Mountain Fortress Terrace", "Arcane Sky Citadel", "Frozen Keep", "Lava Forge", "Forest Ruins",
]

## The arena currently highlighted by the campaign map.
var arena_selected := "mountain_fortress"
var campaign := CampaignProgress.new()
var _session_values: Dictionary = {}
static var _opening_horn_played := false


func _ready() -> void:
	if not _opening_horn_played:
		$OpeningHorn.play()
		_opening_horn_played = true
	$EnterArena.pressed.connect(_enter_selected_arena)
	$PracticeArena.pressed.connect(_enter_practice_arena)
	for button_name: String in DEBUG_SCENES:
		get_node("DebugTools/%s" % button_name).pressed.connect(_open_debug_scene.bind(DEBUG_SCENES[button_name]))
	for index in ROUTE_NODE_NAMES.size():
		get_node("Route/%s" % ROUTE_NODE_NAMES[index]).pressed.connect(select_arena.bind(CampaignProgress.ARENA_IDS[index]))
	load_session_state()


## Restores the map from its persisted snapshot. Public for scene owners and
## deterministic debug/test setup.
func load_session_state() -> void:
	_session_values = SessionSettings.load_values()
	var snapshot: Dictionary = _session_values.get("campaign_snapshot", {})
	set_campaign_snapshot(snapshot)


func set_campaign_snapshot(snapshot: Dictionary) -> void:
	campaign = CampaignProgress.new(snapshot)
	arena_selected = campaign.current_arena()
	refresh_state()


## Repaints lock, conquered, and current-node states after a campaign change.
func refresh_state() -> void:
	for index in ROUTE_NODE_NAMES.size():
		var arena_id: String = CampaignProgress.ARENA_IDS[index]
		var node := get_node_or_null("Route/%s" % ROUTE_NODE_NAMES[index]) as Button
		if node == null:
			continue
		var conquered := arena_id in campaign.completed_ids
		var available := campaign.is_unlocked(arena_id) and not conquered
		node.disabled = not available
		if conquered:
			node.text = "✓  %s\nCONQUERED" % ARENA_TITLES[index]
			node.modulate = Color(0.48, 0.92, 0.62)
		elif available:
			node.text = "◆  %s\nCURRENT ARENA" % ARENA_TITLES[index]
			node.modulate = Color(1.0, 0.82, 0.35)
		else:
			node.text = "🔒  %s\nLOCKED" % ARENA_TITLES[index]
			node.modulate = Color(0.47, 0.52, 0.62)
	$SelectedArena.text = "DESTINATION  ·  %s" % ARENA_TITLES[CampaignProgress.ARENA_IDS.find(arena_selected)]
	$EnterArena.disabled = not campaign.is_unlocked(arena_selected) or arena_selected in campaign.completed_ids


func select_arena(arena_id: String) -> void:
	if not campaign.is_unlocked(arena_id) or arena_id in campaign.completed_ids:
		return
	arena_selected = arena_id
	refresh_state()


## Persists the exact arena and progress snapshot before a match begins.
## Keeping this public makes the hand-off independently testable from scene
## navigation.
func persist_selection(is_campaign_match := true) -> void:
	_session_values = SessionSettings.load_values()
	_session_values["selected_arena_id"] = arena_selected
	_session_values["campaign_snapshot"] = campaign.to_snapshot()
	_session_values["campaign_enabled"] = is_campaign_match
	SessionSettings.save_values(_session_values)


func _enter_selected_arena() -> void:
	persist_selection(true)
	get_tree().change_scene_to_file(GAME_SCREEN)


func _enter_practice_arena() -> void:
	persist_selection(false)
	get_tree().change_scene_to_file(GAME_SCREEN)


func _open_debug_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
