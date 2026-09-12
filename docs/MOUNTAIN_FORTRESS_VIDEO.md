# Mountain Fortress generated video — production status

Status: source image selected and conversion tool prepared. **No generated cinematic video exists yet.** This document does not indicate that playback has been integrated into campaign entry.

## Generate the shot

Use the existing project artwork as the image-to-video reference:
`assets/environment/generated/mountain_fortress_panorama_v1.png`.

Prompt:

> Slow cinematic push toward the mountain fortress. Clouds drift across the distant peaks. Brazier flames flicker in the foreground. Preserve the architecture and composition. Restrained dramatic fantasy atmosphere. No text, no cuts.

Target an eight-second continuous shot. Keep the complete reference composition, with both fortress sides and foreground braziers visible. Preserve the original image aspect ratio when supported; avoid cropping important architecture to fill the frame. Generate no captions, logos, UI, or transition. Add story text and sound in Godot.

Review the generated clip before accepting it: towers and railings must remain stable, flames must move locally, clouds must visibly drift independently of the camera push, and no new objects/cuts may appear. A zoomed still is not the requested final video. Save the provider/model, generation date, exact prompt, reference path, and applicable output rights with the accepted asset provenance.

## Convert the accepted export

FFmpeg with libtheora is available on this development machine. Run:

```bash
bash tools/convert_cinematic.sh /absolute/path/to/approved-fortress.mp4 /tmp/mountain_fortress_intro.ogv
```

The tool preserves the full scene inside a 1280×720 frame using letterboxing,
encodes Theora at 30 fps, strips audio so the game can own music/horn playback,
and refuses to overwrite an existing output. It prints codec/duration metadata.
Inspect the complete converted clip and compare beginning/middle/end frames to
the export before adding it under `assets/cinematics/`.

Preparation verified on 2026-09-12: a one-second synthetic 2:1 test video
converted to 1280×720 Theora at 30 fps, decoded successfully with FFmpeg,
and played in Godot 4.7.2 via VideoStreamPlayer/VideoStreamTheora. Godot's
playback position advanced and its completion signal fired exactly once.
Overwrite refusal and shell syntax checks also passed. This validates the
conversion/playback format only; the synthetic test pattern is not fortress
footage and has not been added to game assets.

## Godot integration after the clip is available

Use VideoStreamPlayer with the accepted .ogv resource; keep title/story labels
in a separate UI overlay. For the lightweight first version:

- First cue: “For years, the First Gate has opened for no one.”
- Second cue: “Defeat the Gatekeeper. Reopen the Warpath.”
- Skip and normal completion converge on one cleanup/start-turn path.
- Keep the controller READY until playback completes; engine handshake may
  initialize but neither side may make a move during the intro.
- Match the video's fit to the viewport; do not stretch the panorama.
- Verify real Godot decoding, readable titles, early/late Skip, and both player
  sides, including the first engine turn when the player is Black.

Follow `CAMPAIGN_CUTSCENES_PLAN.md` for lifecycle ownership and
`CAMPAIGN_STORY_BIBLE.md` for subsequent story content. This single establishing
shot is the immediate deliverable; it does not complete the full story plan.

## Current access limitation

This session exposes image generation but no video generator or Runway
connector. The Browser skill's connection and recovery checks returned no
available browsers. Plugin discovery tools are also not exposed. Generation
requires a connected video service/browser or the user's exported video.
The goal remains incomplete until the actual requested motion clip is produced,
converted, visually inspected, and its Godot playback/title integration verified.
