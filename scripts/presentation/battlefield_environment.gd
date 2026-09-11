class_name BattlefieldEnvironment
extends Node3D

const ArenaCatalog = preload("res://scripts/presentation/arena_catalog.gd")

## Arena art establishes the setting, but the board is the gameplay stage.
## Keep the stage neutral so character materials and square colors remain
## readable in every panorama, including the cold and fire-lit arenas.
const BOARD_AMBIENT_COLOR := Color(0.82, 0.82, 0.82)
const BOARD_AMBIENT_ENERGY := 0.48
const BOARD_KEY_COLOR := Color(1.0, 1.0, 1.0)
const BOARD_KEY_ENERGY := 0.85
const BOARD_FILL_COLOR := Color(0.90, 0.90, 0.90)
const BOARD_FILL_ENERGY := 0.32

## Lightweight procedural setting around the authoritative chessboard. It has no
## gameplay collision or chess-state responsibilities and can be rebuilt freely.

@export var terrain_extent := 150.0
@export var storm_cycle_s := 18.0
@export_enum("mountain_fortress", "arcane_sky_citadel", "frozen_keep", "lava_forge", "forest_ruins") var arena_id := "mountain_fortress"

var _storm_time := 0.0
var _flash: OmniLight3D
var _beacon_lights: Array[OmniLight3D] = []
var _architecture: Node3D

func _ready() -> void:
	_flash = OmniLight3D.new()
	_flash.name = "ArenaAtmosphereLight"
	_flash.position = Vector3(0, 24, -18)
	_flash.light_energy = 0.0
	_flash.omni_range = 68.0
	add_child(_flash)
	apply_arena(arena_id)

func _process(delta: float) -> void:
	_storm_time += delta
	for index in _beacon_lights.size():
		_beacon_lights[index].light_energy = 2.0 + sin(_storm_time * 2.8 + index * 1.7) * 0.45
	var cycle := fmod(_storm_time, storm_cycle_s)
	# A gentle deterministic atmosphere pulse keeps an arena alive without
	# affecting board visibility or coupling environment state to chess.
	_flash.light_energy = 1.7 * exp(-pow((cycle - 2.0) * 4.5, 2.0))


func apply_arena(requested_arena_id: String) -> void:
	arena_id = requested_arena_id if requested_arena_id in ArenaCatalog.ARENAS else "mountain_fortress"
	var arena := ArenaCatalog.definition(arena_id)
	_apply_sky_and_lighting(arena)
	if _architecture != null:
		_architecture.queue_free()
	_architecture = Node3D.new()
	_architecture.name = "ArenaArchitecture"
	add_child(_architecture)
	_beacon_lights.clear()
	_create_grand_terrace(arena)
	_create_arena_markers(arena)
	_create_signature_set_dressing(arena)
	# Keep atmosphere flashes neutral as well: the arena's colors belong in the
	# panorama and emissive props, not as a tint over playable characters.
	_flash.light_color = Color.WHITE


func _apply_sky_and_lighting(arena: Dictionary) -> void:
	var world_environment := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment != null and world_environment.environment != null:
		var sky_material := PanoramaSkyMaterial.new()
		sky_material.panorama = load(arena.backdrop_path) as Texture2D
		sky_material.energy_multiplier = 0.78
		var sky := Sky.new()
		sky.sky_material = sky_material
		world_environment.environment.sky = sky
		world_environment.environment.ambient_light_color = BOARD_AMBIENT_COLOR
		world_environment.environment.ambient_light_energy = BOARD_AMBIENT_ENERGY
	var key_light := get_parent().get_node_or_null("Light") as DirectionalLight3D
	if key_light != null:
		key_light.light_color = BOARD_KEY_COLOR
		key_light.light_energy = BOARD_KEY_ENERGY
	var fill_light := get_parent().get_node_or_null("FillLight") as DirectionalLight3D
	if fill_light != null:
		fill_light.light_color = BOARD_FILL_COLOR
		fill_light.light_energy = BOARD_FILL_ENERGY


