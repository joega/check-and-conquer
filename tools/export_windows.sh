#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$project_root/build/windows-x86_64"
stockfish_root="$project_root/third_party/stockfish/windows-x86_64/stockfish"
stockfish_source="$stockfish_root/stockfish-windows-x86-64-avx2.exe"

if [[ ! -f "$stockfish_source" ]]; then
  echo "Windows Stockfish executable is missing: $stockfish_source" >&2
  echo "Download the official Windows x86-64 AVX2 Stockfish archive and unpack it there." >&2
  exit 1
fi
if [[ ! -f "$stockfish_root/Copying.txt" ]]; then
  echo "Stockfish GPL notice is missing: $stockfish_root/Copying.txt" >&2
  exit 1
fi

mkdir -p "$output_dir/stockfish" "$output_dir/licenses"
rm -rf "$output_dir/stockfish-source"
godot --headless --path "$project_root" --export-release "Windows Desktop" "$output_dir/warchessed.exe"
cp -p "$stockfish_source" "$output_dir/stockfish/stockfish-windows-x86-64-avx2.exe"
cp -p "$stockfish_root/Copying.txt" "$output_dir/stockfish/COPYING.txt"
cp -a "$stockfish_root" "$output_dir/stockfish-source"
cp -p "$project_root/third_party/LICENSES/GODOT-MIT.txt" "$output_dir/licenses/GODOT-MIT.txt"

echo "Windows build written to $output_dir (including Stockfish corresponding source and notices)"
