# Terra session report

Execution handoff: [next_steps.md](../next_steps.md).

Status: prepared; implementation of this queue has not started. The existing
Mountain Fortress fixes are the baseline, not completed work from this queue.

## Work units

| Unit | Deliverable | Status | Evidence / blocker |
| --- | --- | --- | --- |
| U01 | Baseline and animation lookup audit | Verified | UAL1/UAL2 inventory and focused routing, ceremony, browser, melee, and role-action checks passed; rendered Animation Browser review completed. |
| U02 | Real-actor Cinematic Lab | Verified | Real BoardPresenter/ceremony fixtures, normal-speed arrival, reset, and all four rendered Mountain intro cue shots verified. |
| U03 | Cancellation, completion, fallback ownership | Verified | Owned ceremony tweens, stale-callback invalidation, async fallback, watchdog, and cancellation-path integration test passed. |
| U04 | Cinematic preference and HUD ownership | Verified | Preference, HUD/input ownership, mode bypasses, Black opening search, and 1280×720/1920×1080 settings layouts verified. |
| U05 | Minimal sequence data contract | Verified | Mountain now plays catalog-selected, typed intro/victory resources; data identity, missing-resource fallback, lifecycle and real-lab visual regression passed. |
| U06 | Defeat, draw, repeat-victory integration | Verified | Authoritative terminal facts select shared defeat/draw or ordinary victory; terminal integration and real-lab captures passed. |
| U07 | Arcane Sky Citadel | Verified | Chapter II intro/victory/defeat and shared draw run through the real lab for both sides and sparse fixtures; campaign entry and rendered cue review passed. |
| U08 | Frozen Keep | Verified | Chapter III held-shot resources pass the shared side/outcome/sparse Skip matrix; Black-side intro renders were inspected. |
| U09 | Lava Forge | Verified | Chapter IV resources pass the shared matrix and inspected forge/brazier intro framing. |
| U10 | Forest Ruins and final conquest | Verified | Forest resources, one-time authoritative conquest selection, shared matrix, map copy, and conquest render passed. |
| U11 | Complete visual/behavior matrix | Verified | Delivered arena/outcome/side/sparse/Skip matrix passed; original ceremony and actor-routing regressions reran; baseline renderer/GameScreen exit notices recorded. |
| U12 | Full integration, local build, documentation | Verified | Registered tests passed in bounded isolated batches; Linux staging export/smoke and delivered-doc updates completed. |

## Baseline

At session start record the current dirty-tree summary, test commands/results,
and a fresh set of rendered baseline paths. Preserve pre-existing changes.
Distinguish existing warnings/failures from those introduced during this session.

- The working tree was already substantially dirty before U01. It contains the
  campaign/cinematic implementation and documentation listed by `git status` at
  session start; none was reset, cleaned, committed, or reverted.
- U01 baseline logs: `/tmp/cac-terra-u01-baseline/`. Before the routing change,
  `test_king_parley.gd`, `test_grandmaster_ceremony.gd`,
  `test_animation_browser.gd`, and `test_authored_role_actions.gd` passed.
- Imported-library inventory: `/tmp/cac-terra-u01-baseline/animation_inventory.log`.
  It proves `Idle_Rail`, `Sword_Heavy_Combo`, `Sword_Dash`, and `Sword_Block`
  are UAL2 clips; UAL1 provides `Idle`, `Walk`, seating, spell, and basic
  sword clips.

## Per-unit evidence

Append one entry per unit with:

- What changed and why; exact affected paths.
- Acceptance checks actually run, their outcomes, and log paths.
- Rendered artifacts opened and inspected; relevant arena/outcome/player side.
- Remaining limitations and whether dependent units can proceed.
- Documentation/license changes, or “no new assets/licenses.”

### U01 — verified 2026-09-12

- Changed `scripts/actors/piece_actor.gd` so every audited rail/advanced-sword
  semantic alias routes to UAL2, while UAL1 retains its actual imported clips.
  `play_state` now stops the inactive player for either library and reports a
  neutral-idle fallback when a semantic ID has no valid clip, preventing a
  prior walk or attack from continuing. Duration, pause, and playback-position
  routing use the same source-of-truth resolver.
- Added `tests/presentation/test_piece_actor_animation_routing.gd` and
  registered it in `tools/run_headless_tests.sh`. The test proves UAL1 and UAL2
  ownership, one-active-player behavior, speed/pause routing, and invalid-state
  fallback. `tools/inspect_animation_library.gd` now inventories both UAL
  source libraries. `tools/capture_animation_browser.gd` gives a deterministic
  rendered audit of those semantic states in the real Animation Browser scene.
