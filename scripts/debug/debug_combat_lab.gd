extends Node3D

const PIECE_ACTOR_SCENE := preload("res://scenes/actors/PieceActor.tscn")
const Types = preload("res://scripts/chess/chess_types.gd")
const ChoreographyResolver = preload("res://scripts/presentation/capture_choreography_resolver.gd")
const ARCHETYPES := [Types.PAWN, Types.KNIGHT, Types.BISHOP, Types.ROOK, Types.QUEEN, Types.KING]
const ARCHETYPE_LABELS := ["Pawn", "Knight", "Bishop", "Rook", "Queen", "King"]
const PLAYBACK_SPEEDS := [0.25, 0.5, 1.0, 2.0]

@onready var _play_button: Button = $UI/Margin/Controls/Play
@onready var _reset_button: Button = $UI/Margin/Controls/Reset
@onready var _status: Label = $UI/Margin/Controls/Status
@onready var _impact_flash: OmniLight3D = $ImpactFlash

var _attacker
var _victim


func _ready() -> void:
	for label in ARCHETYPE_LABELS:
		$UI/Margin/Controls/AttackerArchetype.add_item(label)
		$UI/Margin/Controls/VictimArchetype.add_item(label)
	for label in ["0.25×", "0.5×", "1×", "2×"]:
		$UI/Margin/Controls/PlaybackSpeed.add_item(label)
	$UI/Margin/Controls/PlaybackSpeed.select(2)
	$UI/Margin/Controls/AttackerArchetype.item_selected.connect(_select_attacker)
	$UI/Margin/Controls/VictimArchetype.item_selected.connect(_select_victim)
	$UI/Margin/Controls/PlaybackSpeed.item_selected.connect(_set_playback_speed)
	_spawn_attacker(Types.PAWN)
	_spawn_victim(Types.PAWN)
	$Camera3D.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)
	await get_tree().process_frame
	_attacker.set_home_transform(_attacker.global_transform)
	_victim.set_home_transform(_victim.global_transform)
	$BattleDirector.choreography = ChoreographyResolver.resolve(Types.PAWN)
	$BattleDirector.impact_landed.connect(_show_impact)
	$BattleDirector.presentation_finished.connect(_finish_capture)
	_play_button.pressed.connect(_play_capture)
	_reset_button.pressed.connect(_reset_lab)
	$UI/Margin/Controls/Back.pressed.connect(_back)
	_status.text = "Ready — camera: capture_medium | anchors: 2.6 m"


func _make_actor(actor_name: String, color: Color, position: Vector3, archetype: int):
	var actor = PIECE_ACTOR_SCENE.instantiate()
	actor.name = actor_name
	actor.side_color = color
	actor.side = Types.WHITE if color.b > color.r else Types.BLACK
	actor.archetype = archetype
	actor.position = position
	add_child(actor)
	actor.set_home_transform(actor.global_transform)
	return actor


func _spawn_attacker(archetype: int) -> void:
	if _attacker != null and is_instance_valid(_attacker):
		_attacker.free()
	_attacker = _make_actor("Attacker", Color(0.2, 0.48, 0.95), Vector3(0.0, 0.0, 3.0), archetype)


func _spawn_victim(archetype: int) -> void:
	if _victim != null and is_instance_valid(_victim):
		_victim.free()
	_victim = _make_actor("Victim", Color(0.83, 0.24, 0.22), Vector3(0.0, 0.0, -3.0), archetype)


func _select_attacker(index: int) -> void:
	if not _play_button.disabled:
		_spawn_attacker(ARCHETYPES[index])
		_status.text = "%s attacker loaded." % ARCHETYPE_LABELS[index]


func _select_victim(index: int) -> void:
	if not _play_button.disabled:
		_spawn_victim(ARCHETYPES[index])
		_status.text = "%s victim loaded." % ARCHETYPE_LABELS[index]


func _set_playback_speed(index: int) -> void:
	if not _play_button.disabled:
		$BattleDirector.playback_speed = PLAYBACK_SPEEDS[index]
		_status.text = "Capture speed: %s" % $UI/Margin/Controls/PlaybackSpeed.get_item_text(index)


func _play_capture() -> void:
	_play_button.disabled = true
	_reset_button.disabled = true
	$UI/Margin/Controls/AttackerArchetype.disabled = true
	$UI/Margin/Controls/VictimArchetype.disabled = true
	$UI/Margin/Controls/PlaybackSpeed.disabled = true
	$BattleDirector.choreography = ChoreographyResolver.resolve_matchup(_attacker.archetype, _victim.archetype)
	_status.text = "Approach → %s → impact" % $BattleDirector.choreography.attacker_clip.replace("attack.", "").replace("_", " ")
	$BattleDirector.play_capture(_attacker, _victim, _victim.global_position)


func _reset_lab() -> void:
	_attacker.reset_actor()
	_victim.reset_actor()
	_impact_flash.light_energy = 0.0
	$ImpactAudio.stop()
	_play_button.disabled = false
	_reset_button.disabled = false
	$UI/Margin/Controls/AttackerArchetype.disabled = false
	$UI/Margin/Controls/VictimArchetype.disabled = false
	$UI/Margin/Controls/PlaybackSpeed.disabled = false
	_status.text = "Reset complete — transforms restored exactly."


func _show_impact() -> void:
	_status.text = "Impact — hit reaction / death / spark burst"
	_impact_flash.light_energy = 8.0
	$ImpactAudio.play_impact()
	var tween := create_tween()
	tween.tween_property(_impact_flash, "light_energy", 0.0, 0.12)


func _finish_capture() -> void:
	_status.text = "Capture complete — attacker settled at destination. Reset to replay."
	_reset_button.disabled = false


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/app/CampaignMap.tscn")


func _exit_tree() -> void:
	if has_node("ImpactAudio"):
		$ImpactAudio.stop()
