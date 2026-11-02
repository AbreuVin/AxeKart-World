# AxéKart World — regras do projeto (Claude e Codex)

Jogo de kart 2.5D, sem fins lucrativos, feito para o pessoal do Axélab (TJBA).
Roda no navegador (Godot 4.7 → exportação Web) em 16:9, e também no PC.
Este arquivo é a fonte única de regras: o `CLAUDE.md` só aponta para cá.

## Regra de ouro: tudo é original

- **Nada da Nintendo nem de outros jogos**: nenhum sprite, modelo, textura, som,
  música, fonte, logotipo, nome de personagem, item ou pista. Também não recriar
  "de memória" (ex.: casco, banana de Mario Kart, Rainbow Road). Inspiração de
  gênero é livre; cópia não.
- Assets externos só com licença CC0 ou feitos por nós (código, SpriteCook, arte
  própria). Registre a origem e a licença em `assets/CREDITS.md`.
- Arte do Axé Fight pode ser reaproveitada (autorizado pelo César em 02/11/2026),
  sempre recortando da arte **ativa** dele e citando em `assets/CREDITS.md`.
- **Vinicius tem cabelo curto e cheio** (não é calvo): nunca descrever "entradas"
  ou calvície em prompts de arte. O kart dele é **vermelho com o número 13**.
- Elenco: Vinicius (jogador), César, Lucas, João — aprovados pelo usuário em 02/11/2026.
  Novos pilotos: `tools/sprites/crop_head.py` (cabeça da guarda do Axé Fight) +
  `kart.json` (cor = `theme_color`, vulgo e nome do `character.json` do Axé Fight) +
  `tools/sprites/build_pilot_sheet.py`. Melhorias de acabamento ficam para depois.
- Pessoas reais do Axélab só entram como piloto com o ok da própria pessoa.
  Registre a aprovação no `kart.json` (`aprovado_por_pessoa: true`). Fotos de
  referência ficam **fora do Git**.

## Arquitetura (orientada a dados)

- Pilotos: `assets/karts/<id>/kart.json` + `sprites/sheet.png`.
  Novo piloto = nova pasta; o código de corrida não muda.
- Pistas: `assets/tracks/<id>/track.json` (pontos de controle da curva fechada,
  largura, decoração). A malha da pista é gerada em código (`scripts/track/track.gd`).
- O kart é um `Node3D` com física arcade própria e determinística
  (`scripts/kart/kart.gd`). Entrada vem de um dicionário `input`, preenchido por
  `player_input.gd` ou `cpu_driver.gd` — assim os testes dirigem sem teclado.
- Visual 2.5D: mundo 3D low-poly + piloto em `Sprite3D` billboard com **8 direções**
  (ver `docs/DESIGN_GUIDE.md`).
- Renderizador `gl_compatibility` (obrigatório para Web).

## Trabalho em conjunto (Claude e Codex)

- Um agente por vez na pasta. Antes de começar: `git status` e `git log --oneline -5`.
  Mudanças sem commit que não são suas → pare e pergunte ao usuário.
- Fluxo **piloto → aprovação → etapa 2**: entregue uma amostra (1 piloto, 1 pista,
  1 item), mostre captura e espere o ok antes de produzir o resto.
- Ao terminar: rode os testes afetados e faça **um commit** em português.
- Não faça `git push`, merge, `--amend`, `reset`, `rebase` ou `--force` sem pedido do usuário.
- Regra nova vale para os dois agentes: registre aqui.

## Testes

```
godot --headless --path . --import
godot --headless --path . --script tests/scripts/test_data_runner.gd
godot --headless --path . --script tests/scripts/test_kart_runner.gd
godot --headless --path . --script tests/scripts/test_race_runner.gd
godot --headless --path . --script tests/scripts/test_frontend_runner.gd
```

Mudou física, pista ou voltas → rode os três. Mudou arte → gere a build Web
(`tools/web/export_web.sh`) e confira capturas reais (`tools/capture/capture_web.py`).

## Organização

- `scripts/` por sistema (`kart/`, `track/`, `race/`, `ui/`, `core/`).
- `tests/scripts/` runners headless; `tools/` geradores e capturas.
- `docs/` design, roadmap e notas de versão; `CHANGELOG.md` a cada versão.
