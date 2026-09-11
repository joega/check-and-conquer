# Acceptance Criteria

Use this file as the objective review checklist.

## Global invariants

- [ ] A visual actor never decides chess legality.
- [ ] A combat animation never decides who survives.
- [ ] Stockfish output is validated by the chess domain before application.
- [ ] Board visuals can be rebuilt from authoritative domain state.
- [ ] User input cannot mutate the board while a move/engine turn is in-flight.
- [ ] Missing optional visual polish degrades gracefully rather than breaking game state.

## Chess correctness

- [ ] Starting perft d1 = 20
- [ ] Starting perft d2 = 400
- [ ] Starting perft d3 = 8,902
- [ ] Starting perft d4 = 197,281
- [ ] Legal castling works.
- [ ] Castling while in check is rejected.
- [ ] Castling through attacked square is rejected.
- [ ] En passant works.
- [ ] Illegal en passant exposing king is rejected.
- [ ] Q/R/B/N promotion works.
- [ ] Promotion capture works.
- [ ] Check detection works.
- [ ] Mate detection works.
- [ ] Stalemate works.
- [ ] Threefold repetition bookkeeping works.
- [ ] Fifty-move rule works.
- [ ] Insufficient material works for supported standard cases.
- [ ] FEN roundtrip preserves complete state.

## Stockfish

- [ ] Process starts from configured/packaged path.
- [ ] `uci`/`uciok` handshake succeeds.
- [ ] `isready`/`readyok` succeeds.
- [ ] New game resets engine.
- [ ] FEN position can be sent.
- [ ] `bestmove` parses safely.
- [ ] Engine stdout does not block render loop.
- [ ] Timeout/crash is handled.
- [ ] Engine can be stopped during restart/undo/quit.
- [ ] Difficulty presets result in valid UCI configuration.

## Piece presentation

For each archetype:

- [ ] white/black side presentation exists.
- [ ] idle works.
- [ ] locomotion works.
- [ ] combat idle works or safely falls back to idle.
- [ ] one primary attack exists.
- [ ] fallback choreography resolves against all victim archetypes.
- [ ] actor ends exactly at board square center after move.
- [ ] dead/hidden actors are cleaned/recycled correctly.

## Combat

- [ ] input locked during battle.
- [ ] attacker/victim face appropriate directions.
- [ ] camera shot activates and returns.
- [ ] impact event is synchronized.
- [ ] victim death/hide occurs once.
- [ ] attacker settles to destination once.
- [ ] battle can be skipped without state corruption.
- [ ] battle reset in debug lab is deterministic.
- [ ] 20 repeat cycles do not drift transforms.

## Special moves presentation

- [ ] castling moves both correct actors.
- [ ] en passant removes the actual victim square actor.
- [ ] promotion swaps visual archetype after move.
- [ ] promotion after capture works.
- [ ] check cue is non-blocking or bounded.
- [ ] checkmate finishes cleanly into game-over state.

## UX

- [ ] start new human-vs-human game.
- [ ] start new human-vs-engine game.
- [ ] choose side.
- [ ] choose difficulty.
- [ ] restart.
- [ ] undo behaves according to mode policy.
- [ ] skip/fast animations setting.
- [ ] sound volume control.
- [ ] camera shake setting/off.
- [ ] game-over result clear.
- [x] Linux release build launches without editor.

## Licensing/provenance

- [ ] all third-party models/animations logged.
- [ ] all third-party audio/VFX logged.
- [ ] Stockfish version/license/source pointer logged.
- [ ] no ripped/copied Battle Chess assets.
- [ ] shipping title/art reviewed for originality.
