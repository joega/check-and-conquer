# Terra work session — campaign presentation completion

Prepared 2026-09-12 after the Grandmaster seating, king arrival/listening, and
ceremony camera fixes. This is an execution handoff, not a request to produce
another plan. Work through the queue, implement each unit, verify it, record
the evidence, and continue without waiting for routine user feedback.

“Units” below means bounded work packages. The six chess archetypes already
exist. This session completes and strengthens their campaign presentation;
it does not start another character/rig acquisition project.

## Outcome and scope

Deliver a campaign that can tell its five-chapter story using the existing
characters, animations, props, arenas, and audio. First make the real ceremony
reproducible and safe to interrupt, then finish controls and outcomes, then
extend content one arena at a time. Leave a tested, reviewable working tree and
a concise progress report even if an external blocker prevents the last unit.

Use these instructions to resolve routine choices while the user is away:

- Preserve current gameplay and the recent visible fixes. Prefer the smallest
  coherent implementation within existing presentation/game boundaries.
- Use the current checkout as truth. It contains substantial existing modified
  and untracked work. Do not reset, clean, broadly revert, or sweep it into a
  commit. This handoff does not request committing, pushing, publishing, or
  changing branches. A new checkout from HEAD will omit important current work.
- No engine upgrade, backend, online play, rule changes, new difficulty design,
  new assets, paid services, voice/video generation, or replacement Grandmaster.
  The current female ranger Grandmaster and chair are the accepted baseline.
- Keep presentation code out of `scripts/chess/` and engine logic out of actors.
  Stockfish remains an unmodified separate UCI process.
- Do not replace the working Tween director with AnimationPlayer solely because
  an older design document suggested it. Extract only enough data to author the
  remaining arenas; no new cinematic language, plugin, or general framework.
- Use neutral standing idle for listeners. Unsupported/missing acting falls
  back to a verified neutral clip, never a random attack or gesture.
- Do not ask the user to choose ordinary shot coordinates, test fixtures,
  internal filenames, or similar reversible implementation details.
- When a unit passes, move to the next ready unit. When a unit has an external
  blocker, document it and work on independent ready units. Do not claim a
  dependent feature complete when its prerequisite is still failing.

## Read first; reconcile old documents with current code

Read `AGENTS.md`, `BATTLE_CHESS_MASTER_PLAN.md`, `docs/ROADMAP.md`,
`docs/VERIFICATION.md`, and the relevant architecture/decision notes. Read
`docs/CAMPAIGN_STORY_BIBLE.md` for existing story copy and
`docs/CAMPAIGN_CUTSCENES_PLAN.md` for remaining acceptance cases.

The older cutscene plan still calls the runtime unimplemented. That is stale:
Mountain Fortress has a working real-time intro and eligible-victory outro.
Some old proposed architecture and timing are also superseded. Recent user
requirements and the current verified Mountain Fortress presentation take
precedence. Do not reimplement completed features from the old checklist.
`docs/MOUNTAIN_FORTRESS_VIDEO.md` describes a separate unavailable video task;
it is not a dependency for this session.

Verified starting points:

| Area | Current source/evidence | Remaining work |
| --- | --- | --- |
| Runtime | `scripts/presentation/cinematic_director.gd`, `scenes/presentation/CampaignCinematic.tscn` | Mountain-only hardcoded timelines; expand after lifecycle checks |
| Dais/staging | `scripts/presentation/grandmaster_ceremony.gd` | Preserve pose; prove cancellation of every actor tween |
| Debug lab | `scripts/debug/debug_cinematic_lab.gd`, `scenes/debug/DebugCinematicLab.tscn` | Currently calls the director without speakers or ceremony; camera stress alone does not test real actors |
| Settings | `scripts/game/session_settings.gd` | `campaign_cinematics_enabled` already defaults true; no visible toggle in GameScreen |
| Entry/results | `scripts/game/game_screen.gd` | Intro selects Mountain only; outro currently requires a newly earned Mountain victory |
| Progress | `scripts/game/campaign_progress.gd` | Existing sequential eligibility must remain authoritative |
| Animation | `scripts/actors/piece_actor.gd` | Actual library/playback must agree with semantic requests |
| Render tools | `tools/capture_grandmaster_ceremony.gd`, `tools/capture_seating_fit.gd` | Reusable evidence baseline; broaden by arena/outcome after content exists |

## Locked regression requirements

