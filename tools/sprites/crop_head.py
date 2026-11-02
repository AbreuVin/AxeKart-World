"""Recorta a cabeça (olhando para a direita) do sprite de guarda do Axé Fight.

Uso: python3 tools/sprites/crop_head.py <idle_frame_00.png> <saida.png> [altura_cabeca_px]
Acha o topo da silhueta, mede a largura da cabeça nas linhas de cima e corta
ombros/punhos abaixo da mandíbula mantendo só as colunas da cabeça.
"""
import sys

import numpy as np
from PIL import Image


def crop_head(src_path, out_path, head_h=74):
    im = Image.open(src_path).convert("RGBA")
    a = np.array(im)
    alpha = a[:, :, 3] > 24
    ys = np.nonzero(alpha.any(axis=1))[0]
    y0 = int(ys.min())
    # largura da cabeça: união das colunas nas linhas do crânio (25%–60% da cabeça)
    band = alpha[y0 + int(head_h * 0.25): y0 + int(head_h * 0.6)]
    cols = np.nonzero(band.any(axis=0))[0]
    # pega o maior bloco contínuo (evita punho erguido ao lado do rosto)
    runs, start = [], cols[0]
    for p, c in zip(cols, cols[1:]):
        if c != p + 1:
            runs.append((start, p))
            start = c
    runs.append((start, cols[-1]))
    x0, x1 = max(runs, key=lambda r: r[1] - r[0])
    x0, x1 = x0 - 3, x1 + 5
    y1 = y0 + head_h
    out = a[y0 - 2:y1, x0:x1].copy()
    # abaixo de 68% da cabeça, mantém só o miolo (pescoço/barba), remove ombros
    cut = int(head_h * 0.68)
    w = out.shape[1]
    for y in range(cut, out.shape[0]):
        row = alpha[y0 - 2 + y, x0:x1]
        t = (y - cut) / max(1, out.shape[0] - cut)
        margin = int(w * (0.16 + 0.30 * t))
        out[y, :margin, 3] = 0
        out[y, w - margin // 2:, 3] = 0
    # remove objetos de cor saturada amarela (ex.: banana do Lucas) na parte baixa
    low = out[cut:]
    r, g, b = low[:, :, 0].astype(int), low[:, :, 1].astype(int), low[:, :, 2].astype(int)
    yellow = (r > 170) & (g > 140) & (b < 90)
    low[yellow, 3] = 0
    Image.fromarray(out).save(out_path)
    return out_path


if __name__ == "__main__":
    crop_head(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 74)
