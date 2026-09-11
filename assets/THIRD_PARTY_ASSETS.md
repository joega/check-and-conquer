# Third-Party Assets

Record every imported model, animation, texture, audio file, and VFX pack here before it becomes a production dependency.

## Entry template

### <Asset/Pack Name>

- Creator:
- Source URL:
- License:
- Date acquired:
- Original archive/file:
- Files used in project:
- Modifications:
- Attribution required: yes/no
- Redistribution notes:
- Verification notes:

### Universal Base Characters [Standard]

- Creator: Quaternius
- Source URL: https://quaternius.com/packs/universalbasecharacters.html
- License: CC0 1.0 Universal (license text retained at `assets/characters/quaternius/LICENSE.txt`)
- Date acquired: 2026-09-10
- Original archive/file: `Universal Base Characters[Standard].zip` (SHA-256 `fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40`)
- Files used in project: `assets/characters/quaternius/Superhero_Male_FullBody.gltf` and `Superhero_Female_FullBody.gltf`, their `.bin` files, and referenced textures. Compatible beard/bun/long/parted hairstyle glTF files are attached as role-specific variants.
- Modifications: Extracted the Godot-ready male and female base characters and required texture files. Duplicated the supplied eye normal map under the filename variant referenced by the supplied glTF. At runtime, `PieceActor` transfers only the textured, skinned head triangles plus eyes, brows, and compatible hairstyle mesh(es) onto the matching outfit skeleton; the base torso/limbs are not layered under clothing.
- Attribution required: no
- Redistribution notes: CC0 public-domain dedication; source archive is retained locally in ignored `assets/source-archives/` and is not committed.
- Verification notes: Imported successfully with Godot 4.7.2 after the referenced texture aliases were included. The scene exposes `Armature/Skeleton3D`; its 65-joint order matches every selected outfit skeleton.

### Universal Animation Library [Standard]

- Creator: Quaternius
- Source URL: https://quaternius.com/packs/universalanimationlibrary.html
- License: CC0 1.0 Universal (license text retained at `assets/animations/quaternius/LICENSE.txt`)
- Date acquired: 2026-09-10
- Original archive/file: `Universal Animation Library[Standard].zip` (SHA-256 `cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724`)
- Files used in project: `assets/animations/quaternius/UAL1_Standard.glb` (the root-motion-disabled export).
- Modifications: Extracted the Godot/Unreal `.glb` only. Mapped source clips to semantic IDs in `PieceActor`; no animation data was edited.
- Attribution required: no
- Redistribution notes: CC0 public-domain dedication; source archive is retained locally in ignored `assets/source-archives/` and is not committed.
- Verification notes: Imported successfully with Godot 4.7.2. Its `AnimationPlayer` drives the same `Armature/Skeleton3D` hierarchy as the selected character; validated source clips are `Idle`, `Walk`, `Sword_Attack`, `Hit_Chest`, and `Death01`.

### Universal Animation Library 2 [Standard]

- Creator: Quaternius
- Source URL: https://quaternius.com/packs/universalanimationlibrary2.html
- License: CC0 1.0 Universal (license text retained at `assets/animations/quaternius/UAL2_LICENSE.txt`)
- Date acquired: 2026-09-10
- Original archive/file: `Universal Animation Library 2[Standard].zip` (SHA-256 `4008ea208a604773a2b2177d965f0f5d3195498b5bf838c3f5785d68e95f2a68`)
- Files used in project: `assets/animations/quaternius/UAL2_Standard.glb`.
- Modifications: Extracted the Godot-ready non-root-motion GLB and retained its README/license. The second `AnimationPlayer` is attached to the same compatible outfit skeleton at runtime.
- Attribution required: no
- Redistribution notes: CC0 public-domain dedication; source archive is retained locally in ignored `assets/source-archives/` and is not committed.
- Verification notes: Imported with Godot 4.7.2. `Hit_Knockback`, `Melee_Hook`, and sword attack variants are exposed and used through normalized semantic IDs.

### Modular Character Outfits - Fantasy [Standard]

- Creator: Quaternius
- Source URL: https://quaternius.com/packs/modularcharacteroutfitsfantasy.html
- License: CC0 1.0 Universal (license text retained at `assets/characters/quaternius/outfits/LICENSE.txt`)
- Date acquired: 2026-09-10
- Original archive/file: `Modular Character Outfits - Fantasy[Standard].zip` (SHA-256 `c3468b18871cc8c8f05ab14df7712baf22cb9f389cbd870babf130e595187f70`)
- Files used in project: full Godot/Unreal glTF outfits `Male_Peasant`, `Female_Peasant`, `Male_Ranger`, and `Female_Ranger`, with their buffers and referenced textures under `assets/characters/quaternius/outfits/`.
- Modifications: Extracted the complete outfit scenes rather than overlaying clothing on the base bodies, as required by the source Readme to avoid clipping. The existing compatible animation library remains attached at runtime. The matching base face, eyes, and brows are transferred onto the shared skeleton, while its torso and limbs remain absent to avoid clothing overlap.
- Attribution required: no
- Redistribution notes: CC0 public-domain dedication; source archive is retained locally in ignored `assets/source-archives/` and is not committed.
- Verification notes: all four outfit skeletons have the matching 65-joint humanoid order and `Armature/Skeleton3D` / `hand_r` names used by `PieceActor`. The pack contains no shield or weapon assets; the old project-created rook shield was removed to preserve visibility.
## Runtime-generated capture audio and VFX

