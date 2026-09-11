# Testing

Run the bootstrap gate from the repository root:

```sh
XDG_DATA_HOME=/tmp/warboard-godot-data \
  XDG_CACHE_HOME=/tmp/warboard-godot-cache \
  XDG_CONFIG_HOME=/tmp/warboard-godot-config \
  godot --headless --path . --script res://tests/test_bootstrap.gd
```

The XDG overrides keep Godot's transient logs, caches, and user data outside the repository and make the command work in restricted or CI environments. This headless check loads and instantiates the main scene plus the three required debug scenes. Future milestones should add focused test scripts beside their domain or integration work and document their commands here.

Run the deterministic M1 cycle gate with:

```sh
XDG_DATA_HOME=/tmp/warboard-godot-data \
  XDG_CACHE_HOME=/tmp/warboard-godot-cache \
  XDG_CONFIG_HOME=/tmp/warboard-godot-config \
  godot --headless --path . --script res://tests/presentation/test_combat_lab.gd
```

It executes twenty Play/Reset cycles at an accelerated simulation rate, confirming victim cleanup, exact attacker settlement, and transform reset without drift.

Run the Animation Browser full-character variant test with:

```sh
godot --headless --path . --script res://tests/presentation/test_animation_browser.gd
```

Run the M2 board-state gate with:

```sh
XDG_DATA_HOME=/tmp/warboard-godot-data \
  XDG_CACHE_HOME=/tmp/warboard-godot-cache \
  XDG_CONFIG_HOME=/tmp/warboard-godot-config \
  godot --headless --path . --script res://tests/chess/test_board_state.gd
```

Run legal-move generation and the required start-position perft gate with:

```sh
XDG_DATA_HOME=/tmp/warboard-godot-data \
  XDG_CACHE_HOME=/tmp/warboard-godot-cache \
  XDG_CONFIG_HOME=/tmp/warboard-godot-config \
  godot --headless --path . --script res://tests/chess/test_legal_moves.gd
```

The expected perft counts are depth 1 = 20, depth 2 = 400, depth 3 = 8,902, and depth 4 = 197,281.

Run deterministic board mapping tests with:

```sh
godot --headless --path . --script res://tests/presentation/test_board_mapper.gd
```

Run the capture-camera restore test with:

```sh
godot --headless --path . --script res://tests/presentation/test_camera_director.gd
```

Run full capture death-timing validation with:

```sh
godot --headless --path . --script res://tests/presentation/test_battle_death_completion.gd
```

Run the board-camera control test with:

```sh
godot --headless --path . --script res://tests/presentation/test_board_camera_controller.gd
```

The current manual demo path is `godot --path .` → **Play vs Stockfish**. Click a piece and a destination square, or enter a UCI move. Right-drag rotates the board, middle-drag pans its focus, and the mouse wheel zooms. Use `Debug Position Loader` to exercise FEN reconstruction and **Animation Browser** to preview every full-character archetype.

Run a scripted local-game smoke test with:

```sh
godot --headless --path . --script res://tests/presentation/test_local_game_projection.gd
```

Run authoritative FEN-to-actor rebuild validation with:

```sh
godot --headless --path . --script res://tests/presentation/test_board_presenter.gd
```

Run the Stockfish integration gate with the supplied Linux executable present:

```sh
XDG_DATA_HOME=/tmp/warboard-godot-data \
  XDG_CACHE_HOME=/tmp/warboard-godot-cache \
  XDG_CONFIG_HOME=/tmp/warboard-godot-config \
  godot --headless --path . --script res://tests/engine/test_stockfish_adapter.gd
```

It launches the real UCI process, verifies its handshake, and validates 100 sequential returned moves through the independent chess domain.

Run the playable-screen opponent smoke test with:

```sh
XDG_DATA_HOME=/tmp/warboard-godot-data \
  XDG_CACHE_HOME=/tmp/warboard-godot-cache \
  XDG_CONFIG_HOME=/tmp/warboard-godot-config \
  godot --headless --path . --script res://tests/integration/test_game_screen_stockfish.gd
```

It submits `e2e4` through the actual screen flow, verifies that one Stockfish response is presented before input unlocks, then switches sides and verifies Stockfish opens as White. It also disables the engine, verifies a two-human local opening, reaches checkmate through the screen controls, validates a complete staged capture with camera restoration, and confirms persisted local-play, capture-speed, camera-shake, and master-volume preferences after a screen relaunch.
