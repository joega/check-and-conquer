class_name BattlefieldEnvironment
extends Node3D

## Lightweight procedural setting around the authoritative chessboard. It has no
## gameplay collision or chess-state responsibilities and can be rebuilt freely.

@export var terrain_extent := 110.0
@export var storm_cycle_s := 18.0

var _storm_time := 0.0
var _flash: OmniLight3D

func _ready() -> void:
	_create_plateau()
	_create_mountains()
	_create_clouds()
	_flash = OmniLight3D.new()
	_flash.name = "StormFlash"
	_flash.position = Vector3(0, 24, -18)
	_flash.light_color = Color(0.56, 0.7, 1.0)
	_flash.light_energy = 0.0
	_flash.omni_range = 68.0
	add_child(_flash)

func _process(delta: float) -> void:
	_storm_time += delta
	var cycle := fmod(_storm_time, storm_cycle_s)
	# A brief, deterministic distant lightning flash adds weather movement
	# without introducing random visual test failures or gameplay coupling.
	_flash.light_energy = 4.0 * exp(-pow((cycle - 2.0) * 4.5, 2.0))

func _create_plateau() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "MountainPlateau"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(terrain_extent, terrain_extent)
	ground.mesh = mesh
	ground.position.y = -0.1
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.075, 0.09, 0.11)
	material.roughness = 0.94
	ground.material_override = material
	add_child(ground)

func _create_mountains() -> void:
	var positions := [
		Vector3(-36, 5, -30), Vector3(-18, 7, -42), Vector3(4, 8, -39),
		Vector3(27, 6, -35), Vector3(44, 9, -22), Vector3(-46, 8, 8),
		Vector3(42, 7, 14), Vector3(-30, 6, 36), Vector3(2, 8, 42), Vector3(31, 7, 34),
	]
	for index in positions.size():
		var mountain := MeshInstance3D.new()
		mountain.name = "Mountain%02d" % index
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = 1.0
		mesh.height = 1.0
		mesh.radial_segments = 7
		mountain.mesh = mesh
		mountain.position = positions[index]
		var size := 8.0 + float(index % 3) * 2.5
		mountain.scale = Vector3(size, size * 2.3, size)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.15, 0.18) if index % 2 == 0 else Color(0.09, 0.12, 0.15)
		material.roughness = 0.98
		mountain.material_override = material
		add_child(mountain)

func _create_clouds() -> void:
	for index in 9:
		var cloud := MeshInstance3D.new()
		cloud.name = "StormCloud%02d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 0.65
		mesh.radial_segments = 12
		mesh.rings = 6
		cloud.mesh = mesh
		cloud.position = Vector3(-28.0 + index * 7.0, 18.0 + (index % 3) * 1.4, -28.0 - (index % 2) * 8.0)
		cloud.scale = Vector3(8.0, 2.2, 3.5)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.13, 0.17, 0.25, 0.82)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 1.0
		cloud.material_override = material
		add_child(cloud)
