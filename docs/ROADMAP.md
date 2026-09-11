# Roadmap — Check & Conquer

The milestones are gates. Do not skip a failed gate by adding more features.

## M0 — Bootstrap

### Deliverables
- Godot latest-stable 4.x project boots.
- Repository structure from master plan exists.
- Test harness works locally/headlessly where appropriate.
- `AGENTS.md`, master plan, decision log, asset/software provenance files are present.
- Minimal `Main.tscn` and debug menu exist.

### Exit criteria
- Clean launch.
- One trivial automated test passes.
- No unexplained startup errors.

---

## M1 — Combat vertical slice

### Goal
Prove the 3D character/rig/animation problem before investing in the rest of the game.

### Deliverables
- One compatible humanoid fantasy character imported.
- Idle + walk + attack + victim hit/death animation available through normalized clip names.
- Skeleton retargeting documented.
- `PieceActor.tscn` basic implementation.
- `DebugCombatLab.tscn` with attacker/victim/reset/play.
- Fixed combat anchors.
- One capture choreography resource.
- Medium capture camera shot.
- Impact sound or placeholder + VFX placeholder.

### Exit criteria
- 20 consecutive play/reset cycles without transform drift or stuck animation state.
- Attacker weapon/limb appears to contact or convincingly pass through victim contact zone.
- Victim reacts on the impact beat.
- Both actors return/reset deterministically.
- Character feet/scale/orientation are acceptable.
- Asset provenance recorded.

---

## M2 — Chess domain

**Progress:** Implemented and covered by headless tests: board state, FEN, UCI submission, structured `MoveResult`, legal filtering, perft d1–d4, special rules, move-history undo, and result detection. Insufficient-material detection recognizes only actual dead positions, avoiding false automatic draws in endings where opposing minor material can participate in a legal mate.

### Deliverables
- Board state.
- Legal move generation.
- Make/unmake.
- FEN import/export.
- UCI move parse/format.
- All standard special rules.
- Game-result detection.
- Move history.

### Exit criteria
- Start-position perft depths 1–4 pass: 20 / 400 / 8902 / 197281.
- Focused tests for castling, en passant, promotion, pins, check, mate, stalemate, repetition, fifty-move, insufficient material.
- No dependency on visual scenes or Stockfish.

---

## M3 — Interactive board

**Progress:** Implemented. The prototype has an 8×8 3D board with four-metre squares, deterministic mapping, actor projection, click selection/highlights, local move submission, walk-clip playback during quiet moves, and special-move projection. The Position Loader validates pasted FEN before rebuilding the visible projection and provides deterministic start, castle, en-passant, promotion, and capture presets.

### Deliverables
- 8×8 3D board.
- Square/world mapping.
- Actor spawn from domain state.
- Human selection + legal destination highlights.
- Move submission.
- Quiet-move presentation.
- Special-move presentation.
- FEN debug position loader.

### Exit criteria
- Two humans can complete a legal local game.
- Invalid moves cannot mutate state.
- Castling/en passant/promotion visuals end on exact domain positions.
- Board can be destroyed/rebuilt from FEN without mismatch.

---

## M4 — Stockfish opponent

**Progress:** Implemented for the bundled Linux Stockfish 19 binary. `StockfishAdapter` owns a nonblocking UCI subprocess, performs handshake/configuration/new-game/stop/quit/timeout handling, and emits parsed bestmoves. The automated real-process test completes 100 sequential legal engine turns. The playable screen now offers White versus Stockfish as its default mode and can fall back to local two-player mode if the engine cannot start. A bounded in-game UCI log supports diagnosis, and the Linux exporter stages the engine externally beside the game so it remains launchable after packaging.

### Deliverables
- UCI process adapter.
- Startup handshake.
- Async stdout parsing.
- Position submission.
- Bestmove parsing.
- Stop/quit/restart behavior.
- Difficulty presets.
- Engine debug console/logging.

### Exit criteria
- 100 sequential engine turns in a scripted test run without deadlock.
- Every returned bestmove is independently accepted as legal by domain.
- Process failure produces recoverable user-facing state rather than freeze.
- New-game/reset cleanly resets engine state.

---

## M5 — Combat integration