func _create_grand_terrace(arena: Dictionary) -> void:
	# A narrow ring of individual weathered slabs physically frames the board.
	# Unlike the earlier full terrain mesh, it terminates near the altar and can
	# never create a flat or jagged false horizon over the panoramic artwork.
	var slab_materials: Array[StandardMaterial3D] = []
	for brightness in [0.82, 1.0, 1.16]:
		var material := StandardMaterial3D.new()
		material.albedo_color = arena.stone * brightness
		material.roughness = 0.86
		material.metallic = 0.08
		slab_materials.append(material)
	for x in range(-22, 23, 4):
		for z in [-20, 20]:
			_add_terrace_slab(Vector3(x, -0.78, z), slab_materials[absi(x + z) % slab_materials.size()])
	for z in range(-16, 17, 4):
		for x in [-20, 20]:
			_add_terrace_slab(Vector3(x, -0.78, z), slab_materials[absi(x + z) % slab_materials.size()])


func _add_terrace_slab(position: Vector3, material: StandardMaterial3D) -> void:
	var slab := MeshInstance3D.new()
	slab.name = "TerraceSlab"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.82, 0.22, 3.82)
	slab.mesh = mesh
	slab.position = position
	slab.material_override = material
	_architecture.add_child(slab)


func _create_arena_markers(arena: Dictionary) -> void:
	for index in [0, 1, 2, 3]:
		var position: Vector3 = [Vector3(-22, 0, -22), Vector3(22, 0, -22), Vector3(-22, 0, 22), Vector3(22, 0, 22)][index]
		var marker := Node3D.new()
		marker.name = "ArenaMarker%02d" % index
		marker.position = position
		_architecture.add_child(marker)
		var pedestal := MeshInstance3D.new()
		var pedestal_mesh := CylinderMesh.new()
		pedestal_mesh.top_radius = 0.50
		pedestal_mesh.bottom_radius = 0.90
		pedestal_mesh.height = 2.1
		pedestal_mesh.radial_segments = 8
		pedestal.mesh = pedestal_mesh
		pedestal.position.y = 1.05
		var stone := StandardMaterial3D.new()
		stone.albedo_color = arena.stone * 0.72
		stone.roughness = 0.9
		pedestal.material_override = stone
		marker.add_child(pedestal)
		var crown := MeshInstance3D.new()
		crown.name = "ArenaAccent"
		if arena.marker == "obelisk":
			var prism := PrismMesh.new()
			prism.left_to_right = 0.5
			prism.size = Vector3(1.05, 2.2, 1.05)
			crown.mesh = prism
			crown.position.y = 3.0
		else:
			var gem := SphereMesh.new()
			gem.radius = 0.43 if arena.marker == "crystal" else 0.56
			gem.height = 1.35 if arena.marker == "crystal" else 0.8
			gem.radial_segments = 10
			crown.mesh = gem
			crown.position.y = 2.45
		var accent := StandardMaterial3D.new()
		accent.albedo_color = arena.accent
		accent.emission_enabled = true
		accent.emission = arena.accent
		accent.emission_energy_multiplier = 3.2
		crown.material_override = accent
		marker.add_child(crown)
		var light := OmniLight3D.new()
		light.name = "ArenaMarkerLight"
		light.position.y = 2.5
		# The glowing marker remains arena-colored through its emissive material;
		# its local illumination must not tint nearby board pieces.
		light.light_color = Color.WHITE
		light.light_energy = 1.4
		light.omni_range = 8.0
		light.shadow_enabled = false
		marker.add_child(light)
		_beacon_lights.append(light)


func _create_signature_set_dressing(arena: Dictionary) -> void:
	# Landmarks stay beyond the terrace rail: the board remains clear and the
	# panorama retains its horizon, while each campaign stop gains its own shape.
	var dressing := Node3D.new()
	dressing.name = "ArenaSetDressing"
	_architecture.add_child(dressing)
	match arena_id:
		"mountain_fortress": _create_watchtowers(dressing, arena)
		"arcane_sky_citadel": _create_arcane_obelisks(dressing, arena)
		"frozen_keep": _create_ice_spires(dressing, arena)
		"lava_forge": _create_forge_braziers(dressing, arena)
		"forest_ruins": _create_ruined_arches(dressing, arena)


