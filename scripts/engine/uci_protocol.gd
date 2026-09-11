class_name UciProtocol
extends RefCounted

static func parse_bestmove(line: String) -> String:
	var fields := line.strip_edges().split(" ", false)
	if fields.size() >= 2 and fields[0] == "bestmove" and fields[1] != "(none)": return fields[1]
	return ""

static func position_command(fen: String) -> String:
	return "position fen %s" % fen

static func go_movetime_command(milliseconds: int) -> String:
	return "go movetime %d" % max(milliseconds, 1)
