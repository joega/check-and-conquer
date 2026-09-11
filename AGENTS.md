# AGENTS.md — Project Warboard

This repository is an agent-led Godot game project. Read `BATTLE_CHESS_MASTER_PLAN.md` before making architectural changes.

## Mission

Build an original 3D animated-combat chess game. Standard chess rules determine outcomes; combat animation is presentation only.

## Non-negotiables

- Godot 4.x latest stable at project bootstrap.
- Chess domain logic is independent of 3D actors and Stockfish.
- Stockfish is a separate UCI subprocess; do not modify it.
- Domain state is authoritative; visuals are rebuildable projections.
- Six archetypes: pawn, knight, bishop, rook, queen, king.
- Generic capture choreography must cover every matchup before signature captures are added.
- Prefer in-place animation + code-controlled root movement.
- Use standardized combat anchors and data-driven choreography resources.
- Do not copy art, characters, specific animations, audio, UI, or branding from the original Battle Chess.
- Record third-party asset/software provenance and licenses.
- Do not add online/backend/account scope to V1.

## Working style

1. Inspect current milestone in `docs/ROADMAP.md`.
2. Make the smallest coherent change that advances its acceptance criteria.
3. Use subagents/worktrees for cleanly separable tasks.
4. Do not let multiple workers redefine the same core interface concurrently.
5. Run relevant tests before declaring work complete.
6. Visual changes require a deterministic debug/reproduction path.
7. Update docs if a technical decision changes.
8. Do not leave undocumented hacks in core gameplay code.

## Architecture boundaries

### `scripts/chess/`
Pure chess state/rules. No scene/node dependencies where avoidable. No animation logic. No Stockfish-specific assumptions beyond standard FEN/UCI serialization.

### `scripts/engine/`
Stockfish UCI subprocess lifecycle, parsing, settings, timeouts, errors. Returned moves must be validated by chess domain.

### `scripts/game/`
Turn orchestration, game phases, player type, session history. May coordinate domain/engine/presentation but should not implement their internals.

### `scripts/presentation/`
BoardPresenter, BattleDirector, CameraDirector, choreography resolver. Must consume structured chess results rather than infer rules.

### `scripts/actors/`
Visual actor behavior only: animation, movement, facing, materials, weapon attachments.

## Required debug scenes

Build and preserve:

- `DebugCombatLab.tscn`
- `DebugAnimationBrowser.tscn`
- `DebugPositionLoader.tscn`

## Test gates

Before full-game integration, chess start-position perft must pass:

- depth 1: 20
- depth 2: 400
- depth 3: 8,902
- depth 4: 197,281

Stockfish adapter must have a real-process integration test where supported.

## Visual-content gate

Do not expand to six characters until one attacker/victim vertical slice can be replayed 20 times without position drift, stuck states, or broken reset.

## Asset rules

Preferred prototype ecosystem: Quaternius CC0 Universal Base Characters, Modular Character Outfits - Fantasy, and Universal Animation Libraries. Validate current license/source before acquisition and record it in `assets/THIRD_PARTY_ASSETS.md`.

Normalize source animation names to project semantic names. Source pack filenames are not gameplay API contracts.

## Completion report for each task

Summarize:

- what changed,
- why,
- tests/verification,
- visible result/reproduction steps if applicable,
- limitations/follow-up,
- docs/licenses updated.
