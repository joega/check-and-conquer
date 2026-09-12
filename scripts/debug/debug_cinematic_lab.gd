extends Node3D

## Deterministic preview harness. It never starts Stockfish or touches campaign
## persistence; it projects immutable domain fixtures through the same board,
## ceremony, and cinematic scene used in play.

const BoardState = preload("res://scripts/chess/board_state.gd")
const CinematicCatalog = preload("res://scripts/presentation/campaign_cinematic_catalog.gd")

const FIXTURES := {
	"Opening formation": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
	"Settled victory": "7k/6Q1/7K/8/8/8/8/8 b - - 0 1",
}

var _human_side := 1
var _arena_id := "mountain_fortress"
var _outcome := "intro"
var _cycles_remaining := 0
var _fixture_name := "Opening formation"


func _ready() -> void:
	if $UI/Controls/Arena.item_count < 5:
		$UI/Controls/Arena.add_item("Forest Ruins")
	if $UI/Controls/Outcome.item_count < 4:
		$UI/Controls/Outcome.add_item("Defeat")
		$UI/Controls/Outcome.add_item("Draw")
	$UI/Controls/Play.pressed.connect(_play)
	$UI/Controls/Skip.pressed.connect($CampaignCinematic.skip)
	$UI/Controls/Reset.pressed.connect(_reset)
	$UI/Controls/Stress20.pressed.connect(_stress)
	$CampaignCinematic.finished.connect(_finished)
	$UI/Controls/Side.item_selected.connect(func(index): _human_side = 1 if index == 0 else -1)
	$UI/Controls/Arena.item_selected.connect(func(index): _arena_id = ["mountain_fortress", "arcane_sky_citadel", "frozen_keep", "lava_forge", "forest_ruins"][index]; $BattlefieldEnvironment.apply_arena(_arena_id))
	$UI/Controls/Outcome.item_selected.connect(func(index): _outcome = ["intro", "victory", "defeat", "draw"][index])
	$UI/Controls/Fixture.item_selected.connect(func(index): _fixture_name = $UI/Controls/Fixture.get_item_text(index))
	for fixture_name: String in FIXTURES:
		$UI/Controls/Fixture.add_item(fixture_name)
	call_deferred("_rebuild_fixture")


func _process(_delta: float) -> void:
	var cinematic = get_node_or_null("CampaignCinematic")
	if cinematic == null:
		return
	var title: Label = cinematic.get_node("Overlay/SpeechBubble/Content/Title")
	$UI/Cue.text = "Cue: %s" % (title.text if cinematic.is_active() else "—")


func _play() -> void:
	if $CampaignCinematic.is_active():
		return
	_start_sequence(1.0)


func _stress() -> void:
	if $CampaignCinematic.is_active():
		return
	_cycles_remaining = 20
	# Ceremony root travel uses real-world durations. Keep the stress harness at
	# normal speed so all 20 cycles exercise seating, approach, return, and board
	# restoration instead of racing the director past moving actors.
	_start_sequence(1.0)


func _start_sequence(speed := 1.0) -> void:
	await _rebuild_fixture()
	$CampaignCinematic.playback_speed = speed
	$UI/Status.text = "Playing %s %s — %s…" % [_arena_id.replace("_", " ").capitalize(), _outcome, _fixture_name]
	if _outcome == "intro":
		var speakers: Dictionary = $GrandmasterCeremony.prepare($BoardPresenter, _human_side)
		$CampaignCinematic.play_sequence(CinematicCatalog.sequence_for(_arena_id, "intro"), _human_side, speakers, $GrandmasterCeremony)
	else:
		var speakers: Dictionary = $GrandmasterCeremony.speakers_for_current_board($BoardPresenter, _human_side)
		$CampaignCinematic.play_sequence(CinematicCatalog.terminal_sequence_for(_arena_id, _outcome), _human_side, speakers)


func _finished(_run_id: int, reason: String) -> void:
	if _cycles_remaining > 0:
		_cycles_remaining -= 1
		if _cycles_remaining > 0:
			call_deferred("_start_sequence")
			return
		$UI/Status.text = "20-cycle stress completed without an active cinematic."
		return
	$UI/Status.text = "Finished: %s" % reason


func _reset() -> void:
	_cycles_remaining = 0
	$CampaignCinematic.cancel()
	$BoardCamera.reset_view()
	await _rebuild_fixture()
	$UI/Status.text = "Reset. %s projection and cinematic ownership restored." % _fixture_name


func _rebuild_fixture() -> void:
	if $CampaignCinematic.is_active():
		return
	$GrandmasterCeremony.cleanup()
	$BoardPresenter.rebuild_from_state(BoardState.from_fen(FIXTURES[_fixture_name]))
	await get_tree().process_frame
