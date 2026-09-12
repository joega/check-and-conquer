# Verification Record

This document records the repeatable checks used for the current Check & Conquer prototype. It distinguishes automated evidence from visual and product review that still requires a person running the game.

## Automated gates

Run all deterministic checks from the repository root:

```sh
bash tools/run_headless_tests.sh
```

The suite covers:

- bootstrap configuration and required debug scenes;
- chess-state FEN/UCI behavior, legal move generation, and start-position perft through depth 4 (`20`, `400`, `8,902`, `197,281`);
- turn phases, session settings, and Stockfish UCI formatting;
- sequential campaign progression, snapshot validation, map lock/conquered states, and persisted arena selection;
- a real Stockfish subprocess handshake and 100 sequential independently validated legal moves;
- board mapping, board-edge coordinate labels, FEN-to-actor reconstruction, input projection, quiet/capture/special-move settlement, and all 36 choreography resolver pairings;
- camera orbit/zoom and capture-shot exit;
- capture audio generation, full victim-death completion, the animation browser, and 20 deterministic Combat Lab play/reset cycles;
- Mountain Fortress Grandmaster dais props, king-only parley staging, and exact 32-piece authoritative formation restoration;
- a playable GameScreen turn against Stockfish and autonomous Stockfish-versus-Stockfish spectator turns.
- all delivered campaign cinematic catalog resources, terminal outcome selection,
  Arcane/Frozen/Lava/Forest real-lab side/outcome/sparse-fixture Skip matrix,
  and one-time Forest conquest selection.

The FEN Position Loader test is part of this command. It verifies valid FEN reconstruction in the scene's actual `BoardPresenter` and confirms invalid input preserves the last valid visual board.

The public repository's [GitHub Actions workflow](../.github/workflows/test.yml)
runs this same command on pushes to `main` and pull requests. It downloads the
pinned Godot editor and compiles the committed Stockfish source into the ignored
test-binary path before the suite starts.

## Linux package check

With Godot 4.7.2 export templates installed:

```sh
bash tools/export_linux.sh
timeout 2s build/linux-x86_64/check-and-conquer.x86_64 --headless
```

The expected smoke-test exit is `124`: the game remains running for the two-second window. This check passed for the Linux export on 2026-09-10 using Godot 4.7.2 export templates. The exporter stages the executable Stockfish binary beside the game and copies its corresponding source and notices.

## Windows package check

The repository includes a Windows Desktop export preset and a staging script.
After adding the official Windows x86-64 universal Stockfish archive at
`third_party/stockfish/windows-x86_64/stockfish/` and installing matching
Godot export templates, run:

```sh
bash tools/export_windows.sh
```

Smoke-test `build/windows-x86_64/check-and-conquer.exe` on a Windows x86-64 machine.
This check remains pending because the Windows Stockfish binary is not in the
repository or current development workspace.

## Manual visual review

Before tagging a public release, run the game from the editor and review:

1. Each player-side default camera framing, close face-level zoom, and all five grand-arena panorama/terrace combinations.
2. Ordinary walk movement and all six role-specific props at gameplay distance.
3. A capture with the action camera centered on the attacking pair, followed by a clean cut to the next turn-aware board view.
4. Settings-menu readability at the target window size.
5. The final title, logo, and marketing art for originality and trademark suitability.

## Ceremony seating and king arrival regression (2026-09-12)

The Grandmaster uses the existing 2.75 chair scale and 1.48 actor scale (with
2.0 internal character display scale). Chair_1's seat top is at source y=0.50.
UAL1 Sitting_Idle puts the pelvis behind the actor origin; the seated origin
now sits 0.60 world metres toward the board from the chair origin. This puts
the hips over the seat, knees beyond its front edge, and feet on the dais.
The ceremony test samples actual pelvis, knee, and toe bones in chair space
through two seconds of seated idle, rather than asserting equal root positions.

The king arrival failure was an animation-library mismatch: Idle_Rail_Call
exists in UAL2, but stance.challenge_01 requested it from UAL1. The old request
recorded a standing semantic state while leaving Walk playing. Both challenge
and the Grandmaster's Idle_FoldArms alias now use their supplying UAL2 player.
The new `test_king_parley.gd` checks actual players on the arrival frame before
dialogue, for both colors and either commander side, and during speaker swaps.

Listener pose follow-up: the ceremony now uses `idle.neutral` (UAL1 `Idle`)
at the gates, on arrival, and while listening. The rail-call pose leans forward
and gestures with both hands, so it is unsuitable for a standing listener.
Only the current speaker uses `Idle_Talking`; the parley regression asserts
the listener's actual `Idle` playback after each speaker swap.

Camera follow-up: Grandmaster lines cut to her dais before their text appears
(opening, objective, and victory). Her opening line holds for four seconds.
The kings share a west-to-east group shot with the Grandmaster visible behind
them; this composition stays on the same side for either player color because
the dais is fixed. Her speech anchor clears her taller seated silhouette.
`capture_grandmaster_ceremony.gd` now captures each intro dialogue cue by title
instead of using stale fixed delays. The cinematic test checks Grandmaster
frustum visibility throughout each of her lines for both player colors.

Verification: ceremony pose/projection test, king parley regression, campaign
intro/outro Skip integration, cinematic director's 20-cycle check, and animation
browser test passed. Rendered the actual Mountain Fortress intro and inspected
front, side, and three-quarter seating views with Godot's OpenGL renderer.
GameScreen-based runs can still emit their existing shutdown resource-leak
diagnostic; the isolated king regression and seating render exit cleanly.

Reproduce the close seating views without changing campaign saves:

```sh
XDG_DATA_HOME=/tmp/cac-seat-review godot --path . --script tools/capture_seating_fit.gd -- /tmp/cac-seat-fit
```

For the live entrance, start a fresh Mountain Fortress campaign match with
cinematics enabled: both kings finish walking at their center markers before
the Gatekeeper speaks, and the Grandmaster remains seated on the side dais.
The full rendered capture is also available through
`tools/capture_grandmaster_ceremony.gd` with isolated XDG data/config paths.
No assets were acquired or modified; licenses are unchanged.

## Headless environment

Headless Godot in the development sandbox can report TCP-listener and user-log-file warnings during export. These are environment limitations; the package completes and the executable passes the smoke launch described above.
