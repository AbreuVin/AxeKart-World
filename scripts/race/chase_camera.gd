class_name ChaseCamera
extends Camera3D
## Câmera atrás do kart, com suavização e FOV maior no turbo.

var target: Kart
var distance := 7.5
var height := 3.0
var _look := Vector3.ZERO


func snap() -> void:
	if target == null:
		return
	global_position = _desired()
	_look = target.global_position + target.forward() * 4.0 + Vector3.UP
	look_at(_look, Vector3.UP)


func _desired() -> Vector3:
	return target.global_position - target.forward() * distance + Vector3.UP * height


func _process(delta: float) -> void:
	if target == null:
		return
	var k := 1.0 - exp(-7.0 * delta)
	global_position = global_position.lerp(_desired(), k)
	var look_target := target.global_position + target.forward() * 4.0 + Vector3.UP
	_look = _look.lerp(look_target, 1.0 - exp(-12.0 * delta))
	look_at(_look, Vector3.UP)
	var want_fov := 78.0 if target.boost_time > 0.0 else 70.0
	fov = lerpf(fov, want_fov, 1.0 - exp(-5.0 * delta))
