class_name CpuDriver
extends RefCounted
## Piloto automático: segue a linha central com deslocamento lateral próprio.

var kart: Kart
var skill := 0.94          # fração da velocidade máxima
var lane := 0.0            # deslocamento lateral preferido (m)
var lookahead := 7         # amostras à frente
var _wobble := 0.0


func _init(k: Kart, s := 0.94, l := 0.0) -> void:
	kart = k
	skill = s
	lane = l
	kart.max_speed *= skill


func update(delta: float) -> void:
	var tr := kart.track
	if tr == null:
		return
	_wobble += delta
	var n := tr.sample_count()
	var i := (maxi(kart.track_index, 0) + lookahead) % n
	var lane_now := lane + sin(_wobble * 0.4) * 1.5
	var target := tr.samples[i] + tr.right_at(i) * lane_now
	var to := target - kart.position
	var local_x := to.dot(kart.right())
	var local_z := to.dot(kart.forward())
	var angle := atan2(local_x, maxf(local_z, 0.1))
	kart.input.steer = clampf(angle * 2.2, -1.0, 1.0)
	# curva fechada à frente → alivia
	var far := tr.tangents[(i + lookahead * 2) % n]
	var sharp := 1.0 - far.dot(kart.forward())
	kart.input.throttle = 0.55 if sharp > 0.5 and kart.speed > kart.max_speed * 0.7 else 1.0
	kart.input.brake = 0.0
	kart.input.drift = false
