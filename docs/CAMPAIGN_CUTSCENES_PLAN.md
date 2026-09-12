# Campaign intro and outro cutscenes — implementation handoff

Date: 2026-09-11. Status: implemented and superseded for runtime details; retain
this document for story and acceptance requirements. See
`docs/TERRA_SESSION_REPORT.md` for current implementation and evidence.

## Outcome and scope

Add skippable, story-led, real-time 3D cinematics before and after campaign matches. Use Godot AnimationPlayer timelines, existing arenas, existing PieceActor semantic animations, and existing audio. Each of the five locations gets its own story, guardian challenge, establishing shots, and victory consequence; defeat and draw share reusable treatments framed for that arena. Forest Ruins gets a distinct campaign-completion ending. **Read [Campaign Story Bible](CAMPAIGN_STORY_BIBLE.md) as part of this handoff**: it supplies the connected narrative, environmental traits, exact dialogue, and chapter storyboards requested by the user.

This is an extension of the implemented M10 campaign and M7 presentation polish. Preserve standard chess, Stockfish isolation, campaign eligibility, PGN review, and the three required debug scenes. Deliver all five arenas, but prove Mountain Fortress end to end before expanding content. No new cinematic plugin, engine upgrade, video pipeline, voice acting, rig ecosystem, or external assets are required.

## Recommended implementer

Use **GPT-5.6 Sol with high reasoning** for the complete feature, especially lifecycle integration. **GPT-5.6 Terra with high reasoning** is a reasonable choice when working through the bounded stages below; Terra is particularly suitable for arena timelines, debug controls, and test coverage after the lifecycle contract is stable. This is a project-specific judgment: the main difficulty is asynchronous coordination across engine callbacks, final combat, scene teardown, and UI.

Official model documentation describes [Sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol) as the flagship for complex professional work and [Terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra) as balancing intelligence and cost. It does not establish a Godot-specific benchmark. The OpenAI Docs skill informed this recommendation only.

One worker owns the integration interfaces. After stage 1 establishes them, a separate worker may author arena resources or review tests. Do not have multiple workers redesign GameScreen or the playback contract concurrently.

## Verified starting points

| Existing file | Relevant behavior and integration point |
| --- | --- |
| `scripts/game/game_screen.gd` | `_initialize_game()` starts the controller before `_play_arena_intro()`, which currently only fades a chapter card. `_after_presentation()` records victory, celebrates, and opens the result panel immediately. `_surrender_and_return()` has its own fall sequence. |
| `scripts/game/turn_controller.gd` | READY already exists. `start()` enters PLAYER_INPUT. Terminal moves set GAME_OVER before their presentation has finished, so GAME_OVER alone is not an outro trigger. |
| `scripts/game/campaign_progress.gd` | Defines five ordered arenas and validates sequential progress. `mark_victory()` rejects repeated advancement. |
| `scripts/presentation/arena_catalog.gd` | Existing chapter titles, opponents, objective copy, and arena visuals are the source of identity. |
| `scripts/presentation/camera_director.gd` | Currently provides impact shake only; shot ownership is a new, narrow extension, not an existing API. |
| `scripts/presentation/board_camera_controller.gd` | Owns orbit/pan/zoom state and supports disabling controls. Restoring only its transform after animating it would risk stale orbit state. |
| `scripts/presentation/board_presenter.gd` | Owns actor projection, ambient gestures, and victory acknowledgement. Can rebuild from authoritative state. |
| `scripts/actors/piece_actor.gd` | Supplies `play_state`, `supports_state`, `state_duration`, `celebrate_victory`, and reset/facing helpers. |
| `scripts/presentation/arena_audio_director.gd` | Supplies arena music and shared SFX routing; cinematic gain control must be added if needed. |
| `scripts/game/session_settings.gd` | Stores validated primitive settings and campaign snapshot. |
| `scripts/app/campaign_map.gd`, `project.godot` | CampaignMap is the actual startup scene. Practice/Quick Match bypasses campaign progression. |
| `tools/run_headless_tests.sh` | Explicit test list, import preparation, and isolated user-data paths; register new test scripts here. |

Read AGENTS.md, the master plan, ROADMAP, ARCHITECTURE, current decisions, and relevant tests before implementation. Recheck these points against the checkout; this handoff is based on the code inspected on the date above.

