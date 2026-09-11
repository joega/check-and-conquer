# Third-Party Software

Populate exact versions/hashes as dependencies are added.

## Stockfish

- Purpose: computer chess opponent/evaluator.
- Integration: separate UCI subprocess over stdin/stdout.
- License: GPLv3.
- Official site: https://stockfishchess.org/
- Developer integration docs: https://official-stockfish.github.io/docs/stockfish-wiki/Developers.html
- Version at plan date (2026-09-10): Stockfish 19 was released 2026-09-05.
- Packaged version: **19** (UCI handshake verified on 2026-09-10).
- Linux x86-64 executable: `third_party/stockfish/linux-x86_64/stockfish/stockfish-linux-x86-64-universal`.
- Windows x86-64 executable: `third_party/stockfish/windows-x86_64/stockfish/stockfish-windows-x86-64-universal.exe`.
- Exact SHA-256: `0f83d24cc46d2c66c60f16001af5444873bc112b7d028594513426894c12da19`.
- Source/license distribution: the tracked source tree and `Copying.txt` are retained under `third_party/stockfish/linux-x86_64/stockfish/`. Both platform exporters copy the GPLv3 notice and corresponding source into their release directory. The CI packaging workflow builds the Linux binary from that source and downloads the matching Windows Stockfish 19 universal binary directly from the official Stockfish GitHub release.

## Godot Engine

- Purpose: game engine/editor/runtime.
- Version: **4.7.2.stable.arch_linux.ed1daf0bf** (pinned 2026-09-10).
- Official release: https://godotengine.org/download/archive/4.7.2-stable/
- License/source notices: Godot is MIT-licensed; `third_party/LICENSES/GODOT-MIT.txt` is copied into Linux release packaging.
