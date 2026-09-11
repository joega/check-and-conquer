extends Node3D

const PIECE_ACTOR_SCENE := preload("res://scenes/actors/PieceActor.tscn")
const Types = preload("res://scripts/chess/chess_types.gd")
const CLIPS := {
	"Idle": &"idle.neutral",
	"Walk": &"locomotion.walk.forward",
	"Hit": &"reaction.hit.generic_01",
	"Death": &"death.backward_01",
}

var _actor
const ARCHETYPES := [Types.PAWN, Types.KNIGHT, Types.BISHOP, Types.ROOK, Types.QUEEN, Types.KING]
const ARCHETYPE_LABELS := ["Pawn", "Knight", "Bishop", "Rook", "Queen", "King"]
const PLAYBACK_SPEEDS := [0.25, 0.5, 1.0, 2.0]


func _ready() -> void:
	# The browser is a close inspection scene, so retain a waist-high target
	# after increasing the complete character presentation scale.
	$Camera3D.look_at(Vector3(0.0, 1.85, 0.0), Vector3.UP)
	for label in ARCHETYPE_LABELS:
		$UI/Margin/Controls/Archetype.add_item(label)
	for label in ["0.25×", "0.5×", "1×", "2×"]:
		$UI/Margin/Controls/PlaybackSpeed.add_item(label)
	$UI/Margin/Controls/PlaybackSpeed.select(2)
	$UI/Margin/Controls/Archetype.item_selected.connect(_select_archetype)
	$UI/Margin/Controls/PlaybackSpeed.item_selected.connect(_set_playback_speed)
	_spawn_actor(ARCHETYPES[0])
	for button_name: String in CLIPS:
		get_node("UI/Margin/Controls/%s" % button_name).pressed.connect(_play.bind(CLIPS[button_name], button_name))
	$UI/Margin/Controls/Attack.pressed.connect(_play_primary_attack)
	$UI/Margin/Controls/CombatIdle.pressed.connect(_play_combat_idle)
	$UI/Margin/Controls/Pause.pressed.connect(_toggle_pause)
	$UI/Margin/Controls/Reset.pressed.connect(_reset)
	$UI/Margin/Controls/Back.pressed.connect(_back)


func _spawn_actor(archetype: int) -> void:
	if _actor != null and is_instance_valid(_actor):
		_actor.queue_free()
	_actor = PIECE_ACTOR_SCENE.instantiate()
	_actor.side_color = Color(0.2, 0.48, 0.95)
	_actor.archetype = archetype
	add_child(_actor)
	_actor.set_animation_speed(PLAYBACK_SPEEDS[$UI/Margin/Controls/PlaybackSpeed.selected])
	call_deferred("_finish_spawn")


func _finish_spawn() -> void:
	if _actor != null and is_instance_valid(_actor):
		_actor.set_home_transform(_actor.global_transform)


func _select_archetype(index: int) -> void:
	_spawn_actor(ARCHETYPES[index])
	$UI/Margin/Controls/Status.text = "%s full-character variant loaded." % ARCHETYPE_LABELS[index]


func _play(semantic_id: StringName, label: String) -> void:
	_actor.play_state(semantic_id)
	$UI/Margin/Controls/Pause.text = "Pause"
	$UI/Margin/Controls/Status.text = "%s — %s" % [label, semantic_id]


func _play_primary_attack() -> void:
	var semantic_id: StringName = _actor.primary_attack_state()
	_play(semantic_id, "Primary attack")


func _play_combat_idle() -> void:
	_play(_actor.combat_idle_state(), "Combat idle")


func _reset() -> void:
	_actor.reset_actor()
	$UI/Margin/Controls/Pause.text = "Pause"
	$UI/Margin/Controls/Status.text = "Reset to neutral pose."


func _set_playback_speed(index: int) -> void:
	if _actor == null:
		return
	_actor.set_animation_speed(PLAYBACK_SPEEDS[index])
	$UI/Margin/Controls/Status.text = "Playback speed: %s" % $UI/Margin/Controls/PlaybackSpeed.get_item_text(index)


func _toggle_pause() -> void:
	if _actor == null:
		return
	var paused: bool = not _actor.is_animation_paused()
	_actor.set_animation_paused(paused)
	$UI/Margin/Controls/Pause.text = "Resume" if paused else "Pause"
	$UI/Margin/Controls/Status.text = "Animation paused." if paused else "Animation resumed."


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/app/Main.tscn")
