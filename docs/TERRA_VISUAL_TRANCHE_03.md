# Terra visual tranche 03 — 2026-09-11

## Scope

This pass advances three high-value presentation needs without expanding the
chess, engine, or asset-intake surface:

1. project-authored Bishop bow draw/release and Rook overhead hammer actions;
2. a short post-capture winner recovery plus restrained full-side checkmate
   acknowledgement; and
3. a campaign-map hierarchy with one explicit current objective and dominant
   next action.

## Role action timelines

The imported CC0 libraries do not contain a usable bow draw/release or a
two-handed hammer strike. `PieceActor` therefore adds semantic project-owned
prop timelines over compatible imported body motion:

- `attack.bow.draw_release_01` shows a nocked local arrow, a draw/aim/release
  arc, and hands it to `BattleDirector` at the exact projectile release beat.
- `attack.hammer.overhead_01` gives the hand-held hammer an explicit lift,
  overhead commitment, descent, and return. Rook generic and signature
  choreography use `hammer_smash`; the previous thrown-masonry substitute is
  no longer the active capture delivery.

Both actions remain data-driven choreography requests, have fixed semantic
durations, and do not change actor-root movement, combat anchors, the captured
piece, or destination settlement. The old masonry helper remains available as
an isolated presentation utility only; no resource selects it.

## Recovery and victory

`BoardPresenter.settle_capture` now asks the winner for
`recovery.capture_ready_01`, a 0.36-second local brace/exhale below the actor
root. Nearby teammates retain the existing one-or-two acknowledgement policy.
On checkmate `GameScreen` asks `BoardPresenter` to acknowledge only the
domain-determined winning side. These are visual consequences after the move
result is settled, never inputs to chess state.

## Campaign hierarchy

The single unlocked campaign arena receives a bright three-pixel gold keyline,
opaque backing, chapter/opponent copy, a current-objective panel, and an
arena-named central action. Conquered and locked cards remain readable but use
the quieter one-pixel backing. Practice and developer tools stay secondary.
The bottom-anchored objective/action/practice controls remain inside a small
viewport rather than depending on fixed 720-pixel offsets.

## Verification

- `tests/presentation/test_authored_role_actions.gd` checks semantic support,
  nocked-arrow handoff, fixed durations, and root-stable recovery.
- Resolver, signature-delivery, death-completion, BoardPresenter, CampaignMap,
  and Combat Lab checks cover route selection, impact ownership, exact
  settlement, victory behavior, responsive map bounds, and twenty reset
  cycles.
- `tools/capture_authored_combat.gd` captures Bishop draw/contact and Rook
  hammer contact in Combat Lab. It is intentionally separate from the broad
  audit and writes only to a supplied outside-source-control directory.

Reproduce rendered inspection with isolated saves:

```sh
XDG_DATA_HOME=/tmp/cac-authored-data XDG_CONFIG_HOME=/tmp/cac-authored-config XDG_CACHE_HOME=/tmp/cac-authored-cache godot --path . --script tools/capture_authored_combat.gd -- /tmp/cac-authored-combat
XDG_DATA_HOME=/tmp/cac-audit-data XDG_CONFIG_HOME=/tmp/cac-audit-config XDG_CACHE_HOME=/tmp/cac-audit-cache godot --path . --script tools/capture_visual_audit.gd -- /tmp/cac-visual-tranche3
```

## Asset/provenance boundary

No external model, clip, audio, texture, or generated bitmap is acquired in
this tranche. The new action timelines are authored GDScript/tween behavior
using the already-recorded Quaternius CC0 weapons, arrow, humanoid rig, and
animation libraries. A future true skeletal bow/hammer animation intake still
requires the normal compatible-rig and redistribution-rights review in
`assets/THIRD_PARTY_ASSETS.md`.
