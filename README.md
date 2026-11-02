# 🏎️ AxéKart World — Axélab

Versão 0.1.1 (protótipo) · [Roadmap](docs/ROADMAP.md) · [Guia visual](docs/DESIGN_GUIDE.md)

Jogo de kart **2.5D** para o navegador, feito em **Godot 4.7 + GDScript**, sem fins
lucrativos, para o pessoal do **Axélab — Laboratório de Inovação do TJBA**.
É da mesma família do **Axé Fight** (do César): mesma paleta, mesmo elenco e o
mesmo jeito de trabalhar com IA (Claude + Codex guiados pelo `AGENTS.md`).

> 100% original: nenhum asset, nome ou música da Nintendo ou de outros jogos.

## 🎮 Como jogar

| Ação | Teclado | Controle |
|---|---|---|
| Acelerar | ↑ / W | A ou RT |
| Frear / ré | ↓ / S | B ou LT |
| Virar | ← → / A D | analógico esquerdo |
| Drift (segure na curva, solte para o turbo) | Shift / Espaço | RB / X |
| Reiniciar | R | Back |
| Voltar ao menu | Esc | — |

3 voltas contra 3 CPUs. Grama deixa lento; drift carregado dá mini-turbo.

## 🚀 Rodar

- **Navegador:** publicado no GitHub Pages a cada push na `main` (`.github/workflows/web.yml`).
- **Godot:** abra `project.godot` no Godot 4.7.x e aperte F5.
- **Build Web local:** `tools/web/export_web.sh` → `build/web/`.

## 🧪 Testes

```
godot --headless --path . --import
godot --headless --path . --script tests/scripts/test_data_runner.gd
godot --headless --path . --script tests/scripts/test_kart_runner.gd
godot --headless --path . --script tests/scripts/test_race_runner.gd
godot --headless --path . --script tests/scripts/test_frontend_runner.gd
python3 tools/capture/capture_web.py   # capturas reais da build Web (Playwright)
```

## 📁 Estrutura

```
assets/karts/<id>/      kart.json + sprites/sheet.png (8 direções)
assets/tracks/<id>/     track.json (pontos da pista, largura, voltas)
scripts/kart|track|race|ui|core
tests/scripts/          runners headless
tools/                  sprites placeholder, exportação Web, capturas
docs/                   guia visual e roadmap
```

Novo piloto = nova pasta em `assets/karts/`. Nova pista = novo `track.json`.