1. Grandmaster chair scale remains 2.75; actor scale remains 1.48 with internal
   display scale 2.0. Her seated root is offset 0.60 world metres toward the board
   from the chair root. This compensates for Sitting_Idle's rearward pelvis.
   Do not “fix” seating by making the two roots equal. Judge actual hips, thighs,
   knees, feet, and chair geometry from side and front views.
2. Both kings stop actual Walk playback at their exact parley markers before
   dialogue decides who speaks. A semantic-state string alone proves nothing.
   `stance.challenge_01` previously looked up UAL2's Idle_Rail_Call in UAL1 and
   silently left Walk running. That library alias is now fixed.
3. The ceremony deliberately no longer uses that challenge pose for listeners:
   `idle.neutral` / actual `Idle` is the standing listener pose. Only the speaker
   uses `Idle_Talking`. Do not reintroduce the hunched rail-call gesture.
4. Grandmaster lines cut to a shot of her before text appears, including opening,
   objective, and victory. Her opening line now holds four seconds. The kings
   share a west-to-east group shot with her visible behind them. The dais does
   not mirror when the player selects Black. Keep text off her face.
5. Every exit restores exact authoritative board projection, camera ownership,
   animation speeds, visibility, and input state. Skip changes presentation only.

Existing gates: `test_grandmaster_ceremony.gd`, `test_king_parley.gd`,
`test_cinematic_director.gd`, and `test_campaign_cinematic_flow.gd`. All are in
their matching `tests/presentation/` or `tests/game/` folders. Preserve them.

## Work queue

Record each unit as pending / in progress / verified / blocked in
`docs/TERRA_SESSION_REPORT.md`. Include changed paths, tests, rendered evidence,
limitations, and next action. Do not spend the session only updating this table.

### U01 — Establish the baseline and fix animation lookup defects

**Depends on:** nothing. **Own:** actor animation mapping and focused tests.

Run the existing relevant tests first and save their output under an isolated
temporary directory. Enumerate both UAL1 and UAL2's actual imported clip lists;
`tools/inspect_animation_library.gd` currently only enumerates UAL1 and may be
extended to inspect both. Audit every existing semantic alias against its
selected player. Candidate aliases to inspect include Idle_Rail-backed states,
Sword_Heavy_Combo, Sword_Dash, and Sword_Block; do not assume library location.

Correct proven mismatches without changing the intended acting. Make a failed
clip request produce a bounded, truthful fallback rather than leave the previous
walk/attack silently running. Ensure `supports_state`, duration, active player,
pause/speed handling, and semantic reporting stay consistent. Preserve authored
bow/hammer timeline durations and actions. Do not globally swap all stances.

**Done when:** real players play each supported alias; switching libraries stops
the other player; invalid requests cannot leave locomotion running; arrival and
listener tests pass. Inspect any changed visible stance in Animation Browser.
Run the animation browser and affected combat/role-action tests as appropriate.

### U02 — Make Cinematic Lab exercise the real scene

**Depends on:** U01. **Own:** debug scene/script, debug fixtures, render helper.

Give the lab a real BoardPresenter projection, the actual GrandmasterCeremony,
and real commander/gatekeeper speaker bindings. Use an immutable starting FEN
fixture to construct the projection. Do not launch Stockfish or load/save the
player's campaign to preview a scene. Reuse environment construction APIs.

Keep Play, Skip, Reset, both human sides, and Stress 20. Display the current cue
and selected fixture in debug UI. Add a clear settled-position fixture for
victory preview; do not pretend moving a camera around an empty floor is a
ceremony preview. Add arena/outcome options only as those sequences are delivered.

**Done when:** Play visibly matches the real Mountain intro, both kings and
Grandmaster are present, Reset is repeatable, and the lab can capture all cue
shots. A 20-cycle run must exercise actor seating/travel/restore, not just speed
the director past actors still moving on an unrelated clock. Normal-speed travel
checks remain required even if the stress harness supports acceleration.

### U03 — Own and cancel every cinematic operation

**Depends on:** U02. **Own:** ceremony/director lifecycle and targeted integration.

Audit the actual tweens created for king approach, return, army materialization,
Grandmaster seating, and camera motion. Some actor travel tweens are local
variables today; prove they cannot keep moving actors after cleanup. Track and
kill owned operations as needed. Cleanup must work even when a home-transform
dictionary is empty; avoid early returns that skip other live work.

