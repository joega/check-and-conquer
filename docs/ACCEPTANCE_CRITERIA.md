# Acceptance Criteria

Use this file as the objective review checklist. Checked items are covered by
the current headless suite or release smoke check; command details and the
remaining manual review are recorded in [VERIFICATION.md](VERIFICATION.md).

## Global invariants

- [x] A visual actor never decides chess legality.
- [x] A combat animation never decides who survives.
- [x] Stockfish output is validated by the chess domain before application.
- [x] Board visuals can be rebuilt from authoritative domain state.
- [x] User input cannot mutate the board while a move/engine turn is in-flight.
- [x] Missing optional visual polish degrades gracefully rather than breaking game state.

## Chess correctness

- [x] Starting perft d1 = 20
- [x] Starting perft d2 = 400
- [x] Starting perft d3 = 8,902
- [x] Starting perft d4 = 197,281
- [x] Legal castling works.
- [x] Castling while in check is rejected.
- [x] Castling through attacked square is rejected.
- [x] En passant works.
- [x] Illegal en passant exposing king is rejected.
- [x] Q/R/B/N promotion works.
- [x] Promotion capture works.
- [x] Check detection works.
- [x] Mate detection works.
- [x] Stalemate works.
- [x] Threefold repetition bookkeeping works.
- [x] Fifty-move rule works.
- [x] Insufficient material works for supported standard cases.
- [x] FEN roundtrip preserves complete state.

## Stockfish

- [x] Process starts from configured/packaged path.
- [x] `uci`/`uciok` handshake succeeds.
- [x] `isready`/`readyok` succeeds.
- [x] New game resets engine.
- [x] FEN position can be sent.
- [x] `bestmove` parses safely.
- [x] Engine stdout does not block render loop.
- [x] Timeout/crash is handled.
- [x] Engine can be stopped during restart/undo/quit.
- [x] Difficulty presets result in valid UCI configuration.

## Piece presentation

For each archetype:

- [x] white/black side presentation exists.
- [x] idle works.
- [x] locomotion works.
- [x] combat idle works or safely falls back to idle.
- [x] one primary attack exists.
- [x] fallback choreography resolves against all victim archetypes.
- [x] actor ends exactly at board square center after move.
- [x] dead/hidden actors are cleaned/recycled correctly.

## Combat

- [x] input locked during battle.
- [x] attacker/victim face appropriate directions.
- [x] camera shot activates and returns.
- [x] impact event is synchronized.
- [x] victim death/hide occurs once.
- [x] attacker settles to destination once.
- [x] battle can be skipped without state corruption.
- [x] battle reset in debug lab is deterministic.
- [x] 20 repeat cycles do not drift transforms.

## Special moves presentation

- [x] castling moves both correct actors.
- [x] en passant removes the actual victim square actor.
- [x] promotion swaps visual archetype after move.
- [x] promotion after capture works.
- [x] check cue is non-blocking or bounded.
- [x] checkmate finishes cleanly into game-over state.

## UX

- [x] start new human-vs-human game.
- [x] start new human-vs-engine game.
- [x] choose side.
- [x] choose difficulty.
- [x] restart.
- [x] undo behaves according to mode policy.
- [x] skip/fast animations setting.
- [x] sound volume control.
- [x] camera shake setting/off.
- [x] game-over result clear.
- [x] Linux release build launches without editor.

## Licensing/provenance

- [x] all third-party models/animations logged.
- [x] all third-party audio/VFX logged.
- [x] Stockfish version/license/source pointer logged.
- [x] no ripped/copied Battle Chess assets.
- [ ] `Check & Conquer` title and art reviewed for originality and trademark suitability. `Warboard` and `Warchessed` are retired as shipping titles; see ADR-013, ADR-014, and ADR-018.
