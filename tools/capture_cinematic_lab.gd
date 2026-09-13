extends SceneTree

## Render every Mountain intro cue from the real-actor Cinematic Lab. The lab
## has no Stockfish or campaign save, so this is safe repeatable visual evidence.
const Evidence = preload("res://tools/visual_evidence_harness.gd")
var output_dir := "/tmp/cac-cinematic-lab"
var outcome := "intro"
var arena := "mountain_fortress"
var human_side := 1
var revision := "working-tree"
var expected_size := Vector2i(1280, 720)
var evidence


func _init() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output_dir = OS.get_cmdline_user_args()[0]
	if OS.get_cmdline_user_args().size() > 1:
		outcome = OS.get_cmdline_user_args()[1]
	if OS.get_cmdline_user_args().size() > 2:
		arena = OS.get_cmdline_user_args()[2]
	if OS.get_cmdline_user_args().size() > 3:
		human_side = -1 if OS.get_cmdline_user_args()[3] == "black" else 1
	if OS.get_cmdline_user_args().size() > 4:
		revision = OS.get_cmdline_user_args()[4]
	if OS.get_cmdline_user_args().size() > 5:
		var fields := OS.get_cmdline_user_args()[5].to_lower().split("x", false)
		expected_size = Vector2i(int(fields[0]), int(fields[1]))
	call_deferred("_run")


func _run() -> void:
	evidence = Evidence.new(output_dir, revision, expected_size)
	await evidence.configure_window(self)
	evidence.viewport.msaa_3d = Viewport.MSAA_2X
	var lab = preload("res://scenes/debug/DebugCinematicLab.tscn").instantiate()
	evidence.viewport.add_child(lab)
	await process_frame
	lab._human_side = human_side
	if arena != "mountain_fortress":
		lab.get_node("UI/Controls/Arena").select({"arcane_sky_citadel": 1, "frozen_keep": 2, "lava_forge": 3, "forest_ruins": 4}.get(arena, 0))
		lab._arena_id = arena
		lab.get_node("BattlefieldEnvironment").apply_arena(arena)
	await process_frame
	if outcome != "intro":
		var outcome_index: int = {"victory": 1, "defeat": 2, "draw": 3}.get(outcome, 0)
		lab.get_node("UI/Controls/Outcome").select(outcome_index)
		lab._outcome = outcome
	lab._play()
	lab.get_node("UI").visible = false
	var remaining := {
		"I · THE FIRST GATE": "01-grandmaster",
		"THE GATEKEEPER": "02-gatekeeper",
		"THE COMMANDER": "03-commander",
		"OBJECTIVE": "04-objective",
	}
	if arena == "arcane_sky_citadel" and outcome == "intro":
		remaining = {"II · THE CLOUD ROAD": "01-opening", "THE SKY SEER": "02-guardian", "THE COMMANDER": "03-commander", "OBJECTIVE": "04-objective"}
	elif arena == "arcane_sky_citadel" and outcome == "victory":
		remaining = {"ONE PATH REMAINS": "01-guardian", "THE WINTER CROWN": "02-outcome"}
	elif arena == "arcane_sky_citadel" and outcome == "defeat":
		remaining = {"CHOOSE AGAIN": "01-defeat"}
	elif arena == "frozen_keep" and outcome == "intro":
		remaining = {"III · THE WINTER CROWN": "01-opening", "THE WINTER WARDEN": "02-guardian", "THE COMMANDER": "03-commander", "OBJECTIVE": "04-objective"}
	elif arena == "frozen_keep" and outcome == "victory":
		remaining = {"THE THAW": "01-guardian", "THE NORTHERN OATH": "02-outcome"}
	elif arena == "frozen_keep" and outcome == "defeat":
		remaining = {"ENDURE": "01-defeat"}
	elif arena == "lava_forge" and outcome == "intro":
		remaining = {"IV · THE EMBER TRIAL": "01-opening", "THE FORGE TYRANT": "02-guardian", "THE COMMANDER": "03-commander", "OBJECTIVE": "04-objective"}
	elif arena == "lava_forge" and outcome == "victory":
		remaining = {"STRENGTH TESTED": "01-guardian", "ONE OATH REMAINS": "02-outcome"}
	elif arena == "lava_forge" and outcome == "defeat":
		remaining = {"THE LINE HOLDS": "01-defeat"}
	elif arena == "forest_ruins" and outcome == "intro":
		remaining = {"V · THE FINAL GROVE": "01-opening", "THE GROVE SOVEREIGN": "02-guardian", "THE COMMANDER": "03-commander", "OBJECTIVE": "04-objective"}
	elif arena == "forest_ruins" and outcome == "victory":
		remaining = {"AN OATH KEPT": "01-victory"}
	elif arena == "forest_ruins" and outcome == "defeat":
		remaining = {"REMEMBER": "01-defeat"}
	elif arena == "forest_ruins" and outcome == "conquest":
		remaining = {"THE FINAL WATCH": "01-guardian", "THE COMMANDER": "02-commander", "WARPATH CONQUERED": "03-conquest"}
	if arena == "mountain_fortress" and outcome == "defeat":
		remaining = {"THE ROAD REMAINS": "01-defeat"}
	elif arena == "mountain_fortress" and outcome == "draw":
		remaining = {"THE ROAD REMAINS CONTESTED": "01-draw"}
	var title: Label = lab.get_node("CampaignCinematic/Overlay/SpeechBubble/Content/Title")
	var deadline := Time.get_ticks_msec() + 25000
	while not remaining.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
		if remaining.has(title.text):
			var label: String = remaining[title.text]
			remaining.erase(title.text)
			await create_timer(0.35).timeout
			await evidence.capture(self, label, {"fixture": "campaign_cinematic", "arena": arena, "outcome": outcome, "human_side": "black" if human_side < 0 else "white", "cue_title": title.text, "speaker": lab.get_node("CampaignCinematic/Overlay/SpeechBubble/Content/Speaker").text})
	assert(remaining.is_empty(), "Every real-lab intro cue must be captured.")
	lab.get_node("CampaignCinematic").skip()
	await process_frame
	evidence.write_manifest("manifest.json", {"tool": "capture_cinematic_lab.gd", "arena": arena, "outcome": outcome, "human_side": human_side, "captured_cues": evidence.captures.size(), "ui_controls_hidden": true})
	quit(evidence.exit_code())
