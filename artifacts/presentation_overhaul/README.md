# Presentation overhaul evidence

Rendered evidence is generated into this directory with isolated Godot user
state. The large PNG sequences are intentionally ignored by Git, while this
index, the capture tools, and the progress ledger are versioned.

## Accepted P0 baseline

The current workspace contains the accepted pre-overhaul baseline under
`baseline/`:

- `visual-1280x720/` and `visual-1920x1080/`: 50 asserted broad-audit images
  and a manifest at each exact output size.
- `motion-1280x720/` and `motion-1920x1080/`: 172 fixed-frame images and a
  2,880-event manifest per resolution. The event streams are identical across
  resolutions and cover short/two-square pawn, knight, long rook, long bishop,
  and pawn capture fixtures at 1× and 0.25×.

The manifests identify revision `1bef499+pre-overhaul`, Compatibility renderer,
AMD Radeon Graphics, camera data, fixture FEN/moves, requested and actual output
dimensions, animation speed, and lifecycle events. `valid: true` and an empty
`failures` array are required before any directory is accepted.

Visual review on 2026-09-12 confirmed that both starting-board images contain
32 actors with no cinematic or arena-title overlay; the two-ply engine images
show a moved human pawn and a legal settled Stockfish reply; the close-tracking
motion frames keep feet and body mechanics readable; and pawn impact is sampled
from `BattleDirector.impact_landed`. The known two OpenGL texture-cleanup
messages remain isolated to process shutdown.

Reproduce both resolutions from the project root:

```bash
XDG_DATA_HOME=/tmp/cac-p0-visual-data XDG_CONFIG_HOME=/tmp/cac-p0-visual-config XDG_CACHE_HOME=/tmp/cac-p0-visual-cache godot --windowed --resolution 1280x720 --fixed-fps 60 --path . --script tools/capture_visual_audit.gd -- artifacts/presentation_overhaul/baseline/visual-1280x720 REVISION 1280x720
XDG_DATA_HOME=/tmp/cac-p0-motion-data XDG_CONFIG_HOME=/tmp/cac-p0-motion-config XDG_CACHE_HOME=/tmp/cac-p0-motion-cache godot --windowed --resolution 1280x720 --fixed-fps 60 --path . --script tools/capture_movement_audit.gd -- artifacts/presentation_overhaul/baseline/motion-1280x720 REVISION 1280x720
```

Repeat with `1920x1080` in the resolution, output directory, and final argument.
Rendered commands require desktop/GPU access. The tools render into explicit
GPU SubViewports, so compositor tiling cannot silently change evidence size.

## Accepted P1 continuous motion

The accepted P1 comparison lives under `p1/`:

- `final-motion-1280x720/` and `final-motion-1920x1080/`: 284 matched captures
  and 5,288 events each for three idle cycles, five quiet moves at 1×/0.25×,
  and pawn capture at 1×/0.25×. The event arrays are byte-identical.
- `idle-1280x720/` and `idle-1920x1080/`: 19 close seam images and 903 events
  each, sampling before/on/after every boundary of three full ping-pong cycles.

All four manifests identify the Compatibility renderer and AMD Radeon Graphics,
report `valid: true` with no failures, and contain only exact requested-size
captures. Visual review on 2026-09-12 found continuous idle boundaries, repeated
steps over long travel, smooth turn entry/exit, and exact settled roots.

Reproduce the matched motion run by replacing the output directory and revision
in the baseline motion command above. Add `idle-only` after the final size
argument to reproduce the close three-loop seam audit without the move/capture
fixtures.

## Accepted P2 combat timing

The accepted P2 reference lives under `p2/`:

- `reference-scaled-1280x720/` and `reference-scaled-1920x1080/` contain 30
  matched stage/contact images and 36 byte-identical events each at
  0.25×/1×/2×.
- `directions-1280x720/` contains the final actual-dagger contact view from all
  eight approach directions with the proxy swing torus removed.
- `combat-1280x720/` records 20 normal-speed reset cycles and one crowded-board
  capture. Its earlier reference frames are retained only for lifecycle and
  crowding evidence; the `reference-scaled-*` pair is the accepted contact and
  speed comparison.
