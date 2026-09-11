# Astra visual direction — 2026-09-11

## Audit evidence and first 30 seconds

Ran the actual Compatibility renderer on AMD integrated graphics, with isolated saves. Captured the campaign, starting board, e2 selection, e2e4 followed by a real Stockfish reply, settings, Position Loader, Animation Browser, and Combat Lab through impact, settlement and reset. `tools/capture_visual_audit.gd` repeats that route. Initial captures were 922×518 because the desktop tiled the window; this is also a useful small-window readability check. Screenshots live outside source control under `/tmp/cac-visual-before` and `/tmp/cac-visual-after`.

The opening illustration and logo promise a grand fantasy campaign. Enter Arena is obvious, but locked cards have nearly the same visual weight as the playable location, and the practice selector stretches awkwardly across the lower illustration. Entering play drops that rich promise onto an overexposed white/mint grid: square material, crests and blue selection lose detail. Human infantry have appealing animated silhouettes, but distant ranks and similarly dressed classes take effort to identify. The player's first move works and Stockfish answers promptly. A short-lived last-move cue disappears while the player is still deciding. Permanent camera telemetry and a transparent settings panel expose prototype scaffolding. Combat is lively, but fixed-direction approach and attack-clip substitutions weaken contact credibility.

## Priorities, ordered by player impact

### 1. Restore board and character tonal range — implement now

- Problem: ambient 1.05 plus key 1.15 and fill 0.92 bleach pale squares to white; minimal shading separates garments and faces.
- Outcome: warm limestone and dark slate-green squares, readable neutral faces, grounded shadows, a stronger foreground army.
- Approach/files: reduce neutral ambient/fill energy in `scripts/presentation/battlefield_environment.gd`; increase matte roughness and lower square albedo in `chess_board.gd`. Preserve panoramic color and the existing shadowed key.
- Risk: dark-side faces could become too dark. Avoid glow, screen-space effects or renderer changes; compare both sides and all five arenas.
- Acceptance: ordinary light tiles retain color; dark tiles and dark clothing remain distinct; every corner stays framed; arena selection never tints the board lights.

### 2. Make chess cues readable without bleaching the board — implement now

- Problem: selection, legal moves and hints add 2.4–3.4 emission to whole tiles; these saturate into similar cyan/white patches. Last move disappears after 3.2 seconds.
- Outcome: selected square has a cyan perimeter, legal destinations retain green rings, hint squares gold perimeters, last move subdued amber perimeters until the next move. Shapes and position supplement color.
- Approach/files: `chess_board.gd` creates thin unshaded perimeter markers, retains bounded legal rings and limits tile emission; `game_screen.gd` retains last move until replacement/reset/review.
- Risk: overlaps between cues. Explicit priority: hint > selection > last move, legal rings remain independent. No full-screen pulse.
- Acceptance: e2/e3/e4 remain distinguishable in start position; clearing selection removes its markers and preserves last move; restart/undo clear stale cues; no geometry crosses square edges.

### 3. Make melee approach and contact intentional — implement now

- Problem: `battle_director.gd` stages south of every victim, even when attacker starts north; `piece_actor.gd` substitutes differently timed combos despite authored contact timestamps. Swing arc expires before contact.
- Outcome: attacker approaches from its actual direction, retains authored attack, and swing overlaps the reaction/sound beat.
- Approach/files: calculate planar victim-to-attacker anchor direction with zero-distance fallback; honor choreography semantic clip; schedule swing in the final 0.09 seconds before impact. Keep domain destination settlement unchanged.
- Risk: crowd overlap remains possible, and library clips still require hand-contact authoring. Test reverse/horizontal/diagonal staging, skip, signatures, full death duration and 20 resets.
- Acceptance: anchor lies on approach side; no route through victim to reach anchor; authored semantic attack survives position changes; swing exists on impact; actor ends exactly at destination.

### 4. Give settings and HUD a deliberate hierarchy — implement now

- Problem: battlefield remains visible through settings text; camera telemetry occupies normal play; manual UCI fields overlap status/arena title when menu opens.
- Outcome: opaque dark settings surface with gold heading, stable legible controls, technical readouts available inside settings, unobstructed play view.
- Approach/files: `scenes/app/GameScreen.tscn` panel style and manual-entry positioning; `scripts/game/game_screen.gd` gates camera telemetry with menu visibility and updates it only while visible.
- Risk: fixed layouts still constrain smaller windows. Preserve existing control names and signals; test settings/restart/pause/engine flow.
- Acceptance: no board texture under settings copy; UCI row sits inside panel without overlap; telemetry absent in normal gameplay and restored by Menu; Hint and Menu remain accessible.

