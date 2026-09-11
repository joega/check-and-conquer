# Architecture

The project begins with the layer boundaries defined in the master plan:

| Area | Responsibility |
| --- | --- |
| `scripts/chess/` | Pure chess state, move generation, FEN/UCI, and results. |
| `scripts/engine/` | Stockfish UCI process lifecycle and parsing. |
| `scripts/game/` | Turn phases, player configuration, and session history. |
| `scripts/presentation/` | Board projection, combat direction, camera, choreography resolution, and arena skinning. |
| `scripts/actors/` | Visual actor animation, movement, facing, and materials. |

Chess state will be authoritative. Presentation receives structured move results and must be able to rebuild from the domain state. The M0 debug-menu scripts are deliberately isolated in `scripts/app/` and `scripts/debug/`; they define no chess or combat interfaces.

## Current domain and presentation contract

`ChessGame.try_uci()` validates a UCI request against legal domain moves, commits it, and returns a `MoveResult` with capture, en-passant, castling, promotion, check, and before/after-FEN facts. `BoardPresenter` consumes those committed facts and exact square/world mapping; it does not calculate chess legality. It can validate and rebuild its actor projection from domain state after a presentation failure.

`StockfishAdapter` owns the UCI executable through Godot's nonblocking process pipes. It performs `uci`/`isready` handshake, applies UCI strength options, sends FEN positions, enforces a response deadline, and emits a parsed bestmove. `TurnController` accepts that bestmove only while in `ENGINE_THINKING`, then sends it through the same domain validation path as a human UCI submission.

`CaptureChoreographyResolver` maps every attacker/victim archetype pairing to a data resource. `BattleDirector` uses only that resource and visual actors, waits for the active death clip to complete, and can run at cinematic or quick speed. `CameraDirector` suspends board orbit input and stages a fixed action shot; `GameScreen` then applies the next player’s default board transform directly. Neither can mutate chess state.

`CampaignProgress` is a pure `scripts/game/` model for the ordered five-location route. It persists primitive snapshots, unlocks exactly one next arena after an authoritative player victory, and has no Node, chess, engine, or rendering dependency. `CampaignMap` only selects its current unlocked destination. `ArenaCatalog` and `BattlefieldEnvironment` map that selected ID to a panorama, local terrace materials, lighting, and decorative markers; they never change rules, positions, or combat anchors.
