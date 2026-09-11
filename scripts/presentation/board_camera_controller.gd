class_name BoardCameraController
extends Camera3D

## Player-controlled board framing. Capture staging temporarily overrides this
## camera, then CameraDirector restores the current board transform.

@export var target := Vector3.ZERO
@export var min_distance := 3.5
@export var max_distance := 72.0
@export var zoom_step := 1.6
@export var orbit_sensitivity := 0.012
@export var pan_sensitivity := 0.0035
@export var pan_limit_m := 20.0
@export var close_focus_height := 3.0
@export var close_focus_distance := 14.0
@export var close_focus_pitch := 0.30
@export var default_board_distance := 42.0
@export var default_board_pitch := 0.70
@export var default_snap_duration_s := 0.32

var _distance := 40.0
var _yaw := 0.0
var _pitch := 0.62
var _home_target := Vector3.ZERO
var _home_distance := 40.0
var _home_yaw := 0.0
var _home_pitch := 0.62
var _rotating := false
var _panning := false
var _controls_enabled := true
var _focused_side := 1
var _snap_tween: Tween


func _ready() -> void:
	var offset := global_position - target
	_distance = clampf(offset.length(), min_distance, max_distance)
	_yaw = atan2(offset.x, offset.z)
	_pitch = asin(clampf(offset.y / _distance, -0.98, 0.98))
	_home_target = target
	_home_distance = _distance
	_home_yaw = _yaw
	_home_pitch = _pitch
	_apply_orbit()


func _unhandled_input(event: InputEvent) -> void:
	if not _controls_enabled:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_rotating = event.pressed
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(-zoom_step)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(zoom_step)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _rotating:
		orbit_by(-event.relative.x * orbit_sensitivity, -event.relative.y * orbit_sensitivity)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _panning:
		pan_by(event.relative)
		get_viewport().set_input_as_handled()


func zoom_by(amount: float) -> void:
	_distance = clampf(_distance + amount, min_distance, max_distance)
	_apply_orbit()


func orbit_by(yaw_delta: float, pitch_delta: float) -> void:
	_yaw += yaw_delta
	_pitch = clampf(_pitch + pitch_delta, 0.24, 1.22)
	_apply_orbit()


func pan_by(drag_delta: Vector2) -> void:
	# Pan along the board plane using the current camera axes. This lets players
	# bring any piece under the close face-level focus without changing the
	# default turn-aware framing used after moves.
	var right := global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var distance_scale := _distance * pan_sensitivity
	target += -right * drag_delta.x * distance_scale + forward * drag_delta.y * distance_scale
	target.x = clampf(target.x, -pan_limit_m, pan_limit_m)
	target.y = 0.0
	target.z = clampf(target.z, -pan_limit_m, pan_limit_m)
	_apply_orbit()


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if not enabled:
		_rotating = false
		_panning = false
		_cancel_snap()


func controls_enabled() -> bool:
	return _controls_enabled


func reset_view() -> void:
	snap_to_side(_focused_side, 0.0)


func focused_side() -> int:
	return _focused_side


func snap_to_side(side: int, duration_s := -1.0) -> void:
	# White's player-side view is from the rank-one end looking toward Black;
	# Black receives the mirrored view from rank eight. The diagonal offset gives
	# depth without hiding files behind one another.
	_focused_side = 1 if side >= 0 else -1
	target = _home_target
	_distance = default_board_distance
	_pitch = default_board_pitch
	_yaw = 2.35 if _focused_side > 0 else -0.79
	var destination := _orbit_transform()
	var actual_duration := default_snap_duration_s if duration_s < 0.0 else duration_s
	_cancel_snap()
	if actual_duration <= 0.0:
		global_transform = destination
		return
	_snap_tween = create_tween()
	_snap_tween.tween_property(self, "global_transform", destination, actual_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_snap_tween.finished.connect(func(): _snap_tween = null)


func current_focus_target() -> Vector3:
	# Full-board framing stays centered on the board. As the player zooms close,
	# lift the focal target smoothly to the enlarged character's face/chest area
	# so close inspection never turns into a floor-level view.
	var range := maxf(close_focus_distance - min_distance, 0.001)
	var close_weight := clampf((close_focus_distance - _distance) / range, 0.0, 1.0)
	return target + Vector3.UP * lerpf(0.0, close_focus_height, close_weight)


func _apply_orbit() -> void:
	global_transform = _orbit_transform()


func _orbit_transform() -> Transform3D:
	var focus_target := current_focus_target()
	# A board angle is ideal at full-board distance, but it looks down on the
	# floor once a player zooms into a character. Ease into a shallow camera
	# pitch alongside the lifted face target so close inspection feels eye-level.
	var range := maxf(close_focus_distance - min_distance, 0.001)
	var close_weight := clampf((close_focus_distance - _distance) / range, 0.0, 1.0)
	var effective_pitch := lerpf(_pitch, close_focus_pitch, close_weight)
	var horizontal := cos(effective_pitch) * _distance
	var position := focus_target + Vector3(sin(_yaw) * horizontal, sin(effective_pitch) * _distance, cos(_yaw) * horizontal)
	return Transform3D(Basis.looking_at(focus_target - position, Vector3.UP), position)


func _cancel_snap() -> void:
	if _snap_tween != null and _snap_tween.is_valid():
		_snap_tween.kill()
	_snap_tween = null
