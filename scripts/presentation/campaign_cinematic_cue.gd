class_name CampaignCinematicCue
extends Resource

## One authored story beat. Bindings refer to stable presentation roles, never
## board coordinates or a selected chess colour.
@export var cue_id := ""
@export var title := ""
@export var speaker_label := ""
@export var speaker_id := ""
@export_multiline var body := ""
@export var hold_s := 3.0
@export var shot_position := Vector3.ZERO
@export var shot_target := Vector3.ZERO
@export var shot_duration_s := 0.0
@export var stage_action := ""
@export var after_action := ""