### 5. Preserve victim silhouette during spell impacts — next code tranche

- Problem: opaque elemental sphere expands to 2.69 m; per-frame projectile trails allocate more meshes at higher FPS.
- Outcome: brief translucent contact core and directional debris; victim reaction stays visible.
- Approach/files: `battle_director.gd` fade core alpha while expanding to <1.6 m, cap trail emissions by time/distance and reuse mesh/material resources.
- Risk: Compatibility transparency sorting; do not add a fog shell. Acceptance: bishop/queen at 0.25×/1×/2× keep heads and torsos readable; all temporary effects clean up after skip/reset; trail count bounded independently of FPS.

### 6. Unify debug and game audio — next code tranche

- Problem: Combat Lab uses synthesized impact while gameplay uses class-specific recorded release/contact audio.
- Outcome: lab auditions the same sound and visual beat players hear.
- Approach/files: connect `weapon_impact` to `ArenaAudioDirector` in DebugCombatLab, replace doubled generic cue, position flash at victim contact. Preserve master volume and speed.
- Risk: layered release and hit can sound doubled. Acceptance: bow/queen release precedes arrival; exactly one contact sound per authored hit; compare headphones at three speeds. Current audit verified event paths, not acoustic quality.

### 7. Improve class silhouettes with existing costume pieces — next visual investment

- Problem: pawn, knight and rook share ranger/peasant silhouettes; the small ground crests disappear behind feet at board distance.
- Outcome: recognizable rank silhouette before reading a crest: low infantry, tall spear, broad hammer, distinct bow, gold queen and royal king.
- Approach/files: `piece_actor.gd` role outfit/hair/accessory mapping and modest role-specific proportions; keep canonical actor roots and hand bones. Audit all six in Animation Browser and starting ranks.
- Risk: clipping and animation compatibility. Acceptance: role identification from both camera sides at 1280×720, no oversized overhead markers; weapon/face visible through idle, walk and attack.

### 8. Author six weapon grips — next visual investment

- Problem: shared zero-rotation grip offsets do not establish convincing role-specific palm contact; dagger visibility is weak in the browser.
- Outcome: fingers meet handles, spear/bow axes match attack intent, weapons never look dropped at the feet.
- Approach/files: per-role socket transform data in `piece_actor.gd`; verify imported weapon axes against hand transforms, inspect at 0.25×. Use only existing CC0 weapons.
- Risk: one grip may improve idle but break attack. Acceptance: screenshots of idle/walk/contact/death for every role, both sides; no detached or ground-intersecting weapon during normal idle.

### 9. Polish move and victory behavior — subsequent code/content

- Problem: generic locomotion and position-seeded gestures add life but do not guarantee foot cadence, impact recovery or celebration coherence.
- Outcome: short moves feel planted; capture winner visibly recovers; victory/defeat holds readable poses; idle gestures remain sparse.
- Approach/files: `board_presenter.gd`, `battle_director.gd`, `piece_actor.gd`; calibrate travel duration to stride, retain full deaths, bound ally celebration to nearby actors and prohibit gesture interruption of move/combat.
- Risk: overly long turns. Acceptance: quiet move <1.2 s for common pawn/knight moves; 20 repeated captures reset; surrender/game-over never stuck; no change to chess results.

### 10. Give the campaign one dominant next action — subsequent UI

- Problem: five uniform cards compete with Enter Arena; practice picker is visually disconnected; lower developer area has poor small-window layout.
- Outcome: current arena gets a clear gold keyline and opponent subtitle; locked cards use quieter text; practice and developer tools become compact secondary controls.
- Approach/files: `CampaignMap.tscn`, `campaign_map.gd`; use containers/anchors for footer and a deliberate focus style. Keep title/map artwork.
- Risk: over-darkening illustrated locations or hiding debug access. Acceptance: keyboard focus and Enter work; current/locked/conquered distinguishable without color; footer fits 1280×720 and 1920×1080.

### 11. Add peripheral atmosphere only after exposure is stable — later asset-free polish

- Problem: panorama is static while local pulsing lights add brightness without clear environmental motion.
- Outcome: subtle distant drifting wisps/snow/embers appropriate to arena, below or beyond playable sightlines; still board center.
- Approach/files: `battlefield_environment.gd`, bounded procedural particles behind the terrace and outside ±18 m board footprint, deterministic seed and no shadows.
- Risk: particles outside board can still project over pieces from opposite view. Acceptance: both camera sides and orbit extremes never obscure ranks; ≤64 particles/arena; no measurable sustained frame-time regression. Do not add board-wide fog, bloom or lightning exposure flashes.

