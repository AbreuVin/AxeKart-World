"""Importa uma folha gerada por IA (grade 4x2 em fundo verde) para o contrato de 8 direções.

Uso: python3 tools/sprites/import_generated_sheet.py assets/karts/<id>
Lê `gerado` do kart.json: {"arquivo": "source/x.png", "colunas": 4, "linhas": 2,
"mapa": [celula_ou_null por quadro 0..7], "espelhar": {"7": 1}}
- quadro k segue docs/DESIGN_GUIDE.md (0 trás, 2 lado direito/nariz p/ direita, 4 frente...)
- espelhar: quadro <- espelho horizontal de outra célula
Remove o verde (chroma key com despill), usa UMA escala para todos os quadros
(medida pela vista de lado) e apoia as rodas no chão (chao_px).
"""
import json
import pathlib
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

FRAME = 256
KART_SIDE_PX = 208   # comprimento do kart na vista lateral (80 px/m × 2,6 m)


def key_green(rgb):
    a = rgb.astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    greenness = g - np.maximum(r, b)
    alpha = np.clip(1.0 - (greenness - 40.0) / 60.0, 0.0, 1.0)
    # despill: borda esverdeada vira neutra
    spill = greenness > 0
    a[..., 1] = np.where(spill, np.minimum(g, np.maximum(r, b) + 6), g)
    out = np.dstack([a, alpha * 255.0]).clip(0, 255).astype(np.uint8)
    return out


def unflip_text(cell):
    """Depois de espelhar, desvira só as áreas de texto claro (ex.: número do kart)."""
    rgb = cell[..., :3].astype(int)
    white = (rgb.min(axis=2) > 205) & (cell[..., 3] > 200)
    lab, n = ndimage.label(ndimage.binary_dilation(white, iterations=5))
    for sl in ndimage.find_objects(lab):
        ys, xs = sl
        h, w = ys.stop - ys.start, xs.stop - xs.start
        if 12 < w < 160 and 10 < h < 110 and white[sl].sum() > 40:
            y0, y1 = max(0, ys.start - 2), ys.stop + 2
            x0, x1 = max(0, xs.start - 2), xs.stop + 2
            cell[y0:y1, x0:x1] = cell[y0:y1, x0:x1][:, ::-1]
    return cell


def bbox(alpha, thr=40):
    ys, xs = np.nonzero(alpha > thr)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def main():
    kdir = pathlib.Path(sys.argv[1])
    cfg = json.loads((kdir / "kart.json").read_text(encoding="utf-8"))
    g = cfg["gerado"]
    src = Image.open(kdir / g["arquivo"]).convert("RGB")
    rgba = key_green(np.array(src))
    cols, rows = g.get("colunas", 4), g.get("linhas", 2)
    cw, ch = src.width // cols, src.height // rows
    # cada kart = maior objeto conectado; atribuído à célula pelo centro (não corta nas bordas)
    mask = rgba[..., 3] > 40
    lab, n = ndimage.label(ndimage.binary_dilation(mask, iterations=3))
    sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    best = {}
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        cell = int(ys.mean() // ch) * cols + int(xs.mean() // cw)
        if cell not in best or sizes[i - 1] > sizes[best[cell] - 1]:
            best[cell] = i
    cells = []
    for idx in range(cols * rows):
        cell = rgba.copy()
        cell[..., 3][lab != best.get(idx, -1)] = 0
        cell[..., 3][cell[..., 3] < 25] = 0
        cells.append(cell)
    # escala única pela vista lateral (quadro 2)
    side = cells[g["mapa"][2]]
    x0, y0, x1, y1 = bbox(side[..., 3])
    scale = KART_SIDE_PX / float(x1 - x0)
    ground = FRAME - int(cfg.get("chao_px", 16))
    sheet = Image.new("RGBA", (FRAME * 8, FRAME), (0, 0, 0, 0))
    mirrors = {int(k): v for k, v in g.get("espelhar", {}).items()}
    for k in range(8):
        if k in mirrors:
            cell = cells[mirrors[k]][:, ::-1].copy()
            if g.get("desvirar_texto"):
                cell = unflip_text(cell)
        else:
            cell = cells[g["mapa"][k]]
        bx0, by0, bx1, by1 = bbox(cell[..., 3])
        crop = Image.fromarray(cell[by0:by1, bx0:bx1])
        w, h = int(round(crop.width * scale)), int(round(crop.height * scale))
        f = min(1.0, (ground - 2) / h, (FRAME - 4) / w)   # nunca corta: reduz só se não couber
        w, h = int(w * f), int(h * f)
        crop = crop.resize((w, h), Image.LANCZOS)
        frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        frame.alpha_composite(crop, ((FRAME - w) // 2, ground - h))
        sheet.paste(frame, (k * FRAME, 0))
    out = kdir / cfg.get("sprite", "sprites/sheet.png")
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print("ok", out, "escala %.3f" % scale)


if __name__ == "__main__":
    main()