- `audio-manifest.json` records ffprobe/ffmpeg decode and non-silence checks for
  every routed approach, arrow, hammer, sword, and arcane cue.

All accepted manifests report `valid: true` and no failures. The actual pawn
dagger reaches 0.431 m from the configured victim contact point within a 0.60 m
radius. Reproduce the matched reference by running
`tools/capture_combat_timeline_audit.gd` with output path, revision, size, and
the final `reference-only` argument. Use `directions-only` for the eight-way
contact sheet or omit the mode for the full lifecycle/crowded run.

## Accepted P3 Mountain Fortress reference

`p3/mountain-1280x720/` and `p3/mountain-1920x1080/` each contain matched
White/Black camera views plus disabled, 2×, and 4× MSAA captures. Each manifest
references the exact baseline image, FEN, and camera transform used for its
comparison, and asserts 64 square/map round trips, a 32 m board extent, and zero
tile-top errors.

The same-scene timing samples record 120 post-warm-up frames per AA mode. 2×
MSAA is the accepted Compatibility setting: it visibly smooths the diagonal
board and team-ring edges while both 1080p median and p95 remain below the
16.67 ms 60 FPS budget. Reproduce with `tools/capture_arena_reference_audit.gd`
and output path, revision, and exact size arguments.

## Accepted P4 role readability

`p4/roles-1280x720/` and `p4/roles-1920x1080/` each contain label-hidden
white and black lineups in idle, walk, attack, recovery, and death plus both
starting-rank views and a close queen face-clearance frame. The manifests list outfit, silhouette, accessory, side,
state, sample time, camera, and root-drift metadata for each role. Both are
valid, contain 13 exact-size images, and report zero actor-root drift.

The implementor review identifies all six roles correctly. Knight and queen
remain the lowest-confidence pair at the farthest rank when a neighboring actor
occludes the hand weapon; their cloth crest and bronze diadem remain distinct.
The accepted follow-up render confirms both queen eyes clear beneath face-clear
buns and a raised diadem, subdued broad-belt tint, and no king chest torus.
Reproduce with `tools/capture_role_readability_audit.gd` and output path,
revision, and exact size arguments.

## P5 content blocker

`p5/content-audit.json` is generated by `tools/audit_animation_content.gd`. It
samples every plausible installed bow/hammer body clip at 30 Hz on the current
65-joint skeleton and records hand/foot motion, clip length, tracks, and looping.
The result is `blocked_on_content`; the current semantic fallbacks remain safe.
The required replacement contract is versioned in
`docs/P5_SKELETAL_ANIMATION_BRIEF.md`.

## Accepted P6 integration

The final integrated evidence lives under `p6/`:

- `visual-1280x720/` and `visual-1920x1080/` each contain 50 exact-size broad
  captures. The five arena records per side include the correct HUD title; both
  manifests link the corresponding P0 baseline and have identical event data.
- `motion-1280x720/` and `motion-1920x1080/` each contain 291 captures and
  5,487 byte-identical frame events. They link the P0 baseline and P1 accepted
  reference and include the final deterministic contact hold.
- `cinematic-mountain-1280x720/` and `cinematic-mountain-1920x1080/` contain
  the four Mountain intro cues. `cinematic-conquest-1280x720/` contains the
  three final Forest conquest cues. Controls are hidden and every cue records
  its camera, speaker metadata, arena, side, and outcome.
- `performance-1920x1080/` records the final warmed Compatibility-renderer GPU
  run: the 32-actor board is 8.311 ms median/9.246 ms p95 across 360 frames;
  five normal-speed captures are 2.099 ms median/3.022 ms p95 across 11,178
  frames. All use 2× MSAA on AMD Radeon Graphics.

All manifests report `valid: true` with no failures. Reproduce the broad and
motion pairs with the commands above, substituting the `p6` output paths and a
revision label. Reproduce cinematics with `tools/capture_cinematic_lab.gd` and
arguments `OUTPUT REVISION SIZE ARENA OUTCOME SIDE`. Reproduce performance at
1920×1080 with `tools/benchmark_presentation.gd -- OUTPUT REVISION 1920x1080`.
`artifacts/.gdignore` prevents these generated PNG sequences from inflating the
Godot import database.
