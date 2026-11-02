class_name Kart
extends Node3D
## Kart arcade determinístico. Não lê teclado: a entrada vem de `input`,
## preenchida pelo jogador (player_input.gd) ou pela CPU (cpu_driver.gd).

signal lap_completed(kart: Kart, lap_time: float)
signal finished(kart: Kart, total_time: float)

# --- ajuste fino (m/s, m/s², rad/s) ---
var max_speed := 32.0
var accel := 20.0
var brake_force := 42.0
var reverse_max := 8.0
var coast := 7.0
var turn_rate := 1.9
var boost_mult := 1.35
var drift_min_speed := 12.0

# --- estado ---
var data: Dictionary = {}
var track: Track
var input := {"throttle": 0.0, "brake": 0.0, "steer": 0.0, "drift": false}
var controls_enabled := false
var speed := 0.0
var heading := 0.0
var offroad := false
var drifting := false
var drift_dir := 0
var drift_charge := 0.0
var boost_time := 0.0
var bumped := false

# --- corrida ---
var track_index := -1
var lateral := 0.0
var fraction := 0.0
var crossed_start := false
var laps_done := 0
var checkpoints := 0  # bits: 1 = 1/3 da pista, 2 = 2/3
var lap_start_time := 0.0
var best_lap := INF
var last_lap := 0.0
var is_finished := false
var finish_time := 0.0
var race_time := 0.0


func forward() -> Vector3:
	return Vector3(-sin(heading), 0.0, -cos(heading))


func right() -> Vector3:
	return Vector3(cos(heading), 0.0, -sin(heading))


func place(t: Transform3D) -> void:
	position = t.origin
	heading = atan2(-(t.basis * Vector3.FORWARD).x, -(t.basis * Vector3.FORWARD).z)
	rotation = Vector3(0, heading, 0)
	speed = 0.0
	if track:
		var info := track.nearest(position)
		track_index = info.index
		fraction = info.fraction
		lateral = info.lateral


func km_h() -> float:
	return absf(speed) * 3.6


## Progresso total na corrida (voltas + fração). Usado para a classificação.
func race_progress() -> float:
	if not crossed_start:
		return fraction - 1.0
	return laps_done + fraction


func step(delta: float) -> void:
	if controls_enabled:
		race_time += delta
	var throttle: float = input.throttle if controls_enabled else 0.0
	var brake: float = input.brake if controls_enabled else 0.0
	var steer: float = clampf(input.steer, -1.0, 1.0) if controls_enabled else 0.0
	var drift_held: bool = bool(input.drift) and controls_enabled
	if is_finished:
		throttle = 0.0
		brake = 0.4

	# drift / mini-turbo
	if drift_held and not drifting and absf(steer) > 0.3 and speed > drift_min_speed and not offroad:
		drifting = true
		drift_dir = 1 if steer > 0.0 else -1
		drift_charge = 0.0
	if drifting:
		drift_charge += delta * (1.0 + 0.6 * absf(steer))
		if not drift_held or speed < drift_min_speed * 0.7 or offroad:
			if drift_charge > 0.7:
				boost_time = 0.5 + minf(drift_charge, 2.5) * 0.35
			drifting = false
			drift_dir = 0
	if boost_time > 0.0:
		boost_time = maxf(0.0, boost_time - delta)

	# velocidade
	var cap := max_speed * (Track.OFFROAD_SPEED if offroad else 1.0) * (boost_mult if boost_time > 0.0 else 1.0)
	if boost_time > 0.0:
		speed += accel * 1.6 * delta
	elif throttle > 0.0 and speed < cap:
		speed = minf(speed + accel * throttle * delta, cap)
	elif brake > 0.0:
		speed -= (brake_force if speed > 0.5 else accel * 0.6) * brake * delta
	else:
		speed = move_toward(speed, 0.0, coast * delta)
	if speed > cap:
		speed = move_toward(speed, cap, 28.0 * delta)
	speed = clampf(speed, -reverse_max, max_speed * boost_mult)

	# direção
	var grip := clampf(absf(speed) / 8.0, 0.0, 1.0)
	var turn := steer
	if drifting:
		turn = drift_dir * 0.6 + steer * 0.5
		grip *= 1.2
	var dir_sign := 1.0 if speed >= 0.0 else -1.0
	heading -= turn * turn_rate * grip * dir_sign * delta

	# movimento (drift desliza um pouco para fora da curva)
	var slide := right() * (-drift_dir * speed * 0.12) if drifting else Vector3.ZERO
	position += (forward() * speed + slide) * delta
	rotation = Vector3(0, heading, 0)

	_update_track(delta)


func _update_track(_delta: float) -> void:
	if track == null:
		return
	var info := track.nearest(position, track_index)
	track_index = info.index
	lateral = info.lateral
	var hw := track.road_width * 0.5
	offroad = absf(lateral) > hw + Track.CURB_WIDTH
	var limit := hw + Track.BARRIER_EXTRA
	bumped = false
	if absf(lateral) > limit:
		position -= info.right * (absf(lateral) - limit) * signf(lateral)
		speed *= 0.6
		bumped = true
		lateral = limit * signf(lateral)

	var f: float = info.fraction
	var prev := fraction
	# cruzou a linha para frente
	if prev > 0.75 and f < 0.25:
		if not crossed_start:
			crossed_start = true  # a 1ª volta conta desde o "VAI!"
		elif checkpoints == 3 and not is_finished:
			last_lap = race_time - lap_start_time
			best_lap = minf(best_lap, last_lap)
			lap_start_time = race_time
			laps_done += 1
			checkpoints = 0
			lap_completed.emit(self, last_lap)
			if laps_done >= track.laps:
				is_finished = true
				finish_time = race_time
				finished.emit(self, race_time)
	# cruzou para trás: invalida a volta em andamento
	elif prev < 0.25 and f > 0.75:
		checkpoints = 0
		if crossed_start and laps_done == 0:
			crossed_start = false
	if f > 0.3 and f < 0.5:
		checkpoints |= 1
	elif f > 0.6 and f < 0.8 and (checkpoints & 1) != 0:
		checkpoints |= 2
	fraction = f


## Corrida começa no "VAI!": zera o relógio da volta.
func start_race() -> void:
	controls_enabled = true
	race_time = 0.0
	lap_start_time = 0.0
