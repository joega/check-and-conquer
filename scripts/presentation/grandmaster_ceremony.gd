class_name GrandmasterCeremony
extends Node3D

## A pre-match presentation stage. It owns no chess state: the two kings are
## borrowed from BoardPresenter and every exit restores their exact projection.

const Types = preload("res://scripts/chess/chess_types.gd")
const CHAIR_SCENE = preload("res://assets/environment/quaternius_props/Chair_1.gltf")
const BANNER_SCENE = preload("res://assets/environment/quaternius_props/Banner_1.gltf")
const TORCH_SCENE = preload("res://assets/environment/quaternius_props/Torch_Metal.gltf")
const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")
const PARLEY_WALK_DURATION := 1.1
const GRANDMASTER_SCALE := 1.48
const GRANDMASTER_CHAIR_SCALE := 2.75
## UAL Sitting_Idle places the pelvis behind the actor root. Move that root
## forward so the hips rest over the seat and the knees clear its front edge.
const GRANDMASTER_SEAT_FORWARD := 0.60

var _board_presenter
var _home_transforms: Dictionary = {}
var _grandmaster
var _chair: Node3D
var _grandmaster_seat_position := Vector3.ZERO
var _grandmaster_seated := false
var _grandmaster_seating_tween: Tween
var _parley_arrival_tween: Tween
var _settlement_tween: Tween
var _actor_tweens: Array[Tween] = []
var _active := false
var _kings_returning := false
var _parley_arrivals: Dictionary = {}
var _operation_generation := 0
var _grandmaster_home_transform: Transform3D


func _ready() -> void:
	_build_dais()


func _exit_tree() -> void:
	cleanup()


func prepare(board_presenter, human_side: int) -> Dictionary:
	cleanup()
	_operation_generation += 1
	_active = true
	_kings_returning = false
	_parley_arrivals.clear()
	_board_presenter = board_presenter
	_reset_grandmaster()
	var speakers := {"grandmaster": _grandmaster}
	var king_index := 0
	for actor in _board_presenter.actors.values():
		_home_transforms[actor] = actor.global_transform
		if actor.archetype != Types.KING:
			actor.visible = false
			continue
		var is_commander: bool = actor.side == human_side
		speakers["commander" if is_commander else "gatekeeper"] = actor
		actor.visible = true
		# Both kings arrive through separate side gates; these are terrace markers,
		# deliberately outside the chess grid rather than fake chess squares.
		actor.global_position = Vector3(-12.0 if king_index == 0 else 12.0, 0.0, -17.0)
		actor.face_world_position(Vector3(0.0, 0.0, -6.5))
		actor.play_state(&"idle.neutral")
		king_index += 1
	_grandmaster.visible = true
	return speakers


