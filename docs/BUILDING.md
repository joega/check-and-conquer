# Running and validating the demo

Use Godot 4.7.2 and keep the supplied Stockfish 19 directory at `third_party/stockfish/linux-x86_64/stockfish/`.

Launch the demo from the repository root:

```sh
godot --path .
```

The game opens on **The Warpath**. The campaign route starts at Mountain Fortress Terrace; **Practice Arena** starts a Quick Match versus Stockfish without advancing campaign progress, and the temporary developer tools are grouped on the lower left. The default game is White versus Stockfish. The full-width in-game **Menu** contains restart, undo, campaign return, side, campaign difficulty, promotion, capture pace, audio, fullscreen, camera, and engine diagnostic controls. Choose **Beginner** for the gentlest Stockfish setting; each conquered arena increases the opponent slightly. These options persist in `user://warchessed_settings.cfg` (with automatic import of legacy Warboard settings). Right-drag rotates the board, middle-drag pans the focus across it, and the mouse wheel zooms. After each move, the camera returns to the player-side board view; captures keep the player's current board view rather than zooming into a separate camera shot.

Run every deterministic headless gate, including the real Stockfish process test, with:

```sh
bash tools/run_headless_tests.sh
```

The current binary path is Linux-specific. A distributable build needs platform-specific Stockfish binaries and the GPLv3 source/license material recorded in [THIRD_PARTY_SOFTWARE.md](THIRD_PARTY_SOFTWARE.md).

## Linux release build

Install Godot's Linux export templates for the same 4.7.2 version, then run:

```sh
bash tools/export_linux.sh
```

The script creates `build/linux-x86_64/warchessed.x86_64`, places the unmodified Stockfish executable plus its GPLv3 notice in the adjacent `stockfish/` directory, copies Stockfish's corresponding source into `stockfish-source/`, and includes Godot's MIT notice in `licenses/`. Development tests, source archives, third-party source, and unused hair assets are excluded from the game PCK; the base-character face resources remain because they are layered over the outfit meshes. Run the exported executable from that directory so the engine remains discoverable. The runtime uses this external copy because executables stored inside a Godot PCK cannot be launched as UCI subprocesses.
