extends Node3D

const Mapper = preload("res://scripts/presentation/board_mapper.gd")

@export var square_size := Mapper.SQUARE_SIZE_M
var tiles: Dictionary = {}

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

func set_highlights(selected_square: int, destinations: Array) -> void:
	for square in tiles:
		var material := tiles[square].material_override as StandardMaterial3D
		material.emission_enabled = square == selected_square or square in destinations
		material.emission = Color(0.25, 0.8, 1.0) if square == selected_square else Color(0.2, 0.9, 0.35)
		material.emission_energy_multiplier = 0.7
