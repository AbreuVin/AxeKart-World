class_name RaceHud
extends CanvasLayer
## HUD arcade: volta, tempo, posição, velocidade, contagem e chegada.

const CYAN := InterfaceTheme.P1
const VIOLET := InterfaceTheme.P2
const AMBER := InterfaceTheme.ALERT

var pilot_label: Label
var lap_label: Label
var time_label: Label
var best_label: Label
var pos_label: Label
var speed_label: Label
var center_label: Label
var hint_label: Label
var boost_bar: ProgressBar
var result_panel: PanelContainer
var result_label: Label


func _ready() -> void:
	var tl := _panel(Vector2(20, 20), Vector2(300, 140))
	pilot_label = _label(tl, 16, AMBER)
	lap_label = _label(tl, 30, CYAN)
	time_label = _label(tl, 22, InterfaceTheme.TEXT)
	best_label = _label(tl, 18, VIOLET)
	var tr := _panel(Vector2(1280 - 180, 20), Vector2(160, 90))
	pos_label = _label(tr, 54, AMBER)
	pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var br := _panel(Vector2(1280 - 240, 720 - 110), Vector2(220, 90))
	speed_label = _label(br, 34, InterfaceTheme.TEXT)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	boost_bar = ProgressBar.new()
	boost_bar.max_value = 2.5
	boost_bar.show_percentage = false
	boost_bar.custom_minimum_size = Vector2(190, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = VIOLET
	boost_bar.add_theme_stylebox_override("fill", fill)
	br.get_child(0).add_child(boost_bar)

	center_label = Label.new()
	center_label.add_theme_font_size_override("font_size", 120)
	center_label.add_theme_color_override("font_color", AMBER)
	center_label.add_theme_color_override("font_outline_color", Color.BLACK)
	center_label.add_theme_constant_override("outline_size", 18)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.position = Vector2(0, 200)
	center_label.size = Vector2(1280, 200)
	add_child(center_label)

	hint_label = Label.new()
	hint_label.text = "Setas/WASD: acelerar, frear e virar   Shift/Espaço: drift   R: reiniciar   Esc: menu"
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hint_label.add_theme_constant_override("outline_size", 6)
	hint_label.position = Vector2(20, 720 - 34)
	add_child(hint_label)

	result_panel = _panel(Vector2(390, 180), Vector2(500, 340))
	result_label = _label(result_panel, 26, InterfaceTheme.TEXT)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_panel.visible = false


func _panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", InterfaceTheme.panel_style())
	p.position = pos
	p.custom_minimum_size = size
	var box := VBoxContainer.new()
	p.add_child(box)
	add_child(p)
	return p


func _label(panel: PanelContainer, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	panel.get_child(0).add_child(l)
	return l


static func pilot_name(d: Dictionary) -> String:
	var v := String(d.get("vulgo", ""))
	var n := String(d.get("display_name", d.get("id", "?")))
	return "%s • %s" % [n, v] if v != "" else n


static func fmt(t: float) -> String:
	if t == INF or t <= 0.0:
		return "--:--.--"
	var m := int(t / 60.0)
	var s := fmod(t, 60.0)
	return "%d:%05.2f" % [m, s]


func update_race(k: Kart, position: int, total: int, laps: int) -> void:
	pilot_label.text = pilot_name(k.data)
	lap_label.text = "VOLTA %d/%d" % [mini(k.laps_done + 1, laps), laps]
	time_label.text = "Tempo  " + fmt(k.race_time if not k.is_finished else k.finish_time)
	best_label.text = "Melhor " + fmt(k.best_lap)
	pos_label.text = "%dº" % position
	speed_label.text = "%d km/h" % int(k.km_h())
	boost_bar.value = k.drift_charge if k.drifting else 0.0


func show_center(text: String, color := AMBER) -> void:
	center_label.text = text
	center_label.add_theme_color_override("font_color", color)


func show_result(text: String) -> void:
	result_label.text = text
	result_panel.visible = true
