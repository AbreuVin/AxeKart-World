# Guia de fidelidade visual — AxéKart

Leia antes de mexer em arte, pilotos, pistas, HUD ou câmera.

## Mesma família do Axé Fight

O AxéKart é um jogo irmão do **Axé Fight** (César, `CesarRafael71/Axefight`).
Quem joga um tem que reconhecer o outro. A referência é o `docs/DESIGN_GUIDE.md`
do Axé Fight e as artes ativas dele.

- **Tokens de interface idênticos** (`scripts/ui/interface_theme.gd`): tinta `#101823`,
  texto `#eef3fa`, P1 ciano `#62d8e8`, P2 violeta `#b5a2f3`, alerta âmbar `#f0bd6b`,
  perigo coral `#f47983`. Não invente cores novas para a HUD.
- **Painéis escuros translúcidos**, tipografia clara, viewport lógico 1280×720.
- **Marca:** logo **AxéKart** no mesmo tratamento do AxéFight (raios ciano e dourado,
  névoa/poeira leve em movimento). Subtítulo aprovado pelo usuário:
  **"Mais Bananas, Mais Bally, Mais Pomodoro e Mais Velocidade"** (não alterar sem pedido).
- **Pilotos:** mesmo tratamento dos lutadores — ilustração raster com aspecto vetorial,
  proporções humanas realistas, contorno escuro fino, sombreamento em planos,
  transparência limpa, filtro `nearest`. Nada de pixel art grosseira ou render 3D
  no piloto. Identidade (rosto, roupa, vulgo) segue o `character.json` do Axé Fight.
- **Elenco compartilhado:** os pilotos são o elenco do Axé Fight, com `display_name`
  e `vulgo` iguais. Reaproveitar arte do Axé Fight só com o ok do César e da pessoa.
- **Cenários:** pistas temáticas nos mesmos lugares (Café Axélab, Lounge Axélab,
  Tribunal TJBA) e depois Salvador (Pelourinho, Orla).
- **Placeholders** (blocos low-poly) existem só para testar a jogabilidade e devem
  ser substituídos antes de qualquer versão para o pessoal.

## Estilo técnico

- 2.5D: pista e cenário em 3D low-poly, cores chapadas; pilotos e karts em sprite 2D.
- Tela 16:9, base 1280×720, `stretch = canvas_items`, `aspect = keep`.

## Sprite do piloto (contrato)

- Folha horizontal com **8 quadros** de 256×256 px, fundo transparente.
- Quadro `k` = kart visto com a câmera a `k × 45°` ao redor dele,
  partindo de **trás** (k=0) e girando para a **direita** do kart
  (k=2 lado direito, k=4 frente, k=6 lado esquerdo). Elevação da câmera ≈ 18°.
- Escala 80 px/m: kart de ~2,6 m ocupa ~208 px no quadro de lado; origem nas rodas,
  centralizada, com o chão a `chao_px` (16) px da borda inferior.
- `pixel_size` 0,0125 m/px; filtro nearest.
- Gerador: `tools/sprites/build_pilot_sheet.py assets/karts/<id>` — kart e corpo com
  **formas arredondadas** (nada de caixas), contorno escuro fino só na silhueta de cada
  peça e sombreamento em 3 tons, no traço do Axé Fight + **cabeça ilustrada**
  (`cabeca` no `kart.json`, olhando para a direita, recortada da arte do Axé Fight).
  Quadros 2–4 usam a cabeça; 5–6 espelhada; 0, 1 e 7 a nuca gerada pela silhueta.
  Sem `cabeca`, o piloto usa capacete (placeholder).
- Arte final de outra origem (SpriteCook, ilustração) deve obedecer o mesmo contrato.

## Pista

- Largura padrão 14 m, zebras vermelho/branco de 1,2 m, faixa de grama
  lenta (velocidade máx. 45%) e barreira invisível 6 m após a borda.
- Linha de largada quadriculada no ponto de controle 0, sentido do ponto 0 → 1.
- Decoração nunca dentro da pista nem a menos de 8 m da borda.

## Validação

- Testes headless (ver `AGENTS.md`) + captura real da build Web em 1280×720.