Replaying over an active run must cancel the old run before installing new
speaker/ceremony bindings. Check the current ordering of `play_*`, `_begin`,
and `cancel`. A missing camera/overlay must not emit completion synchronously
before GameScreen starts awaiting it and then strand the screen. Use a small
consistent asynchronous completion contract or an equally explicit status path.

Add a bounded watchdog using declared sequence duration plus a documented grace
period. Preserve exactly-once completion and cancellation without stale
continuations. Verify generation checks after relevant awaits. Fix proven
defects locally; do not rewrite the working Stockfish adapter on speculation.

**Done when:** early/mid/late Skip, repeated Skip, Reset during approach, Reset
during return/materialization, replay during playback, scene teardown, and
missing-camera/overlay paths all settle or safely cancel. Wait beyond the old
travel duration after cancellation and assert roots stay restored. Natural and
skip paths each hand off once; no actor/state/camera drift in 20 real cycles.

### U04 — Finish cinematic controls and HUD ownership

**Depends on:** U03. **Own:** GameScreen/settings scene and persistence tests.

Expose the existing Campaign cinematics setting in Match Settings, using the
current persistence key and layout conventions. Validate its type on load with
a backward-compatible true default. Apply preference to subsequent eligible
sequences; do not restart or interrupt a match when the checkbox changes.

During INTRO/OUTRO show story and Skip, hide misleading gameplay status such as
“White to move,” and prevent Menu/Hint/board controls from competing with speech.
Restore the normal HUD on all completion paths. Guard direct handlers as well as
button visibility. Escape must skip once without also pausing/selecting after
the handoff. Restart retries immediately; practice/spectator bypass cutscenes.

**Done when:** toggle persists; old/malformed config behaves safely; disabled,
practice, spectator, and restart paths bypass correctly. For human Black, engine
ready-before and ready-after intro paths yield exactly one opening search.
No intro input mutates FEN/history. Check layouts at 1280×720 and 1920×1080.

### U05 — Extract the small arena sequence data contract

**Depends on:** U03. **Own:** director, small presentation resources/catalog.

Move authored dialogue, cue durations, speaker IDs, outcome selection data, and
shot parameters into a small typed presentation resource under `data/cinematics/`
or an equally simple existing-style catalog. Keep a finite set of known stage
actions: seating, approach, dialogue, return, formation restore. Do not create
an interpreter for arbitrary commands. Keep game/progress objects out of data.

Migrate Mountain first without changing its accepted seating/listening/framing.
Keep old entry points as wrappers if that reduces integration risk. GameScreen
selects the sequence from immutable arena/result facts; the director only plays
it. Use stable bindings for commander/guardian/Grandmaster, not fixed chess color.
ArenaCatalog remains the source of chapter/opponent identity.

**Done when:** migrated Mountain renders the same accepted composition and
passes all regression gates; absent data/binding falls back without hanging;
the lab can select the data without an arena-specific GameScreen branch.
Document the exact contract before any parallel content authoring.

### U06 — Add defeat, draw, and repeat-victory treatment

**Depends on:** U04 + U05. **Own:** outcome selection and shared outcome resources.

Implement short shared defeat and draw sequences using the Story Bible's copy.
Distinguish a human victory from a newly earned campaign unlock: repeat wins may
have ordinary victory presentation without advancing anything. Snapshot the
finished arena, result, winner, and newly completed campaign status before
progress persistence changes the next selected arena.

Trigger outcomes after the terminal move/capture fully settles. Save eligible
progress before playing the outro. Do not infer a result from dialogue, animation,
or `mark_victory()` returning false. Preserve surrender's existing fall-and-return
flow without adding a second movie. Never kill/capture a king for defeat staging.
Use current surviving actor positions and a safe wide fallback for sparse/debug
positions. Preserve PGN review and return-to-final-position behavior.

**Done when:** actual terminal quiet/capture fixtures choose the correct outcome;
defeat/draw/repeat/disabled/practice/spectator never unlock; earned wins save once
even on Skip/fallback. Tests verify result/PGN/FEN/projection unchanged by playback.
Do not claim this gate from only calling `_present_terminal_result` directly.

### U07 — Deliver Arcane Sky Citadel

**Depends on:** U06. **Own:** one arena's data, debug fixtures, captures.

Implement the Story Bible's Chapter II intro, victory, and defeat; reuse shared
draw. Use obelisks/sky and distinct measured shot framing. Use existing light or
audio only when it improves the shot; a magical bridge or new effect is unnecessary.
Keep the Grandmaster visible whenever bound as narrator, and use neutral listeners.

