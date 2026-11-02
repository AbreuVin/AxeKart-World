class_name DataLoader
extends RefCounted
## Carrega pilotos e pistas a partir das pastas de dados (arquitetura orientada a dados).

const KARTS_DIR := "res://assets/karts"
const TRACKS_DIR := "res://assets/tracks"


static func read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Não abriu %s" % path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


static func load_karts() -> Array:
	var out: Array = []
	var dir := DirAccess.open(KARTS_DIR)
	if dir == null:
		return out
	for sub in dir.get_directories():
		var path := "%s/%s/kart.json" % [KARTS_DIR, sub]
		if not FileAccess.file_exists(path):
			continue
		var d := read_json(path)
		if d.is_empty():
			continue
		d["base_dir"] = "%s/%s" % [KARTS_DIR, sub]
		out.append(d)
	out.sort_custom(func(a, b): return int(a.get("ordem", 99)) < int(b.get("ordem", 99)))
	return out


static func load_track(track_id: String) -> Dictionary:
	return read_json("%s/%s/track.json" % [TRACKS_DIR, track_id])
