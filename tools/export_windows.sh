#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$project_root/build/windows-x86_64"
stockfish_root="$project_root/third_party/stockfish/windows-x86_64/stockfish"
stockfish_source="$stockfish_root/stockfish-windows-x86-64-universal.exe"
stockfish_corresponding_source="$project_root/third_party/stockfish/linux-x86_64/stockfish"

if [[ ! -f "$stockfish_source" ]]; then
  echo "Windows Stockfish executable is missing: $stockfish_source" >&2
  echo "Download the official Windows x86-64 universal Stockfish archive and unpack it there." >&2
  exit 1
fi
if [[ ! -f "$stockfish_corresponding_source/Copying.txt" ]]; then
	echo "Stockfish GPL notice/source is missing: $stockfish_corresponding_source" >&2
	exit 1
fi

rm -rf "$output_dir"
mkdir -p "$output_dir/stockfish" "$output_dir/licenses"
godot --headless --path "$project_root" --export-release "Windows Desktop" "$output_dir/check-and-conquer.exe"
cp -p "$stockfish_source" "$output_dir/stockfish/stockfish-windows-x86-64-universal.exe"
cp -p "$stockfish_corresponding_source/Copying.txt" "$output_dir/stockfish/COPYING.txt"
cp -p "$project_root/third_party/LICENSES/STOCKFISH-SOURCE.md" "$output_dir/stockfish/SOURCE.md"
cp -p "$project_root/third_party/LICENSES/GODOT-MIT.txt" "$output_dir/licenses/GODOT-MIT.txt"

echo "Windows build written to $output_dir (including Stockfish GPL notice and source pointer)"
