#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
data_root="${CAC_TEST_DATA_HOME:-/tmp/check-and-conquer-godot-data}"
cache_root="${CAC_TEST_CACHE_HOME:-/tmp/check-and-conquer-godot-cache}"
config_root="${CAC_TEST_CONFIG_HOME:-/tmp/check-and-conquer-godot-config}"

tests=(
  tests/test_bootstrap.gd
  tests/chess/test_board_state.gd
  tests/chess/test_pseudo_move_generator.gd
  tests/chess/test_legal_moves.gd
  tests/chess/test_chess_game.gd
  tests/chess/test_turn_controller.gd
  tests/game/test_session_settings.gd
  tests/game/test_campaign_progress.gd
  tests/app/test_main_loading.gd
  tests/app/test_campaign_map.gd
  tests/engine/test_uci_protocol.gd
  tests/engine/test_stockfish_adapter.gd
  tests/presentation/test_board_mapper.gd
  tests/presentation/test_chess_board.gd
  tests/presentation/test_position_loader.gd
  tests/presentation/test_board_camera_controller.gd
  tests/presentation/test_battlefield_environment.gd
  tests/presentation/test_camera_director.gd
  tests/presentation/test_procedural_impact_audio.gd
  tests/presentation/test_arena_audio_director.gd
  tests/presentation/test_weapon_presentation.gd
  tests/presentation/test_battle_death_completion.gd
  tests/presentation/test_melee_polish.gd
  tests/presentation/test_animation_browser.gd
  tests/presentation/test_board_presenter.gd
  tests/presentation/test_capture_projection.gd
  tests/presentation/test_special_move_projection.gd
  tests/presentation/test_choreography_resolver.gd
  tests/presentation/test_signature_delivery_followups.gd
  tests/presentation/test_combat_lab.gd
  tests/presentation/test_local_game_projection.gd
  tests/integration/test_game_screen_stockfish.gd
)

# A clean checkout has source assets and their .import settings, but never the
# generated .godot import cache. Build it before scenes preload those assets.
"$godot_bin" --headless --path "$project_root" --import

for test_path in "${tests[@]}"; do
  test_id="${test_path//\//_}"
  XDG_DATA_HOME="$data_root/$test_id" \
  XDG_CACHE_HOME="$cache_root/$test_id" \
  XDG_CONFIG_HOME="$config_root/$test_id" \
    "$godot_bin" --headless --path "$project_root" --script "$test_path"
done
