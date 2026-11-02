# Changelog

## 0.5.0 — Vinicius ilustrado por IA, kart 13
- Piloto do Vinicius gerado por IA (Canva) com referências do Axé Fight: cabelo cheio,
  barba, camiseta preta, calça cáqui e kart vermelho nº 13 em 8 ângulos.
- Importador `import_generated_sheet.py`: chroma key com despill, recorte por objeto,
  escala única e apoio no chão.
- Pendência: vista trás-esquerda é espelhada (número aparece invertido).

## 0.4.0 — pista Café & Lounge Axélab
- Nova pista interna (607 m): porcelanato, teto com placas e luminárias redondas,
  paredes com as artes do Café e do Lounge do Axé Fight, mesas altas com banquetas,
  jardineiras, cabines coloridas, estantes de nichos e bancos do Lounge.
- Zebras em ciano/branco (tokens do Axé Fight). Circuito de teste mantido para os testes de física.

## 0.3.1 — karts arredondados
- Gerador refeito com superfícies arredondadas: carroceria curva, bico afinado, pontões,
  rodas cilíndricas, tronco e braços até o volante; contorno só na silhueta.
- Kart do Vinicius vermelho (pedido do usuário).

## 0.3.0 — elenco na pista
- César • Ai Cesinhaaa, Lucas • Bananinha e João • JVAFREITAS entram como pilotos CPU,
  com cabeça da arte do Axé Fight e kart na cor-tema de cada um.
- Recortador `crop_head.py`; nuca com a cor de cabelo de cada piloto; placeholders removidos.
- HUD e chegada mostram o vulgo.

## 0.2.0 — piloto de amostra (Vinicius)
- Novo gerador de piloto `build_pilot_sheet.py` no traço do Axé Fight, folhas 8×256 px.
- Vinicius • Balanço da Maré como piloto do jogador, com a cabeça da arte do Axé Fight
  (camiseta preta, kart cáqui na cor-tema dele). CPUs com capacete até a aprovação.

## 0.1.1 — tela inicial
- Tela inicial da família do AxéFight: marca **AxéKart** com raios ciano e dourados girando,
  poeira e névoa em movimento, kart passando e o subtítulo
  **"Mais Bananas, Mais Bally, Mais Pomodoro e Mais Velocidade"**.
- Enter, clique, toque ou A/Start começam a corrida; Esc volta ao menu.
- O relógio da corrida só começa no "VAI!".

## 0.1.0 — protótipo
- Pista procedural "Circuito de Teste do Axélab" (zebras, largada quadriculada, palmeiras e pilhas de processos).
- Kart arcade determinístico: aceleração, freio/ré, grama lenta, barreira, drift com mini-turbo.
- Pilotos placeholder em sprite 2.5D de 8 direções; 3 CPUs; 3 voltas; posição; melhor volta; chegada.
- HUD com os tokens visuais do Axé Fight.
- Testes headless, exportação Web sem threads e deploy no GitHub Pages.