- Verification logs: `/tmp/cac-terra-u01-verify2-routing.log`,
  `-king.log`, `-browser.log`, `-melee.log`, and `-actions.log` are clean passes;
  `test_grandmaster_ceremony.gd` passed its assertions in
  `/tmp/cac-terra-u01-verify3-ceremony.log`. `git diff --check` passed.
- Rendered review: `/tmp/cac-terra-u01-render/browser/ual2-watch.png`,
  `ual2-guard.png`, and `ual2-heavy-combo.png` were opened and inspected. The
  Pawn visibly occupies each requested UAL2 pose in `DebugAnimationBrowser`.
  Reproduce with `godot --path . --script tools/capture_animation_browser.gd --
  /tmp/cac-animation-browser` under isolated XDG paths.
- Limitation: the existing Grandmaster ceremony test can emit a Godot shutdown
  notice that one resource remains in use after its PASS line; it has no
  assertion or script error and did not block U01's actor-routing acceptance.
  No new assets or licenses were added.

### U02 — verified 2026-09-12

- Rebuilt `scenes/debug/DebugCinematicLab.tscn` around the real `ChessBoard`,
  `BoardPresenter`, `BattlefieldEnvironment`, `GrandmasterCeremony`, and
  `CampaignCinematic` components. `scripts/debug/debug_cinematic_lab.gd` now
  creates the opening formation and a sparse settled-victory projection from
  immutable FEN strings; it neither starts Stockfish nor reads/writes campaign
  progress. Play binds the actual commander, gatekeeper, and Grandmaster.
- Added fixture selection and live cue display. Reset rebuilds the selected
  immutable projection after cancelling the cinematic. Stress 20 deliberately
  uses normal playback so each cycle includes real seating, king approach,
  return, and restoration rather than racing the director past actor tweens.
- Added `tests/presentation/test_debug_cinematic_lab.gd`, registered it in
  `tools/run_headless_tests.sh`, and verified it at
  `/tmp/cac-terra-u02-verify3.log`. It proves the real 32-actor opening
  projection, component bindings, speaker staging, normal-speed parley arrival,
  Skip restoration, and three-piece victory fixture. The existing director
  regression also passed at `/tmp/cac-terra-u02-regression.log`.
- Rendered review: `tools/capture_cinematic_lab.gd` captured the actual Lab's
  Grandmaster, Gatekeeper, Commander, and Objective cues at
  `/tmp/cac-terra-u02-render/intro/01-grandmaster.png` through
  `04-objective.png`; all four were opened and inspected. Reproduce with
  `godot --path . --script tools/capture_cinematic_lab.gd --
  /tmp/cac-cinematic-lab` under isolated XDG paths.
- No new assets or licenses. The Lab intentionally exposes only the delivered
  Mountain intro/victory outcomes; later arena/outcome options remain deferred.

### U03 — verified 2026-09-12

- `scripts/presentation/grandmaster_ceremony.gd` now owns every king approach,
  return, and formation-materialization tween. Cleanup invalidates its operation
  generation, kills all owned operations even when no home-transform dictionary
  exists, restores all borrowed roots, and runs during scene teardown. Late
  callbacks carry a generation check. The Grandmaster resets to her verified
  standing home pose between replayed runs.
- `scripts/presentation/cinematic_director.gd` now cancels on teardown, uses an
  asynchronous missing-camera/overlay fallback so callers can install their
  `await finished`, and owns a watchdog based on declared sequence duration plus
  a 1.5-second grace period. Watchdog cleanup uses the same exactly-once
  completion/restoration path.
- Added `tests/presentation/test_cinematic_lifecycle.gd` and registered it in
  `tools/run_headless_tests.sh`. `/tmp/cac-terra-u03-verify4/`
  `test_cinematic_lifecycle.log` passes early/mid/late Skip, repeated Skip,
  replay, Reset during return/materialization, teardown, waiting beyond former
  travel duration, and asynchronous missing-overlay fallback. Regression checks
  passed at `/tmp/cac-terra-u03-regress/director.log` and `grandmaster.log`.
  `git diff --check` passed.
- No new assets or licenses. The known Godot resource-at-exit notice in the
  existing Grandmaster ceremony test remains after its PASS line; no lifecycle
  assertion or script error is emitted by the new cancellation test.

### U04 — verified 2026-09-12

