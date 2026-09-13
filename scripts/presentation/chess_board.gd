extends Node3D

const Mapper = preload("res://scripts/presentation/board_mapper.gd")
const BeveledBoxMesh = preload("res://scripts/presentation/beveled_box_mesh.gd")

@export var square_size := Mapper.SQUARE_SIZE_M
var tiles: Dictionary = {}
var coordinate_labels: Array[Label3D] = []
var _selected_square := -1
var _destinations: Array = []
var _last_move_squares: Array = []
var _hint_squares: Array = []
var _legal_markers: Array[MeshInstance3D] = []
var _square_markers: Array[Node3D] = []

func _ready() -> void:
	_create_board_altar()
	var tile_mesh := BeveledBoxMesh.create(Vector3(square_size * 0.98, 0.12, square_size * 0.98), 0.055)
	var pale_tiles: Array[StandardMaterial3D] = []
	var dark_tiles: Array[StandardMaterial3D] = []
	for variation in [-0.025, 0.0, 0.022]:
		pale_tiles.append(_stone_material(Color("a7977e").lightened(variation) if variation >= 0.0 else Color("a7977e").darkened(-variation), 0.86))
		dark_tiles.append(_stone_material(Color("344640").lightened(variation) if variation >= 0.0 else Color("344640").darkened(-variation), 0.88))
	for rank in 8:
		for file in 8:
			var square := rank * 8 + file
			var tile := MeshInstance3D.new()
			tile.mesh = tile_mesh
			tile.position = Mapper.square_to_world(square, square_size) + Vector3(0, -0.06, 0)
			var variation_index := posmod(file * 5 + rank * 3, 3)
			# Highlight state is tile-local; duplicate the palette sample so one
			# square's emission cannot bleed into every matching variation.
			var material: StandardMaterial3D = (pale_tiles[variation_index] if (file + rank) % 2 == 0 else dark_tiles[variation_index]).duplicate()
			tile.material_override = material
			add_child(tile)
			tiles[square] = tile
	_create_coordinate_labels()


