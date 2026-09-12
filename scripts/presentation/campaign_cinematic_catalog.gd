class_name CampaignCinematicCatalog
extends RefCounted

const MOUNTAIN_INTRO = preload("res://data/cinematics/mountain_fortress_intro.tres")
const MOUNTAIN_VICTORY = preload("res://data/cinematics/mountain_fortress_victory.tres")
const ARCANE_INTRO = preload("res://data/cinematics/arcane_sky_citadel_intro.tres")
const ARCANE_VICTORY = preload("res://data/cinematics/arcane_sky_citadel_victory.tres")
const ARCANE_DEFEAT = preload("res://data/cinematics/arcane_sky_citadel_defeat.tres")
const FROZEN_INTRO = preload("res://data/cinematics/frozen_keep_intro.tres")
const FROZEN_VICTORY = preload("res://data/cinematics/frozen_keep_victory.tres")
const FROZEN_DEFEAT = preload("res://data/cinematics/frozen_keep_defeat.tres")
const LAVA_INTRO = preload("res://data/cinematics/lava_forge_intro.tres")
const LAVA_VICTORY = preload("res://data/cinematics/lava_forge_victory.tres")
const LAVA_DEFEAT = preload("res://data/cinematics/lava_forge_defeat.tres")
const FOREST_INTRO = preload("res://data/cinematics/forest_ruins_intro.tres")
const FOREST_VICTORY = preload("res://data/cinematics/forest_ruins_victory.tres")
const FOREST_DEFEAT = preload("res://data/cinematics/forest_ruins_defeat.tres")
const FOREST_CONQUEST = preload("res://data/cinematics/forest_ruins_conquest.tres")
const SHARED_DEFEAT = preload("res://data/cinematics/shared_defeat.tres")
const SHARED_DRAW = preload("res://data/cinematics/shared_draw.tres")

const SEQUENCES := {
	"mountain_fortress:intro": MOUNTAIN_INTRO,
	"mountain_fortress:victory": MOUNTAIN_VICTORY,
	"arcane_sky_citadel:intro": ARCANE_INTRO,
	"arcane_sky_citadel:victory": ARCANE_VICTORY,
	"arcane_sky_citadel:defeat": ARCANE_DEFEAT,
	"frozen_keep:intro": FROZEN_INTRO,
	"frozen_keep:victory": FROZEN_VICTORY,
	"frozen_keep:defeat": FROZEN_DEFEAT,
	"lava_forge:intro": LAVA_INTRO,
	"lava_forge:victory": LAVA_VICTORY,
	"lava_forge:defeat": LAVA_DEFEAT,
	"forest_ruins:intro": FOREST_INTRO,
	"forest_ruins:victory": FOREST_VICTORY,
	"forest_ruins:defeat": FOREST_DEFEAT,
	"forest_ruins:conquest": FOREST_CONQUEST,
	"shared:defeat": SHARED_DEFEAT,
	"shared:draw": SHARED_DRAW,
}


static func sequence_for(arena_id: String, outcome: String) -> Resource:
	return SEQUENCES.get("%s:%s" % [arena_id, outcome]) as Resource


static func terminal_sequence_for(arena_id: String, outcome: String) -> Resource:
	var sequence := sequence_for(arena_id, outcome)
	return sequence if sequence != null else sequence_for("shared", outcome)
