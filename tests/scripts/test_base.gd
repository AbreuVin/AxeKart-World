class_name TestBase
extends SceneTree
## Base dos runners headless: check() registra falhas; finish() sai com código.

var failures := 0
var passes := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
		print("  ok   ", msg)
	else:
		failures += 1
		printerr("  FALHA ", msg)


func finish() -> void:
	print("%d ok, %d falhas" % [passes, failures])
	quit(1 if failures > 0 else 0)


func make_track() -> Track:
	var t := Track.new()
	root.add_child(t)
	t.setup(DataLoader.load_track("circuito_teste"), false)
	return t


func make_kart(t: Track, slot := 0) -> Kart:
	var k := Kart.new()
	k.track = t
	root.add_child(k)
	k.place(t.grid_transform(slot))
	return k


func simulate(k: Kart, seconds: float, inp: Dictionary) -> void:
	k.input = inp.duplicate()
	var steps := int(seconds * 60.0)
	for i in steps:
		k.step(1.0 / 60.0)
