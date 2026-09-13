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
  -> namespaced AnimationPlayer mixer
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

### Runtime locomotion contract

UAL1 and UAL2 are duplicated into `ual1` and `ual2` namespaces on one
AnimationPlayer. Semantic callers never select a source player or filename.
Godot's native blend time connects compatible clips across both libraries;
the actor owns pause, speed, movement, turn, ambient, role-action, and recovery
cancellation as one lifecycle.

The current in-place `Walk` calibration is 2.2 displayed world metres per
cycle. Root travel uses a short quadratic acceleration, linear middle, and
quadratic deceleration. Animation cadence is derived from travelled distance
and actual root duration, so playback-speed changes are applied once and long
moves add cycles. Quiet board travel targets 9 m/s plus a 0.18 s plant allowance,
with root duration bounded to 0.50–4.0 s. Facing into travel uses animated
shortest-yaw turns; rebuild/reset methods keep their immediate orientation path.

The imported neutral idle is duplicated with ping-pong looping because its
ordinary end-to-start seam visibly resets. Stance phase remains deterministic
from actor identity and position. Do not change the source import globally:
the runtime copy keeps previews and other source users isolated.

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

Project-authored overlay semantics are kept separate from imported clips:

| Semantic ID | Ownership / base motion |
| --- | --- |
| `attack.bow.draw_release_01` | Project prop timeline over `Spell_Simple_Shoot` |
| `attack.hammer.overhead_01` | Project prop timeline over UAL2 `Melee_Hook` |
| `recovery.capture_ready_01` | Project local recovery over `Idle_Rail` |

These are not claims that the third-party packs contain skeletal bow or hammer
clips. A future source clip must go through the complete intake checklist.

### Rejected animation intake

**KayKit Character Animations 1.2** was evaluated on 2026-09-11 as a possible
CC0 source for `Shoot(2h)Bow` and `HeavyAttack`. The evaluation archive was
`kaykit_character_animations_1.2.zip` (SHA-256
`c9d3fbea492dc6edd0903939369a564c2240b892430bcd99e0aee4876110bb8f`), obtained
from the creator's current [KayKit Character Animations page](https://kaylousberg.itch.io/kaykit-character-animations)
via its OpenGameArt mirror. It is not a production dependency and no copy is
retained in the repository.

The pack clears the CC0 license gate but fails the compatibility gate: its
animated character has only `Body`, `Head`, `armLeft`, `handSlotLeft`,
`armRight`, and `handSlotRight` bones, while the project's compatible
Quaternius actors use a 65-joint humanoid skeleton with forearm, hand, and
lower-body articulation. Retargeting it would make the exact bow/hammer hand
contact this intake is meant to improve visibly less credible. Keep the
project-owned bridge timelines until a redistributable source provides a
meaningfully compatible humanoid rig and passes Animation Browser plus the
20-cycle Combat Lab gate.

**CMU Graphics Lab Motion Capture Database** was also evaluated on 2026-09-11.
Its documented commercial-use terms permit inclusion in a commercially sold
product but prohibit direct resale of the data, with a requested CMU/NSF
acknowledgement. Trial `79_86` (shooting bow and arrow; SHA-256
`fabe071c2c3fb0a636035cca5d82ff282f851d711cf1b3736e2b12d355283056`) and
trial `62_10` (hammering sequence; SHA-256
`2cdd4da130e60bee55521616688c5b614e60e4c4adcb92ffb3b2321f6faeb49a`) supply
spine, forearm, and hand joints, but `62_10` is a one-handed nail action—not a
two-handed weapon strike. Trial `79_01` (chopping wood; SHA-256
`397e7883dccc8037eec1183b93b91cc0527ab28060b840c0d4996632b237721f`) was
tested as a two-handed heavy-swing proxy. Conversion to the matching 65-joint
Quaternius skeleton succeeded structurally, but visual playback produced
distorted arm axes and lost two-hand contact. No CMU trial, conversion, or
derived asset is retained. A future CMU candidate requires a deliberate
per-rig retarget authoring pass and the full visual gate; do not treat generic
bone-name correspondence as sufficient.

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

## Procedural hard-surface reference

Small altar, rail, tile, terrace, and accessory hard-surface pieces may use
`BeveledBoxMesh.create(size, bevel)`. It preserves the requested outer AABB and
adds flat-shaded inset faces, edge strips, and corner facets. Board tile centers
stay on `BoardMapper`; a 0.12 m tile remains centered at y=-0.06 so its top is
exactly y=0. Materials that receive gameplay highlights must be duplicated per
tile even when their base palette is shared.

Mountain Fortress is the material/lighting reference: warm limestone, dark
slate, aged bronze, neutral color-sourced ambient light, and a neutral two-split
key shadow. Panorama light does not tint the playable stage. Existing CC0
Banner_1 and Torch_Metal props replace local placeholder towers. Compatibility
AA was measured after warm-up on identical fixtures; 2× MSAA is the selected
balance, with the exact 720p/1080p samples retained in the P3 manifests.

## Role silhouette accessories

Small role cues remain presentation-only children of the current compatible
65-joint outfit rig. Project-authored crests, mantles, pauldrons, diadems, and
crowns use `BoneAttachment3D` on Head or spine_03; the bishop
hood duplicates the separately skinned `Female_Ranger_Head_Hood` mesh and
rebinds it with `skeleton = NodePath("..")`. The native ranger hood stays
hidden on knight, queen, rook, and king so shared outfits do not produce shared
head silhouettes. Hair selection is part of face clearance: queens use the
compatible buns mesh because the long front lock covered both eyes beneath the
diadem.

Accessory dimensions must be checked label-hidden at gameplay scale and through
idle, walk, attack, recovery, and death. They may not change actor root scale,
ModelRoot scale, combat anchors, or weapon grips. Team color stays on small
hood/pauldron details and cloth accessories; broad belt meshes retain near-source
color so they do not read as floating torso bands. Authored bronze stays
side-neutral. The piece glyph remains a fallback base cue and must be hidden
during silhouette acceptance evidence.

## Shared combat timeline and measured contact

`CaptureChoreography` owns plant time, clip-relative impact time, recovery time,
contact height, and accepted contact radius. `BattleDirector` latches the
selected presentation speed at capture start and applies that scale to turns,
root travel, body clips, project-authored prop motion, projectile arrival,
sound, death, settlement, and recovery. A settings change during a capture is
therefore applied to the next capture.

Contact evidence must measure the nearest point on the equipped weapon mesh to
the choreography's victim contact point. The current pawn reference uses 1.30 m
anchor separation, a 0.40 s dagger marker, 2.30 m contact height, and a 0.60 m
radius; the final measured distance is 0.431 m. At the marker, generic melee
holds the exact clip pose for one process frame before measuring so Skeleton3D
bone attachments commit consistently at normal, slow, and accelerated rates.
Effects may reinforce that beat but must leave the weapon and victim silhouette
visible. Cancellation stops actor motion, temporary effects, and combat audio
before authoritative snapping.