**Progress:** Implemented. Captures from the playable board commit in the chess domain and route to the generic BattleDirector choreography before actor-map settlement. En passant and promotion projection are tested; captures keep the player's current board view through the death beat, avoiding a separate zoom or reset. Full death clips finish before cleanup, then the surviving attacker visibly walks onto the committed square. Each choreography selects deterministically between compatible chest/head hits and backward/knockback deaths. Recorded CC0 weapon and fireball effects, flash, one-shot spark burst, nearby ally celebration gestures, and optional camera shake are synchronized to impact and settlement. The player HUD has no battle-skip control.

### Deliverables
- Captures route from `MoveResult` into `BattleDirector`.
- Presentation locks input.
- Victim removal and attacker settlement.
- En-passant capture integration.
- Promotion after capture.
- Camera return to board.
- Animation skip/fast path.

### Exit criteria
- Scripted games containing captures, en passant, castle, and promotion end with visual actors exactly matching domain state.
- Skipping a battle cannot skip/logically alter a chess move.
- Presentation exception/failure can rebuild board from domain.

---

## M6 — Six archetypes

**Progress:** Implemented. All six domain archetypes project on textured CC0 full fantasy outfits over the matching detailed base-character face, eyes, brows, and compatible role-specific hair, with peasant/ranger silhouettes selected by role, restrained blue/red material tints, and compact team-color ground rings. Each uses a distinct hand-assembled sword, lance, staff, mace, sceptre, or royal blade with neutral metal/wood/gold materials instead of team-colored placeholder cylinders. Large overhead primitive role markers are removed; a compact base chess crest, outfit, hair, and weapon preserve readability without blocking a capture. The complete presentation assembly uses a two-times display scale while its actor root remains in authoritative board metres; wider capture anchors, a face-level close focus, and a turn-aware three-quarter board view preserve clear framing. Each has idle, walk, combat-idle, primary attack, fallback capture choreography, and a visible hand prop. All 36 attacker/victim combinations resolve through a data-driven generic fallback. The supplied animation library gives pawn/king a sword slash, knight a jab, rook a guard push, and bishop/queen a spell shot. A CC0 medieval weapon library now replaces the prior hand-built primitives: pawns dual-wield daggers, knight carries a spear, bishop carries a bow, rook carries a war hammer, queen carries a golden sword, and king carries a claymore. Bishop captures fire a diagonal arrow, rook hurls a masonry volley, and queen captures launch an arcane bolt before authoritative settlement. A horse-mounted knight remains a planned dedicated actor/animation slice.

### Deliverables per archetype
- model/outfit/material,
- weapon/prop,
- idle,
- walk,
- combat idle,
- primary attack,
- fallback capture choreography,
- side material variants.

### Exit criteria
- All 36 attacker/victim type combinations resolve to either an exact choreography or valid fallback.
- No missing clip crashes.
- Pieces are recognizable at board camera distance.
- Style feels coherent rather than like six unrelated asset packs.

---

## M7 — V1 UX and polish

**Visual tranche (2026-09-11):** The Astra audit in `ASTRA_VISUAL_DIRECTION.md` prioritizes twelve concrete polish investments. Its first four restore neutral lighting/material contrast, replace saturated tile cues with distinct perimeters and retained last-move feedback, correct directional melee staging and authored contact timing, and give Match Settings an opaque reading surface with bounded engine diagnostics and menu-only camera telemetry. Existing debug scenes remain available; `tools/capture_visual_audit.gd` reproduces the rendered review route.

**Progress:** Implemented for the current Linux target. The playable screen keeps a board-first view with a compact, non-overlapping Match Settings panel for optional manual UCI entry, restart, undo, pause/resume, surrender and return, player-versus-Stockfish and spectator controls, side, Beginner/Adventurer/Champion/Master campaign difficulty, promotion piece, capture speed, fullscreen, master volume, camera shake, and bounded Stockfish diagnostics. Surrender plays each surviving character's full capture-fall animation before the game returns to the campaign map. Each conquered arena raises the selected difficulty profile slightly. A balanced direct player-side turn view frames every board corner with a readable foreground team and remains behind the human player while Stockfish moves from the far side. Manual board framing persists across moves; a compact Reset View button restores the tuned default on demand. Beginner Coach can be toggled from Match Settings; its Hint action asks the existing Stockfish process for a legal suggestion without taking a turn, while high-contrast raised green destination rings, gold coach hints, and brief amber last-move trails keep board changes obvious. A live corner readout exposes the editable camera tilt, spin, zoom, and pan values for view tuning. The arena is a physical bronze-railed stone altar framed by a narrow ring of local weathered terrace slabs, themed corner markers, and location-specific landmarks, while original high-detail panoramas supply the distant location. Each arena has its own looping original procedural music bed; board landings and weapon families emit distinct recorded effects. Actors select varied battle stances, appearances, gestures, and capture-win celebrations so ranks do not read as clones; a randomized single-piece ambient weight shift makes the formation feel alert without a synchronized loop. Prominent board callouts distinguish check, checkmate victory, checkmate defeat, stalemate, and campaign conquest, while the game-over panel keeps PGN copy and deterministic review controls available. The setting is isolated from chess state so it can be freely rebuilt. These player settings, including fullscreen and campaign route state, persist in `user://check_and_conquer_settings.cfg`. The Linux export stages Stockfish externally, includes the required notices/source, and has been smoke-launched headlessly as `check-and-conquer.x86_64`.

