## Player-facing route selection for the sequential five-arena campaign.
##
## The map only reads and writes campaign snapshots. Chess rules and arena
## rendering stay outside this Control so it can remain a light-weight menu.
extends Control

const CampaignProgress = preload("res://scripts/game/campaign_progress.gd")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const ArenaCatalog = preload("res://scripts/presentation/arena_catalog.gd")
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
var practice_arena_id := "mountain_fortress"
var campaign := CampaignProgress.new()
var _session_values: Dictionary = {}
func _ready() -> void:
	$EnterArena.pressed.connect(_enter_selected_arena)
	$PracticeArena.pressed.connect(_enter_practice_arena)
	$PracticeArenaPicker.item_selected.connect(_select_practice_arena)
	for arena_id in CampaignProgress.ARENA_IDS:
		$PracticeArenaPicker.add_item(ArenaCatalog.definition(arena_id).title)
		$PracticeArenaPicker.set_item_metadata($PracticeArenaPicker.item_count - 1, arena_id)
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
	practice_arena_id = str(_session_values.get("selected_arena_id", arena_selected))
	if not practice_arena_id in CampaignProgress.ARENA_IDS:
		practice_arena_id = arena_selected
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
		var label_color := Color(1.0, 0.82, 0.35)
		if conquered:
			node.text = "✓  %s\nCONQUERED" % ARENA_TITLES[index]
			label_color = Color(0.48, 0.92, 0.62)
		elif available:
			var arena := ArenaCatalog.definition(arena_id)
			node.text = "◆  %s\nCURRENT · %s" % [ARENA_TITLES[index], str(arena.opponent).to_upper()]
		else:
			node.text = "🔒  %s\nLOCKED" % ARENA_TITLES[index]
		# Lock state must not dim the whole card; the icon and text carry the
		# availability cue while the illustrated map remains legible behind it.
		node.modulate = Color.WHITE
		node.add_theme_color_override("font_color", label_color)
		node.add_theme_color_override("font_disabled_color", label_color)
		_apply_route_hierarchy(node, available)
	$EnterArena.disabled = not campaign.is_unlocked(arena_selected) or arena_selected in campaign.completed_ids
	var selected_arena := ArenaCatalog.definition(arena_selected)
	$CampaignFocus/Chapter.text = "%s  ·  CURRENT OBJECTIVE" % str(selected_arena.chapter).to_upper()
	$CampaignFocus/Title.text = str(selected_arena.title)
	$CampaignFocus/Detail.text = "%s  —  %s" % [str(selected_arena.opponent), str(selected_arena.intro)]
	$EnterArena.text = "ENTER ARENA  ·  %s" % str(selected_arena.title).to_upper()
	var practice_index := CampaignProgress.ARENA_IDS.find(practice_arena_id)
	$PracticeArenaPicker.select(maxi(practice_index, 0))


func _apply_route_hierarchy(card: Button, is_current: bool) -> void:
	# One current route card acts as the campaign's visual destination. Locked
	# and conquered locations keep their readable backing but deliberately lose
	# the gold keyline, so the central action does not compete with five peers.
	var base := card.get_theme_stylebox("normal") as StyleBoxFlat
	if base == null:
		return
	var style := base.duplicate() as StyleBoxFlat
	style.border_width_left = 3 if is_current else 1
	style.border_width_top = 3 if is_current else 1
	style.border_width_right = 3 if is_current else 1
	style.border_width_bottom = 3 if is_current else 1
	style.border_color = Color(1.0, 0.76, 0.25, 0.96) if is_current else Color(0.82, 0.61, 0.22, 0.28)
	style.bg_color = Color(0.06, 0.09, 0.14, 0.88) if is_current else Color(0.025, 0.045, 0.08, 0.68)
	card.add_theme_stylebox_override("normal", style)
	card.add_theme_stylebox_override("disabled", style)


func select_arena(arena_id: String) -> void:
	if not campaign.is_unlocked(arena_id) or arena_id in campaign.completed_ids:
		return
	arena_selected = arena_id
	refresh_state()


## Persists the exact arena and progress snapshot before a match begins.
## Keeping this public makes the hand-off independently testable from scene
## navigation.
func persist_selection(is_campaign_match := true, selected_id := "") -> void:
	var arena_id := arena_selected if selected_id.is_empty() else selected_id
	_session_values = SessionSettings.load_values()
	_session_values["selected_arena_id"] = arena_id
	_session_values["campaign_snapshot"] = campaign.to_snapshot()
	_session_values["campaign_enabled"] = is_campaign_match
	SessionSettings.save_values(_session_values)


func _enter_selected_arena() -> void:
	persist_selection(true)
	get_tree().change_scene_to_file(GAME_SCREEN)


func _enter_practice_arena() -> void:
	persist_selection(false, practice_arena_id)
	get_tree().change_scene_to_file(GAME_SCREEN)


func _select_practice_arena(index: int) -> void:
	practice_arena_id = str($PracticeArenaPicker.get_item_metadata(index))


func _open_debug_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