## Player experience

Default: campaign cinematics enabled. A persisted **Campaign cinematics** toggle enables/disables them independently of capture speed. No first-view tracking in this version: normal entry from the campaign map plays the intro; Restart retries immediately without replaying it. Practice and spectator matches retain their existing chapter card/result presentation and do not play campaign cinematics, even if a saved campaign flag is true.

| Event | Intended sequence |
| --- | --- |
| Campaign entry | Loading completes → story intro, 16–22 seconds → default board view for chosen human side → first turn. |
| Human campaign win | Final move/capture fully settles → eligible progress saved once → story victory outro, 10–14 seconds → existing result panel → player chooses map/restart/review. |
| Human campaign defeat | Final move/capture settles → defeat outro, 5–7 seconds → result panel. No unlock. |
| Any terminal draw | Final move settles → neutral draw outro, 4–6 seconds → result panel. No victory claim or unlock. |
| Final eligible campaign win | Final combat settles → final progress saved → distinct conquest outro, 20–25 seconds, replacing ordinary victory → result panel → completed campaign map. |
| Surrender | Preserve current full fall presentation, then return to map. Do not add a second defeat cinematic. |
| Cinematics disabled | Start play or show results directly; identity/result text remains available in HUD/panel. |

Provide a visible **Skip cinematic** button and a keyboard action (Space or Escape) throughout playback. Consume the triggering input so it cannot also select a square, pause, or activate the next screen. Natural completion and skip use the same cleanup and continuation. Disabling campaign cinematics does not introduce a capture-skip button.

Use the chapter/opponent identity from ArenaCatalog and the authored story/objective cues from the Story Bible within the intro timeline, replacing the separate campaign chapter-card tween. Keep text legible at 1280×720 and 1920×1080, with safe margins and speaker labels. Store timed narrative cues in presentation resources and hold them long enough to read. The story must work without voice assets. For this version, Escape skips during cinematics; normal pause applies again after playback. Cinematics do not pause the SceneTree, which would complicate engine processing and completion.

## Storyboards and art direction

The Story Bible is authoritative for dialogue, narrative pacing, and full shot timings. The following summarizes the shot structure for implementation:

| Time | Intro beat |
| --- | --- |
| 0–5 s | Slow reveal across a real terrace/watchtower foreground toward the distant fortress; chapter/title and opening narration. Arena horn sounds once. |
| 5–11 s | Medium three-quarter shot of the opposing king, presented as the Gatekeeper; one compatible restrained gesture and guardian challenge. |
| 11–18 s | Human formation and Commander's response, then objective and transition to human-side board composition. Clear text, switch back to gameplay camera, release the first turn. |

Victory: brief winning-side acknowledgement, arena landmark shot with “secured” copy, then restore the board and reveal results. Defeat: focus the losing human king in a subdued supported pose, then pull back to show the opposing formation. Draw: balanced wide composition and neutral result text. Do not invent a captured/dead king; a held combat idle is an acceptable initial substitute if no credible subdued clip exists.

| Arena ID | Intro visual distinction | Victory/conquest distinction |
| --- | --- | --- |
| `mountain_fortress` | Terrace/watchtower foreground; Gatekeeper reveal. | Fortress secured; route to the Cloud Road acknowledged. |
| `arcane_sky_citadel` | Obelisk foreground against the sky panorama; Sky Seer reveal. | Restrained existing arcane light accent; citadel held. |
| `frozen_keep` | Ice-spire foreground and cold panorama; Winter Warden reveal. | Quiet winning formation against the ice; Winter Crown secured in text. |
| `lava_forge` | Forge brazier foreground; Forge Tyrant reveal. | Warm forge framing, restrained ember emphasis; Ember Trial complete. |
| `forest_ruins` | Ruined-arch foreground; Grove Sovereign reveal. | Final eligible win: formation acknowledgement → wide grove shot → “Warpath conquered” chapter treatment. No next-arena copy. |

All five need genuinely different framing and timing details, not only recolored titles. Reuse templates and existing effects where suitable; avoid requiring new animated landmarks.

