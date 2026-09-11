# Warchessed

**Warchessed** is an original 3D chess game where every legal move plays out on a living battlefield. Chess rules remain authoritative; animated duels give captures their drama.

![Status](https://img.shields.io/badge/status-prototype-gold) ![Engine](https://img.shields.io/badge/Godot-4.7.2-blue) ![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)

[![Test](https://github.com/joega/warboard/actions/workflows/test.yml/badge.svg)](https://github.com/joega/warboard/actions/workflows/test.yml)

## What you can play today

- A complete local chess rules engine: legal move validation, castling, en passant, promotion, checkmate, draws, FEN, and UCI moves.
- Play versus Stockfish 19, with selectable side and beginner-to-master campaign difficulty that rises gradually by arena, plus a Stockfish-versus-Stockfish spectator mode.
- A five-stop campaign route: win Mountain Fortress Terrace, Arcane Sky Citadel, Frozen Keep, and Lava Forge to unlock the final Forest Ruins match.
- An animated 3D board with six readable fantasy archetypes, full outfits, detailed faces, role-specific hair, and distinct weapons.
- Walk animations for ordinary moves and cinematic capture choreography with impact effects, death reactions, camera framing, and a skip control.
- A stable player-side board view that remains behind the human player while Stockfish moves across the board. Five themed grand arenas use original generated 360° panoramas, local stone terraces, and arena-specific lighting. Right-drag orbits, middle-drag pans to any character, and the mouse wheel zooms to face level.
- Post-game move review and one-click PGN copy built from authoritative snapshots, plus debug scenes for replaying combat, browsing animations, and rebuilding the board from a FEN position.

Warchessed is early in development. The focus is a polished offline Linux prototype before any distribution features are considered.

## Run it

### Requirements

- [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/)
- Linux (the Stockfish integration and export target are Linux-specific)
- A local Stockfish 19 Linux x86-64 executable at `third_party/stockfish/linux-x86_64/stockfish/stockfish-linux-x86-64-universal`

The Stockfish executable is excluded from Git because of its size. Download the
Linux x86-64 universal build from the [official Stockfish site](https://stockfishchess.org/download/),
place it at the path above, and ensure it is executable. The committed source
tree and GPL notice provide the corresponding-source material used by releases.

Open the project in Godot or run:

```sh
godot --path .
```

The game opens directly on **The Warpath**. Win the current arena to unlock the next location, then select it from the campaign route. **Practice Arena** on the lower right starts a Quick Match versus Stockfish without advancing the route; the current developer tools sit on the lower left. Select a piece and then a highlighted square to move it. The board stays clear during play; the full-width **Menu** contains restart, undo, controls, side, campaign difficulty, spectator mode, promotion, animation speed, audio, fullscreen, and engine diagnostics. Each arena has an original procedural music bed, and board landings plus sword, spear, bow, arcane, hammer, and wall attacks have distinct effects.

## Development

Run the deterministic test suite, including chess perft and the real Stockfish subprocess test:

```sh
bash tools/run_headless_tests.sh
```

GitHub Actions runs the same suite on pushes and pull requests. It compiles the
committed Stockfish source into a temporary CI executable, so the real engine
integration remains covered without committing the large platform binary.

Create a Linux export with Godot's matching export templates installed:

```sh
bash tools/export_linux.sh
```

The exporter creates `build/linux-x86_64/` and places Stockfish beside the game executable so Godot can launch it as a UCI process.

## Design principles

- Standard chess rules decide every outcome. The combat layer is presentation only.
- The pure chess domain owns the game state; 3D actors can be rebuilt from it at any time.
- Stockfish is an isolated UCI subprocess whose moves are independently validated before use.
- Every capture pairing has a generic fallback before bespoke choreography is added.
- Campaign progress is a small pure game-layer model. Arena visuals are presentation-only, so every standard chess match remains rebuildable and portable between locations.
- Warchessed uses original presentation and does not reproduce art, animations, audio, UI, or branding from any existing chess-combat game.

## Credits and licenses

Character models, outfits, and animation source packs are by [Quaternius](https://quaternius.com/) under CC0 1.0. The bundled chess engine is [Stockfish](https://stockfishchess.org/), distributed under GPLv3; its executable, source, and notices are staged with Linux exports. Godot is MIT licensed.

See [third-party asset provenance](assets/THIRD_PARTY_ASSETS.md) and [third-party software notices](docs/THIRD_PARTY_SOFTWARE.md) for the complete record.

## Project status

The playable prototype has passed chess perft through depth 4, real-process Stockfish integration, repeatable combat reset checks, and a Linux export smoke launch. Current development is focused on visual polish, camera/input refinement, and human release review.

## Contributing

This project is currently developed in public while the prototype takes shape. Issues and pull requests are welcome when they preserve the separation between chess rules, engine integration, gameplay orchestration, and presentation.
