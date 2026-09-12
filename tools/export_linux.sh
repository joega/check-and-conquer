#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$project_root/build/linux-x86_64"
stockfish_source="$project_root/third_party/stockfish/linux-x86_64/stockfish/stockfish-linux-x86-64-universal"

if [[ ! -x "$stockfish_source" ]]; then
  echo "Stockfish executable is missing or not executable: $stockfish_source" >&2
  exit 1
fi

rm -rf "$output_dir"
mkdir -p "$output_dir/stockfish" "$output_dir/licenses"
godot --headless --path "$project_root" --export-release "Linux Desktop" "$output_dir/check-and-conquer.x86_64"
cp -p "$stockfish_source" "$output_dir/stockfish/stockfish-linux-x86-64-universal"
cp -p "$project_root/third_party/stockfish/linux-x86_64/stockfish/Copying.txt" "$output_dir/stockfish/COPYING.txt"
cp -p "$project_root/third_party/LICENSES/STOCKFISH-SOURCE.md" "$output_dir/stockfish/SOURCE.md"
cp -p "$project_root/third_party/LICENSES/GODOT-MIT.txt" "$output_dir/licenses/GODOT-MIT.txt"

echo "Linux build written to $output_dir (including Stockfish GPL notice and source pointer)"
