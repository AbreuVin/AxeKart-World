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
  névoa/poeira leve em movimento). Subtítulo a definir com o usuário.
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

- Folha horizontal com **8 quadros** de 128×128 px, fundo transparente.
- Quadro `k` = kart visto com a câmera a `k × 45°` ao redor dele,
  partindo de **trás** (k=0) e girando para a **direita** do kart
  (k=2 lado direito, k=4 frente, k=6 lado esquerdo). Elevação da câmera ≈ 18°.
- Kart de ~2,6 m ocupa ~104 px de largura no quadro de lado; origem nos pés das rodas,
  centralizada, com o chão a 8 px da borda inferior.
- `pixel_size` padrão 0,025 m/px; filtro nearest.
- O placeholder é gerado por `tools/sprites/make_placeholder_kart.py`;
  a arte final (SpriteCook ou ilustração) deve obedecer o mesmo contrato.

## Pista

- Largura padrão 14 m, zebras vermelho/branco de 1,2 m, faixa de grama
  lenta (velocidade máx. 45%) e barreira invisível 6 m após a borda.
- Linha de largada quadriculada no ponto de controle 0, sentido do ponto 0 → 1.
- Decoração nunca dentro da pista nem a menos de 8 m da borda.

## Validação

- Testes headless (ver `AGENTS.md`) + captura real da build Web em 1280×720.
