class_name Race
extends Node3D
## Monta a corrida: pista, karts (1 jogador + CPUs), câmera, HUD, contagem e chegada.

const TRACK_ID := "circuito_teste"
const COUNTDOWN := 3.0
const CPU_SKILLS := [0.95, 0.92, 0.89]
const CPU_LANES := [-2.5, 2.5, 0.0]

var track: Track
var karts: Array[Kart] = []
var player: Kart
var cpus: Array[CpuDriver] = []
var camera: ChaseCamera
var hud: RaceHud
var countdown := COUNTDOWN
var started := false
var finish_order: Array[Kart] = []
var headless := false


func _ready() -> void:
	PlayerInput.ensure_actions()
	_build_environment()
	track = Track.new()
	track.name = "Track"
	add_child(track)
	track.setup(DataLoader.load_track(TRACK_ID), not headless)

	var datas := DataLoader.load_karts()
	for slot in datas.size():
		var d: Dictionary = datas[slot]
		var k := Kart.new()
		k.name = "Kart_%s" % d.get("id", slot)
		k.data = d
		k.track = track
		add_child(k)
		k.place(track.grid_transform(slot))
		k.finished.connect(_on_finished)
		if not headless:
			var spr := KartSprite.new()
			k.add_child(spr)
			spr.setup(k, d.base_dir, d)
		karts.append(k)
	player = karts[0]
	for i in range(1, karts.size()):
		cpus.append(CpuDriver.new(karts[i], CPU_SKILLS[(i - 1) % 3], CPU_LANES[(i - 1) % 3]))

	if not headless:
		camera = ChaseCamera.new()
		camera.current = true
		add_child(camera)
		camera.target = player
		camera.snap()
		hud = RaceHud.new()
		add_child(hud)


func _build_environment() -> void:
	if headless:
		return
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#2b7bd6")
	sm.sky_horizon_color = Color("#bfe3ff")
	sm.ground_horizon_color = Color("#bfe3ff")
	sm.ground_bottom_color = Color("#3d7a3a")
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.8
	e.fog_enabled = true
	e.fog_light_color = Color("#bfe3ff")
	e.fog_density = 0.004
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	add_child(sun)


func _physics_process(delta: float) -> void:
	if not started:
		countdown -= delta
		if hud:
			var n := int(ceil(countdown))
			hud.show_center(str(n) if n > 0 else "VAI!")
		if countdown <= 0.0:
			started = true
			for k in karts:
				k.start_race()
	elif hud and countdown > -1.0:
		countdown -= delta
		if countdown <= -1.0:
			hud.show_center("")

	if started and not headless:
		PlayerInput.read_into(player)
	for c in cpus:
		c.update(delta)
	for k in karts:
		k.step(delta)

	if hud:
		hud.update_race(player, player_position(), karts.size(), track.laps)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/ui/FrontEnd.tscn")


func standings() -> Array[Kart]:
	var arr: Array[Kart] = karts.duplicate()
	arr.sort_custom(func(a: Kart, b: Kart):
		if a.is_finished and b.is_finished:
			return a.finish_time < b.finish_time
		if a.is_finished != b.is_finished:
			return a.is_finished
		return a.race_progress() > b.race_progress())
	return arr


func player_position() -> int:
	return standings().find(player) + 1


func _on_finished(k: Kart, _t: float) -> void:
	finish_order.append(k)
	if k == player and hud:
		hud.show_center("CHEGADA!", InterfaceTheme.P1)
		var lines := "RESULTADO\n\n"
		var order := standings()
		for i in order.size():
			var kk: Kart = order[i]
			var t := RaceHud.fmt(kk.finish_time) if kk.is_finished else "correndo..."
			lines += "%dº  %s   %s\n" % [i + 1, RaceHud.pilot_name(kk.data), t]
		lines += "\nMelhor volta: %s\n\nR para correr de novo" % RaceHud.fmt(player.best_lap)
		hud.show_result(lines)
