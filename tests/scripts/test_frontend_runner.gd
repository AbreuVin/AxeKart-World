extends TestBase
## Tela inicial: marca, subtítulo aprovado, tokens do Axé Fight e cena de corrida válida.

var _ran := false


func _process(_delta: float) -> bool:
	if not _ran:
		_ran = true
		_run()
	return false


func _run() -> void:
	print("[test_frontend]")
	var fe := FrontEnd.new()
	root.add_child(fe)
	var sub := fe.get_node_or_null("Subtitle") as Label
	check(sub != null, "subtítulo existe")
	if sub:
		check(sub.text == "Mais Bananas, Mais Bally, Mais Pomodoro e Mais Velocidade", "subtítulo aprovado pelo usuário")
	check(FrontEnd.TITLE_A + FrontEnd.TITLE_B == "AxéKart", "marca AxéKart")
	check(ResourceLoader.exists(FrontEnd.RACE_SCENE), "cena da corrida existe")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/FrontEnd.tscn", "jogo abre na tela inicial")
	check(InterfaceTheme.P1 == Color("#62d8e8") and InterfaceTheme.P2 == Color("#b5a2f3") and InterfaceTheme.INK == Color("#101823"),
		"tokens iguais aos do Axé Fight")
	finish()