### 12. Acquire targeted animation/character content — later acquisition / larger future work

- Problem: spear uses a jab, bow a generic spell cast, knight is not mounted; more effects cannot repair these silhouettes/contact mechanics.
- Outcome: authored thrust, bow draw/release, two-handed hammer and royal celebration, followed by a dedicated mounted-knight slice.
- Approach/files: source compatible rigged clips/outfits, normalize semantic names, record exact provenance in `assets/THIRD_PARTY_ASSETS.md`; use contact markers in choreography resources. Mounted actor remains separate future work after 20-cycle validation.
- Risk: license/retargeting and scope. No downloads in this tranche. Acceptance: verified compatible redistribution rights before intake; feet/weapon contact inspected; all 36 generic fallbacks and authoritative settlement retained.

## Boundaries and verification

No chess/engine contracts change, no new external assets, no online scope. Existing war-horn provenance is unresolved and theme distribution terms remain a release follow-up already recorded in the asset ledger; this tranche does not acquire or replace those assets.

Run `bash tools/run_headless_tests.sh` and the rendered audit with isolated saves:

```sh
XDG_DATA_HOME=/tmp/cac-audit-data XDG_CONFIG_HOME=/tmp/cac-audit-config XDG_CACHE_HOME=/tmp/cac-audit-cache godot --path . --script tools/capture_visual_audit.gd -- /tmp/cac-visual-after
```

Headless tests establish behavior, not visual quality. Compare before/after rendered board, selection, settings and contact. Additional lighting views must cover all arenas and both sides. GPU exit texture-cleanup diagnostics are recorded separately from scene/script failures.

## Implemented tranche and verification record

Items 1–4 are implemented. Lighting is 0.48 ambient / 0.85 key / 0.32 fill; matte limestone/slate squares retain color under that rig. Selection and hints use explicit cyan/gold perimeters, green legal rings remain, and last move uses persistent amber perimeters. Undo/restart/review remove stale cues. Melee staging uses the incoming direction and victim location (including en passant); authored clips retain their timing, and swing begins 0.09 s before impact. Settings now use an opaque dark surface, manual UCI controls fit inside, engine output scrolls within a fixed rectangle, and camera telemetry appears only with Menu.

Verification:

- `bash tools/run_headless_tests.sh`: exit 0, all 32 test programs passed. Includes perft 20/400/8,902/197,281; 100 real Stockfish turns; 36 choreography pairings; castling, en passant and promotion projection; 20 complete Combat Lab play/reset cycles.
- New melee regression: twenty captures across eight directions, authored clips across stance seeds, distinct victim/destination, coincident-position fallback, windup skip, contact-visible swing, exact settlement. This accelerated test skips at impact; the separate Combat Lab gate verifies full-duration resets.
- Board tests verify cue priority, bounded emission, removal and retained last move. Game integration checks menu telemetry, opaque panel, contained controls, last-move persistence beyond the former timeout and clearing on restart/review.
- Rendered audit: exit 0. Inspected both sides of all five arenas, selection, real e2e4/Stockfish reply, settings and all required debug scenes. Before/first-after were 922×518; final desktop layout produced 1882×1058. Final screenshots: `/tmp/cac-visual-final/`; prior comparisons: `/tmp/cac-visual-before/` and `/tmp/cac-visual-after/`. Arena comparison shots switch presentation only, so their HUD retains the mountain match title.
- First suite import encountered sandbox-denied editor-settings/socket writes; a separate isolated-XDG import with desktop permissions exited 0 with no errors. Test exit cleanup reports resource/ObjectDB leftovers; rendered audit reports two small GL texture leftovers at shutdown, also present before changes. No script assertions or scene-load failures. No claim of a leak-free release build or a measured 60 FPS budget.

Inspection: launch `godot --path .`, Enter Arena, select e2 and play e4; wait more than four seconds after the reply to see retained amber outlines. Open Menu to inspect settings and telemetry. Run Combat Lab, Play Capture, Reset; use the documented capture command for the entire repeatable route.

Remaining limitations: hand-to-weapon and anatomical hit contact still need role-specific authoring; far-rank class silhouettes remain similar; debug-room lighting retains its pre-existing bright calibration; spell cores, peripheral landmark emission and campaign footer still need polish. Current work adds no assets and requires no provenance changes. README, roadmap and ADR-019 record the behavior changes.

Terra's next three investments: (1) translucent, bounded spell impacts/trails (item 5), (2) game/lab audio parity (item 6), (3) a combined six-role silhouette and weapon-grip pass (items 7–8), with screenshots of idle, walk and contact before acquiring more content.
