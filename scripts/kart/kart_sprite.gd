class_name KartSprite
extends Sprite3D
## Sprite 2.5D: escolhe 1 de N quadros conforme o ângulo da câmera em volta do kart.
## Contrato da folha: docs/DESIGN_GUIDE.md.

var kart: Kart
var frames := 8
var _bob := 0.0


func setup(k: Kart, base_dir: String, d: Dictionary) -> void:
	kart = k
	frames = int(d.get("frames", 8))
	texture = load("%s/%s" % [base_dir, d.get("sprite", "sprites/sheet.png")])
	hframes = frames
	pixel_size = float(d.get("pixel_size", 0.025))
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = false
	centered = true
	# origem nos pés: o quadro tem 8 px de chão abaixo das rodas
	offset = Vector2(0, 64 - 8)


func _process(delta: float) -> void:
	if kart == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var v := cam.global_position - kart.global_position
	# ângulo da câmera ao redor do kart: 0 = atrás, positivo = à direita do kart
	var lx := v.dot(kart.right())
	var lz := -v.dot(kart.forward())
	var theta := atan2(lx, lz)
	if kart.drifting:
		theta -= kart.drift_dir * 0.45
	var k := int(round(theta / (TAU / frames)))
	frame = posmod(k, frames)
	# leve vibração do motor
	_bob += delta * (8.0 + kart.km_h() * 0.15)
	position.y = 0.03 * sin(_bob) if absf(kart.speed) > 1.0 else 0.0
