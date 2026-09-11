## Pure campaign state for the sequential arena tour.
##
## This object deliberately knows nothing about scenes, chess positions, or an
## engine game. A caller marks the current arena victorious only after its game
## result is authoritative, then persists `to_snapshot()` if desired.
extends RefCounted

const ARENA_IDS: Array[String] = [
	"mountain_fortress",
	"arcane_sky_citadel",
	"frozen_keep",
	"lava_forge",
	"forest_ruins",
]

var current_arena_id: String
var unlocked_ids: Array[String] = []
var completed_ids: Array[String] = []


func _init(snapshot: Dictionary = {}) -> void:
	reset()
	if not snapshot.is_empty():
		restore_snapshot(snapshot)


func reset() -> void:
	current_arena_id = ARENA_IDS.front()
	unlocked_ids = [current_arena_id]
	completed_ids = []


func current_arena() -> String:
	return current_arena_id


func is_unlocked(arena_id: String) -> bool:
	return arena_id in unlocked_ids


## Records one campaign win. Only the current, unlocked arena may advance.
## Repeating a completed victory and trying to skip ahead are both rejected.
func mark_victory(arena_id: String) -> bool:
	if campaign_complete() or arena_id != current_arena_id or not is_unlocked(arena_id):
		return false
	if arena_id in completed_ids:
		return false
	completed_ids.append(arena_id)
	var next_index := ARENA_IDS.find(arena_id) + 1
	if next_index < ARENA_IDS.size():
		current_arena_id = ARENA_IDS[next_index]
		if current_arena_id not in unlocked_ids:
			unlocked_ids.append(current_arena_id)
	return true


func campaign_complete() -> bool:
	return completed_ids.size() == ARENA_IDS.size()


func progress_fraction() -> float:
	return float(completed_ids.size()) / float(ARENA_IDS.size())


func to_snapshot() -> Dictionary:
	return {
		"current_arena_id": current_arena_id,
		"unlocked_ids": unlocked_ids.duplicate(),
		"completed_ids": completed_ids.duplicate(),
	}


## Restores only a valid sequential campaign state. Invalid or stale data
## resets safely rather than allowing an impossible map progression.
func restore_snapshot(snapshot: Dictionary) -> bool:
	var restored_completed := _valid_string_array(snapshot.get("completed_ids", []))
	var restored_unlocked := _valid_string_array(snapshot.get("unlocked_ids", []))
	var completed_count := restored_completed.size()
	if restored_completed != ARENA_IDS.slice(0, completed_count):
		reset()
		return false
	if restored_unlocked != ARENA_IDS.slice(0, min(completed_count + 1, ARENA_IDS.size())):
		reset()
		return false
	var expected_current := ARENA_IDS[min(completed_count, ARENA_IDS.size() - 1)]
	if snapshot.get("current_arena_id", "") != expected_current:
		reset()
		return false
	current_arena_id = expected_current
	completed_ids = restored_completed
	unlocked_ids = restored_unlocked
	return true


func _valid_string_array(value: Variant) -> Array[String]:
	if not value is Array:
		return []
	var result: Array[String] = []
	for entry in value:
		if not entry is String or entry not in ARENA_IDS or entry in result:
			return []
		result.append(entry)
	return result