func bring_kings_to_parley() -> void:
	if not _active:
		return
	_cancel_actor_tweens()
	if _parley_arrival_tween != null and _parley_arrival_tween.is_valid():
		_parley_arrival_tween.kill()
	_parley_arrivals.clear()
	var generation := _operation_generation
	var index := 0
	for actor in _home_transforms:
		if actor.archetype != Types.KING:
			continue
		var destination := Vector3(-3.2 if index == 0 else 3.2, 0.0, -6.5)
		actor.face_world_position(Vector3.ZERO)
		actor.play_state(&"locomotion.walk.forward")
		_parley_arrivals[actor] = destination
		var tween := _track_tween(create_tween())
		tween.tween_property(actor, "global_position", destination, PARLEY_WALK_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		index += 1
	# This is deliberately one shared barrier, rather than two actor callbacks.
	# Dialogue never decides who stops: when the entrance time elapses, both kings
	# are snapped to their own markers and both locomotion clips end together.
	_parley_arrival_tween = create_tween()
	_parley_arrival_tween.tween_interval(PARLEY_WALK_DURATION)
	_parley_arrival_tween.tween_callback(_complete_parley_arrivals.bind(generation))


func begin_grandmaster_seating() -> void:
	if _grandmaster == null or not is_instance_valid(_grandmaster) or _grandmaster_seated:
		return
	if _grandmaster_seating_tween != null and _grandmaster_seating_tween.is_valid():
		return
	_grandmaster.visible = true
	_grandmaster.face_world_position(Vector3.ZERO)
	_grandmaster.play_state(&"ceremony.seat.enter")
	var duration := clampf(_grandmaster.state_duration(&"ceremony.seat.enter"), 0.65, 1.25)
	_grandmaster_seating_tween = create_tween()
	_grandmaster_seating_tween.tween_property(_grandmaster, "global_position", _grandmaster_seat_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_grandmaster_seating_tween.finished.connect(_finish_grandmaster_seating.bind(_operation_generation), CONNECT_ONE_SHOT)


func set_dialogue_speaker(speaker) -> void:
	if not _active:
		return
	for actor in _home_transforms:
		if actor.archetype != Types.KING:
			continue
		# A line may be queued before a slower frame completes the travel tween.
		# Speech setup must never be what stops a moving king.
		if _parley_arrivals.has(actor):
			continue
		actor.set_animation_speed(1.0)
		if actor == speaker:
			actor.play_state(&"idle.talking_01")
		else:
			actor.play_state(&"idle.neutral")


func hold_kings_for_dialogue() -> void:
	if not _active:
		return
	for actor in _home_transforms:
		if actor.archetype == Types.KING:
			_hold_king_for_parley(actor)


func return_kings_to_board() -> void:
	if not _active:
		return
	_kings_returning = true
	_cancel_actor_tweens()
	var generation := _operation_generation
	for actor in _home_transforms:
		if actor.archetype != Types.KING:
			continue
		var home: Transform3D = _home_transforms[actor]
		actor.face_world_position(home.origin)
		var run_duration := 0.78
		actor.play_state(&"locomotion.run.forward")
		actor.set_animation_speed(maxf(actor.state_duration(&"locomotion.run.forward") / run_duration, 0.01))
		var tween := _track_tween(create_tween())
		tween.tween_property(actor, "global_position", home.origin, run_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.finished.connect(_finish_king_return.bind(actor, home, generation), CONNECT_ONE_SHOT)


func settle_board_formation() -> void:
	if not _active:
		return
	_cancel_actor_tweens()
	var delay := 0.0
	var generation := _operation_generation
	for actor in _home_transforms:
		var home: Transform3D = _home_transforms[actor]
		actor.visible = true
		if actor.archetype == Types.KING:
			if not _kings_returning:
				actor.global_transform = home
				actor.start_battle_stance()
			continue
		# A small vertical materialization reads as an arrival but ends exactly at
		# the original authoritative actor transform.
		actor.global_transform = home.translated(Vector3.UP * 1.25)
		var tween := _track_tween(create_tween())
		tween.tween_interval(delay)
		tween.tween_property(actor, "global_transform", home, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(actor.start_battle_stance)
		delay += 0.018
	_settlement_tween = create_tween()
	_settlement_tween.tween_interval(delay + 0.28)
	_settlement_tween.tween_callback(_complete_settlement.bind(generation))


func cleanup() -> void:
	_operation_generation += 1
	_cancel_actor_tweens()
	if _settlement_tween != null and _settlement_tween.is_valid():
		_settlement_tween.kill()
	_settlement_tween = null
	if _parley_arrival_tween != null and _parley_arrival_tween.is_valid():
		_parley_arrival_tween.kill()
	_parley_arrival_tween = null
	if _grandmaster_seating_tween != null and _grandmaster_seating_tween.is_valid():
		_grandmaster_seating_tween.kill()
	_grandmaster_seating_tween = null
	for actor in _home_transforms:
		if actor != null and is_instance_valid(actor):
			actor.global_transform = _home_transforms[actor]
			actor.visible = true
			actor.start_battle_stance()
	_home_transforms.clear()
	_active = false
	_kings_returning = false
	_parley_arrivals.clear()
	_reset_grandmaster()


func _hold_king_for_parley(actor) -> void:
	if actor == null or not is_instance_valid(actor) or not _active:
		return
	actor.set_animation_speed(1.0)
	actor.play_state(&"idle.neutral")


func _complete_parley_arrivals(generation: int) -> void:
	if not _active or generation != _operation_generation:
		return
	for actor in _parley_arrivals:
		if actor == null or not is_instance_valid(actor):
			continue
		actor.global_position = _parley_arrivals[actor]
		_hold_king_for_parley(actor)
	_parley_arrivals.clear()
	_parley_arrival_tween = null


func _finish_king_return(actor, home: Transform3D, generation: int) -> void:
	if generation != _operation_generation or actor == null or not is_instance_valid(actor):
		return
	actor.set_animation_speed(1.0)
	actor.global_transform = home
	actor.start_battle_stance()


func _complete_settlement(generation: int) -> void:
	if generation != _operation_generation or not _active:
		return
	# Retain home transforms while the director can still be skipped or reset.
	_kings_returning = false
	_parley_arrivals.clear()
	_settlement_tween = null


func _track_tween(tween: Tween) -> Tween:
	_actor_tweens.append(tween)
	return tween


func _cancel_actor_tweens() -> void:
	for tween in _actor_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_actor_tweens.clear()


func _reset_grandmaster() -> void:
	if _grandmaster == null or not is_instance_valid(_grandmaster):
		return
	_grandmaster.global_transform = _grandmaster_home_transform
	_grandmaster.visible = true
	_grandmaster.set_animation_speed(1.0)
	_grandmaster_seated = false
	if _grandmaster.is_inside_tree():
		_finish_grandmaster_setup()


func speakers_for_current_board(board_presenter, human_side: int) -> Dictionary:
	var speakers := {"grandmaster": _grandmaster}
	for actor in board_presenter.actors.values():
		if actor != null and is_instance_valid(actor) and actor.archetype == Types.KING:
			speakers["commander" if actor.side == human_side else "gatekeeper"] = actor
	return speakers


func _build_dais() -> void:
	# The Grandmaster remains on this side terrace, beyond the rail and outside
	# BoardPresenter. Chair_1 is deliberately documented as a temporary throne.
	var dais := Node3D.new()
	dais.name = "GrandmasterDais"
	dais.position = Vector3(20.0, -0.55, 0.0)
	add_child(dais)
	var stone := _material(Color(0.12, 0.11, 0.16))
	_add_box(dais, "DaisBase", Vector3(5.0, 0.85, 5.0), Vector3(0.0, 0.42, 0.0), stone)
	_add_box(dais, "DaisStep", Vector3(3.7, 0.48, 3.5), Vector3(0.0, 1.05, -0.38), stone)
	_chair = CHAIR_SCENE.instantiate() as Node3D
	_chair.name = "TemporaryThroneChair"
	_chair.position = Vector3(0.0, 1.25, 0.62)
	_chair.rotation.y = PI
	# The 0.50 m source seat becomes 1.375 m high, matching the underside of
	# the seated thighs at the actor's effective 2.96 display scale.
	_chair.scale = Vector3.ONE * GRANDMASTER_CHAIR_SCALE
	dais.add_child(_chair)
	for side in [-1.0, 1.0]:
		var banner := BANNER_SCENE.instantiate() as Node3D
		banner.position = Vector3(side * 2.25, 1.2, 1.45)
		banner.scale = Vector3.ONE * 1.45
		dais.add_child(banner)
		var torch := TORCH_SCENE.instantiate() as Node3D
		torch.position = Vector3(side * 2.2, 1.15, -1.45)
		torch.scale = Vector3.ONE * 2.5
		dais.add_child(torch)
		_add_torch_light(dais, Vector3(side * 2.15, 2.7, -1.45))
	_grandmaster = ACTOR_SCENE.instantiate()
	_grandmaster.name = "Grandmaster"
	_grandmaster.archetype = Types.QUEEN
	_grandmaster.side = Types.WHITE
	_grandmaster.side_color = Color(0.18, 0.07, 0.26)
	_grandmaster.appearance_seed = 91
	# Seat placement is finalized after the dais receives its board-facing
	# rotation; its skeleton pelvis is not at the actor root.
	_grandmaster.position = Vector3(0.0, 0.70, 0.0)
	_grandmaster.scale = Vector3.ONE * GRANDMASTER_SCALE
	add_child(_grandmaster)
	dais.look_at(Vector3.ZERO, Vector3.UP)
	# Chair_1's feet begin at local y=0.  Its root is already placed on the dais
	# floor, so this keeps the actor root on that same floor while the UAL1
	# sitting pose lowers the body into the chair's measured seat height.
	_grandmaster_seat_position = _chair.global_position
	_grandmaster_seat_position.y = _grandmaster.global_position.y
	_grandmaster_seat_position -= dais.global_basis.z * GRANDMASTER_SEAT_FORWARD
	_grandmaster.global_position = _grandmaster_seat_position
	_grandmaster.face_world_position(Vector3.ZERO)
	_grandmaster_home_transform = _grandmaster.global_transform
	call_deferred("_finish_grandmaster_setup")


func _finish_grandmaster_setup() -> void:
	var accents := _grandmaster.get_node_or_null("VisualAccents") as Node3D
	if accents != null:
		accents.visible = false
	_grandmaster.set_equipped_weapons_visible(false)
	_grandmaster.global_position = _grandmaster_seat_position
	_grandmaster.face_world_position(Vector3.ZERO)
	_grandmaster.play_state(&"ceremony.seat.idle")
	_grandmaster_seated = true


func _finish_grandmaster_seating(generation := _operation_generation) -> void:
	if generation != _operation_generation or _grandmaster == null or not is_instance_valid(_grandmaster):
		return
	_grandmaster.global_position = _grandmaster_seat_position
	_grandmaster.face_world_position(Vector3.ZERO)
	_grandmaster.set_animation_speed(1.0)
	_grandmaster.play_state(&"ceremony.seat.idle")
	_grandmaster_seated = true
	_grandmaster_seating_tween = null


func _add_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: StandardMaterial3D) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = material
	parent.add_child(mesh)


func _add_torch_light(parent: Node3D, position: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = Color(1.0, 0.58, 0.20)
	light.light_energy = 2.1
	light.omni_range = 8.0
	parent.add_child(light)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material