func _stone_material(color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _create_board_altar() -> void:
	var board_extent := Mapper.BOARD_SIZE_M
	var stone := _stone_material(Color("242a2e"), 0.82, 0.06)
	var pedestal := MeshInstance3D.new()
	pedestal.name = "BoardPedestal"
	var pedestal_mesh := BeveledBoxMesh.create(Vector3(board_extent + 2.4, 0.7, board_extent + 2.4), 0.18)
	pedestal.mesh = pedestal_mesh
	pedestal.position.y = -0.43
	pedestal.material_override = stone
	add_child(pedestal)
	var bronze := _stone_material(Color("755330"), 0.48, 0.58)
	var rail_index := 0
	for rail_data in [
		[Vector3(0, -0.03, -(board_extent * 0.5 + 0.48)), Vector3(board_extent + 1.45, 0.24, 0.42)],
		[Vector3(0, -0.03, board_extent * 0.5 + 0.48), Vector3(board_extent + 1.45, 0.24, 0.42)],
		[Vector3(-(board_extent * 0.5 + 0.48), -0.03, 0), Vector3(0.42, 0.24, board_extent + 1.45)],
		[Vector3(board_extent * 0.5 + 0.48, -0.03, 0), Vector3(0.42, 0.24, board_extent + 1.45)],
	]:
		var rail := MeshInstance3D.new()
		rail.name = "BoardBronzeRail%02d" % rail_index
		rail_index += 1
		var rail_mesh := BeveledBoxMesh.create(rail_data[1], 0.075)
		rail.mesh = rail_mesh
		rail.position = rail_data[0]
		rail.material_override = bronze
		add_child(rail)
	var rune_material := StandardMaterial3D.new()
	rune_material.albedo_color = Color("765431")
	rune_material.metallic = 0.58
	rune_material.roughness = 0.50
	rune_material.emission_enabled = false
	rune_material.emission_energy_multiplier = 0.0
	var rune_index := 0
	for corner in [Vector3(-17.1, 0.13, -17.1), Vector3(17.1, 0.13, -17.1), Vector3(-17.1, 0.13, 17.1), Vector3(17.1, 0.13, 17.1)]:
		var rune := MeshInstance3D.new()
		rune.name = "BoardCornerRune%02d" % rune_index
		rune_index += 1
		var rune_mesh := CylinderMesh.new()
		rune_mesh.top_radius = 0.28
		rune_mesh.bottom_radius = 0.36
		rune_mesh.height = 0.12
		rune_mesh.radial_segments = 8
		rune.mesh = rune_mesh
		rune.position = corner
		rune.material_override = rune_material
		add_child(rune)

func set_highlights(selected_square: int, destinations: Array) -> void:
	_selected_square = selected_square
	_destinations = destinations.duplicate()
	_clear_legal_markers()
	for square in _destinations:
		_add_legal_marker(square)
	_refresh_highlights()


func show_last_move(from_square: int, to_square: int) -> void:
	_last_move_squares = [from_square, to_square]
	_refresh_highlights()


func clear_last_move() -> void:
	_last_move_squares.clear()
	_refresh_highlights()


func show_hint(from_square: int, to_square: int) -> void:
	_hint_squares = [from_square, to_square]
	_refresh_highlights()


func clear_hint() -> void:
	_hint_squares.clear()
	_refresh_highlights()


func _refresh_highlights() -> void:
	for marker in _square_markers:
		remove_child(marker)
		marker.queue_free()
	_square_markers.clear()
	for square in tiles:
		var material := tiles[square].material_override as StandardMaterial3D
		material.emission_enabled = false
		material.emission_energy_multiplier = 0.0
		if square in _last_move_squares:
			material.emission_enabled = true
			material.emission = Color(1.0, 0.62, 0.12)
			material.emission_energy_multiplier = 0.06
		if square in _destinations:
			material.emission_enabled = true
			material.emission = Color(0.22, 1.0, 0.34)
			material.emission_energy_multiplier = 0.10
		if square == _selected_square:
			material.emission_enabled = true
			material.emission = Color(0.20, 0.78, 1.0)
			material.emission_energy_multiplier = 0.14
		if square in _hint_squares:
			material.emission_enabled = true
			material.emission = Color(1.0, 0.78, 0.18)
			material.emission_energy_multiplier = 0.18
		if square in _hint_squares:
			_add_square_marker(square, Color("f5c85e"), "Hint")
		elif square == _selected_square:
			_add_square_marker(square, Color("5cdce8"), "Selected")
		elif square in _last_move_squares:
			_add_square_marker(square, Color("c59851"), "LastMove")


func _add_square_marker(square: int, color: Color, kind: String) -> void:
	var frame := Node3D.new()
	frame.name = "%sMarker_%d" % [kind, square]
	frame.position = Mapper.square_to_world(square, square_size) + Vector3.UP * 0.025
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	var span := square_size * 0.88
	for index in 4:
		var edge := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var horizontal := index < 2
		mesh.size = Vector3(span, 0.025, 0.07) if horizontal else Vector3(0.07, 0.025, span)
		edge.mesh = mesh
		edge.position = Vector3(0, 0, span * (0.5 if index == 0 else -0.5)) if horizontal else Vector3(span * (0.5 if index == 2 else -0.5), 0, 0)
		edge.material_override = material
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		frame.add_child(edge)
	add_child(frame)
	_square_markers.append(frame)


func _add_legal_marker(square: int) -> void:
	if not tiles.has(square):
		return
	var marker := MeshInstance3D.new()
	marker.name = "LegalMoveMarker_%d" % square
	var mesh := TorusMesh.new()
	mesh.inner_radius = square_size * 0.17
	mesh.outer_radius = square_size * 0.25
	mesh.rings = 8
	mesh.ring_segments = 20
	marker.mesh = mesh
	marker.position = Mapper.square_to_world(square, square_size) + Vector3(0, 0.028, 0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("66e396")
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.material_override = material
	add_child(marker)
	_legal_markers.append(marker)
	var pulse := marker.create_tween().set_loops()
	pulse.tween_property(marker, "scale", Vector3.ONE * 1.13, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse.tween_property(marker, "scale", Vector3.ONE, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _clear_legal_markers() -> void:
	for marker in _legal_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_legal_markers.clear()


func coordinate_label_count() -> int:
	return coordinate_labels.size()


func _create_coordinate_labels() -> void:
	# Labels live just outside the moveable surface, so the expanded board stays
	# easy to read without adding floating UI over the character models.
	var edge := Mapper.BOARD_SIZE_M * 0.5 + square_size * 0.34
	for file in 8:
		var file_label := _coordinate_label(char("a".unicode_at(0) + file))
		file_label.position = Vector3((file - 3.5) * square_size, 0.18, -edge)
		add_child(file_label)
		coordinate_labels.append(file_label)
	for rank in 8:
		var rank_label := _coordinate_label(str(rank + 1))
		rank_label.position = Vector3(-edge, 0.18, (rank - 3.5) * square_size)
		add_child(rank_label)
		coordinate_labels.append(rank_label)


func _coordinate_label(value: String) -> Label3D:
	var label := Label3D.new()
	label.name = "Coordinate_%s" % value
	label.text = value
	label.font_size = 30
	label.pixel_size = 0.02
	label.outline_size = 5
	label.modulate = Color(0.92, 0.8, 0.48)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return label