- Added the visible `CampaignCinematics` Match Settings checkbox in
  `scenes/app/GameScreen.tscn`, persistence wiring in `scripts/game/game_screen.gd`,
  and strict boolean validation in `scripts/game/session_settings.gd`. Missing
  or malformed saved values safely default to enabled.
- INTRO/OUTRO now hide status, Menu, Hint, quick-reset, and outcome HUD while
  the cinematic overlay owns the story/Skip control; normal HUD ownership is
  restored after every awaited handoff. Direct menu toggles refuse non-playing
  phases. Changing the checkbox only saves the preference; Restart immediately
  starts the new match without interrupting the current one.
- Focused checks passed at `/tmp/cac-terra-u04-verify/settings.log` and
	`flow.log`, including malformed config fallback, visible preference control,
	intro HUD/input ownership, Skip restoration, and disabled-preference restart.
	`/tmp/cac-terra-u04-modes/test_campaign_cinematic_modes.log` additionally
	proves practice/spectator bypass and exactly one Black opening search after
	intro handoff. The pre-existing Godot resource-at-exit notice follows the
	flow/modes PASS lines. No new assets/licenses.
- Rendered Match Settings checks at 1280×720 and 1920×1080 are in
	`/tmp/cac-terra-u04-render2/settings/1280x720.png` and `1920x1080.png`.
	Both were opened and inspected; the Campaign Cinematics control is readable
	and no longer overlaps Fullscreen or Reset View. Reproduce with
	`godot --path . --script tools/capture_match_settings.gd --
	/tmp/cac-match-settings` under isolated XDG paths.

### U05 — verified 2026-09-12

- Added the minimal presentation-only resource contract:
  `CampaignCinematicSequence` identifies an arena/outcome and ordered cues;
  `CampaignCinematicCue` holds stable cue/speaker identifiers, visible copy,
  hold and shot parameters, and the finite ceremony actions. Mountain Fortress
  intro and victory now live in `data/cinematics/`, while
  `CampaignCinematicCatalog` is the only data lookup.
- `GameScreen` selects a sequence from immutable `arena_id` and outcome facts;
  `CinematicDirector` consumes only the selected resource and resolved visual
  bindings. It retains the prior asynchronous fallback for absent data and no
  longer owns Mountain-specific cue text or durations. `DebugCinematicLab`
  selects the same catalog resources. ADR-024 in `docs/DECISIONS.md` records
  the exact contract and action vocabulary before additional arena work.
- Added `tests/presentation/test_campaign_cinematic_catalog.gd`, registered in
  `tools/run_headless_tests.sh`. It proves sequence identity, ordered speakers,
  declared timings/actions, and asynchronous missing-data cleanup. Focused
  regressions all passed in `/tmp/cac-terra-u05-final/`: director, catalog,
  lifecycle, cinematic lab, campaign flow, and mode/Black-engine handoff.
  `git diff --check` passed. The campaign-flow log retains the known resource
  shutdown notice after its PASS line, with no assertion or script error.
- Rendered real-lab review is in
  `/tmp/cac-terra-u05-render/intro/01-grandmaster.png` through
  `04-objective.png`, captured by `tools/capture_cinematic_lab.gd` and opened
  for inspection. The migrated resource playback preserves the accepted
  Grandmaster, Gatekeeper, Commander, and Objective framing.
- No new assets or licenses. The generic data contract is ready for shared
  defeat/draw/repeat-victory selection in U06.

### U06 — verified 2026-09-12

- Added short Story Bible-aligned shared defeat and draw resources under
  `data/cinematics/`; they use a narrator-held, safe wide board shot and do
  not stage a captured or dead king. `CampaignCinematicCatalog` provides those
  only as terminal fallbacks, so unavailable arena-specific content remains
  safe while later chapters can supply their own defeat resources.
- `GameScreen` now derives `victory`, `defeat`, or `draw` solely from the
  committed terminal `MoveResult` and side-to-move fact after presentation has
  settled. It records eligible campaign progress first, then plays the selected
  sequence. All human campaign wins, including repeats rejected by
  `mark_victory`, receive ordinary victory presentation; defeat/draw never
  invoke campaign settlement. Surrender remains outside this path. Narration
  cues retain a centered readable panel without requiring an actor binding.
