# P5 skeletal animation content brief

Status: **blocked on content** (2026-09-12).

The current safe fallback remains in production: semantic bow and hammer
requests use compatible Quaternius body motion plus a project-authored prop
timeline. This is visibly useful presentation but does not satisfy the P5 gate
for true skeletal body mechanics.

## Verified gap

The repository owns only Quaternius UAL1/UAL2 skeletal animation content. The
reproducible `tools/audit_animation_content.gd` sampler records every plausible
installed source clip at 30 Hz against the current 65-joint skeleton. Its local
report is `artifacts/presentation_overhaul/p5/content-audit.json`.

- `Spell_Simple_Shoot` barely changes hand separation and contains no set,
  string pull to the face, release, or bow recovery. `Pistol_Shoot` holds the
  hands together for a firearm pose.
- `Melee_Hook`, `TreeChopping`, `Farm_Harvest`, and `OverhandThrow` do not keep
  both hands on a shared hammer shaft through windup and contact. The available
  motions are one-handed, looping, low harvesting, or visibly lift a foot.
- Blender, assimp, gltf-transform, and a project skeletal-authoring helper are
  absent from the current machine. Godot can inspect and remap animation but is
  not a credible bounded authoring route for these two whole-body clips here.
- The previously rejected KayKit candidate has six bones. The tested CMU bow
  and chopping conversions distorted arm axes or lost two-hand contact; the CMU
  hammer clip is a one-handed nail action. No rejected or derived file is kept.

## Required deliverables

Deliver two non-looping, in-place GLB animation clips on the exact Quaternius
65-joint hierarchy and joint order used by `Armature/Skeleton3D`. Keep actor and
Armature roots constant, use the current forward/up convention, omit embedded
weapons and root travel, and supply 30 fps keys or an equivalent clean sample.

### Bow draw/aim/release/recovery

- Target duration: 0.9–1.1 seconds.
- Keep the forward hand locked to the bow grip.
- Reach the other hand to nock/string, draw it to the face with visible
  shoulder/elbow/spine participation, hold a brief aim, release, follow through,
  and return to a blend-ready battle stance.
- Keep both feet planted with controlled pelvis/torso rotation.
- Supply an exact `release_time_s` marker; target frame 18–21 at 30 fps.

### Two-handed hammer windup/strike/recovery

- Target duration: 0.9–1.1 seconds.
- Keep both hands on one shaft with stable grip spacing throughout lift,
  windup, descent, contact, and early recovery.
- Use shoulders/elbows, torso/hips, knee compression, and weight transfer to
  sell the force while the feet remain planted.
- Return to a blend-ready battle stance.
- Supply an exact `impact_time_s` marker; target frame 18–22 at 30 fps.

## Source and intake contract

The license must permit commercial redistribution. Record creator, source page,
version, exact file, SHA-256, license text, modifications, and attribution. Do
not resubmit KayKit or the tested CMU motions without new evidence that fixes
the documented rig and contact failures.

Before replacing the fallback, verify both teams/outfits in Animation Browser
at 0.25×/1×/2×; inspect hands against bow/string/shaft for the full clip; run 20
full capture/reset cycles per action; prove exact actor settlement and zero root
drift; and capture matched 720p/1080p event-driven evidence. Retain semantic IDs
`attack.bow.draw_release_01` and `attack.hammer.overhead_01`; keep release and
impact markers data-owned. Remove the prop overrides only after both skeletal
clips pass.
