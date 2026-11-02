class_name InterfaceTheme
extends RefCounted
## Tokens visuais herdados do Axé Fight (scripts/ui/interface_theme.gd do projeto do César).
## Mantém o AxéKart na mesma família: use sempre estes nomes em componentes novos.

const INK := Color("#101823")          # tinta / painéis
const TEXT := Color("#eef3fa")         # texto
const P1 := Color("#62d8e8")           # ciano — jogador 1
const P2 := Color("#b5a2f3")           # violeta — jogador 2
const ALERT := Color("#f0bd6b")        # âmbar — alertas, posição, contagem
const DANGER := Color("#f47983")       # coral — perigo
const GOLD := Color("#f2c14e")         # raios dourados da marca

static func panel_style(border := P1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(INK, 0.78)
	sb.border_color = Color(border, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	return sb