- Added `tests/game/test_campaign_terminal_cinematics.gd`, registered in
  `tools/run_headless_tests.sh`. It drives terminal presentation after a real
  initialized match and proves defeat, domain draw, and repeat victory choose
  the intended authored sequence, reach the result panel, and leave the
  campaign snapshot unchanged. The focused terminal, flow, mode, catalog, and
  director passes are in `/tmp/cac-terra-u06-final/`; the terminal test’s PASS
  is at `/tmp/cac-terra-u06-final/test_campaign_terminal_cinematics.log`.
  `git diff --check` passed. Existing GameScreen resource-at-exit notices occur
  only after PASS in terminal/flow/mode logs.
- Extended the deterministic Cinematic Lab and capture helper with shared
  defeat/draw selection. Opened render evidence is
  `/tmp/cac-terra-u06-render2/defeat/01-defeat.png` and
  `/tmp/cac-terra-u06-render2/draw/01-draw.png`; each shows the readable
  narration panel over a wide, current real-board formation. No new assets or
  licenses.

### U07 — verified 2026-09-12

- Added Arcane Sky Citadel intro, victory, and defeat resources with the
  Chapter II Story Bible copy, stable Sky Seer/Commander/Grandmaster bindings,
  and obelisk-facing opening composition. Shared draw remains a catalog fallback.
  `GameScreen` now starts any campaign arena with an authored intro instead of
  retaining Mountain-only entry branching. The Lab exposes Arcane selection;
  its capture helper accepts arena, outcome, and human-side arguments.
- Added `test_arcane_cinematic_matrix.gd` and
  `test_arcane_campaign_cinematic_flow.gd`, both registered in the headless
  runner. `/tmp/cac-u07-matrix/test.log` proves both sides, intro/victory/
  defeat/draw, opening and sparse fixtures, and representative early/late Skip
  restore the exact authoritative projection. `/tmp/cac-u07-flow/test.log`
  proves a real unlocked Arcane campaign entry chooses the Chapter II intro and
  hands off safely after Skip. The catalog contract regression passes at
  `/tmp/cac-u07/catalog3.log`; `git diff --check` passes. The GameScreen flow
  retains the pre-existing post-PASS resource shutdown notice.
- Opened renders: White intro cues are
  `/tmp/cac-u07-render2/intro/01-opening.png` through `04-objective.png`;
  Black intro cues are in `/tmp/cac-u07-black/intro/`; victory is in
  `/tmp/cac-u07-outcomes/victory/`; and defeat is
  `/tmp/cac-u07-outcomes/defeat2/01-defeat.png`. They show the Arcane obelisks,
  neutral listeners, readable dialogue, and safe wide defeat composition.
  Renderer shutdown may emit known GL texture-leak diagnostics after successful
  screenshots; no script error occurred in the final captures.
- No new assets or licenses. Frozen Keep can use the same frozen catalog and
  Lab/capture contract without new runtime conditionals.

### U08 — verified 2026-09-12

- Added Frozen Keep Chapter III intro, victory, and defeat resources using the
  Winter Warden’s supplied copy and deliberately longer 6-second held lines.
  The sequence uses existing ice-spire dressing and never changes weather or
  the arena state. The Lab/capture controls now select Frozen Keep.
- Extended the existing matrix test to cover Arcane and Frozen. It passes at
  `/tmp/cac-u08-matrix/test.log`, proving both human sides, intro/victory/
  defeat/shared-draw selection, opening and sparse fixtures, and early/late
  Skip restoration. Catalog parsing remains clean at `/tmp/cac-u08.log`; `git
  diff --check` passed.
- Opened Black-side Frozen intro captures at
  `/tmp/cac-u08-render/intro/01-opening.png` through `04-objective.png`.
  The ice/stone silhouettes remain distinct from Arcane and the longer text is
  readable. The renderer has the known post-capture GL texture notices only.
  No new assets or licenses.

### U09 — verified 2026-09-12

- Added Lava Forge Chapter IV intro, victory, and defeat resources with the
  Forge Tyrant’s Story Bible copy. The intro uses the existing warm brazier
  dressing only as distant framing; no new boss, hammer action, or forge
  destruction was introduced. The Lab/capture arena selector now includes Lava.
- Expanded the shared real-actor matrix at `/tmp/cac-u09/matrix.log`; it passes
  Arcane, Frozen, and Lava for both sides, all delivered outcomes, sparse and
  opening fixtures, plus early/late Skip restoration. `git diff --check`
  passed.
- Opened `/tmp/cac-u09-render/intro/01-opening.png` through `04-objective.png`.
  The warm braziers are visible without covering speaker text or actors. Known
  renderer GL texture notices follow successful screenshots; no script error.
  No new assets or licenses.

### U10 — verified 2026-09-12