The distant panoramas are flat generated backdrops, not traversable sets. Keep camera paths within verified local geometry and backdrop coverage. Avoid reverse shots, full orbits, underside views, and close shots that expose panorama edges, low-detail weapon grips, or unavailable skeletal acting. Test both human colors; the opponent is the opposite side, not always Black. Frame kings from current actor positions, with a wide-shot fallback for missing debug actors.

## Architecture and ownership

Use one reusable `CampaignCinematic.tscn` under `scenes/presentation/`, containing an AnimationPlayer, a dedicated cinematic camera rig, and presentation helpers. Keep the overlay under the GameScreen UI with a clear Skip action. Prefer typed per-arena resources under `data/cinematics/` referencing authored animations/shot parameters. Use Godot timelines for shot progression, UI fades, and presentation event timing. Actor requests go through semantic actor APIs; timeline tracks must not target imported skeleton paths or mutate game state.

Proposed small additions (names may be adjusted consistently):

- `scripts/presentation/cinematic_sequence.gd`: typed resource containing ID, timeline/animation reference, duration bound, and shot/actor cue configuration. Avoid a general scripting language for cinematics.
- `scripts/presentation/cinematic_director.gd`: playback, validated presentation bindings, cancellation, timeout, and cleanup. Lives outside chess/engine code.
- `scenes/presentation/CampaignCinematic.tscn`: reusable playback assembly; per-arena AnimationLibrary/resources can share base beats.
- `scenes/debug/DebugCinematicLab.tscn` and `scripts/debug/debug_cinematic_lab.gd`: deterministic preview and stress loop.

Freeze this contract before parallel content authoring:

```text
play(sequence, presentation_context, run_id)
skip()
cancel()  # releases ownership; never starts the obsolete continuation
finished(run_id, reason)  # completed | skipped | fallback; exactly once
```

The context contains arena ID, human/winning side, immutable result display data, actor bindings, and presentation services. It must not contain a mutable ChessGame, CampaignProgress, or Stockfish adapter. GameScreen selects intro/victory/defeat/draw/conquest from authoritative facts; the director never determines who won.

Use a small screen lifecycle enum such as INITIALIZING, INTRO, PLAYING, OUTRO, RESULTS, LEAVING. This belongs in game orchestration; do not add cinematic rules to `scripts/chess/`. TurnController retains READY during intro and GAME_OVER during outro. Screen lifecycle guards must cover mouse picking, manual UCI submission, hint requests, engine requests/results, restart, side/difficulty/spectator changes, pause, and review entry.

### Camera, actor, and audio ownership

Extend CameraDirector narrowly to acquire/release cinematic camera ownership. Animate a separate cinematic Camera3D, leaving the board camera's orbit/pan/zoom state intact. Stop pending camera shake before ownership changes, disable board controls, and record the prior active camera/control state. Release returns to the unchanged gameplay camera; do not reset a manually adjusted view after an outro. Intro ends at the selected side's default view. Ordinary captures keep their existing camera behavior.

Suspend BoardPresenter ambient gesture scheduling and cancel/reset any active competing actor gesture before an authored cue. Choose actor bindings deterministically. Keep roots on board squares; use in-place acting for this scope. Restore affected facing, animation speed, idle/stance, props, visibility, and ambient scheduling on every exit. BoardPresenter remains responsible for projection; if restoration fails, GameScreen rebuilds from authoritative state. Do not duplicate a second army for cinematic staging.

Reuse the arena music player. Route cinematic cues through owned players or shared semantic audio services, respect master volume, and restore any temporary gain on skip/failure/teardown. The entry horn must have one owner so initialization and timeline do not both play it. Capture-speed settings must not accelerate cutscene acting or camera tracks; restore any actor speed overrides afterward.

### Starting play and showing results

Introduce one guarded post-intro start path. Initialize board/environment/settings and allow the engine handshake, but keep TurnController READY until intro completion/skip/fallback. Then start the controller once and request the opening engine move if the human plays Black. Engine readiness can arrive before or after this point; both paths must converge without duplicate `go` requests. Spectator/practice bypass cinematic playback and use the same safe start path where applicable.

At game end, await `_present_result()` completely, verify projection, and settle the controller before selecting an outro. Preserve `_record_campaign_victory_if_earned()` eligibility and persist earned progress before playback. Snapshot the finished arena ID, outcome text, winner, and whether this event completed the campaign before settings advance to the next arena. Never unlock anything from an AnimationPlayer event or a cinematic completion callback. Replaying an already completed arena may show ordinary victory but must not claim a new unlock or replay the final conquest as newly earned.

