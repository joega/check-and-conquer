class_name BattlefieldEnvironment
extends Node3D

## Lightweight procedural setting around the authoritative chessboard. It has no
## gameplay collision or chess-state responsibilities and can be rebuilt freely.

@export var terrain_extent := 150.0
@export var storm_cycle_s := 18.0

var _storm_time := 0.0
var _flash: OmniLight3D
var _beacon_lights: Array[OmniLight3D] = []

func _ready() -> void:
	_create_storm_beacons()
	_flash = OmniLight3D.new()
	_flash.name = "StormFlash"
	_flash.position = Vector3(0, 24, -18)
	_flash.light_color = Color(0.56, 0.7, 1.0)
	_flash.light_energy = 0.0
	_flash.omni_range = 68.0
	add_child(_flash)

func _process(delta: float) -> void:
	_storm_time += delta
	for index in _beacon_lights.size():
		_beacon_lights[index].light_energy = 2.0 + sin(_storm_time * 2.8 + index * 1.7) * 0.45
	var cycle := fmod(_storm_time, storm_cycle_s)
	# A brief, deterministic distant lightning flash adds weather movement
	# without introducing random visual test failures or gameplay coupling.
	_flash.light_energy = 4.0 * exp(-pow((cycle - 2.0) * 4.5, 2.0))

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
