# Project Warboard — Agent Handoff Pack

This folder is intended to be copied into the root of a new Godot/Codex repository.

## Start here

1. Put the files in the repository root.
2. Open Codex in that repository.
3. Paste the contents of `KICKOFF_PROMPT.md` into the root agent session.
4. Let the root agent read and implement the plan milestone-by-milestone.

The master specification is `BATTLE_CHESS_MASTER_PLAN.md`.

## Bootstrap

The project is pinned to Godot 4.7.2 stable. Launch the debug menu with:

```sh
godot --path .
```

The current demo path is **Play vs Stockfish**. It starts with the player as White against Stockfish as Black; use the toggle to switch to local two-player mode, or choose Black and let Stockfish open. Click a source and destination, or enter UCI such as `e2e4`. Choose a difficulty, capture speed, and promotion piece from the controls. Right-drag rotates the board and the mouse wheel zooms; captures temporarily use their own action shot before restoring that view. The in-game button toggles fullscreen. Camera shake, volume, capture speed, game mode, side, difficulty, and fullscreen persist between launches. The chess domain validates every submitted move before the visual actor moves.

Run the headless bootstrap gate with the command in [`docs/TESTING.md`](docs/TESTING.md).

See [docs/BUILDING.md](docs/BUILDING.md) for launch controls and the complete headless verification command.

The Linux release exporter is `bash tools/export_linux.sh`; it stages the external Stockfish executable and its license/source material beside the exported game.

## Why multiple files?

- `BATTLE_CHESS_MASTER_PLAN.md` is the product/technical source of truth.
- `AGENTS.md` gives durable repo-level agent behavior and architecture boundaries.
- `docs/ROADMAP.md` keeps milestone order explicit.
- `docs/ASSET_PIPELINE.md` isolates the highest-risk 3D workflow.
- `docs/ACCEPTANCE_CRITERIA.md` prevents agents from calling incomplete work “done.”
- `docs/DECISIONS.md` prevents architecture drift.
- `KICKOFF_PROMPT.md` starts the root agent with the right priorities.

Working title only. Do not ship under “Battle Chess” without an independent naming/IP review.
