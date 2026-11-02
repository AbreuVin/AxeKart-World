extends TestBase
## Física do kart: aceleração, grama, barreira, ré, curva e mini-turbo.


func _initialize() -> void:
	print("[test_kart]")
	var t := make_track()

	var k := make_kart(t)
	k.controls_enabled = true
	simulate(k, 0.5, {"throttle": 0.0, "brake": 0.0, "steer": 0.0, "drift": false})
	check(absf(k.speed) < 0.01, "parado sem acelerar")
	simulate(k, 2.5, {"throttle": 1.0, "brake": 0.0, "steer": 0.0, "drift": false})
	check(k.speed > 25.0 and k.speed <= k.max_speed + 0.01, "acelera até perto da máxima (%.1f m/s)" % k.speed)

	# curva: virar à direita diminui o heading
	var h0 := k.heading
	simulate(k, 0.3, {"throttle": 1.0, "brake": 0.0, "steer": 1.0, "drift": false})
	check(k.heading < h0, "direita gira no sentido horário")

	# grama
	var k2 := make_kart(t, 1)
	k2.controls_enabled = true
	var i := 100
	k2.position = t.samples[i] + t.right_at(i) * (t.road_width * 0.5 + 3.0)
	k2.heading = atan2(-t.tangents[i].x, -t.tangents[i].z)
	k2.track_index = i
	k2.speed = k2.max_speed
	simulate(k2, 0.6, {"throttle": 1.0, "brake": 0.0, "steer": 0.0, "drift": false})
	check(k2.offroad, "detecta grama")
	check(k2.speed < k2.max_speed * 0.6, "grama reduz velocidade (%.1f)" % k2.speed)

	# barreira
	var k3 := make_kart(t, 2)
	k3.controls_enabled = true
	k3.position = t.samples[i] + t.right_at(i) * 40.0
	k3.track_index = i
	k3.step(1.0 / 60.0)
	check(absf(k3.lateral) <= t.road_width * 0.5 + Track.BARRIER_EXTRA + 0.01, "barreira segura o kart")

	# ré
	var k4 := make_kart(t, 3)
	k4.controls_enabled = true
	simulate(k4, 2.0, {"throttle": 0.0, "brake": 1.0, "steer": 0.0, "drift": false})
	check(k4.speed < 0.0 and k4.speed >= -k4.reverse_max, "dá ré limitada (%.1f)" % k4.speed)

	# drift + mini-turbo
	var k5 := make_kart(t, 0)
	k5.controls_enabled = true
	k5.speed = 28.0
	simulate(k5, 0.1, {"throttle": 1.0, "brake": 0.0, "steer": 1.0, "drift": true})
	check(k5.drifting, "entra em drift")
	simulate(k5, 1.2, {"throttle": 1.0, "brake": 0.0, "steer": 0.6, "drift": true})
	simulate(k5, 1.0 / 60.0, {"throttle": 1.0, "brake": 0.0, "steer": 0.0, "drift": false})
	check(not k5.drifting and k5.boost_time > 0.0, "soltar o drift carregado dá turbo")

	# sem controles (antes do VAI!) não anda
	var k6 := make_kart(t, 1)
	simulate(k6, 1.0, {"throttle": 1.0, "brake": 0.0, "steer": 0.0, "drift": false})
	check(absf(k6.speed) < 0.01, "travado antes da largada")
	finish()
