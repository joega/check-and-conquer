extends SceneTree

const CampaignProgress = preload("res://scripts/game/campaign_progress.gd")


func _init() -> void:
	var campaign = CampaignProgress.new()
	assert(campaign.current_arena() == "mountain_fortress")
	assert(campaign.is_unlocked("mountain_fortress"))
	assert(not campaign.is_unlocked("arcane_sky_citadel"))
	assert(is_zero_approx(campaign.progress_fraction()))
	assert(not campaign.mark_victory("arcane_sky_citadel"), "Cannot skip a locked arena.")
	var beginner_first := CampaignProgress.difficulty_profile(0, "mountain_fortress")
	var beginner_second := CampaignProgress.difficulty_profile(0, "arcane_sky_citadel")
	assert(beginner_first.name == "Beginner" and beginner_first.elo == 1320 and beginner_first.skill == 0)
	assert(beginner_second.elo > beginner_first.elo and beginner_second.skill > beginner_first.skill, "Campaign opponents must become gradually harder at each arena.")
	assert(campaign.mark_victory("mountain_fortress"))
	assert(campaign.current_arena() == "arcane_sky_citadel")
	assert(campaign.is_unlocked("arcane_sky_citadel"))
	assert(is_equal_approx(campaign.progress_fraction(), 0.2))
	assert(not campaign.mark_victory("mountain_fortress"), "Victories cannot be repeated.")

	var restored = CampaignProgress.new(campaign.to_snapshot())
	assert(restored.current_arena() == "arcane_sky_citadel")
	assert(restored.completed_ids == ["mountain_fortress"])
	assert(restored.unlocked_ids == ["mountain_fortress", "arcane_sky_citadel"])

	for arena_id in CampaignProgress.ARENA_IDS.slice(1):
		assert(restored.mark_victory(arena_id))
	assert(restored.campaign_complete())
	assert(is_equal_approx(restored.progress_fraction(), 1.0))
	assert(not restored.mark_victory("forest_ruins"))

	var invalid = CampaignProgress.new({
		"current_arena_id": "lava_forge",
		"unlocked_ids": ["mountain_fortress", "lava_forge"],
		"completed_ids": ["mountain_fortress"],
	})
	assert(invalid.current_arena() == "mountain_fortress", "Invalid snapshots reset safely.")
	print("PASS: campaign progression, rejection, and snapshot restore.")
	quit(0)
