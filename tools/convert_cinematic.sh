#!/usr/bin/env bash
# Convert an approved generated clip to Godot's built-in video format.
# Preserve the full composition with letterboxing; audio is owned by Godot.
set -euo pipefail

if [[ $# != 2 ]]; then
  echo "Usage: bash tools/convert_cinematic.sh SOURCE_VIDEO OUTPUT.ogv" >&2
  exit 2
fi

source_video="$1"
output_video="$2"
if [[ ! -f "$source_video" ]]; then
  echo "Source video does not exist: $source_video" >&2
  exit 2
fi
if [[ "$output_video" != *.ogv || -e "$output_video" ]]; then
  echo "Output must be a new .ogv file; existing files are never overwritten." >&2
  exit 2
fi
for tool_name in ffmpeg ffprobe; do
  if ! command -v "$tool_name" >/dev/null; then
    echo "Required tool unavailable: $tool_name" >&2
    exit 2
  fi
done
if [[ -z "$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$source_video")" ]]; then
  echo "Source must contain a video stream." >&2
  exit 2
fi

# 720p limits CPU decoding cost; square pixels and padding avoid stretching
# the original 2:1 fortress panorama to the game's 16:9 viewport.
ffmpeg -hide_banner -nostdin -n -i "$source_video" \
  -map 0:v:0 -an -sn -dn \
  -vf 'scale=1280:720:force_original_aspect_ratio=decrease:force_divisible_by=2:reset_sar=1,pad=1280:720:(ow-iw)/2:(oh-ih)/2,fps=30' \
  -c:v libtheora -q:v 7 -pix_fmt yuv420p \
  -map_metadata -1 "$output_video"

ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,width,height,pix_fmt,r_frame_rate:format=duration \
  -of json "$output_video"
