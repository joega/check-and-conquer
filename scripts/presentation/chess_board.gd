extends Node3D

const Mapper = preload("res://scripts/presentation/board_mapper.gd")

@export var square_size := Mapper.SQUARE_SIZE_M
var tiles: Dictionary = {}
var coordinate_labels: Array[Label3D] = []

func _ready() -> void:
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