`scripts/presentation/procedural_impact_audio.gd` synthesizes the V1 capture-impact tone at runtime from sine waves. It uses no third-party audio asset or sample.

`GameScreen.tscn` uses a short one-shot `GPUParticles3D` burst of small emissive
procedural meshes at the committed capture contact point. It uses no texture,
model, VFX pack, or other third-party visual asset.


### LowPoly Medieval Weapons

- Creator: Quaternius
- Source URL: https://quaternius.itch.io/lowpoly-medieval-weapons (archive mirrored by OpenGameArt)
- License: CC0 1.0 Universal
- Date acquired: 2026-09-10
- Original archive/file: `Medieval Weapons Pack - Sept 2018.zip` (SHA-256 `b8a18124c460387a02b9ed3e940229eaa091b540699fad75627d0c0291d33912`)
- Files used in project: imported FBX meshes for Dagger, Dagger_2, Spear, Bow_Golden, Arrow, Hammer_Double, Scythe, Spear, Sword, Sword_2, Sword_Golden, and Claymore under `assets/weapons/quaternius/`.
- Modifications: Selected compatible meshes only; runtime attaches them to named humanoid hand bones with normalized display scale. The arrow is instantiated only during Bishop ranged captures.
- Attribution required: no
- Redistribution notes: CC0 public-domain dedication; the source archive is retained locally in ignored `assets/source-archives/`.
- Verification notes: Godot 4.7.2 imported each selected FBX. Board reconstruction, capture death completion, and Combat Lab's 20-cycle reset passed with weapon-bearing actors.

### Fantasy Sound Effects (Tinysized SFX)

- Creator: Tinysized
- Source URL: https://lpc.opengameart.org/content/fantasy-sound-effects-tinysized-sfx
- License: CC0 1.0 Universal
- Date acquired: 2026-09-11
- Original archive/file: `tinysized.zip` (SHA-256 `7f00e2b1dae15e68db0e1d6096767f03755e9e7c247128afc3e935e63774d7db`; archive remains outside the repository)
- Files used in project: `assets/audio/cc0_fantasy/arrow-feathers-01.wav`, `arrow-grab-from-quiver-01.wav`, `metal-hammer-hit-01.wav`, `paralyzer-discharge-02.wav`, `sword-clash-01.wav`, `sword-clash-03.wav`, and `wood-twigs-break-01.wav`.
- Modifications: Extracted the selected WAV effects without editing. `ArenaAudioDirector` assigns them to landings, blade clashes, arrows, arcane discharges, and heavy impacts.
- Attribution required: no
- Redistribution notes: CC0 public-domain dedication; only the selected runtime effects are committed.
- Verification notes: Imported by Godot 4.7.2 and selected through `ArenaAudioDirector`; these replace the ordinary runtime-synthesized combat beeps.

### War Horn opening cue

- Creator: user-provided; original creator not yet supplied
- Source URL: not supplied
- License: pending source/license confirmation
- Date acquired: 2026-09-11
- Original archive/file: `war-horn.mp3` (SHA-256 `2925944228f76084c121905bf709357913185a77017733088af63a7ca6c3f108`)
- Files used in project: `assets/audio/war-horn.mp3`
- Modifications: Relocated into the project audio directory; no audio edit.
- Attribution required: unknown pending source/license confirmation
- Redistribution notes: Do not distribute independently until provenance is confirmed.
- Verification notes: Assigned to the campaign map `OpeningHorn` player and played once per app session when the opening map appears.

### Fireball

- Creator: Julien Matthey (uploaded by diligentcircle)
- Source URL: https://opengameart.org/content/fireball-1
- License: CC0 1.0 Universal
- Date acquired: 2026-09-11
- Original archive/file: `105016__julien-matthey__jm-fx-fireball-01.wav` (SHA-256 `3992598c814de25c318780e506aeda673a7e410b7b3c4f0793883483ff9766b8`)
- Files used in project: `assets/audio/cc0_fantasy/fireball-01.wav`
- Modifications: none
- Attribution required: no
- Redistribution notes: CC0 public-domain dedication.
- Verification notes: Assigned to the Queen arcane cast and impact cues, replacing the lightning-like prototype discharge.