**Done when:** both sides, all four outcomes, early/late Skip, and sparse end
positions pass the shared matrix below. Capture opening, guardian, commander,
objective, and outcome frames. This arena is the template gate for the next two;
do not expand while it still requires new runtime conditionals to work.

### U08 — Deliver Frozen Keep

**Depends on:** U07. **Own:** Chapter III content and evidence.

Use the supplied Winter Warden dialogue, quieter timing, and ice/stone framing.
Preserve the chapter's promise to return with help. Do not melt the environment
or add weather mechanics. Favor held shots and restrained acting.

**Done when:** Chapter III intro/victory/defeat/shared draw pass the same matrix;
the environment and pacing visibly differ from Chapter II; dialogue remains
readable at both supported resolutions with no speaker hidden behind ice props.

### U09 — Deliver Lava Forge

**Depends on:** U07; run after U08 by default. **Own:** Chapter IV content/evidence.

Use the Forge Tyrant dialogue and warm brazier framing with neutral readable
character lighting. Keep strength-versus-rule meaning intact. No boss fight,
execution, custom hammer clip, or additional capture content is required.

**Done when:** the same arena matrix passes and no brazier/flare/foreground prop
occludes speakers. Chapter IV's victory leads into the final grove with the
existing story copy, not a generic reused Mountain outro.

### U10 — Deliver Forest Ruins and earned final conquest

**Depends on:** U08 + U09. **Own:** Chapter V, final-event selection, completion copy.

Implement Chapter V intro/defeat/draw, ordinary repeat victory, and the distinct
20–25 second conquest ending from the Story Bible. A newly earned final campaign
win selects conquest once; ordinary replay must not claim a second completion.
Keep both kings visible where practical, otherwise use their actual positions
in separate shots. Sparse formations must work. Do not invent a new throne,
kneeling animation, cinematic item, or traveling montage.

Update the existing completed-map copy to echo “Five strongholds. One open road.”
Preserve result panel, map/practice/replay access, PGN copy, and review; do not
automatically dismiss results or reset progression.

**Done when:** first final win, repeated final win, Skip at multiple beats,
disabled cinematics, reload of saved completion, and return from review all
preserve completion exactly once. Final ending is visibly distinct and longer.

### U11 — Complete the visual and behavior matrix

**Depends on:** U10. **Own:** QA tools, focused corrections, verification report.

Run and inspect the matrix below. Fix concrete failures within the owning layer,
then rerun the affected checks. Do not merely accumulate screenshots nobody has
opened. Record evidence paths and what each image/test demonstrates. Extend the
existing capture tool to choose arena/outcome/side/fixture deterministically.

Address any new errors introduced by these units. Current GameScreen runs can
emit shutdown resource/GL-texture leak diagnostics: baseline them honestly.
If tracing proves a leak is owned by the new cinematic objects, fix it here;
otherwise record the remaining baseline issue rather than hiding logs or turning
unrelated cleanup into a broad rewrite.

**Done when:** every required matrix cell is verified or explicitly blocked with
its dependent deliverable still incomplete. Recheck original seating, arrival,
listener pose, and speaker framing after the full content expansion.

### U12 — Final integration gate and handoff

**Depends on:** U11. **Own:** final checks and documentation only except fixes.

Run `bash tools/run_headless_tests.sh`, including registered new tests, the
domain's perft depths 1–4 (20 / 400 / 8902 / 197281), the real Stockfish test,
and combat projection/reset gates. Investigate failures; don't weaken assertions
to finish. If fixing a failure changes behavior, rerun the affected gate.

After tests/rendering pass, perform the existing local Linux export/smoke check
if its installed dependencies are available. Inspect `tools/export_linux.sh`
first: it currently recreates `build/linux-x86_64`. Preserve any user-owned output
or use a separate staging path rather than silently deleting unknown artifacts.
This is a local build, not publication. Missing templates/platform tooling block
only that check; record them without claiming another platform was verified.

Update ROADMAP, VERIFICATION, and architecture/decisions only to reflect delivered
behavior. Correct stale “not implemented” text in the older cutscene plan with a
pointer to actual status; don't erase the useful story/acceptance requirements.
No new third-party assets are planned, so licenses should remain unchanged.
Finish `docs/TERRA_SESSION_REPORT.md` with unit status, tests, captures, remaining
defects, and the exact next action. Do not say “all done” if a required gate failed.

