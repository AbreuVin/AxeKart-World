class_name FrontEnd
extends Control
## Tela inicial do AxéKart: mesma família da tela do AxéFight
## (marca com raios ciano e dourados, névoa/poeira leve em movimento).

const TITLE_A := "Axé"
const TITLE_B := "Kart"
const SUBTITLE := "Mais Bananas, Mais Bally, Mais Pomodoro e Mais Velocidade"
const RACE_SCENE := "res://scenes/Main.tscn"
const KART_SHEET := "res://assets/karts/vinicius/sprites/sheet.png"

var _t := 0.0
var _dust: Array[Vector3] = []   # x, y, velocidade
var _kart_tex: Texture2D
var _kart_x := -200.0
var _starting := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	PlayerInput.ensure_actions()
	_rng.seed = 7
	for i in 70:
		_dust.append(Vector3(_rng.randf() * 1280.0, _rng.randf() * 720.0, _rng.randf_range(8.0, 30.0)))
	_kart_tex = load(KART_SHEET)

	var title := HBoxContainer.new()
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	title.position = Vector2(0, 190)
	title.size = Vector2(1280, 170)
	title.add_theme_constant_override("separation", 0)
	add_child(title)
	title.add_child(_title_label(TITLE_A, InterfaceTheme.TEXT))
	title.add_child(_title_label(TITLE_B, InterfaceTheme.P1))

	var sub := _label(SUBTITLE, 26, InterfaceTheme.ALERT)
	sub.name = "Subtitle"
	sub.position = Vector2(0, 372)
	sub.size = Vector2(1280, 40)
	add_child(sub)

	var hint := _label("Enter, clique ou A no controle para correr", 22, InterfaceTheme.TEXT)
	hint.name = "Hint"
	hint.position = Vector2(0, 560)
	hint.size = Vector2(1280, 40)
	add_child(hint)

	var credit := _label("Axélab • TJBA — da família do AxéFight", 15, Color(InterfaceTheme.TEXT, 0.6))
	credit.position = Vector2(0, 684)
	credit.size = Vector2(1280, 24)
	add_child(credit)


func _title_label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 150)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", InterfaceTheme.INK)
	l.add_theme_constant_override("outline_size", 26)
	l.add_theme_color_override("font_shadow_color", Color(InterfaceTheme.GOLD, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 6)
	return l


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", InterfaceTheme.INK)
	l.add_theme_constant_override("outline_size", 8)
	return l


func _process(delta: float) -> void:
	_t += delta
	for i in _dust.size():
		var d := _dust[i]
		d.x += d.z * delta
		d.y -= d.z * 0.3 * delta
		if d.x > 1290.0 or d.y < -10.0:
			d = Vector3(-10.0, _rng.randf() * 720.0, d.z)
		_dust[i] = d
	_kart_x += 260.0 * delta
	if _kart_x > 1480.0:
		_kart_x = -260.0
	var hint := get_node_or_null("Hint")
	if hint:
		hint.modulate.a = 0.55 + 0.45 * sin(_t * 3.0)
	queue_redraw()


func _draw() -> void:
	# fundo: tinta do Axé Fight com leve degradê
	draw_rect(Rect2(0, 0, 1280, 720), InterfaceTheme.INK)
	var center := Vector2(640, 280)
	# raios ciano e dourados girando atrás da marca
	var rays := 18
	for i in rays:
		var a0 := _t * 0.12 + TAU * i / rays
		var a1 := a0 + TAU / rays * 0.45
		var col := InterfaceTheme.P1 if i % 2 == 0 else InterfaceTheme.GOLD
		col.a = 0.16
		draw_colored_polygon(PackedVector2Array([center,
			center + Vector2.from_angle(a0) * 1100.0,
			center + Vector2.from_angle(a1) * 1100.0]), col)
	# halo
	for r in 6:
		draw_circle(center, 260.0 - r * 36.0, Color(InterfaceTheme.P1, 0.025))
	# névoa no chão
	for band in 5:
		var y := 600.0 + band * 26.0 + sin(_t * 0.7 + band) * 6.0
		draw_rect(Rect2(0, y, 1280, 40), Color(InterfaceTheme.P2, 0.05))
	# pista estilizada
	draw_rect(Rect2(0, 500, 1280, 46), Color("#2a3140"))
	for i in 20:
		var x := fposmod(i * 80.0 - _t * 260.0, 1600.0) - 160.0
		draw_rect(Rect2(x, 520, 44, 6), Color(InterfaceTheme.TEXT, 0.7))
	# kart passando (quadro de lado da folha de 8 direções)
	if _kart_tex:
		var src := Rect2(256 * 2, 0, 256, 256)
		draw_texture_rect_region(_kart_tex, Rect2(_kart_x, 368, 176, 176), src)
		for s in 4:
			draw_circle(Vector2(_kart_x - 8 - s * 18, 520 - s * 3), 6.0 - s, Color(InterfaceTheme.TEXT, 0.25 - s * 0.05))
	# poeira
	for d in _dust:
		draw_circle(Vector2(d.x, d.y), 1.6, Color(InterfaceTheme.GOLD, 0.35))


func _input(event: InputEvent) -> void:
	var go := false
	if event is InputEventKey and event.pressed and not event.echo:
		go = event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	elif event is InputEventMouseButton and event.pressed:
		go = true
	elif event is InputEventScreenTouch and event.pressed:
		go = true
	elif event is InputEventJoypadButton and event.pressed:
		go = event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]
	if go:
		start_race()


func start_race() -> void:
	if _starting:
		return
	_starting = true
	get_tree().change_scene_to_file(RACE_SCENE)
