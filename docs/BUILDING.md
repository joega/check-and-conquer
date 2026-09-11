# Running and validating the demo

Use Godot 4.7.2 and keep the supplied Stockfish 19 directory at `third_party/stockfish/linux-x86_64/stockfish/`.

Launch the demo from the repository root:

```sh
godot --path .
```

Choose **Play vs Stockfish**. The default game is White versus Stockfish. The compact in-game toolbar keeps move, restart, undo, and Settings visible; Settings opens the computer/local, side, difficulty, promotion, capture-speed, audio, camera, fullscreen, and diagnostic controls. These options persist in `user://warboard_settings.cfg`. Right-drag rotates the board; the mouse wheel zooms. After each move, the camera settles into a three-quarter view from the side deciding next; manual close zoom raises its focus to face level. Captures use a temporary fixed action shot before the normal board view returns.

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

The script creates `build/linux-x86_64/warboard.x86_64`, places the unmodified Stockfish executable plus its GPLv3 notice in the adjacent `stockfish/` directory, copies Stockfish's corresponding source into `stockfish-source/`, and includes Godot's MIT notice in `licenses/`. Development tests, source archives, third-party source, and unused hair assets are excluded from the game PCK; the base-character face resources remain because they are layered over the outfit meshes. Run the exported executable from that directory so the engine remains discoverable. The runtime uses this external copy because executables stored inside a Godot PCK cannot be launched as UCI subprocesses.
