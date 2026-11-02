"""Gera a folha placeholder de 8 direções de um kart (contrato em docs/DESIGN_GUIDE.md).

Uso: python3 tools/sprites/make_placeholder_kart.py <saida.png> <cor_kart_hex> <cor_capacete_hex>
Renderização ortográfica simples de caixas com pintor + iluminação plana. 100% original.
"""
import math
import sys

from PIL import Image, ImageDraw

FRAME = 128
FRAMES = 8
SCALE = 40.0          # px por metro
ELEV = math.radians(18)
GROUND_PAD = 8


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(rgb, f):
    return tuple(max(0, min(255, int(c * f))) for c in rgb)


def box(cx, cy, cz, sx, sy, sz, color):
    """Caixa centrada (x direita, y cima, z trás). Retorna lista de faces (pts, normal, cor)."""
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    v = [(cx + dx * hx, cy + dy * hy, cz + dz * hz)
         for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
    # índice = (dx>0)*4 + (dy>0)*2 + (dz>0)
    faces = [
        ((0, 1, 3, 2), (-1, 0, 0)), ((4, 6, 7, 5), (1, 0, 0)),
        ((0, 4, 5, 1), (0, -1, 0)), ((2, 3, 7, 6), (0, 1, 0)),
        ((0, 2, 6, 4), (0, 0, -1)), ((1, 5, 7, 3), (0, 0, 1)),
    ]
    return [([v[i] for i in idx], n, color) for idx, n in faces]


def kart_model(kart_rgb, helmet_rgb):
    dark = (34, 34, 40)
    skin = (205, 150, 110)
    shirt = (230, 230, 235)
    parts = []
    parts += box(0, 0.32, 0.05, 1.25, 0.34, 2.1, kart_rgb)          # chassi
    parts += box(0, 0.30, -1.12, 1.45, 0.16, 0.22, shade(kart_rgb, 0.8))  # para-choque
    parts += box(0, 0.62, 1.05, 1.5, 0.08, 0.32, shade(kart_rgb, 0.7))    # aerofólio
    parts += box(-0.5, 0.48, 1.05, 0.08, 0.3, 0.12, dark)
    parts += box(0.5, 0.48, 1.05, 0.08, 0.3, 0.12, dark)
    for sx in (-0.72, 0.72):
        for sz in (-0.72, 0.78):
            parts += box(sx, 0.26, sz, 0.32, 0.52, 0.52, dark)       # rodas
    parts += box(0, 0.78, 0.25, 0.62, 0.62, 0.45, shirt)             # tronco
    parts += box(0, 1.02, -0.25, 0.7, 0.12, 0.12, dark)              # volante
    parts += box(0, 1.27, 0.22, 0.5, 0.48, 0.5, helmet_rgb)          # capacete
    parts += box(0, 1.24, -0.04, 0.42, 0.18, 0.04, (40, 60, 90))     # viseira
    parts += box(-0.36, 0.86, -0.08, 0.14, 0.14, 0.5, skin)          # braços
    parts += box(0.36, 0.86, -0.08, 0.14, 0.14, 0.5, skin)
    return parts


def render_frame(parts, theta):
    d = (math.sin(theta) * math.cos(ELEV), math.sin(ELEV), math.cos(theta) * math.cos(ELEV))
    f = (-d[0], -d[1], -d[2])
    right = (f[1] * 0 - f[2] * 1, f[2] * 0 - f[0] * 0, f[0] * 1 - f[1] * 0)
    rl = math.sqrt(sum(c * c for c in right))
    right = tuple(c / rl for c in right)
    up = (right[1] * f[2] - right[2] * f[1], right[2] * f[0] - right[0] * f[2],
          right[0] * f[1] - right[1] * f[0])
    light = (0.4, 0.85, 0.35)
    dot = lambda a, b: sum(x * y for x, y in zip(a, b))
    ground_y = FRAME - GROUND_PAD

    def proj(p):
        return (FRAME / 2 + dot(p, right) * SCALE, ground_y - dot(p, up) * SCALE
                + dot((0, 0, 0), up) * SCALE)

    img = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    # sombra
    sh = [proj((x, 0, z)) for x, z in ((-0.9, -1.2), (0.9, -1.2), (0.9, 1.2), (-0.9, 1.2))]
    dr.polygon(sh, fill=(0, 0, 0, 70))
    faces = []
    for pts, n, col in parts:
        if dot(n, d) <= 0.001:
            continue
        depth = sum(dot(p, d) for p in pts) / 4
        lum = 0.55 + 0.45 * max(0.0, dot(n, light))
        faces.append((depth, [proj(p) for p in pts], shade(col, lum)))
    faces.sort(key=lambda t: t[0])
    for _, poly, col in faces:
        dr.polygon(poly, fill=col + (255,), outline=(20, 20, 26, 255))
    return img


def main():
    out, kart_hex, helmet_hex = sys.argv[1], sys.argv[2], sys.argv[3]
    parts = kart_model(hex_rgb(kart_hex), hex_rgb(helmet_hex))
    sheet = Image.new("RGBA", (FRAME * FRAMES, FRAME), (0, 0, 0, 0))
    for k in range(FRAMES):
        sheet.paste(render_frame(parts, k * math.tau / FRAMES), (k * FRAME, 0))
    sheet.save(out)
    print("ok", out)


if __name__ == "__main__":
    main()
