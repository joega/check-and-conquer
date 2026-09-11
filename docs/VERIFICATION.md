# Verification Record

This document records the repeatable checks used for the current Warboard prototype. It distinguishes automated evidence from visual and product review that still requires a person running the game.

## Automated gates

Run all deterministic checks from the repository root:

```sh
bash tools/run_headless_tests.sh
```

The suite covers:

- bootstrap configuration and required debug scenes;
- chess-state FEN/UCI behavior, legal move generation, and start-position perft through depth 4 (`20`, `400`, `8,902`, `197,281`);
- turn phases, session settings, and Stockfish UCI formatting;
- a real Stockfish subprocess handshake and 100 sequential independently validated legal moves;
- board mapping, board-edge coordinate labels, FEN-to-actor reconstruction, input projection, quiet/capture/special-move settlement, and all 36 choreography resolver pairings;
- camera orbit/zoom and capture-shot restoration;
- capture audio generation, full victim-death completion, the animation browser, and 20 deterministic Combat Lab play/reset cycles;
- a playable GameScreen turn against Stockfish and autonomous Stockfish-versus-Stockfish spectator turns.

The FEN Position Loader test is part of this command. It verifies valid FEN reconstruction in the scene's actual `BoardPresenter` and confirms invalid input preserves the last valid visual board.

The public repository's [GitHub Actions workflow](../.github/workflows/test.yml)
runs this same command on pushes to `main` and pull requests. It downloads the
pinned Godot editor and compiles the committed Stockfish source into the ignored
test-binary path before the suite starts.

## Linux package check

With Godot 4.7.2 export templates installed:

```sh
bash tools/export_linux.sh
timeout 2s build/linux-x86_64/warboard.x86_64 --headless
```

The expected smoke-test exit is `124`: the game remains running for the two-second window. The exporter stages the executable Stockfish binary beside the game and copies its corresponding source and notices.

## Manual visual review

Before tagging a public release, run the game from the editor and review:

1. Each player-side default camera framing and close face-level zoom.
2. Ordinary walk movement and all six role-specific props at gameplay distance.
3. A capture with the action camera centered on the attacking pair, followed by the restored turn-aware board view.
4. Settings-menu readability at the target window size.
5. The final title, logo, and marketing art for originality and trademark suitability.

## Known environment note

Headless Godot in the development sandbox can report TCP-listener and user-log-file warnings during export. These are environment limitations; the package completes and the executable passes the smoke launch described above.
