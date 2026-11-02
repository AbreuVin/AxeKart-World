extends TestBase
## Corrida completa em modo headless: CPUs fazem 3 voltas, contagem de voltas e chegada.


var _ran := false


func _process(_delta: float) -> bool:
	if not _ran:
		_ran = true
		_run()
	return false


func _run() -> void:
	print("[test_race]")
	var race := Race.new()
	race.headless = true
	race.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(race)
	check(race.karts.size() >= 4, "4 karts no grid")

	# jogador também no piloto automático para o teste
	var auto := CpuDriver.new(race.player, 1.0, 0.0)
	var dt := 1.0 / 60.0
	var sim := 0.0
	var all_done := false
	while sim < 400.0 and not all_done:
		auto.update(dt)
		race._physics_process(dt)
		sim += dt
		all_done = race.karts.all(func(k): return k.is_finished)
	check(all_done, "todos terminam as 3 voltas (%.0f s simulados)" % sim)
	for k in race.karts:
		check(k.laps_done == 3, "%s fez 3 voltas" % k.name)
		check(k.best_lap > 15.0 and k.best_lap < 90.0, "%s melhor volta plausível (%.1f s)" % [k.name, k.best_lap])
	check(race.finish_order.size() == race.karts.size(), "ordem de chegada completa")
	var st := race.standings()
	check(st[0] == race.finish_order[0], "1º colocado = 1º a chegar")

	# volta pela contramão não conta
	var t := race.track
	var k := make_kart(t, 0)
	k.start_race()
	var n := t.sample_count()
	for step in 3 * n:
		var i := (n - (step % n) + n / 2) % n
		k.position = t.samples[i]
		k.step(dt)
	check(k.laps_done == 0, "contramão não conta volta")

	# atalho (pular checkpoints) não conta
	var k2 := make_kart(t, 1)
	k2.start_race()
	for i in range(int(n * 0.9), n):
		k2.position = t.samples[i]
		k2.step(dt)
	for rep in 3:
		for i in range(0, int(n * 0.1)):
			k2.position = t.samples[i]
			k2.step(dt)
		for i in range(int(n * 0.9), n):
			k2.position = t.samples[i]
			k2.step(dt)
	check(k2.laps_done == 0, "atalho pela linha não conta volta")
	finish()
