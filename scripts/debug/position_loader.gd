extends Node3D

## Deterministic visual reconstruction tool. This scene never mutates a game;
## it validates a FEN then rebuilds the visible actor projection from it.
const BoardState = preload("res://scripts/chess/board_state.gd")

const PRESETS := {
	"Starting position": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
	"Castle both sides": "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1",
	"En passant": "7k/8/8/3pP3/8/8/8/K7 w - d6 0 1",
	"Promotion": "7k/P7/8/8/8/8/7p/7K w - - 0 1",
	"Capture framing": "7k/8/8/3p4/4P3/8/8/K7 w - - 0 1",
}

var current_state


func _ready() -> void:
	for preset_name: String in PRESETS:
		$UI/Preset.add_item(preset_name)
	$UI/Load.pressed.connect(load_fen.bind($UI/FEN.text))
	$UI/Preset.item_selected.connect(_load_preset)
	load_fen(PRESETS["Starting position"])


func load_fen(fen: String) -> bool:
	var validation := validate_fen(fen)
	if not validation.is_empty():
		$UI/Status.text = "FEN not loaded: %s" % validation
		$UI/Status.modulate = Color(1.0, 0.48, 0.42)
		return false
	current_state = BoardState.from_fen(fen)
	$BoardPresenter.rebuild_from_state(current_state)
	$UI/FEN.text = current_state.to_fen()
	$UI/Status.text = "Loaded %d actors • %s to move" % [$BoardPresenter.actor_count(), "White" if current_state.side_to_move > 0 else "Black"]
	$UI/Status.modulate = Color(0.72, 0.9, 0.76)
	return true


func validate_fen(fen: String) -> String:
	var fields := fen.strip_edges().split(" ", false)
	if fields.size() != 6:
		return "expected six FEN fields"
	var ranks := fields[0].split("/", false)
	if ranks.size() != 8:
		return "expected eight board ranks"
	for rank in ranks:
		var files := 0
		for symbol in rank:
			if symbol >= "1" and symbol <= "8":
				files += int(symbol)
			elif not symbol in "prnbqkPRNBQK":
				return "invalid board symbol '%s'" % symbol
			else:
				files += 1
		if files != 8:
			return "every rank must contain eight files"
	if not fields[1] in ["w", "b"]:
		return "side to move must be w or b"
	if fields[2] != "-":
		var seen := {}
		for symbol in fields[2]:
			if not symbol in "KQkq" or seen.has(symbol):
				return "invalid castling rights"
			seen[symbol] = true
	if fields[3] != "-" and (fields[3].length() != 2 or fields[3][0] < "a" or fields[3][0] > "h" or not fields[3][1] in ["3", "6"]):
		return "en passant square must be - or a legal target square"
	if not fields[4].is_valid_int() or int(fields[4]) < 0:
		return "halfmove clock must be zero or greater"
	if not fields[5].is_valid_int() or int(fields[5]) < 1:
		return "fullmove number must be one or greater"
	return ""


func _load_preset(index: int) -> void:
	var label: String = $UI/Preset.get_item_text(index)
	load_fen(PRESETS[label])
