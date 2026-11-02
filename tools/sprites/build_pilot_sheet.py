"""Gera a folha de 8 direções de um piloto (contrato v2 em docs/DESIGN_GUIDE.md).

Estilo da família Axé Fight: contorno escuro fino, sombreamento em planos (2 tons),
cores chapadas, transparência limpa. O kart e o corpo são desenhados aqui; a cabeça
vem de uma ilustração (`cabeca` no kart.json, olhando para a DIREITA).
Sem `cabeca`, desenha um capacete (placeholder).

Uso: python3 tools/sprites/build_pilot_sheet.py assets/karts/<id>
"""
import json
import math
import pathlib
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

FRAME = 256
FRAMES = 8
SS = 2                      # supersampling
SCALE = 80.0 * SS           # px por metro
ELEV = math.radians(18)
GROUND_PAD = 16 * SS
OUTLINE = (22, 22, 30)
LIGHT = (0.35, 0.85, 0.4)


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mul(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


def box(c, s, color, tag="corpo"):
    cx, cy, cz = c
    hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
    v = [(cx + dx * hx, cy + dy * hy, cz + dz * hz) for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
    faces = [((0, 1, 3, 2), (-1, 0, 0)), ((4, 6, 7, 5), (1, 0, 0)), ((0, 4, 5, 1), (0, -1, 0)),
             ((2, 3, 7, 6), (0, 1, 0)), ((0, 2, 6, 4), (0, 0, -1)), ((1, 5, 7, 3), (0, 0, 1))]
    return [([v[i] for i in idx], n, color, tag) for idx, n in faces]


def model(cfg):
    kart = rgb(cfg.get("cor", "#62d8e8"))
    acc = rgb(cfg.get("cor_detalhe", "#101823"))
    shirt = rgb(cfg.get("camisa", "#1d1d22"))
    skin = rgb(cfg.get("pele", "#b98260"))
    tire = (52, 54, 62)
    rim = (190, 196, 206)
    p = []
    p += box((0, 0.30, 0.10), (1.20, 0.28, 1.95), kart)                 # chassi
    p += box((0, 0.42, -0.78), (0.85, 0.16, 0.55), kart)                # bico
    p += box((0, 0.28, -1.12), (1.40, 0.14, 0.20), acc)                 # para-choque
    p += box((-0.66, 0.36, 0.05), (0.14, 0.22, 1.1), acc)               # saias laterais
    p += box((0.66, 0.36, 0.05), (0.14, 0.22, 1.1), acc)
    p += box((0, 0.66, 1.06), (1.46, 0.08, 0.30), acc)                  # aerofólio
    p += box((-0.48, 0.50, 1.06), (0.07, 0.26, 0.10), acc)
    p += box((0.48, 0.50, 1.06), (0.07, 0.26, 0.10), acc)
    p += box((0, 0.48, 0.62), (0.70, 0.30, 0.34), mul(kart, 0.85))      # banco
    for sx in (-0.72, 0.72):
        for sz in (-0.70, 0.78):
            p += box((sx, 0.26, sz), (0.30, 0.52, 0.52), tire)
            p += box((sx * 1.06, 0.26, sz), (0.04, 0.24, 0.24), rim)
    # piloto
    p += box((0, 0.80, 0.34), (0.66, 0.58, 0.40), shirt, "piloto")      # tronco
    p += box((-0.37, 0.86, 0.10), (0.16, 0.16, 0.42), shirt, "piloto")  # mangas
    p += box((0.37, 0.86, 0.10), (0.16, 0.16, 0.42), shirt, "piloto")
    p += box((-0.30, 0.80, -0.20), (0.12, 0.12, 0.34), skin, "piloto")  # antebraços
    p += box((0.30, 0.80, -0.20), (0.12, 0.12, 0.34), skin, "piloto")
    p += box((0, 0.80, -0.38), (0.62, 0.10, 0.08), (30, 30, 36))        # volante
    p += box((0, 0.66, -0.36), (0.08, 0.20, 0.08), (30, 30, 36))
    return p


class Cam:
    def __init__(self, theta):
        self.d = (math.sin(theta) * math.cos(ELEV), math.sin(ELEV), math.cos(theta) * math.cos(ELEV))
        f = tuple(-x for x in self.d)
        r = (-f[2], 0.0, f[0])
        rl = math.hypot(r[0], r[2])
        self.r = (r[0] / rl, 0.0, r[2] / rl)
        self.u = (self.r[1] * f[2] - self.r[2] * f[1], self.r[2] * f[0] - self.r[0] * f[2],
                  self.r[0] * f[1] - self.r[1] * f[0])

    @staticmethod
    def dot(a, b):
        return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]

    def proj(self, p):
        W = FRAME * SS
        return (W / 2 + self.dot(p, self.r) * SCALE, W - GROUND_PAD - self.dot(p, self.u) * SCALE)

    def depth(self, p):
        return self.dot(p, self.d)


def head_variants(head_path):
    """Retorna dict: 'lado' (olha à direita), 'costas' (nuca), por silhueta da ilustração."""
    if not head_path:
        return None
    src = Image.open(head_path).convert("RGBA")
    alpha = src.getchannel("A")
    sym = ImageChops.lighter(alpha, alpha.transpose(Image.FLIP_LEFT_RIGHT))  # silhueta simétrica
    w, h = src.size
    hair = Image.new("RGBA", src.size, (0, 0, 0, 0))
    dr = ImageDraw.Draw(hair)
    # nuca: cabelo escuro em cima, pescoço/orelhas embaixo, sombreado em planos
    dr.rectangle((0, 0, w, int(h * 0.74)), fill=(40, 33, 28, 255))
    dr.rectangle((0, int(h * 0.40), w // 2, int(h * 0.74)), fill=(30, 25, 21, 255))
    dr.rectangle((0, int(h * 0.74), w, h), fill=(150, 104, 76, 255))
    dr.rectangle((0, int(h * 0.74), w // 2, h), fill=(126, 86, 62, 255))
    dr.ellipse((int(w * 0.02), int(h * 0.42), int(w * 0.16), int(h * 0.62)), fill=(164, 114, 84, 255))
    dr.ellipse((int(w * 0.84), int(h * 0.42), int(w * 0.98), int(h * 0.62)), fill=(150, 104, 76, 255))
    back = Image.new("RGBA", src.size, (0, 0, 0, 0))
    back.paste(hair, (0, 0), sym)
    # contorno fino
    edge = sym.filter(ImageFilter.MaxFilter(3))
    out = Image.new("RGBA", src.size, OUTLINE + (0,))
    out.putalpha(edge)
    out.alpha_composite(back)
    return {"lado": src, "costas": out}


def head_for_frame(heads, k):
    # k: 0 trás, 1 trás-dir, 2 dir (kart olha p/ direita da tela), 3 frente-dir, 4 frente,
    #    5 frente-esq, 6 esq, 7 trás-esq
    if k in (2, 3, 4):
        return heads["lado"]
    if k in (5, 6):
        return heads["lado"].transpose(Image.FLIP_LEFT_RIGHT)
    if k in (0, 1):
        return heads["costas"]
    return heads["costas"].transpose(Image.FLIP_LEFT_RIGHT)


def render(cfg, heads, k):
    W = FRAME * SS
    cam = Cam(k * math.tau / FRAMES)
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    items = []
    for pts, n, col, tag in model(cfg):
        if Cam.dot(n, cam.d) <= 0.001:
            continue
        lit = Cam.dot(n, LIGHT)
        shade = 1.0 if lit > 0.45 else (0.78 if lit > 0.0 else 0.62)   # cel shading em planos
        items.append((sum(cam.depth(p) for p in pts) / 4, "face", ([cam.proj(p) for p in pts], mul(col, shade))))
    head_c = (0.0, 1.30, 0.30)
    head_h = 0.70
    if heads:
        items.append((cam.depth(head_c) + 0.05, "cabeca", None))
    else:
        for pts, n, col, tag in box(head_c, (0.5, 0.5, 0.52), rgb(cfg.get("capacete", "#101823")), "piloto"):
            if Cam.dot(n, cam.d) > 0.001:
                lit = Cam.dot(n, LIGHT)
                items.append((sum(cam.depth(p) for p in pts) / 4 + 0.02, "face",
                              ([cam.proj(p) for p in pts], mul(col, 1.0 if lit > 0.45 else 0.75))))
    # sombra no chão
    sh = [cam.proj((x, 0, z)) for x, z in ((-0.95, -1.25), (0.95, -1.25), (0.95, 1.25), (-0.95, 1.25))]
    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).polygon(sh, fill=(0, 0, 0, 80))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6 * SS)))
    items.sort(key=lambda t: t[0])
    for _, kind, data in items:
        if kind == "face":
            poly, col = data
            dr.polygon(poly, fill=col + (255,), outline=OUTLINE + (255,), width=SS)
        else:
            hv = head_for_frame(heads, k)
            ph = int(head_h * SCALE)
            pw = int(hv.width * ph / hv.height)
            hv = hv.resize((pw, ph), Image.LANCZOS)
            cx, cy = cam.proj(head_c)
            img.alpha_composite(hv, (int(cx - pw / 2), int(cy - ph * 0.55)))
            dr = ImageDraw.Draw(img)
    return img.resize((FRAME, FRAME), Image.LANCZOS)


def main():
    kdir = pathlib.Path(sys.argv[1])
    cfg = json.loads((kdir / "kart.json").read_text(encoding="utf-8"))
    heads = head_variants(kdir / cfg["cabeca"]) if cfg.get("cabeca") else None
    sheet = Image.new("RGBA", (FRAME * FRAMES, FRAME), (0, 0, 0, 0))
    for k in range(FRAMES):
        sheet.paste(render(cfg, heads, k), (k * FRAME, 0))
    out = kdir / cfg.get("sprite", "sprites/sheet.png")
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print("ok", out)


if __name__ == "__main__":
    main()