## Shared acceptance matrix

For each delivered arena, verify intro, human victory, human defeat, and a domain
draw for White and Black. Include natural completion and representative early
and late Skip. For Forest also verify newly earned conquest and repeat victory.
Automate combinations that exercise the same contract; inspect rendered key
shots for every arena/outcome and both player sides, including sparse end states.

At minimum assert:

- The current speaker's body/head are visible from the first displayed frame;
  text does not cover the face, clip outside the viewport, or overlap result UI.
- Listening kings stand neutrally; actual Walk/Run ends on arrival; only one
  animation player drives an actor at once.
- Dialogue is held long enough to read. Reuse Story Bible targets for new arenas;
  retain the accepted Mountain composition instead of padding/reworking it merely
  to hit an old approximate duration.
- Camera paths stay within real terrace geometry and panorama coverage. No
  reverse shots expose missing scenery. Grandmaster is never a mirrored actor
  assumption when choosing Black.
- Natural, Skip, fallback, and cancel restore camera/input/actor ownership;
  canceled callbacks cannot later move roots or show obsolete dialogue/results.
- Outcome playback leaves authoritative FEN/history/PGN/result and campaign
  eligibility unchanged. Final capture settles before outro; no duplicate `go`.
- Capture-speed setting does not accelerate story text. Muted audio still leaves
  the story understandable. Horn/music are not doubled or left overridden.

## Test and capture commands

Run from the repository root. Use new isolated XDG paths for each run so fixtures
cannot overwrite the user's progress. For example:

```sh
run_dir=$(mktemp -d /tmp/cac-terra.XXXXXX)
XDG_DATA_HOME="$run_dir/data" XDG_CONFIG_HOME="$run_dir/config" XDG_CACHE_HOME="$run_dir/cache" \
  godot --headless --path . --script tests/presentation/test_king_parley.gd
```

Use the same pattern for other tests; register new ones in
`tools/run_headless_tests.sh`. Save logs and verify exit status **and** absence
of assertion/script errors: Godot assertion failures can leave a script running,
and a forced timed quit is not a passing test. Bounded test deadlines should
exit nonzero on failure. Close only your identified stalled test processes.

Rendered baseline commands (require a working local display):

```sh
XDG_DATA_HOME="$run_dir/data" XDG_CONFIG_HOME="$run_dir/config" XDG_CACHE_HOME="$run_dir/cache" \
  godot --path . --script tools/capture_seating_fit.gd -- "$run_dir/seating"
XDG_DATA_HOME="$run_dir/intro-data" XDG_CONFIG_HOME="$run_dir/config" XDG_CACHE_HOME="$run_dir/cache" \
  godot --path . --script tools/capture_grandmaster_ceremony.gd -- "$run_dir/intro"
```

If sandbox display access fails, use the available permission mechanism for the
local Godot render. A headless test cannot substitute for visual verification.
If rendering is unavailable after safe checks, finish independent code/test work,
record the visual gate as blocked, and do not claim visual approval.

## Parallel work and session boundaries

Sequential implementation is the default through U07. If using subagents, one
worker owns core director/ceremony/GameScreen contracts; independent test review
or capture inspection is suitable parallel work. After U07 freezes the data
contract, Frozen and Lava resources can be authored independently in distinct
files, with one integrator. Do not let multiple workers edit the same interface
or run exported builds against partially merged assets. Preserve current dirty
work if using worktrees; HEAD alone is not this handoff's baseline.

Stop a dependent unit only for a concrete boundary: unavailable runtime/render
tool, asset/license requirement outside scope, a destructive operation involving
unknown user data, or an unresolved product decision that changes the requested
experience. Exhaust safe in-scope alternatives and keep independent work moving.
Do not spend time acquiring content or generating video to bypass a blocker.

At a context boundary, update the report with the exact files changed, current
unit, last passing check, live process handles, and next command. On resumption,
inspect the current tree and continue; do not restart completed units. When U12
passes, stop implementing and hand back the evidence rather than inventing scope.

## Suggested handoff prompt

> Read `next_steps.md` and execute its work units in order. Implement, test, and
> visually verify each unit before marking it complete. Preserve the current
> dirty worktree and recent ceremony fixes. Continue to the next ready unit
> without asking for routine decisions; record progress and blockers in
> `docs/TERRA_SESSION_REPORT.md`. Do not publish, acquire assets, or expand scope.
> Finish the queue if possible; otherwise leave an exact, honest continuation.
