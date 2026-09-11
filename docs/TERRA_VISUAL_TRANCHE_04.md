# Terra visual tranche 04 — recovery inspection and campaign arrival

Date: 2026-09-11

## Scope

This pass makes the existing post-capture recovery and victory acknowledgements
inspectable without playing a full match, and turns completion of the fifth
arena into a clear Warpath endpoint.

## Changes

- `DebugAnimationBrowser` now exposes **Capture Recovery** and **Victory
  Acknowledgement** actions.
- `DebugCombatLab` now exposes matching preview controls. Recovery is checked
  against the actor's exact board-root transform, while victory poses leave the
  combat lifecycle untouched.
- `PieceActor` cancels an outstanding recovery tween before any incompatible
  state or reset, preventing a late pose reset from affecting later previews.
- When every arena is conquered, the map replaces the stale current-objective
  copy with **Campaign Conquered / The Final Grove Is Yours**, marks Forest
  Ruins as **Final Conquered**, and disables the obsolete campaign-entry
  action. Practice Arena remains available.

## Deterministic visual reproduction

Run the focused combat audit under isolated settings paths:

```bash
XDG_DATA_HOME=/tmp/cac-authored-data \
XDG_CONFIG_HOME=/tmp/cac-authored-config \
XDG_CACHE_HOME=/tmp/cac-authored-cache \
godot --path . --script tools/capture_authored_combat.gd -- /tmp/cac-authored-combat
```

Inspect `capture-recovery.png` and `victory-acknowledgement.png`. The broader
audit additionally creates `01b-campaign-conquered.png` after injecting the
validated all-arenas-completed snapshot:

```bash
XDG_DATA_HOME=/tmp/cac-visual-data \
XDG_CONFIG_HOME=/tmp/cac-visual-config \
XDG_CACHE_HOME=/tmp/cac-visual-cache \
godot --path . --script tools/capture_visual_audit.gd -- /tmp/cac-visual-audit
```

## Limitation

The Bishop and Rook actions remain project-authored prop timelines over
compatible Quaternius body clips. The evaluated KayKit clips were CC0 but did
not satisfy the rig-compatibility gate; the rationale is recorded in
`ASSET_PIPELINE.md`. No new third-party asset was added in this tranche.
