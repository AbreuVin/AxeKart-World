class_name PlayerInput
extends RefCounted
## Lê teclado/controle e preenche kart.input. Cria as ações em tempo de execução.

const ACTIONS := {
	"acelerar": [KEY_UP, KEY_W],
	"frear": [KEY_DOWN, KEY_S],
	"esquerda": [KEY_LEFT, KEY_A],
	"direita": [KEY_RIGHT, KEY_D],
	"drift": [KEY_SHIFT, KEY_SPACE],
	"reiniciar": [KEY_R],
}
const PAD_BUTTONS := {
	"acelerar": [JOY_BUTTON_A],
	"frear": [JOY_BUTTON_B],
	"drift": [JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_X],
	"reiniciar": [JOY_BUTTON_BACK],
}


static func ensure_actions() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.2)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		for btn in PAD_BUTTONS.get(action, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = btn
			InputMap.action_add_event(action, jb)
	_add_axis("esquerda", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("direita", JOY_AXIS_LEFT_X, 1.0)
	_add_axis("acelerar", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_axis("frear", JOY_AXIS_TRIGGER_LEFT, 1.0)


static func _add_axis(action: String, axis: int, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)


static func read_into(kart: Kart) -> void:
	kart.input.throttle = Input.get_action_strength("acelerar")
	kart.input.brake = Input.get_action_strength("frear")
	kart.input.steer = Input.get_action_strength("direita") - Input.get_action_strength("esquerda")
	kart.input.drift = Input.is_action_pressed("drift")
