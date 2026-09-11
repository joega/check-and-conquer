extends Node3D

const Mapper = preload("res://scripts/presentation/board_mapper.gd")

@export var square_size := Mapper.SQUARE_SIZE_M
var tiles: Dictionary = {}
var coordinate_labels: Array[Label3D] = []

func _ready() -> void:
	_create_board_altar()
	for rank in 8:
		for file in 8:
			var square := rank * 8 + file
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(square_size * 0.98, 0.12, square_size * 0.98)
			tile.mesh = mesh
			tile.position = Mapper.square_to_world(square, square_size) + Vector3(0, -0.06, 0)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("d8c39a") if (file + rank) % 2 == 0 else Color("4f684e")
			tile.material_override = material
			add_child(tile)
			tiles[square] = tile
	_create_coordinate_labels()


func _create_board_altar() -> void:
	var board_extent := Mapper.BOARD_SIZE_M
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.055, 0.075, 0.10)
	stone.metallic = 0.18
	stone.roughness = 0.74
	var pedestal := MeshInstance3D.new()
	pedestal.name = "BoardPedestal"
	var pedestal_mesh := BoxMesh.new()
	pedestal_mesh.size = Vector3(board_extent + 2.4, 0.7, board_extent + 2.4)
	pedestal.mesh = pedestal_mesh
	pedestal.position.y = -0.43
	pedestal.material_override = stone
	add_child(pedestal)
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.55, 0.34, 0.12)
	bronze.metallic = 0.72
	bronze.roughness = 0.32
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
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = rail_data[1]
		rail.mesh = rail_mesh
		rail.position = rail_data[0]
		rail.material_override = bronze
		add_child(rail)
	var rune_material := StandardMaterial3D.new()
	rune_material.albedo_color = Color(0.20, 0.70, 1.0)
	rune_material.emission_enabled = true
	rune_material.emission = Color(0.06, 0.35, 1.0)
	rune_material.emission_energy_multiplier = 2.4
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
	for square in tiles:
		var material := tiles[square].material_override as StandardMaterial3D
		material.emission_enabled = square == selected_square or square in destinations
		material.emission = Color(0.25, 0.8, 1.0) if square == selected_square else Color(0.2, 0.9, 0.35)
		material.emission_energy_multiplier = 0.7


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
