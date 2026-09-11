## Player-facing route selection for the sequential five-arena campaign.
##
## The map only reads and writes campaign snapshots. Chess rules and arena
## rendering stay outside this Control so it can remain a light-weight menu.
extends Control

const CampaignProgress = preload("res://scripts/game/campaign_progress.gd")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const GAME_SCREEN := "res://scenes/app/GameScreen.tscn"

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


func _ready() -> void:
	$Header/Back.pressed.connect(_return_to_main)
	$EnterArena.pressed.connect(_enter_selected_arena)
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
func persist_selection() -> void:
	_session_values = SessionSettings.load_values()
	_session_values["selected_arena_id"] = arena_selected
	_session_values["campaign_snapshot"] = campaign.to_snapshot()
	SessionSettings.save_values(_session_values)


func _enter_selected_arena() -> void:
	persist_selection()
	get_tree().change_scene_to_file(GAME_SCREEN)


func _return_to_main() -> void:
	get_tree().change_scene_to_file("res://scenes/app/Main.tscn")
