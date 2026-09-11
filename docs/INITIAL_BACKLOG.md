# Initial Backlog

This is a suggested first task graph for the root agent. Task IDs are stable references, not mandatory branch names.

## Phase A — Bootstrap and risk proof

### WARB-001 — Bootstrap Godot repository
**Depends on:** none  
**Scope:** Pin latest stable Godot 4.x, create directory structure, test harness, `Main.tscn`, debug launch path, basic CI/headless test command if practical.  
**Acceptance:** Project launches cleanly and one test passes.

### WARB-002 — Acquire and document prototype character/animation assets
**Depends on:** WARB-001  
**Scope:** Select one compatible Quaternius humanoid/fantasy character and idle/walk/attack/death clips. Record provenance/license.  
**Acceptance:** Exact source files and licenses are documented; files import into Godot.

### WARB-003 — Canonical humanoid import/retarget pipeline
**Depends on:** WARB-002  
**Scope:** Normalize scale/orientation, configure humanoid bone map, validate clips, define semantic names.  
**Acceptance:** Same character can play idle/walk/attack/death through normalized animation API.

### WARB-004 — PieceActor primitive
**Depends on:** WARB-003  
**Scope:** Reusable actor scene with animation state control, facing, code-driven translation, team material hook, reset.  
**Acceptance:** Actor can be spawned twice and controlled independently without shared-state animation bugs.

### WARB-005 — Debug Animation Browser
**Depends on:** WARB-004  
**Scope:** UI/debug scene to select actor and semantic animation, control speed, reset pose, inspect root drift.  
**Acceptance:** All normalized clips can be audited without editing scene internals.

### WARB-006 — Combat anchors and capture choreography resource
**Depends on:** WARB-004  
**Scope:** Define attacker/victim staging transforms and typed choreography data.  
**Acceptance:** One data resource describes attack clip, victim reaction/death, timing, shot, and impact package.

### WARB-007 — CameraDirector primitive
**Depends on:** WARB-001  
**Scope:** Board/default and capture-medium shots with deterministic transition/restore API.  
**Acceptance:** Debug call can enter capture shot and return without transform drift.

### WARB-008 — BattleDirector vertical slice
**Depends on:** WARB-004, WARB-006, WARB-007  
**Scope:** Orchestrate approach, facing, attack, impact marker, victim death, cleanup, attacker settlement.  
**Acceptance:** One scripted capture completes and emits `presentation_finished`.

### WARB-009 — Debug Combat Lab
**Depends on:** WARB-008  
**Scope:** Play/reset controls, anchor visualization, speed controls, deterministic reset.  
**Acceptance:** 20 repeat cycles with no actor/camera/state drift. This closes M1.

## Phase B — Chess core (may parallelize after WARB-003/004 prove pipeline)

### WARB-010 — Chess board/state representation
**Depends on:** WARB-001  
**Scope:** Pure domain types, piece representation, square helpers, side-to-move, state metadata.  
**Acceptance:** Starting position/FEN initializes deterministically.

### WARB-011 — Pseudo-legal move generation
**Depends on:** WARB-010  
**Scope:** All piece movement including pawn specials before king-safety filtering.  
**Acceptance:** Focused move-generation tests pass.

### WARB-012 — Make/unmake + legal filtering
**Depends on:** WARB-011  
**Scope:** Undo record, attacks/check detection, pinned/king-safety legality.  
**Acceptance:** Starting perft d1–d4 = 20/400/8902/197281.

### WARB-013 — Special rules and results
**Depends on:** WARB-012  
**Scope:** castling legality, en passant edge cases, promotions, mate/stalemate, repetition, fifty-move, insufficient material.  
**Acceptance:** Focused acceptance suite passes.

### WARB-014 — FEN/UCI + move result contract
**Depends on:** WARB-013  
**Scope:** Complete FEN roundtrip, UCI move parse/format, presentation-oriented `MoveResult`.  
**Acceptance:** Known positions/moves roundtrip; MoveResult explicitly encodes capture/special-move facts.

## Phase C — Board/game integration

### WARB-015 — 3D board and square mapping
**Depends on:** WARB-001  
**Scope:** 64 squares, exact square↔world conversion, coordinate debug overlay.  
**Acceptance:** Every square center roundtrips deterministically.