- Added Forest Ruins intro, defeat, ordinary repeat-victory, and distinct
  24-second conquest resources using the Chapter V copy. `GameScreen` now
  selects `conquest` only when the just-recorded eligible final victory has
  made campaign progress complete; repeated final wins select ordinary victory.
  `campaign_map.gd` now echoes “Five strongholds. One open road.” on completion.
- Added `test_final_conquest_selection.gd`, registered in the headless runner.
  `/tmp/cac-u10-final/test.log` proves the final mark persists once, conquest
  is selected for that earned event, and the repeat is rejected and selects
  ordinary victory. The full delivered-arena matrix passes at
  `/tmp/cac-u10-matrix/test.log`, covering both sides, sparse/opening fixtures,
  all outcomes including Forest conquest, and representative skip restoration.
  `git diff --check` passed. The GameScreen test retains only the known
  post-PASS resource notice.
- Opened final-conquest evidence at
  `/tmp/cac-u10-render2/conquest/01-guardian.png` through `03-conquest.png`.
  The result is visibly longer than ordinary victory, uses actual formation
  positions, and avoids throne/kneeling/extra assets. No new assets/licenses.

### U11 — verified 2026-09-12

- `tools/capture_cinematic_lab.gd` now deterministically selects every delivered
  arena, outcome, and player side. The real-actor matrix test covers Arcane,
  Frozen, Lava, and Forest for both sides, opening/sparse fixtures, all
  delivered outcomes, and representative early/late Skip restoration; it
  passes at `/tmp/cac-u12/cinematic2/test_arcane_cinematic_matrix.log`.
- Rechecked the original high-risk presentation gates: director 20-cycle at
  `/tmp/cac-u12/cinematic2/test_cinematic_director.log`, lifecycle at
  `/tmp/cac-u12/cinematic3/test_cinematic_lifecycle.log`, real Mountain lab at
  `/tmp/cac-u12/cinematic3/test_debug_cinematic_lab.log`, Grandmaster ceremony
  at `/tmp/cac-u12/cinematic3/test_grandmaster_ceremony.log`, king arrival at
  `/tmp/cac-u12/cinematic4/test_king_parley.log`, and alias routing at
  `/tmp/cac-u12/cinematic4/test_piece_actor_animation_routing.log`.
- Inspected representative White/Black/outcome renders for every new arena in
  U07–U10 evidence paths. Known diagnostics: Godot can report one resource
  still in use after PASS for GameScreen/ceremony tests, and GUI capture can
  report GL texture leaks after all screenshots are written. No assertion or
  script error accompanies these baseline notices. No new assets/licenses.

### U12 — verified 2026-09-12

- Ran every script registered in `tools/run_headless_tests.sh` under its same
  isolated XDG convention, in bounded batches because this host ends a single
  command after 30 seconds. Core/domain/app/engine logs are in
  `/tmp/cac-u12/core/`, cinematic/game logs in `/tmp/cac-u12/cinematic*/`, and
  presentation/integration logs in `/tmp/cac-u12/presentation-*/`. This
  includes perft through depth 4, the real Stockfish 100-move adapter test,
  combat reset, projection, and GameScreen integration.
- The GameScreen Stockfish test exposed one stale chapter-card assertion after
  Arcane adopted cinematic entry. It now asserts the active Arcane sequence and
  its authored Sky Seer introduction; the rerun passed at
  `/tmp/cac-u12/presentation-e/test.log`. `git diff --check` passed.
- Inspected `tools/export_linux.sh` first: it deletes existing output, so a
  non-destructive export was staged at `/tmp/cac-u12/export/`. Godot produced
  the executable/PCK and copied Stockfish/license material; a two-second
  headless smoke launch returned the expected running-process timeout. Sandbox
  TCP/user-log diagnostics occurred during export/smoke and existing output was
  not touched.
- Updated README, ROADMAP, VERIFICATION, and the stale cutscene-plan status.
  No new assets or licenses.

## Coverage matrix

Add rows for each arena/outcome/player-side combination as it is delivered.
Track behavioral test evidence and rendered review separately. A test asserting
that a resource exists is not a rendered or integration pass.

## Continuation checkpoint

- Current unit: complete.
- Last completed unit: U12.
- Next action: none; preserve this dirty working tree for review.
- Live process handles: none created by this handoff task.
- Blocking questions/dependencies: none identified that prevent starting U01.

## Final handoff

Fill when stopping: delivered behavior, verification summary, screenshot/debug
reproduction commands, remaining defects, unverified platforms, and next action.
Do not mark unfinished or blocked units verified.
