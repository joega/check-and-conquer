class_name ArenaCatalog
extends RefCounted

## Presentation-only definitions for campaign locations. Arena identity never
## enters chess state: a standard game can be rebuilt under any of these skins.

const ARENAS := {
	"mountain_fortress": {
		"title": "Mountain Fortress Terrace", "chapter": "I · The First Gate",
		"opponent": "The Gatekeeper", "intro": "Claim the first gate and begin the Warpath.",
		"backdrop_path": "res://assets/environment/generated/mountain_fortress_panorama_v1.png",
		"accent": Color(1.0, 0.43, 0.10), "stone": Color(0.22, 0.25, 0.29),
		"ambient": Color(0.72, 0.65, 0.53), "marker": "brazier",
	},
	"arcane_sky_citadel": {
		"title": "Arcane Sky Citadel", "chapter": "II · The Cloud Road",
		"opponent": "The Sky Seer", "intro": "Cross the cloud road beneath the watchful citadel.",
		"backdrop_path": "res://assets/environment/generated/arcane_sky_citadel_panorama_v1.png",
		"accent": Color(0.55, 0.30, 1.0), "stone": Color(0.15, 0.16, 0.29),
		"ambient": Color(0.47, 0.42, 0.78), "marker": "obelisk",
	},
	"frozen_keep": {
		"title": "Frozen Keep", "chapter": "III · The Winter Crown",
		"opponent": "The Winter Warden", "intro": "Break the frostbound line and take the Winter Crown.",
		"backdrop_path": "res://assets/environment/generated/frozen_keep_panorama_v1.png",
		"accent": Color(0.28, 0.82, 1.0), "stone": Color(0.49, 0.63, 0.72),
		"ambient": Color(0.55, 0.72, 0.94), "marker": "crystal",
	},
	"lava_forge": {
		"title": "Lava Forge", "chapter": "IV · The Ember Trial",
		"opponent": "The Forge Tyrant", "intro": "Survive the Ember Trial and temper your final advance.",
		"backdrop_path": "res://assets/environment/generated/lava_forge_panorama_v1.png",
		"accent": Color(1.0, 0.16, 0.025), "stone": Color(0.12, 0.075, 0.065),
		"ambient": Color(0.70, 0.25, 0.15), "marker": "brazier",
	},
	"forest_ruins": {
		"title": "Forest Ruins", "chapter": "V · The Final Grove",
		"opponent": "The Grove Sovereign", "intro": "The final grove awaits its rightful victor.",
		"backdrop_path": "res://assets/environment/generated/forest_ruins_panorama_v1.png",
		"accent": Color(0.38, 1.0, 0.50), "stone": Color(0.24, 0.31, 0.20),
		"ambient": Color(0.61, 0.74, 0.48), "marker": "crystal",
	},
}
static func ids() -> Array[String]:
	return ARENAS.keys()


static func definition(arena_id: String) -> Dictionary:
	return ARENAS.get(arena_id, ARENAS["mountain_fortress"]).duplicate(true)
