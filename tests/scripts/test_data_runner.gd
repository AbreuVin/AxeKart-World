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
			check(tex.get_width() == 128 * int(d.get("frames", 8)) and tex.get_height() == 128,
				"folha de %s segue o contrato 8x128" % d.get("id"))
		check(not d.get("placeholder", false) or not d.get("aprovado_por_pessoa", false),
			"placeholder de %s não finge ser pessoa real" % d.get("id"))
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
	finish()
