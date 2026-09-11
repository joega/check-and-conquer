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
- Exact SHA-256: `0f83d24cc46d2c66c60f16001af5444873bc112b7d028594513426894c12da19`.
- Source/license distribution: the downloaded source tree and `Copying.txt` are retained beside the executable. `tools/export_linux.sh` copies the GPLv3 notice and corresponding source into the Linux release directory.

## Godot Engine

- Purpose: game engine/editor/runtime.
- Version: **4.7.2.stable.arch_linux.ed1daf0bf** (pinned 2026-09-10).
- Official release: https://godotengine.org/download/archive/4.7.2-stable/
- License/source notices: Godot is MIT-licensed; `third_party/LICENSES/GODOT-MIT.txt` is copied into Linux release packaging.