Refactor result-panel population into a reusable method called after outro completion/skip/fallback. Absorb the existing immediate checkmate celebration/banner into cinematic playback when enabled, avoiding double gestures and overlapping result UI. The disabled/practice path retains ordinary result feedback. PGN copy and review work after the outro without replaying it when returning to the final position.

### Cancellation and failure

Use a monotonic match/run generation token for all new asynchronous continuations. Restart, scene exit, and return invalidate prior runs before freeing nodes. Every callback after an await checks the generation and object validity. A cleanup method must be idempotent and stop owned timelines/tweens/cues, clear the overlay, release camera/actor ownership, and prevent a late completion from starting a turn or showing an old result panel.

The independent lifecycle review also found that the adapter emits parsed bestmoves after `stop_thinking()`, while the screen routes hints through a boolean flag. A generation/FEN check alone cannot identify an old UCI response once a new search starts. Clear pending hint/move state and drain canceled searches before issuing a new one, or recreate the adapter on restart. Prove the chosen behavior with delayed-response tests; this requires no modification to Stockfish itself.

Reject restart/undo/side changes through normal UI during INTRO/OUTRO; still make teardown cancellation safe for external scene changes and debug tests. Surrender cannot overlap a running capture or cinematic. Guard its direct handler, not only button visibility. If invoked during active presentation, reject or defer until settlement rather than starting competing actor animation.

Handle missing sequence/clip/binding with a bounded fallback: use a supported idle or wide shot where possible, otherwise clean up and continue to play/results. Add a sequence duration watchdog with a small documented grace interval. Do not await a completion signal forever; stopping or seeking an AnimationPlayer is not equivalent to normal completion. Skip runs cleanup explicitly rather than seeking through potentially side-effecting call tracks. Cancellation suppresses old continuation; fallback completes the current valid one. Defer unsafe node removal from timeline callbacks.

## Implementation stages

### 1. Mountain Fortress vertical slice and lifecycle

Implement the director/resource/scene, dedicated camera ownership, screen lifecycle, one intro and one victory outro, Skip, and a minimal Cinematic Lab. Wire actual campaign entry and actual terminal-move settlement. Add tests for human White/Black startup, engine readiness on both sides of intro completion, and result persistence independent of playback.

Gate: Mountain Fortress looks coherent, finishes or skips cleanly, and survives 20 deterministic replay/reset cycles with no drift, stuck state, duplicate continuation, or leaked effects. Run a rendered pass before authoring more arena content. Do not mark the complete feature done at this gate.

### 2. Complete outcomes and user controls

Implement shared defeat/draw treatments, the cinematics toggle with settings validation/backward-compatible defaults, restart policy, existing surrender coexistence, review behavior, timeout/missing-resource fallback, and cancellation tests. Ensure practice/spectator bypass and both human sides behave correctly. Preserve engine recovery UI and never let a late engine callback overwrite a cinematic/result screen or mutate a stale match.

### 3. All five arenas and final conquest

Author per-arena resources/shots and timed dialogue using `CAMPAIGN_STORY_BIBLE.md` and the storyboard matrix. Implement all five guardian stories and transitions, then the Forest Ruins conquest variant only for a newly earned final campaign win. Tune titles, text reading time, shot framing, compatible gestures, and audio by inspecting actual rendered playback. Verify every arena/outcome/side combination; use wide fallback shots for sparse final positions. Include the completed campaign-map story copy and the Story Bible's narrative acceptance criteria.

### 4. Verification and handoff

Register tests, complete the matrix below, capture representative video or timestamped frames, and update docs. Report actual tests run, visible defects, and any unverified platform. Export/smoke-test the existing Linux build when the full suite and rendered checks pass. No new external publication is part of this task.

## Verification and acceptance

Add behavioral tests, not only resource-existence assertions:

