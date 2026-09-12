class_name CampaignCinematicSequence
extends Resource

## Deliberately small finite sequence contract. The director recognizes only
## the declared ceremony actions below; resources cannot run arbitrary code.
@export var sequence_id := ""
@export var arena_id := ""
@export_enum("intro", "victory") var outcome := "intro"
@export var final_hold_s := 0.0
@export var cues: Array[Resource] = []