### Deliverables
- Main menu.
- Human vs human / human vs AI.
- Side choice.
- Difficulty.
- Restart.
- Undo policy.
- Game-over UI.
- Check/checkmate cues.
- Volume/camera-shake/animation-speed settings.
- Window/fullscreen settings.
- Packaging instructions.

### Exit criteria
- Fresh user can launch and start game without debug UI.
- Complete match can be played without opening console.
- Settings persist for session (disk persistence desirable).
- Release build starts on target OS.

---

## M8 — Signature capture content

**Progress:** Six original overrides now cover every attacker archetype: pawn versus queen uses a UAL2 riposte; knight versus pawn uses a two-beat jab-and-guard-push lunge; bishop versus king uses spell judgment; rook versus knight uses a mace-hook breaker; queen versus rook uses a spell-command and guard-push; and king versus bishop uses a UAL2 sword strike. All are assembled from normalized CC0 clips, selected by the data-driven resolver, replayable in Combat Lab, complete the chosen victim death clip, and fall back to the standard archetype choreography for every other matchup. Every archetype now also generates a short-lived role-colored impact stamp—dual-blade shards, lance-blue shock, frost shards, forge debris, arcane burst, or royal-gold burst—so ordinary and signature captures remain readable from the board view.

### Strategy
Add memorable bespoke overrides only after V1 is stable.

Prioritize by:
- visual comedy/drama,
- common encounter likelihood,
- piece personality,
- ease of producing synchronized clips.

### Exit criteria
Each signature capture:
- is original,
- has a deterministic debug reproduction,
- gracefully falls back if asset missing,
- ends in the same destination transforms as generic choreography,
- does not alter chess rules.

---

## M9 — Productization candidates

Not V1 commitments:
- Steam release pipeline,
- achievements,
- PGN cinematic replay,
- Stockfish-vs-Stockfish spectator mode,
- analysis after game,
- online multiplayer,
- theme/mod packs.

**Progress:** The Stockfish-versus-Stockfish spectator candidate is implemented as an optional persisted setting. It reuses the same UCI process, independent domain validation, turn phases, board projection, and combat presentation as normal engine play; it does not add online scope. The chess domain now also produces standard PGN movetext with SAN, custom-start FEN headers, and result markers. Completed games expose a compact review flow that rebuilds each authoritative snapshot, including the initial and final positions; this is the deterministic base for future cinematic replay and export UI.

---

## M10 — Grand arena campaign

**Progress:** Implemented. The game launches directly to a map-like five-stop Warpath route, with temporary developer tools on its lower left and Practice Arena/Quick Match plus an unrestricted arena picker on its lower right. `CampaignProgress` advances only after the human player checkmates Stockfish at the current arena; Practice Arena explicitly disables progression. Campaign progress persists as a validated primitive snapshot and unlocks the next location. Mountain Fortress Terrace is the first playable grand arena; Arcane Sky Citadel, Frozen Keep, Lava Forge, and Forest Ruins are themed follow-up locations, with Forest Ruins as the final match. Every location has an original generated 2:1 panorama plus a shared local terrace ring plus distinctive watchtowers, obelisks, ice spires, forge braziers, or ruined arches, neutral board lighting, HUD identity, and a brief chapter card that introduces a location-specific opponent and objective. The campaign shell changes no chess rule, board coordinate, piece, engine, or capture contract.