func _dressing_material(color: Color, emission_strength := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if emission_strength > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_strength
	return material


func _add_dressing_mesh(parent: Node3D, node_name: String, mesh: PrimitiveMesh, position: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _create_watchtowers(parent: Node3D, arena: Dictionary) -> void:
	var stone := _dressing_material(arena.stone * 0.72)
	var roof := _dressing_material(Color(0.18, 0.10, 0.07))
	for index in 2:
		var x := -26.0 if index == 0 else 26.0
		var tower := CylinderMesh.new()
		tower.top_radius = 1.45
		tower.bottom_radius = 1.8
		tower.height = 5.0
		_add_dressing_mesh(parent, "FortressWatchtower%02d" % index, tower, Vector3(x, 1.7, -22.5), stone)
		var roof_mesh := CylinderMesh.new()
		roof_mesh.top_radius = 0.0
		roof_mesh.bottom_radius = 2.1
		roof_mesh.height = 2.4
		_add_dressing_mesh(parent, "FortressTowerRoof%02d" % index, roof_mesh, Vector3(x, 5.4, -22.5), roof)


func _create_arcane_obelisks(parent: Node3D, arena: Dictionary) -> void:
	var stone := _dressing_material(arena.stone * 0.95)
	var glow := _dressing_material(arena.accent, 3.6)
	for index in 3:
		var x := -18.0 + float(index) * 18.0
		var base := BoxMesh.new()
		base.size = Vector3(2.2, 0.85, 2.2)
		_add_dressing_mesh(parent, "CitadelRuneBase%02d" % index, base, Vector3(x, -0.15, -24.0), stone)
		var obelisk := PrismMesh.new()
		obelisk.size = Vector3(1.25, 5.2, 1.25)
		_add_dressing_mesh(parent, "CitadelObelisk%02d" % index, obelisk, Vector3(x, 2.8, -24.0), glow)


func _create_ice_spires(parent: Node3D, arena: Dictionary) -> void:
	var ice := _dressing_material(arena.accent.lerp(Color.WHITE, 0.35), 1.5)
	for index in 5:
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = 0.45 + float(index % 2) * 0.22
		spike.height = 2.2 + float(index % 3) * 0.7
		var x := -20.0 + float(index) * 10.0
		_add_dressing_mesh(parent, "FrozenIceSpire%02d" % index, spike, Vector3(x, 0.75 + spike.height * 0.5, -23.0), ice)


func _create_forge_braziers(parent: Node3D, arena: Dictionary) -> void:
	var iron := _dressing_material(Color(0.10, 0.075, 0.065))
	var fire := _dressing_material(arena.accent, 5.0)
	for index in 3:
		var x := -18.0 + float(index) * 18.0
		var bowl := TorusMesh.new()
		bowl.inner_radius = 0.72
		bowl.outer_radius = 1.05
		bowl.rings = 8
		bowl.ring_segments = 16
		_add_dressing_mesh(parent, "ForgeBrazier%02d" % index, bowl, Vector3(x, 1.0, -23.0), iron)
		var flame := SphereMesh.new()
		flame.radius = 0.46
		flame.height = 1.35
		_add_dressing_mesh(parent, "ForgeFlame%02d" % index, flame, Vector3(x, 1.55, -23.0), fire)


func _create_ruined_arches(parent: Node3D, arena: Dictionary) -> void:
	var stone := _dressing_material(arena.stone * 1.08)
	for index in 2:
		var x := -16.0 if index == 0 else 16.0
		for side in [-1.0, 1.0]:
			var pillar := BoxMesh.new()
			pillar.size = Vector3(0.85, 4.4, 0.85)
			_add_dressing_mesh(parent, "GroveArchPillar%02d_%d" % [index, int(side)], pillar, Vector3(x + side * 2.0, 1.4, -23.0), stone)
		var lintel := BoxMesh.new()
		lintel.size = Vector3(4.85, 0.72, 0.85)
		_add_dressing_mesh(parent, "GroveArchLintel%02d" % index, lintel, Vector3(x, 3.75, -23.0), stone)
