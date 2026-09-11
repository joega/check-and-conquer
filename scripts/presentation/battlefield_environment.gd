class_name BattlefieldEnvironment
extends Node3D

## Lightweight procedural setting around the authoritative chessboard. It has no
## gameplay collision or chess-state responsibilities and can be rebuilt freely.

@export var terrain_extent := 110.0
@export var storm_cycle_s := 18.0

var _storm_time := 0.0
var _flash: OmniLight3D
var _clouds: Array[MeshInstance3D] = []
var _beacon_lights: Array[OmniLight3D] = []

func _ready() -> void:
	_create_plateau()
	_create_mountains()
	_create_clouds()
	_create_storm_beacons()
	_flash = OmniLight3D.new()
	_flash.name = "StormFlash"
	_flash.position = Vector3(0, 24, -18)
	_flash.light_color = Color(0.56, 0.7, 1.0)
	_flash.light_energy = 0.0
	_flash.omni_range = 68.0
	add_child(_flash)
	_create_rain()

func _process(delta: float) -> void:
	_storm_time += delta
	for index in _clouds.size():
		var cloud := _clouds[index]
		var home_position: Vector3 = cloud.get_meta("home_position")
		cloud.position = home_position + Vector3(sin(_storm_time * 0.10 + index) * 4.0, sin(_storm_time * 0.16 + index) * 0.35, cos(_storm_time * 0.08 + index) * 3.0)
	for index in _beacon_lights.size():
		_beacon_lights[index].light_energy = 2.0 + sin(_storm_time * 2.8 + index * 1.7) * 0.45
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
		cloud.set_meta("home_position", cloud.position)
		cloud.scale = Vector3(8.0, 2.2, 3.5)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.13, 0.17, 0.25, 0.82)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 1.0
		cloud.material_override = material
		add_child(cloud)
		_clouds.append(cloud)


func _create_rain() -> void:
	var rain := GPUParticles3D.new()
	rain.name = "StormRain"
	rain.amount = 500
	rain.lifetime = 2.2
	rain.visibility_aabb = AABB(Vector3(-34, 0, -34), Vector3(68, 28, 68))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(31, 0.2, 31)
	process.direction = Vector3(0, -1, 0)
	process.spread = 5.0
	process.gravity = Vector3(0, -13, 0)
	process.initial_velocity_min = 6.0
	process.initial_velocity_max = 9.0
	process.color = Color(0.58, 0.72, 1.0, 0.42)
	rain.process_material = process
	var streak := QuadMesh.new()
	streak.size = Vector2(0.025, 0.72)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.63, 0.78, 1.0, 0.38)
	streak.material = material
	rain.draw_pass_1 = streak
	rain.position = Vector3(0, 21, 0)
	add_child(rain)


func _create_storm_beacons() -> void:
	var positions := [Vector3(-21, 0, -21), Vector3(21, 0, -21), Vector3(-21, 0, 21), Vector3(21, 0, 21)]
	for index in positions.size():
		var beacon := Node3D.new()
		beacon.name = "StormBeacon%02d" % index
		beacon.position = positions[index]
		add_child(beacon)
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.48
		pillar_mesh.bottom_radius = 0.86
		pillar_mesh.height = 3.2
		pillar_mesh.radial_segments = 6
		pillar.mesh = pillar_mesh
		pillar.position.y = 1.6
		var stone := StandardMaterial3D.new()
		stone.albedo_color = Color(0.10, 0.14, 0.19)
		stone.metallic = 0.12
		stone.roughness = 0.84
		pillar.material_override = stone
		beacon.add_child(pillar)
		var flame := MeshInstance3D.new()
		var flame_mesh := SphereMesh.new()
		flame_mesh.radius = 0.52
		flame_mesh.height = 1.4
		flame.mesh = flame_mesh
		flame.position.y = 3.55
		var flame_material := StandardMaterial3D.new()
		flame_material.albedo_color = Color(0.18, 0.58, 1.0)
		flame_material.emission_enabled = true
		flame_material.emission = Color(0.06, 0.32, 1.0)
		flame_material.emission_energy_multiplier = 5.0
		flame.material_override = flame_material
		beacon.add_child(flame)
		var light := OmniLight3D.new()
		light.name = "BeaconLight"
		light.position.y = 3.5
		light.light_color = Color(0.22, 0.53, 1.0)
		light.light_energy = 2.0
		light.omni_range = 9.0
		beacon.add_child(light)
		_beacon_lights.append(light)
