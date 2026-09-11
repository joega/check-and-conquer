# Terra visual tranche 02 — 2026-09-11

## Baseline and confirmed defects

The prior rendered audit and current source inspection confirmed that bishop and
queen projectile trails were created once per rendered frame, while their
elemental contact core grew as an opaque sphere. Combat Lab also used its own
procedural impact sound, so it did not audition the event routing used in a
match. Finally, all weapon attachments used the same near-zero transform even
though the imported dagger, spear, bow, hammer, sword, and claymore use
different source axes.

## Implementation order

1. Make spell contact and trails bounded, shared-resource presentation effects
   with cleanup owned by `BattleDirector`.
2. Route Combat Lab through `ArenaAudioDirector`, retaining separate release
   and contact events from `BattleDirector`.
3. Replace generic weapon attachment values with explicit role grip profiles;
   use only existing CC0 outfits, hair, weapons, and normalized clips.

## Implemented behavior

- Ranged effects now emit at 0.18 m spacing with a 24-particle ceiling per
  projectile. Trail meshes and per-colour materials are shared. All temporary
  effects are cleared on settlement, skip, reset path, and scene exit.
- Spell contacts are alpha-faded 0.18 m cores, expanding only to 0.432 m over
  0.16 seconds, with reduced local light. This leaves the victim head and torso
  readable while the separate role shards retain impact emphasis.
- Combat Lab has the same `ArenaAudioDirector` connection as `GameScreen`.
  It no longer plays the procedural generic impact cue; the flash uses the
  actual victim contact point and is intentionally restrained.
- `PieceActor.WEAPON_GRIPS` now owns hand bone, mesh, scale, local offset, and
  local rotation per role. The role profiles also make pawn low/dual-blade,
  knight tall/spear, bishop bow, rook broad/hammer, queen gold blade, and king
  claymore presentation distinct without changing authoritative roots or
  choreography timings.

## Verification and remaining inspection

Headless checks cover distance emission bounds, temporary-effect cleanup,
20 Combat Lab play/reset cycles, audio routing, animation-browser attachment
creation, and all six grip profiles. The rendered audit records bishop/queen
impact plus each role's idle, walk, and primary-contact pose at both sides;
the generated screenshots are intentionally outside source control. Acoustic
quality still requires listening in a desktop session; code checks establish
event routing and cue identity only.

Rendered evidence was captured on the AMD Compatibility renderer under
`/tmp/cac-visual-tranche2b/` (role pose set and bishop contact) and
`/tmp/cac-spell-contact/` (bishop/queen contact grid). Reproduce with:

```sh
XDG_DATA_HOME=/tmp/cac-audit-data XDG_CONFIG_HOME=/tmp/cac-audit-config XDG_CACHE_HOME=/tmp/cac-audit-cache godot --path . --script tools/capture_visual_audit.gd -- /tmp/cac-visual-after
XDG_DATA_HOME=/tmp/cac-spell-data XDG_CONFIG_HOME=/tmp/cac-spell-config XDG_CACHE_HOME=/tmp/cac-spell-cache godot --path . --script tools/capture_spell_contact.gd -- /tmp/cac-spell-contact
```

Remaining limitation: the supplied generic clips do not provide authored bow
draw, two-handed hammer, or anatomically exact hand contact at every frame.
The new grips are the best compatible attachment adjustment and do not conceal
this limitation with larger VFX.
