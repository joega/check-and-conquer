#!/usr/bin/env python3
"""Write a reproducible non-silence/format manifest for runtime combat cues."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CUES = {
    "approach_step": "assets/audio/cc0_fantasy/wood-twigs-break-01.ogg",
    "dual_sword_impact_a": "assets/audio/cc0_fantasy/sword-clash-03.ogg",
    "dual_sword_impact_b": "assets/audio/cc0_fantasy/sword-clash-01.ogg",
    "arrow_release_a": "assets/audio/cc0_fantasy/arrow-feathers-01.ogg",
    "arrow_release_b": "assets/audio/cc0_fantasy/arrow-grab-from-quiver-01.ogg",
    "heavy_impact": "assets/audio/cc0_fantasy/metal-hammer-hit-01.ogg",
    "arcane_cast_impact": "assets/audio/cc0_fantasy/fireball-01.ogg",
}


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, check=True, text=True, capture_output=True)


def inspect(label: str, relative: str) -> dict[str, object]:
    path = ROOT / relative
    probe = json.loads(
        run([
            "ffprobe", "-v", "error", "-show_entries",
            "format=duration:stream=sample_rate,channels", "-of", "json", str(path),
        ]).stdout
    )
    stream = probe["streams"][0]
    duration = float(probe["format"]["duration"])
    volume = run([
        "ffmpeg", "-hide_banner", "-nostats", "-i", str(path),
        "-af", "volumedetect", "-f", "null", "-",
    ]).stderr
    mean_match = re.search(r"mean_volume:\s+(-?[0-9.]+) dB", volume)
    max_match = re.search(r"max_volume:\s+(-?[0-9.]+) dB", volume)
    if mean_match is None or max_match is None:
        raise RuntimeError(f"Could not measure {relative}")
    mean_db = float(mean_match.group(1))
    max_db = float(max_match.group(1))
    if duration <= 0.05 or max_db < -12.0:
        raise RuntimeError(f"Cue is silent or truncated: {relative}")
    return {
        "cue": label,
        "file": relative,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "duration_s": duration,
        "sample_rate_hz": int(stream["sample_rate"]),
        "channels": int(stream["channels"]),
        "mean_volume_db": mean_db,
        "max_volume_db": max_db,
        "non_silent": True,
    }


def main() -> int:
    output = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp/cac-combat-audio-manifest.json")
    records = [inspect(label, relative) for label, relative in CUES.items()]
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps({
        "tool": "tools/audit_combat_audio.py",
        "method": "ffprobe stream metadata plus decoded ffmpeg volumedetect",
        "valid": True,
        "cues": records,
    }, indent=2) + "\n")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
