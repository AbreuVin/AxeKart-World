extends TestBase
## Dados: pilotos e pista carregam e obedecem o contrato.


func _initialize() -> void:
	print("[test_data]")
	var karts := DataLoader.load_karts()
	check(karts.size() >= 4, "pelo menos 4 pilotos (%d)" % karts.size())
	for d in karts:
		check(d.has("id") and d.has("display_name"), "kart %s tem id e display_name" % d.get("id"))
		var tex = load("%s/%s" % [d.base_dir, d.get("sprite", "")])
		check(tex is Texture2D, "sprite de %s carrega" % d.get("id"))
		if tex is Texture2D:
			check(tex.get_width() == 256 * int(d.get("frames", 8)) and tex.get_height() == 256,
				"folha de %s segue o contrato 8x256" % d.get("id"))
		check(not d.get("placeholder", false) or not d.get("aprovado_por_pessoa", false),
			"placeholder de %s não finge ser pessoa real" % d.get("id"))
		check(String(d.get("vulgo", "")) != "", "%s tem vulgo do Axé Fight" % d.get("id"))
		if d.has("cabeca"):
			check(FileAccess.file_exists("%s/%s" % [d.base_dir, d.cabeca]), "cabeça de %s existe" % d.get("id"))
	check(karts[0].get("id") == "vinicius", "Vinicius é o piloto do jogador (amostra)")
	var t := make_track()
	check(t.total_length > 600.0, "pista com mais de 600 m (%.0f m)" % t.total_length)
	check(t.samples[0].distance_to(t.samples[t.sample_count() - 1]) < 15.0, "pista fechada")
	check(t.laps == 3, "3 voltas")
	# grid não sobrepõe e fica na pista
	for s in 4:
		var g := t.grid_transform(s)
		var info := t.nearest(g.origin)
		check(absf(info.lateral) < t.road_width * 0.5, "largada %d dentro da pista" % s)
		check(info.fraction > 0.9, "largada %d antes da linha" % s)
	# pista do Café & Lounge Axélab
	var c := Track.new()
	root.add_child(c)
	c.setup(DataLoader.load_track("cafe_lounge"), false)
	check(c.total_length > 500.0, "Café & Lounge com mais de 500 m (%.0f m)" % c.total_length)
	check(String(c.data.get("tema", "")) == "interno", "Café & Lounge é pista interna")
	for s in 4:
		var info := c.nearest(c.grid_transform(s).origin)
		check(absf(info.lateral) < c.road_width * 0.5 and info.fraction > 0.9, "largada %d ok no Café & Lounge" % s)
	for key in ["norte", "sul", "leste", "oeste"]:
		var rel := String(c.data.paredes.get(key, ""))
		check(ResourceLoader.exists("res://assets/tracks/cafe_lounge/" + rel), "parede %s com arte do Axé Fight" % key)
	var b := c.bounds()
	var inside := true
	for p in c.samples:
		if not b.grow(-Track.ROOM_MARGIN + 8.0).has_point(Vector2(p.x, p.z)):
			inside = false
	check(inside, "pista inteira dentro da sala")
	finish()
