class_name CaptureChoreographyResolver
extends RefCounted

## Resolves an attacker archetype to its generic fallback. Exact matchup
## overrides can be added here later without changing BattleDirector.

const Types = preload("res://scripts/chess/chess_types.gd")

const GENERIC_PATHS := {
	Types.PAWN: "res://data/choreography/pawn_generic_sword.tres",
	Types.KNIGHT: "res://data/choreography/knight_generic_charge.tres",
	Types.BISHOP: "res://data/choreography/bishop_generic_strike.tres",
	Types.ROOK: "res://data/choreography/rook_generic_guard.tres",
	Types.QUEEN: "res://data/choreography/queen_generic_command.tres",
	Types.KING: "res://data/choreography/king_generic_command.tres",
}

const SIGNATURE_PATHS := {
	"%d:%d" % [Types.PAWN, Types.QUEEN]: "res://data/choreography/pawn_vs_queen_riposte.tres",
	"%d:%d" % [Types.KNIGHT, Types.PAWN]: "res://data/choreography/knight_vs_pawn_lunge.tres",
	"%d:%d" % [Types.BISHOP, Types.KING]: "res://data/choreography/bishop_vs_king_judgment.tres",
	"%d:%d" % [Types.ROOK, Types.KNIGHT]: "res://data/choreography/rook_vs_knight_breaker.tres",
	"%d:%d" % [Types.QUEEN, Types.ROOK]: "res://data/choreography/queen_vs_rook_command.tres",
	"%d:%d" % [Types.KING, Types.BISHOP]: "res://data/choreography/king_vs_bishop_strike.tres",
}


static func resolve(attacker_type: int) -> CaptureChoreography:
	var path: String = GENERIC_PATHS.get(attacker_type, GENERIC_PATHS[Types.PAWN])
	return load(path) as CaptureChoreography


static func resolve_matchup(attacker_type: int, victim_type: int) -> CaptureChoreography:
	var signature_path: String = SIGNATURE_PATHS.get("%d:%d" % [attacker_type, victim_type], "")
	if not signature_path.is_empty():
		var signature := load(signature_path) as CaptureChoreography
		if signature != null:
			return signature
	return resolve(attacker_type)
