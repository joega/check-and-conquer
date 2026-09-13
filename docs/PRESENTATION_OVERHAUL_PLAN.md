# Presentation overhaul — implementation handoff

Date: 2026-09-12. Status: planned; no implementation in this handoff.

## Objective and model choice

Make the existing playable game visibly more deliberate: planted movement,
continuous animation transitions, credible weapon contact, recognizable roles,
and a cohesive fantasy diorama. The primary deliverable is a better-looking
game in motion, demonstrated with matched before/after evidence.

Recommended implementor: **GPT-5.6 Sol, high reasoning**. Terra can execute
bounded tickets below, especially materials, fixtures, and regression checks.
Astra is the preferred single owner when maximum quality matters more than
cost, or for a difficult animation/contact problem and final visual critique.
These are task-specific judgments, not measured Godot benchmarks. Official
[model guidance](https://developers.openai.com/api/docs/models/compare)
positions Terra for intelligence/cost balance, Sol for complex professional
work, and Astra for the hardest end-to-end work. Checked 2026-09-12.

A stronger model cannot replace missing body animation or prove smoothness
from still images. All implementors must use the same visual gates.

## Read first and preserve

Read `AGENTS.md`, `BATTLE_CHESS_MASTER_PLAN.md`, `docs/ROADMAP.md`,
`docs/ASSET_PIPELINE.md`, and the relevant entries in `docs/DECISIONS.md`.
Read `docs/ASTRA_VISUAL_DIRECTION.md` and `docs/TERRA_VISUAL_TRANCHE_02.md`
through `04.md` as history. Several earlier checklist items are already
implemented; inspect current code before treating an old problem as open.

This is a renewed M7 quality pass over existing M6/M8/M10 presentation.
Keep standard chess, Stockfish, campaign progression, settings, and existing
cinematics working. Domain state stays authoritative. Actor roots stay in
board metres; code controls root travel and exact settlement. Preserve the
semantic clip API, all 36 generic matchup fallbacks, and the three required
debug scenes, plus the existing Cinematic Lab.

Retain the current renderer and existing models for the initial proof.
Do not add arenas, signature sequences, mounted knights, online features,
or a new campaign story to satisfy this plan. An optional renderer comparison
belongs after the core gates, only if measured evidence warrants it.

## Evidence behind this plan

Source inspection on the handoff date found:

- `BoardPresenter._walk_actor_to()` completes one walk cycle over every move,
  with travel capped at 1.25 seconds. `PieceActor.move_to_world_position()`
  independently applies quadratic easing. Gait and travel are not coupled.
- `PieceActor.play_state()` switches between two AnimationPlayers using
  stop/play calls without deliberate transition blending.
- `face_world_position()` and `restore_board_facing()` change facing instantly.
- `start_battle_stance()` explicitly freezes a pose to avoid snapping idle
  seams; sparse whole-model gestures substitute for a continuous idle.
- Bow and hammer semantics use spell-shoot and melee-hook body clips with
  local weapon tweens. These are bridge effects, not authored skeletal attacks.
  Fixed prop tween durations versus scaled body/director time are a timing
  risk to verify, not an already-proven failure at every speed.

Fresh rendered captures in `/tmp/cac-review-visual` show a plain geometric
stage against a richly illustrated panorama and repeated outfit silhouettes.
Those temporary files may disappear; recreate evidence in the next session.
The broad audit completed but its `02-board` and `04-engine-reply` images
showed intro dialogue. Filenames and a successful exit did not establish the
claimed state. Two GL texture-leak messages appeared at shutdown; track those
separately from scene failures and do not claim a leak-free baseline.

## Execution rules

Work in order P0 → P1 → P2 → P3 → P4 → P5 → P6. P1–P3 are the first
playable proof; continue to the remaining tickets once those gates pass.
Do not stop after planning, a baseline capture, or an animation-controller
refactor. Do not mark an item complete merely because a test passes.

Each ticket needs implementation, relevant regression checks, rendered
inspection, and a short evidence entry. Record status and next action in
the ledger below so another session can resume without rediscovery.
Use small coherent changes and preserve unrelated user edits.

Use subagents/worktrees for independent work when useful under AGENTS.md.
One owner must control `PieceActor`, animation semantics, and the movement/
combat lifecycle. Do not let two workers redesign that interface concurrently.
Environment work and an independent verification review can be delegated once
their boundaries are fixed. A model switch is optional, never an acceptance gate.

## P0 — Make visual evidence trustworthy

Primary files: `tools/capture_visual_audit.gd`, `tools/capture_authored_combat.gd`,
debug scene scripts, and a small reusable fixture helper if needed.

- [x] Isolate settings/saves and explicitly set arena, side, seed, camera,
  animation speed, and cinematic mode for every fixture.
- [x] Gameplay shots must explicitly complete/disable the intro through its
  supported lifecycle and wait for presentation/input readiness. `READY`
  alone is insufficient because the domain can remain ready during an intro.
- [x] Assert the expected FEN/move count, live board actors, active camera,
  and absence of the cinematic overlay before labeling a gameplay shot.
  Capture cinematics as separate fixtures. Use bounded waits with useful errors.
  For the engine fixture, prove history advances 0 → 1 → 2 and finishes in
  `ScreenPhase.PLAYING` with settled actors and no pending engine request.
  Checking only White to move also passes when neither move happened.
- [x] Replace the universal 0.35-second role "contact" snapshot with actual
  impact events or authored clip contact markers. Otherwise call it a timed
  pose sample. Use `tools/capture_cinematic_lab.gd` for cinematic evidence.
- [x] Add repeatable movement inspection: short pawn move, two-square pawn
  move, knight move, and long rook/bishop move in legal sparse positions.
- [x] Record a full movement/capture sequence, either video or fixed-step
  image sequence, at normal speed and 0.25×. Include timestamps and event
  markers; still contact screenshots alone cannot prove smoothness.
- [x] Capture matching 1280×720 and 1920×1080 views. Record actual output
  dimensions, renderer, GPU, camera settings, fixture, and revision.

Gate: the starting-board image shows 32 projected pieces and no intro;
the engine-reply image proves an accepted human move and legal engine reply;
reruns reproduce the same intended views and event samples. Audit assertions
must fail when those conditions are absent.

## P1 — Continuous motion with the current characters

Primary files: `scripts/actors/piece_actor.gd`, `scenes/actors/PieceActor.tscn`,
`scripts/presentation/board_presenter.gd`, `scripts/presentation/battle_director.gd`.

- [x] Give the compatible animation libraries one blending owner. Preferred
  implementation: namespaced libraries on one AnimationPlayer driven by an
  AnimationTree; keep callers using existing semantic IDs. Use another compact
  design only if it demonstrates equivalent cross-library blending and lifecycle.
- [x] Blend idle ↔ locomotion, locomotion → attack, and recovery → idle.
  Start with 0.10–0.18-second transitions and tune from recordings. Hits may
  need a sharper transition; death must never blend back to idle accidentally.
- [x] Calibrate the walk cycle's apparent stride in displayed world units.
  Drive cycle progress from travel distance or a shared velocity profile.
  Long moves require additional steps, not a single stretched cycle.
- [x] Give travel a short start, steady middle, and planted stop. Match gait
  speed to acceleration/deceleration. Keep common moves near the existing
  sub-1.25-second pace when feasible; allow a documented bounded longer-move
  duration instead of making characters skate to satisfy an arbitrary cap.
- [x] Animate facing along the shortest yaw turn. Turn into travel and back
  into stance without snapping. Preserve immediate orientation methods for
  reset/rebuild callers; do not silently make synchronous setup asynchronous.
- [x] Repair/crossfade a compatible idle loop and stagger phases deterministically.
  Replace frozen-pose ambient motion only after the loop passes seam inspection.
- [x] Give movement, turning, blending, and recovery explicit cancellation.
  Skip/reset/rebuild must prevent old tweens or callbacks from mutating new state.

Gate: short and long moves show consistent apparent stride, no visible skating
or orientation pop at 1×, and no unexplained pose jump at 0.25×. Inspect at
least three complete idle loops. Final root positions satisfy existing exact-
settlement tolerances. Pause/resume, speed, repeated reset, and actor replacement
remain correct. Preserve truthful `supports_state`, `state_duration`, playback
speed/pause, source-clip previews, and death-completion behavior.
Some existing tests inspect the two private AnimationPlayers directly. When
consolidating them, migrate those assertions to equivalent observable behavior;
do not preserve obsolete internals or delete coverage simply to make tests pass.

## P2 — One excellent capture, then shared combat timing

Primary files: `battle_director.gd`, `capture_choreography.gd`,
`data/choreography/*.tres`, `piece_actor.gd`, `arena_audio_director.gd`.

- [x] Pick one generic pawn-versus-pawn capture as the reference; use the
  actual equipped dagger attack and existing compatible body animation.
- [x] Tune anticipation → approach/plant → strike → reaction → death →
  recovery/settlement. Document actual clip contact markers and anchor spacing.
- [x] Use a common speed-scaled presentation timeline for body animation,
  prop actions, projectile release, impact, sound, and recovery. Clarify whether
  mid-capture speed changes apply immediately or on the next capture.
- [x] At the contact beat, the weapon intersects or convincingly crosses the
  victim contact zone. Sound/reaction/VFX fire on that beat, not before arrival.
  Keep effects restrained enough to inspect the weapon and victim silhouette.
- [x] Verify actual audible output: family-appropriate approach/release/impact,
  no accidental duplicated contact sounds, and no sounds after cancellation.
- [x] Apply the corrected shared timing and movement to all delivery paths,
  including arrow, hammer, arcane bolt, and signature follow-ups. Keep full
  death completion and authoritative survivor settlement.

Gate: 20 full-speed play/reset cycles pass without drift, stuck state, duplicate
events, or lingering effects. Inspect 0.25×/1×/2×, incoming approaches from eight
directions, and one crowded-board capture. Test skip/reset before impact, during
reaction, and during recovery. Keep the board camera stable and player framing
intact. No new cinematic camera system is required for this gate.
The existing automated Combat Lab test accelerates time by 32×. Keep it as a
lifecycle regression, but it does not replace the normal-speed visual replay.

## P3 — Make Mountain Fortress a finished visual reference

Primary files: `chess_board.gd`, `battlefield_environment.gd`, `arena_catalog.gd`,
`scenes/app/GameScreen.tscn`, relevant materials/meshes under `assets/`.

Direction: a crafted fantasy chess diorama. Warm limestone, dark slate,
restrained aged bronze, tactile edges, readable stylized figures. Background
detail should support the stage rather than dominate its contrast.

- [x] Give square/altar/rail edges a small bevel or equivalent authored edge
  treatment. Add restrained roughness and color variation. Keep square centers,
  board extents, hit testing, and overlay heights consistent.
- [x] Replace the most conspicuous foreground primitive landmarks with
  coherent reusable geometry or compatible already-owned props. Concentrate
  detail near the playable stage; do not rebuild the whole distant environment.
- [x] Tune key/fill balance and shadow quality to model clothing and ground
  feet. Keep pale tiles below clipping and both armies readable. Preserve the
  earlier neutral-lighting gains; do not restart the overexposed/tinted-board cycle.
- [x] Unify local materials with the panorama's broad palette and light
  direction without adding a strong board color cast. Inspect both player sides.
- [x] Evaluate supported antialiasing options on the current Compatibility
  renderer. Choose from measured visual improvement and frame cost, not labels.
- [x] Simplify excessive emissive accents. Selection, hints, last move, and
  team rings must remain distinct without becoming the brightest art everywhere.

Gate: matched before/after views at both resolutions show tactile board edges,
grounded figures, retained material detail, and a coherent foreground. All 64
squares remain readable and interactable. Establish this reference before
propagating its shared materials/lighting rules to all five arenas.

## P4 — Roles that read at gameplay distance

Primary files: role appearance/weapon profiles in `piece_actor.gd`, compatible
outfit assets, Animation Browser, and starting-position fixtures.

- [x] Establish distinct silhouettes: compact pawn; tall spear-bearing knight;
  hooded/mantled archer bishop; broad armored hammer rook; distinct queen
  headwear/shoulders; unmistakable royal king silhouette.
- [x] Use existing compatible costume elements or small project-authored
  accessories first. Color alone and enlarged weapons are insufficient.
- [x] Integrate restrained blue/red identity into clothing details as well
  as bases. Keep metals/materials coherent; retain non-color role cues.
- [x] Validate all role profiles in idle, walk, attack, recovery, and death,
  for both teams. Accessories must follow the appropriate bones and avoid
  face/hand/weapon obstruction. Preserve canonical scale and combat anchors.

Gate: provide a six-role lineup at gameplay scale plus both starting ranks.
Run a label-hidden identification review; record ambiguous roles honestly.
No mandatory human approval pause: perform and document the implementor review,
then include the lineup for user evaluation. No new full six-model replacement
until a single candidate passes the existing rig and 20-cycle slice gate.

## P5 — Replace bow/hammer body-motion approximations

Primary files: `assets/animations/`, semantic mapping, role choreography,
`docs/ASSET_PIPELINE.md`, `assets/THIRD_PARTY_ASSETS.md`.

- [x] Inspect available authoring tools and already-owned compatible clips.
  Prefer a bounded skeletal edit on the current rig: one proper bow
  draw/aim/release/recovery and one two-handed hammer windup/strike/recovery.
  Evaluate a true spear thrust next if its existing jab still fails contact.
- [ ] Author body mechanics, not just prop translation: shoulders/elbows,
  two-hand contact where applicable, torso/hips, planted feet, and weight transfer.
  Hand IK may assist a grip; it does not replace the whole action.
- [x] If sourcing content, verify current source/license before intake and
  record exact provenance. Use the established intake checklist. Do not repeat
  the rejected six-bone KayKit or failed generic CMU retarget attempts without
  new evidence addressing their documented failures.
- [x] Keep normalized semantic IDs and data-owned contact/release markers.
  Remove obsolete prop overrides only after replacement clips are proven.
- [x] Paid purchase, commissioning, or external outreach requires the user's
  authorization. Finish independent tickets and prepare a concrete candidate
  or animator brief if that is the actual remaining dependency.

Gate: bow hands stay on bow/string through draw and release; hammer hands stay
on the shaft through windup/contact; feet and torso sell the force. Validate
both sides, 0.25×/1×/2×, exact settlement, and 20 full resets for each new action.
If no viable clip/authoring route passes, label this ticket **blocked on content**,
retain the safe fallback, and specify the missing clip/rig/contact requirements.
Never call a prop-only adjustment a completed skeletal animation replacement.

**P5 status (2026-09-12): blocked on content.** No installed clip or available
authoring route passes the body-mechanics gate. The second item remains open;
the safe semantic prop/body fallbacks stay in place. The exact missing rig,
motion, marker, license, and validation contract is in
`docs/P5_SKELETAL_ANIMATION_BRIEF.md`.

## P6 — Integrate, simplify presentation, and prove the improvement

- [x] Apply the approved reference treatment across five arenas; preserve
  location identity without burying the board in atmosphere or glow.
- [x] Tune existing HUD/dialogue spacing, typography, opaque reading surfaces,
  and camera composition to match the stage. Avoid redundant speaker labels,
  cropped text, and dialogue boxes covering principal actors. Preserve settings,
  keyboard access, cinematic Skip, and manual board-camera ownership.
- [x] Recheck intro/ordinary play/capture/check/checkmate/defeat/conquest paths
  with the new animation owner, including sitting/standing king ceremonies.
- [x] Run the full headless suite after integration and relevant focused tests
  during each ticket. Add behavioral regression coverage for new cancellation,
  timing, and distance-to-stride behavior; avoid tests that merely copy constants.
- [x] Capture matched final images and motion sequences. Review actual output,
  not just audit exit status. Keep a before/after comparison and reproduction
  manifest in a documented artifact directory; do not depend solely on `/tmp`.
- [x] Measure frame times after warm-up on the available GPU: full starting
  board and repeated captures at 1080p. Report median/p95, renderer, settings,
  and sampling method. Target the master plan's 60 FPS; investigate >10% p95
  regression against the same baseline. Report an existing missed target honestly.

Final gate: all unblocked tickets have visual evidence and behavioral checks;
20-cycle replay, 36 matchup resolution, full death playback, special moves,
cinematic lifecycle, real Stockfish integration, and perft remain passing.
Document any blocked content separately; partial completion is not full overhaul.

## Commands and evidence

Run from the project root. Use fresh task-specific temporary directories for
each comparison and keep user campaign saves isolated. Rendered commands require
desktop/GPU access; headless mode cannot replace visual review.

```bash
XDG_DATA_HOME=/tmp/cac-polish-data XDG_CONFIG_HOME=/tmp/cac-polish-config XDG_CACHE_HOME=/tmp/cac-polish-cache godot --windowed --resolution 1280x720 --fixed-fps 60 --path . --script tools/capture_visual_audit.gd -- artifacts/presentation_overhaul/baseline/visual-1280x720 REVISION 1280x720
XDG_DATA_HOME=/tmp/cac-polish-motion-data XDG_CONFIG_HOME=/tmp/cac-polish-motion-config XDG_CACHE_HOME=/tmp/cac-polish-motion-cache godot --windowed --resolution 1280x720 --fixed-fps 60 --path . --script tools/capture_movement_audit.gd -- artifacts/presentation_overhaul/baseline/motion-1280x720 REVISION 1280x720
XDG_DATA_HOME=/tmp/cac-polish-combat-data XDG_CONFIG_HOME=/tmp/cac-polish-combat-config XDG_CACHE_HOME=/tmp/cac-polish-combat-cache godot --path . --script tools/capture_authored_combat.gd -- /tmp/cac-polish-combat
XDG_DATA_HOME=/tmp/cac-polish-tests-data XDG_CONFIG_HOME=/tmp/cac-polish-tests-config XDG_CACHE_HOME=/tmp/cac-polish-tests-cache bash tools/run_headless_tests.sh
```

Repeat the two evidence commands at `1920x1080`, changing both the output path
and final size argument. Do not change desktop configuration to obtain evidence;
use the normal execution-permission mechanism if needed.

## Progress ledger and final report

| Ticket | Status at handoff | Required evidence |
| --- | --- | --- |
| P0 | Complete (2026-09-12) | Asserted gameplay fixtures, baseline motion and manifest |
| P1 | Complete (2026-09-12) | Short/long moves, turns, idle seams, lifecycle checks |
| P2 | Complete (2026-09-12) | Contact sequence, audible review, timing/reset gates |
| P3 | Complete (2026-09-12) | Mountain reference before/after, both views/resolutions |
| P4 | Complete (2026-09-12) | Six-role lineup, both ranks, deformation/grip inspection |
| P5 | Blocked on content (2026-09-12) | Reproducible clip audit and exact 65-joint animator brief |
| P6 | Complete (2026-09-12) | Full suite, five arenas, cinematics, frame times, final evidence |

### P0 evidence — trustworthy rendered fixtures

- Files: `tools/visual_evidence_harness.gd`, repaired
  `tools/capture_visual_audit.gd`, new `tools/capture_movement_audit.gd`,
  `tests/presentation/test_visual_evidence_harness.gd`, and the public
  Stockfish pending-work query.
- Visible result: starting board and engine reply are captured only after all
  gameplay overlays clear. Browser attack images are explicitly timed poses;
  contact filenames are driven by `impact_landed`. Motion uses a close tracking
  camera and legal sparse positions so gait, facing, and settlement are visible.
- Evidence: `artifacts/presentation_overhaul/baseline/` contains exact-size
  1280×720 and 1920×1080 broad and fixed-frame motion runs. Both motion
  manifests have 172 PNG records and identical 2,880-event streams. Broad runs
  contain 50 records each. All four manifests are valid with no fixture errors.
- Checks: the fixture-contract test passes and proves overlay, history, and
  camera mismatches are rejected; the real Stockfish adapter completed 100
  sequential legal requests; baseline animation routing, special projection,
  full death, 20-cycle Combat Lab, and cinematic lifecycle tests pass.
- Baseline defects made measurable: short pawn 0.5833 s, two-square pawn 1.15 s,
  and knight/24 m rook/28.284 m bishop all capped at 1.25 s. The current motion
  stretches one gait cycle and snaps facing, which is the P1 work now underway.
- Remaining diagnostics: two known Compatibility-renderer texture IDs are
  reported at shutdown. No asset or license files changed in P0.

### P1 evidence — continuous motion on the current rig

- Files: `piece_actor.gd` now owns one namespaced AnimationPlayer mixer for
  UAL1/UAL2, distance-driven locomotion, shortest-yaw turns, a repaired
  ping-pong neutral idle, and cancellable movement/turn/ambient/recovery
  lifecycles. `board_presenter.gd` owns quiet-move timing and replacement
  generations; `battle_director.gd` uses the same movement contract for capture
  approach and settlement. `test_continuous_motion.gd` covers the new behavior.
- Visible result: short and long moves use the same 2.2 m apparent stride,
  accelerate from rest, hold a steady middle, plant into arrival, and turn
  continuously. The previous one-cycle long-move stretch is gone. Native
  0.10–0.14 s blends connect locomotion, attack/recovery, and idle; hit/death
  entry uses a sharper 0.055 s transition and death never schedules an idle
  callback.
- Evidence: `artifacts/presentation_overhaul/p1/final-motion-1280x720/` and
  `final-motion-1920x1080/` each contain 284 captures and 5,288 frame events;
  their event arrays are byte-identical and every PNG has the requested size.
  `idle-1280x720/` and `idle-1920x1080/` add close seam triplets across three
  full five-second ping-pong cycles. All four manifests are valid with no
  fixture failures and zero idle root drift.
- Measured 1× settlement: short pawn 0.80 s, two-square pawn 1.25 s, knight
  1.35 s, 24 m rook 3.1167 s, and 28.284 m bishop 3.6667 s. Maximum sampled
  root travel is 0.1491 m/frame and maximum wrapped yaw change is 0.1953
  rad/frame at 1×; 0.25× samples scale continuously. Capture impact/death/
  completion remain 1.4167/4.0/4.65 s at 1× and settle exactly.
- Checks: animation routing, continuous motion, BoardPresenter projection,
  en-passant/promotion, both king parley directions, Grandmaster ceremony,
  full death playback, and 20-cycle Combat Lab all pass. The motion test also
  proves pause/resume, cancellation, actor replacement, and exact root targets.
- Visual review: paired 720p/1080p frames show repeated steps on rook/bishop
  travel and no orientation pop at 1× or 0.25×. Frame triplets on all idle
  turnaround/start boundaries show no visible pose discontinuity.
- Docs: ADR-025 and `ASSET_PIPELINE.md` record the mixer and movement contract.
  No assets were acquired or modified, so provenance/licenses are unchanged.

### P2 evidence — one measured capture and one shared timeline

- Files: `capture_choreography.gd` owns plant, contact, and recovery data;
  `battle_director.gd` stages and speed-scales anticipation through recovery;
  `piece_actor.gd` reports actual equipped-weapon distance; and
  `arena_audio_director.gd` owns cancellable approach and impact playback.
  `test_capture_timeline.gd` covers sequencing, speed latching, cancellation,
  exact settlement, contact geometry, and late-audio suppression.
- Reference choreography: the pawn-versus-pawn dagger attack plants at 1.30 m
  anchor separation. Its 0.40 s clip contact marker crosses a contact point
  2.30 m above the victim root at 0.431 m, inside the 0.60 m accepted radius.
  The former pawn proxy swing torus is suppressed so the equipped blade and
  victim silhouette remain inspectable.
- Shared timing: capture speed is latched when presentation starts; a setting
  change during a capture applies to the next one. The same scale drives turns,
  travel, body clips, prop actions, projectile arrival, sound, death,
  settlement, and recovery for generic, arrow, hammer, arcane, and signature
  follow-up paths. The final reference completes in 20.0167/5.05/2.5333 s at
  0.25×/1×/2×.
- Evidence: `artifacts/presentation_overhaul/p2/reference-scaled-1280x720/`
  and `reference-scaled-1920x1080/` each contain 30 exact-size captures and 36
  byte-identical events with no failures. `directions-1280x720/` records all
  eight incoming directions after proxy removal. `combat-1280x720/` records 20
  normal-speed play/reset cycles and a crowded 32-actor board that settles to
  31 actors without moving its camera. `audio-manifest.json` verifies all seven
  routed CC0 cues decode as non-silent 44.1 kHz stereo audio.
- Checks: the timeline, melee, authored role-action, signature follow-up,
  choreography resolver, arena audio, full death, and 20-cycle Combat Lab tests
  pass. Skip is covered before strike, during reaction, and during recovery;
  temporary effects reach zero and actors snap to authoritative roots.
- Visual review: matched contact frames show the equipped dagger crossing the
  victim zone with the reaction already starting; no proxy effect obscures it.
  The eight-direction sheet keeps both silhouettes readable and the crowded
  fixture retains the player board camera.
- Docs: ADR-026 and `ASSET_PIPELINE.md` record the shared timeline/contact
  contract. No content was acquired or modified; the audio is existing recorded
  CC0 material already listed in provenance.

### P3 evidence — Mountain Fortress visual reference

- Files: `beveled_box_mesh.gd` builds reusable flat-shaded chamfers;
  `chess_board.gd` applies them without changing square centers, outer bounds,
  or top height; `battlefield_environment.gd` owns neutral color ambient,
  two-split shadows, restrained lights, beveled terrace slabs, and coherent
  Mountain landmarks; `arena_catalog.gd` supplies the warm limestone palette.
- Visible result: the former razor-edged, flat altar now has readable stone and
  aged-bronze edge planes, deterministic material variation, grounded actor
  shadows, and warm local geometry that matches the panorama. The conspicuous
  cylinder/cone foreground towers are replaced by low dressed-stone banner and
  torch standards using existing licensed props. Cyan corner emission is now
  non-emissive aged bronze; gameplay markers retain distinct shapes and colors.
- Evidence: `artifacts/presentation_overhaul/p3/mountain-1280x720/` and
  `mountain-1920x1080/` each contain matched White/Black player-side views and
  disabled/2×/4× AA images. Both manifests are valid, reference the exact P0
  baseline files/FEN/camera, record 64 mapping round trips and zero tile-height
  errors, and report the same 32 m board extent. Visual review confirms all 64
  squares and both armies remain readable. A 99%-luminance audit of the 720p
  board crop finds zero clipped pixels after tuning (the matched baseline had
  14).
- AA decision: 2× MSAA visibly smooths diagonal rail, square, and team-ring
  edges. At 720p its disabled/2×/4× median times were
  5.801/6.727/8.805 ms and p95 8.806/9.683/10.299 ms; at 1080p they were
  7.411/10.537/11.618 ms and p95 10.325/11.865/12.876 ms. 2× is selected in
  `project.godot`; 4× adds less visible improvement for more cost.
- Checks: board and five-arena environment tests pass, including independent
  tile materials, exact geometry, imported Mountain props, neutral ambient
  source, and shadow settings. Arena replacement now removes the outgoing
  presentation node immediately, fixing stale one-frame lookups during skin
  switches.
- Docs: ADR-027 and `ASSET_PIPELINE.md` record the reference treatment and AA
  measurement. No asset was acquired or modified; reused banner/torch sources
  were already documented as CC0.

### P4 evidence — six readable role profiles

- Files: `piece_actor.gd` hides the duplicated ranger hoods, transfers the
  compatible skinned ranger hood to the bishop, adds small bone-bound role
  accessories, strengthens team tint only on garment details, and holds the
  knight spear upright at rest. `test_role_readability.gd` verifies the visual
  contract through five required pose families.
- Visible result: the compact unadorned pawn, open-headed crested lancer,
  hooded/mantled archer, broad bronze-shouldered hammer guard, three-point
  diadem queen, and five-point crowned king now keep distinct outlines. The
  queen uses face-clear buns and a raised diadem; the oversized king chest
  collar was removed after rendered review.
  All use the same canonical actor/model scale and the P2 pawn grip/contact is
  unchanged. Blue/red stays restrained on small hood/pauldron details, cloth
  crests, and compact floor bases; broad ranger belts remain near their authored
  material colors and bronze remains neutral.
- Evidence: `artifacts/presentation_overhaul/p4/roles-1280x720/` and
  `roles-1920x1080/` each contain 13 exact-size images: label-hidden white and
  black lineups in idle/walk/attack/recovery/death, a close queen face-clearance
  view, and both starting-rank views. Both manifests are valid and report zero
  root drift.
- Label-hidden review: both rendered lineups were identified correctly from
  left to right. Pawn, bishop, rook, and king are high confidence. Knight and
  queen remain medium confidence at the farthest starting rank when another
  actor occludes their hand weapon; the cloth crest and bronze diadem still
  separate them. This residual ambiguity is recorded in both manifests.
- Checks: role readability, weapon presentation, animation routing/browser,
  authored bow/hammer fallback, full death completion, measured melee contact,
  and 20-cycle Combat Lab tests pass. Every authored accessory follows a valid
  bone (or the bishop hood's compatible 65-joint skin), remains finite in every
  pose, leaves face/head meshes present, and never changes actor roots.
- Docs: ADR-028 and `ASSET_PIPELINE.md` record the role-appearance contract.
  No asset was acquired or modified; the transferred hood comes from the
  already documented CC0 outfit pack.

### P5 evidence — actionable skeletal content blocker

- Files: `tools/audit_animation_content.gd` samples candidate clips on the
  actual 65-joint runtime skeleton; `docs/P5_SKELETAL_ANIMATION_BRIEF.md`
  specifies the missing bow and hammer deliverables and their intake gate.
- Evidence: `artifacts/presentation_overhaul/p5/content-audit.json` records
  source clip length, track count, loop mode, hand separation/motion, and foot
  vertical range at 30 Hz. `Spell_Simple_Shoot` changes hand separation only
  0.0426 m and moves the hands only 0.0509/0.0208 m. `Pistol_Shoot` holds hands
  0.0663–0.0723 m apart. Hammer candidates include a 0.7073 m spacing range
  (`Melee_Hook`), a looping chop with hands 0.7947–1.0603 m apart, a low 2.5 s
  harvest, and a one-handed throw. None meets bow-string or two-hand-shaft
  mechanics.
- Tooling: Godot 4.7.2 can inspect/remap the rig, but Blender, assimp,
  gltf-transform, and a project skeletal editor are absent. The documented
  six-bone KayKit and distorted/one-handed CMU trials remain rejected with no
  retained derived assets.
- Safe state: normalized semantic IDs, data-owned release/impact markers,
  exact settlement, and the verified prop/body fallbacks remain unchanged.
  Purchase, commission, or outreach was not attempted. Completing the open
  body-mechanics item requires two licensed in-place clips matching the brief,
  followed by both-team, three-speed, 20-reset, grip, and exact-root evidence.

### P6 evidence — integrated presentation and final verification

- Files: `battlefield_environment.gd` propagates the P3 chamfered stage,
  neutral ambient/shadow, restrained marker-emission, and authored-prop rules
  across all five arenas. `CampaignCinematic.tscn` and
  `cinematic_director.gd` provide opaque dialogue surfaces and suppress speaker
  rows when the title already names that speaker. The visual and motion tools
  now link their baseline manifests; `capture_cinematic_lab.gd` uses the exact
  evidence harness; and `benchmark_presentation.gd` records warm GPU timings.
- Visible result: all five board-first arena views retain distinct panorama,
  palette, and landmark identity while sharing readable stone/bronze edge
  planes. Mountain intro and Forest conquest frames keep principal actors and
  board context clear at 720p and 1080p. Gatekeeper/Commander/Narration labels
  no longer repeat their title, while Objective retains the useful Grandmaster
  speaker row. Follow-up review places the Grandmaster directly in the calibrated
  seated idle from the first cue, hides her ceremony weapon, and confirms that
  her face and raised diadem remain clear. Visual review found no cropped dialogue.
- Evidence: `artifacts/presentation_overhaul/p6/visual-1280x720/` and
  `visual-1920x1080/` each contain 50 exact-size captures, correct arena HUD
  identity, five matching events, and baseline links. The final motion pair
  contains 291 captures and 5,487 byte-identical events per resolution with
  exact settlement. Mountain intro manifests contain four cues at both
  resolutions; the Forest conquest manifest contains three cues. Every
  manifest is valid with no fixture failures.
- Performance: the final 1920×1080 Compatibility-renderer run on AMD Radeon
  Graphics uses 2× MSAA and 120 warm-up frames. The 32-actor starting board
  measured 8.311 ms median and 9.246 ms p95 over 360 frames, with zero frames
  above 16.67 ms. Five normal-speed captures measured 2.099 ms median and
  3.022 ms p95 over 11,178 rendered frames, with one frame above 16.67 ms. The
  board p95 is 22.07% below the matched P3 11.865 ms reference, so no regression
  investigation is required.
- Checks: one clean `tools/run_headless_tests.sh` run passed all 51 tests with
  no script errors or failures. This includes perft depth 4, the real Stockfish
  100-move subprocess test, all 36 choreography resolutions, full death,
  special moves, cinematic lifecycle, and 20 Combat Lab play/reset cycles. A
  timing race found by the full gate is covered by ten repeated accelerated
  timeline runs: the exact authored contact pose is held for one process frame
  so skeleton attachments commit before proximity is measured.
- Docs: ADR-029 records the shared arena/HUD integration boundary. Rendered
  evidence is excluded from Godot imports through `artifacts/.gdignore` while
  the reproduction README and generators remain versioned. No content was
  acquired or modified, so third-party provenance is unchanged. P5 remains the
  separately documented content blocker; P0-P4 and P6 are complete.

For each completed ticket record: files changed, visible improvement, exact
fixture/command, artifact paths, checks run, remaining defects, and next action.
Update `docs/ROADMAP.md`; update `docs/DECISIONS.md` for animation ownership or
other architectural decisions and `docs/ASSET_PIPELINE.md` for pipeline changes.
Update asset provenance only when content is acquired or modified. Final handoff
must say what changed, why, verification, visible reproduction, limitations,
and docs/licenses updated. Do not report historical tests as newly executed.

## Paste into the next session

> Implement `docs/PRESENTATION_OVERHAUL_PLAN.md`. Read the project instructions
> and required context, then execute P0 through P6 in order. Begin with fresh
> deterministic visual evidence, fix movement/blending/contact on the existing
> rig, and carry the work through the visual treatment and role improvements.
> Use actual rendered motion and before/after comparisons as acceptance gates.
> Keep chess, Stockfish, campaign behavior, and exact actor settlement intact.
> Update the progress ledger as you go; continue through unblocked work without
> stopping after the first ticket. If skeletal content requires a purchase or
> commission, finish independent work and present the concrete missing asset
> brief. Do not hide content gaps behind extra VFX or mark unverified work done.