1. During intro, attempts to submit UCI, click a move, request a hint, or start engine thinking leave FEN/history unchanged. Completion and repeated Skip yield exactly one first-turn handoff. Black starts with exactly one engine turn.
2. Terminal quiet and capture moves, including a promotion capture fixture, finish settlement before outro starts. Cinematics leave FEN, PGN, result, and actor-square mapping unchanged.
3. Eligible wins advance/save exactly once even on skip, missing timeline, or timeout. Defeat, all supported draws, surrender, practice, spectator, and repeat wins never unlock arenas. Final conquest only occurs for the qualifying fifth win.
4. Normal end, early/mid/late Skip, duplicate Skip, cancellation, and timeout all restore camera/control state, actor roots/facing/speed/props, HUD, music gain, and ambient behavior. A manually panned/zoomed outro returns to that same view without a jump on the next camera input.
5. Scene exit or debug restart during each timeline phase leaves no valid old continuation. Inject late engine ready/bestmove/error and presentation callbacks to prove they cannot affect a new run. Avoid expanding the Stockfish protocol unless evidence requires it.
6. PGN review and Return to Final do not replay an outro or resave campaign victory. Missing debug actors resolve safely.
7. Settings load from old/malformed snapshots with safe defaults; changing the cinematic preference leaves capture-speed behavior intact.

Suggested tests: `tests/presentation/test_cinematic_director.gd`, `tests/game/test_campaign_cinematics.gd`, and focused additions to session-settings, camera, and real-process GameScreen integration tests. Register scripts in `tools/run_headless_tests.sh`.

Run `bash tools/run_headless_tests.sh` after integration, retaining start-position perft 20 / 400 / 8,902 / 197,281 and the existing real Stockfish integration gate. Use the runner's isolated user-data convention for all cinematic fixtures; do not overwrite the developer's campaign progress. Headless tests cannot establish visual or acoustic quality.

The new Cinematic Lab must offer arena, outcome, human side, deterministic fixture/seed, Play, Skip, Reset, and a 20-cycle stress action. Use real actors/environment/director with synthetic read-only result context; no campaign save or Stockfish is needed. Include sparse endings and camera-customization fixtures. Proposed direct launch once implemented:

```bash
godot --path . res://scenes/debug/DebugCinematicLab.tscn
```

Provide a reproducible capture helper patterned after `tools/capture_visual_audit.gd`, recording arena/outcome/side/seed/timestamps. Capture all five intros and wins, representative defeat/draw, and the final conquest; verify both sides and early/mid/late skips. Inspect at 1280×720 and 1920×1080 for readable text, actor framing, panorama seams, clipping, animation pops, camera transitions, and restored gameplay. Listen to horn/music/cue overlap and test muted playback. Check frame pacing against the existing 60-fps target and name the hardware used.

## Documentation and provenance

During implementation, update ARCHITECTURE for ownership/lifecycle, DECISIONS with an accepted cinematic ADR, ROADMAP with actual progress, ACCEPTANCE_CRITERIA with the automated/rendered gates, and README with controls/debug commands. Existing required debug scenes must still launch. Do not label planned work as implemented.

Reuse current licensed assets first. Project-authored timeline files should be identified as original choreography. If additional assets become necessary, validate the current source/license before acquisition and record all derived files in `assets/THIRD_PARTY_ASSETS.md`; do not block delivery on an unneeded content pack. Keep Blender/mocap, voiced dialogue, prerecorded videos, cinematic galleries, and large terrain expansion as future work.

Godot reference: [AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html). Timelines provide playback and sequencing; this plan adds explicit lifecycle, skip, and restoration behavior around them.

## Pasteable handoff

> Implement `docs/CAMPAIGN_CUTSCENES_PLAN.md` and `docs/CAMPAIGN_STORY_BIBLE.md` in Check & Conquer. Read AGENTS.md and the master plan first. Deliver dramatic, skippable in-engine story intros and outcome outros for all five campaign arenas, including the guardians' dialogue, distinct environmental atmosphere, chapter transitions, and final conquest, using existing assets and Godot AnimationPlayer. Follow the four stages; prove the Mountain Fortress slice for 20 cycles before expanding content. Preserve chess authority, campaign eligibility, final-combat settlement, camera state, PGN review, practice/spectator behavior, and Stockfish lifecycle. Own the integration contract before delegating resource/test work. Use deterministic debug scenes and rendered verification as well as the headless suite. Continue through all stages, document verification and limitations, and do not stop after a placeholder camera pan or a framework without finished arena stories.
