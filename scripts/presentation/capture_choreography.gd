class_name CaptureChoreography
extends Resource

@export var id: StringName = &"capture.pawn.generic_sword_01"
@export var attacker_clip: StringName = &"Sword_Attack"
@export var attacker_followup_clip: StringName = &""
@export var victim_hit_clip: StringName = &"Hit_Chest"
@export var victim_hit_variants: Array[StringName] = []
@export var victim_death_clip: StringName = &"Death01"
@export var victim_death_variants: Array[StringName] = []
@export var approach_duration_s := 0.65
@export var impact_time_s := 0.42
@export var followup_time_s := 0.0
@export var cleanup_time_s := 1.2
@export var anchor_separation_m := 2.6
@export var camera_shot: StringName = &"capture_medium"
@export var impact_sfx: StringName = &"placeholder.impact"
@export var vfx_profile: StringName = &"placeholder.spark"
