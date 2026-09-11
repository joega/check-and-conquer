# Asset and Animation Pipeline

This document exists because the 3D asset pipeline is the highest-risk area of Check & Conquer.

## Objective

A new humanoid character should be usable by the game without writing character-specific gameplay code.

The desired pipeline is:

```text
source model/animation
  -> provenance/license record
  -> Godot import
  -> canonical scale/orientation
  -> humanoid bone map / retarget
  -> normalized semantic clip names
  -> AnimationTree
  -> PieceActor contract
  -> Combat Lab validation
  -> production archetype
```

## Preferred prototype assets

Start with Quaternius compatible packs:

- Universal Base Characters
- Modular Character Outfits - Fantasy
- Universal Animation Library 1
- Universal Animation Library 2

The pack pages identify these as CC0 and designed around a compatible humanoid rig. Re-check the current page/license before importing anything.

## Intake checklist

For each source pack or file:

- [ ] source URL recorded
- [ ] creator recorded
- [ ] license recorded
- [ ] acquisition date recorded
- [ ] original filename/archive recorded
- [ ] attribution requirement understood
- [ ] redistribution terms understood
- [ ] model scale checked
- [ ] forward axis checked
- [ ] ground/feet alignment checked
- [ ] skeleton mapped
- [ ] unexpected root motion checked
- [ ] materials/textures render correctly
- [ ] animation names normalized
- [ ] animation loop flags set correctly
- [ ] weapon socket(s) validated
- [ ] tested in Animation Browser
- [ ] tested in Combat Lab

## Canonical coordinate policy

Choose and document one convention in `docs/DECISIONS.md` after first successful import. Recommended:

- Godot Y-up world.
- Actor local forward uses Godot-appropriate consistent forward axis.
- Feet rest at local Y=0.
- Actor origin near ground under pelvis/feet.
- Board square centers map to exact Node3D world positions.
- Combat anchor separation starts around 1.5 m and is tuned visually.

Do not compensate for broken import orientation in every choreography. Normalize the actor once.

## Root motion policy

V1 default: disable/strip root translation from locomotion and attacks when practical.

Godot moves `PieceActor` root. Skeleton animation supplies body motion. This keeps final board transforms exact.

If an otherwise excellent signature animation requires root motion, isolate that exception inside the signature choreography and restore exact final transforms at the end.

## Clip semantics

Gameplay should request semantic animation IDs, not filenames.

Examples:

```text
idle.neutral
idle.combat
locomotion.walk.forward
attack.sword.slash_01
attack.sword.overhead_01
attack.magic.cast_01
attack.heavy.smash_01
reaction.hit.generic_01
reaction.stagger_01
death.backward_01
death.forward_01
victory.short_01
```

Maintain a mapping from semantic IDs to imported animation library names if direct renaming is inconvenient.

### Initial M1 mapping

The first imported Quaternius set is mapped in `scripts/actors/piece_actor.gd`:

| Semantic ID | Imported clip |
| --- | --- |
| `idle.neutral` | `Idle` |
| `locomotion.walk.forward` | `Walk` |
| `attack.sword.slash_01` | `Sword_Attack` |
| `reaction.hit.generic_01` | `Hit_Chest` |
| `death.backward_01` | `Death01` |

The compatibility proof is structural: both imported scenes use `Armature/Skeleton3D`. At runtime, `PieceActor` places the imported animation player under the base-character root, where its existing tracks address that shared hierarchy. Root translation remains code-controlled.

## Looping

Likely loops:
- idle
- combat idle
- walk

Non-loops:
- attacks
- hit reactions
- deaths
- victory beats

Tests/debug scene should expose accidental loop flags immediately.

## Animation retargeting

Use Godot's humanoid skeleton retargeting workflow (`SkeletonProfileHumanoid`) for rigs that are compatible.

Reference:
https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html

Do not manually repair dozens of bones before testing whether an alternate source model imports cleanly. Asset replacement is often cheaper than pipeline exceptions.

## Weapon attachments

Weapons should be separate scenes/meshes attached through canonical sockets/bones.

Define logical slots:

```text
right_hand_weapon
left_hand_weapon
shield
staff
```

A character definition maps these slots to actual bone/socket paths.

Avoid baking every weapon permanently into each character mesh unless the source asset requires it.

## Combat contact

Perfect physical contact is not required for generic V1 captures. Use:

- anchor spacing,
- facing,
- clip selection,
- impact timing,
- camera angle,
- VFX,
- sound,
- victim reaction

to create perceptual contact.

If an attack misses by 10–20 cm but reads correctly from the selected camera, it can be acceptable. If it visibly passes a meter away, fix anchors/clip/pose.

## Animation Browser

Create `DebugAnimationBrowser.tscn` with:

- character/archetype selector,
- semantic clip list,
- play/pause,
- playback speed,
- loop toggle display,
- skeleton/bone debug optional,
- root motion trail optional,
- reset pose.

This is the fastest way to audit a large animation pack.

## Combat Lab

Create `DebugCombatLab.tscn` with:

- attacker selector,
- victim selector,
- choreography selector,
- reset,
- play,
- 0.25× / 0.5× / 1× speed,
- impact marker visualization,
- anchor visualization,
- camera-shot selector,
- skip-to-impact optional.

A custom capture is not production-ready until it passes in Combat Lab.

## Art consistency

During prototype, prefer one asset creator/ecosystem. If new packs are introduced, assess:

- proportions,
- texture style,
- poly density,
- material roughness/metalness,
- facial detail,
- weapon scale,
- animation exaggeration.

Do not create an “asset-store collage.”

## When Blender becomes justified

Blender is an escalation tool, not the base workflow.

Open Blender when a specific validated need exists:

- remove persistent root motion,
- adjust contact pose,
- repair weighting on an otherwise ideal character,
- combine/export animation clips,
- create a canonical two-actor signature capture,
- create/adjust a weapon socket,
- simplify a mesh.

Document reproducible import/export settings if Blender becomes part of the pipeline.

## Signature-capture delivery contract

A custom animator/mocap process should deliver:

- attacker animation on canonical rig,
- victim animation on canonical rig,
- known start transforms,
- known impact time/marker,
- known completion time,
- compatible weapon convention,
- non-looping clip,
- export file + license/provenance.

Runtime choreography remains responsible for camera, VFX, audio, cleanup, and exact chess-square settlement.
