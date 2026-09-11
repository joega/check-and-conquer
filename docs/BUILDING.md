# Running and validating the demo

Use Godot 4.7.2 and keep the supplied Stockfish 19 directory at `third_party/stockfish/linux-x86_64/stockfish/`.

Launch the demo from the repository root:

```sh
godot --path .
```

The game opens on **The Warpath**. The campaign route starts at Mountain Fortress Terrace; **Practice Arena** starts a Quick Match versus Stockfish without advancing campaign progress, and the temporary developer tools are grouped on the lower left. The default game is White versus Stockfish. The full-width in-game **Menu** contains restart, undo, campaign return, side, campaign difficulty, promotion, capture pace, audio, fullscreen, camera, and engine diagnostic controls. Choose **Beginner** for the gentlest Stockfish setting; each conquered arena increases the opponent slightly. These options persist in `user://check_and_conquer_settings.cfg` (with automatic import of legacy settings). Right-drag rotates the board, middle-drag pans the focus across it, and the mouse wheel zooms. After each move, the camera returns to the player-side board view; captures keep the player's current board view rather than zooming into a separate camera shot.

Run every deterministic headless gate, including the real Stockfish process test, with:

```sh
bash tools/run_headless_tests.sh
```

Each distributable build needs its matching platform Stockfish executable and
the GPLv3 source/license material recorded in [THIRD_PARTY_SOFTWARE.md](THIRD_PARTY_SOFTWARE.md).

## Linux release build

Install Godot's Linux export templates for the same 4.7.2 version, then run:

```sh
bash tools/export_linux.sh
```

The script creates `build/linux-x86_64/check-and-conquer.x86_64`, places the unmodified Stockfish executable plus its GPLv3 notice in the adjacent `stockfish/` directory, copies Stockfish's corresponding source into `stockfish-source/`, and includes Godot's MIT notice in `licenses/`. Development tests, source archives, third-party source, and unused hair assets are excluded from the game PCK; the base-character face resources remain because they are layered over the outfit meshes. Run the exported executable from that directory so the engine remains discoverable. The runtime uses this external copy because executables stored inside a Godot PCK cannot be launched as UCI subprocesses.

## Windows release build

Download and unpack the official Windows x86-64 universal Stockfish archive at
`third_party/stockfish/windows-x86_64/stockfish/`, retaining its
`stockfish-windows-x86-64-universal.exe`. The tracked Stockfish 19 source tree
and `Copying.txt` under `third_party/stockfish/linux-x86_64/stockfish/` supply
the corresponding GPL material for both platform packages.
Install the matching Godot 4.7.2 Windows export templates, then run:

```sh
bash tools/export_windows.sh
```

The script creates `build/windows-x86_64/check-and-conquer.exe` and stages the
unmodified engine at `stockfish/stockfish-windows-x86-64-universal.exe`, its GPL
notice, corresponding source, and the Godot MIT notice. Run the game from that
directory so the external UCI process remains discoverable.

## Continuous GitHub builds

Every push to `main` runs the **Package desktop builds** workflow. It builds
the Linux Stockfish executable from the tracked Stockfish 19 source, downloads
the matching official Windows universal executable, and uploads ready-to-run
Linux and Windows zip files. The latest pair replaces the assets in the
repository's **Latest development build** prerelease; the same pair is retained
for 30 days with the individual Actions run.