### WARB-016 — BoardPresenter actor synchronization
**Depends on:** WARB-004, WARB-014, WARB-015  
**Scope:** Spawn/reset actors from domain state; visual map keyed by logical piece identity/square.  
**Acceptance:** FEN loader rebuilds correct visual board repeatedly.

### WARB-017 — Selection and legal move UX
**Depends on:** WARB-014, WARB-015, WARB-016  
**Scope:** ray picking, selection, legal/capture highlights, cancel, promotion choice.  
**Acceptance:** Human-vs-human legal game input works; invalid input cannot mutate domain.

### WARB-018 — TurnController/game phases
**Depends on:** WARB-014, WARB-017  
**Scope:** explicit phases, interaction lock, move request flow, game-over transition.  
**Acceptance:** No concurrent input during presentation/engine phases.

## Phase D — Stockfish

### WARB-019 — UCI subprocess adapter
**Depends on:** WARB-001  
**Scope:** spawn, async line IO, handshake, commands, bestmove parser, stop/quit.  
**Acceptance:** Real Stockfish integration test succeeds.

### WARB-020 — Engine supervision/error handling
**Depends on:** WARB-019  
**Scope:** timeout/crash/restart states; safe cancellation during quit/restart/undo.  
**Acceptance:** Forced process termination cannot freeze the game.

### WARB-021 — Difficulty profiles
**Depends on:** WARB-019  
**Scope:** player-friendly preset data mapped to supported UCI options.  
**Acceptance:** each preset handshakes/configures and returns legal moves.

### WARB-022 — Human-vs-engine orchestration
**Depends on:** WARB-018, WARB-020, WARB-021  
**Scope:** after human presentation, send FEN, await bestmove, validate/apply, present response.  
**Acceptance:** full games complete without phase deadlocks.

## Phase E — Full battle integration

### WARB-023 — Quiet move presentation
**Depends on:** WARB-016, WARB-018  
**Scope:** code-driven locomotion/slide from square to square with exact settlement.  
**Acceptance:** scripted quiet moves remain aligned after long sequences.

### WARB-024 — Capture presentation integration
**Depends on:** WARB-009, WARB-018, WARB-023  
**Scope:** route captures into BattleDirector using MoveResult.  
**Acceptance:** victim removed once; attacker ends on exact destination; next turn starts only after completion.

### WARB-025 — Special move visuals
**Depends on:** WARB-024  
**Scope:** castle, en passant, promotion, promotion-capture.  
**Acceptance:** visual board always matches authoritative FEN after each case.

### WARB-026 — Skip/fast/failure recovery
**Depends on:** WARB-024  
**Scope:** skip battle, speed multiplier, cancellation-safe cleanup, rebuild-on-presentation-error.  
**Acceptance:** skipping/failure never changes logical outcome.

## Phase F — Six archetypes

### WARB-027 — Pawn visual/combat definition
### WARB-028 — Knight visual/combat definition
### WARB-029 — Bishop visual/combat definition
### WARB-030 — Rook visual/combat definition
### WARB-031 — Queen visual/combat definition
### WARB-032 — King visual/combat definition

**Depends on:** WARB-024  
**Acceptance for each:** recognizable model/outfit, team variants, movement, idle/combat idle, primary attack, universal fallback capture.

### WARB-033 — Choreography resolver completeness
**Depends on:** WARB-027..032  
**Scope:** exact override → attacker fallback → universal fallback.  
**Acceptance:** all 36 type matchups resolve without missing asset/clip errors.

## Phase G — V1

### WARB-034 — Main menu and match configuration
### WARB-035 — Restart/undo/session history
### WARB-036 — Check/checkmate/game-over presentation
### WARB-037 — Audio/VFX polish pass
### WARB-038 — Settings/accessibility
### WARB-039 — Release packaging + license notices
### WARB-040 — V1 acceptance sweep

WARB-040 closes only when `docs/ACCEPTANCE_CRITERIA.md` is satisfied or every exception is explicitly documented.

## Phase H — Signature content

Create individual tickets such as `SIG-pawn-vs-queen-01`; do not make “all 36 signatures” one task. Each signature must be independently optional and must preserve generic fallback.
