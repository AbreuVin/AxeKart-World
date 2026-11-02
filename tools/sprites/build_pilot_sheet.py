"""Gera a folha de 8 direções de um piloto (contrato v2 em docs/DESIGN_GUIDE.md).

Estilo da família Axé Fight: formas arredondadas, contorno escuro fino só na silhueta,
sombreamento em planos (3 tons),
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


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _norm(v):
    l = math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2) or 1.0
    return (v[0] / l, v[1] / l, v[2] / l)


def loft(rings, color, caps=True):
    """Superfície convexa ligando anéis (mesma quantidade de pontos). Normais para fora."""
    pts = [p for r in rings for p in r]
    c = tuple(sum(p[i] for p in pts) / len(pts) for i in range(3))
    faces = []

    def add(poly):
        n = _norm(_cross(_sub(poly[1], poly[0]), _sub(poly[2], poly[0])))
        mid = tuple(sum(p[i] for p in poly) / len(poly) for i in range(3))
        if sum(n[i] * (mid[i] - c[i]) for i in range(3)) < 0:
            n = (-n[0], -n[1], -n[2])
        faces.append((poly, n, color))

    for a, b in zip(rings, rings[1:]):
        m = len(a)
        for i in range(m):
            j = (i + 1) % m
            add([a[i], a[j], b[j], b[i]])
    if caps:
        add(list(rings[0]))
        add(list(rings[-1]))
    return faces


def plan_ring(y, hw_front, hw_back, hl, r=0.22, n=6, scale=1.0, z0=0.0):
    """Contorno arredondado no plano XZ (vista de cima), bico (-z) mais estreito."""
    out = []
    corners = [((hw_back - r), (hl - r)), (-(hw_back - r), (hl - r)),
               (-(hw_front - r), -(hl - r)), ((hw_front - r), -(hl - r))]
    starts = [0.0, 0.5 * math.pi, math.pi, 1.5 * math.pi]
    for (cx, cz), a0 in zip(corners, starts):
        for k in range(n):
            a = a0 + 0.5 * math.pi * k / (n - 1)
            out.append(((cx + r * math.cos(a)) * scale, y, (cz + r * math.sin(a)) * scale + z0))
    return out


def ellipse_ring(center, rx, ry, axis="z", n=14):
    cx, cy, cz = center
    out = []
    for k in range(n):
        a = math.tau * k / n
        u, v = rx * math.cos(a), ry * math.sin(a)
        if axis == "z":
            out.append((cx + u, cy + v, cz))
        elif axis == "x":
            out.append((cx, cy + v, cz + u))
        else:
            out.append((cx + u, cy, cz + v))
    return out


def cylinder_x(center, radius, width, color, n=16):
    cx, cy, cz = center
    return loft([ellipse_ring((cx - width / 2, cy, cz), radius, radius, "x", n),
                 ellipse_ring((cx + width / 2, cy, cz), radius, radius, "x", n)], color)


def tube(p0, p1, r, color, n=10):
    d = _norm(_sub(p1, p0))
    up = (0, 1, 0) if abs(d[1]) < 0.9 else (1, 0, 0)
    u = _norm(_cross(d, up))
    v = _cross(d, u)

    def ring(c, rr):
        return [tuple(c[i] + rr * (math.cos(math.tau * k / n) * u[i] + math.sin(math.tau * k / n) * v[i])
                      for i in range(3)) for k in range(n)]
    return loft([ring(p0, r), ring(p1, r * 0.92)], color)


def model(cfg):
    """Lista de peças: cada peça é uma lista de faces convexas (contorno só na silhueta)."""
    kart = rgb(cfg.get("cor", "#62d8e8"))
    acc = rgb(cfg.get("cor_detalhe", "#3b4456"))
    shirt = rgb(cfg.get("camisa", "#1d1d22"))
    skin = rgb(cfg.get("pele", "#b98260"))
    tire = (46, 48, 56)
    rim = (196, 202, 212)
    metal = (120, 126, 138)
    parts = []
    # carroceria: 3 anéis (base recolhida, cintura, topo chanfrado) = laterais arredondadas
    parts.append(loft([plan_ring(0.14, 0.40, 0.58, 1.02, scale=0.9),
                       plan_ring(0.32, 0.46, 0.64, 1.05),
                       plan_ring(0.44, 0.36, 0.54, 0.98, scale=0.92)], kart))
    # bico afinado
    parts.append(loft([ellipse_ring((0, 0.40, -0.70), 0.40, 0.14),
                       ellipse_ring((0, 0.36, -1.02), 0.34, 0.10),
                       ellipse_ring((0, 0.30, -1.20), 0.22, 0.06)], kart))
    # para-choque dianteiro arredondado
    parts.append(loft([plan_ring(0.20, 0.70, 0.70, 0.10, r=0.09, z0=-1.22),
                       plan_ring(0.32, 0.70, 0.70, 0.10, r=0.09, z0=-1.22)], acc))
    # pontões laterais (cápsulas)
    for sx in (-0.70, 0.70):
        parts.append(loft([ellipse_ring((sx, 0.34, -0.42), 0.06, 0.06),
                           ellipse_ring((sx, 0.34, -0.25), 0.11, 0.12),
                           ellipse_ring((sx, 0.34, 0.40), 0.11, 0.12),
                           ellipse_ring((sx, 0.34, 0.56), 0.06, 0.07)], acc))
    # motor e aerofólio
    parts.append(loft([plan_ring(0.30, 0.30, 0.30, 0.18, r=0.10, z0=0.98),
                       plan_ring(0.56, 0.26, 0.26, 0.15, r=0.10, z0=0.98)], metal))
    for sx in (-0.46, 0.46):
        parts.append(tube((sx, 0.42, 1.10), (sx, 0.70, 1.14), 0.035, acc))
    parts.append(loft([plan_ring(0.70, 0.74, 0.74, 0.16, r=0.08, z0=1.14),
                       plan_ring(0.78, 0.74, 0.74, 0.13, r=0.07, z0=1.16)], kart))
    # banco
    parts.append(loft([plan_ring(0.44, 0.30, 0.32, 0.20, r=0.12, z0=0.60),
                       plan_ring(0.92, 0.28, 0.30, 0.10, r=0.08, z0=0.74)], mul(kart, 0.7)))
    # rodas (cilindros) + cubos
    for sx in (-0.74, 0.74):
        for sz in (-0.72, 0.80):
            parts.append(cylinder_x((sx, 0.27, sz), 0.27, 0.30, tire))
            parts.append(cylinder_x((sx * 1.2, 0.27, sz), 0.12, 0.03, rim, n=12))
    # piloto: tronco arredondado
    parts.append(loft([ellipse_ring((0, 0.50, 0.40), 0.30, 0.22, "y"),
                       ellipse_ring((0, 0.82, 0.38), 0.35, 0.24, "y"),
                       ellipse_ring((0, 1.06, 0.36), 0.28, 0.20, "y"),
                       ellipse_ring((0, 1.12, 0.36), 0.12, 0.10, "y")], shirt))
    # braços até o volante
    for sx in (-1, 1):
        sh = (0.30 * sx, 1.00, 0.34)
        el = (0.34 * sx, 0.80, 0.08)
        hd = (0.20 * sx, 0.86, -0.28)
        parts.append(tube(sh, el, 0.085, shirt))
        parts.append(tube(el, hd, 0.065, skin))
        parts.append(loft([ellipse_ring(hd, 0.06, 0.06, "x", 8),
                           ellipse_ring((hd[0], hd[1], hd[2] - 0.08), 0.05, 0.05, "x", 8)], skin))
    # volante
    parts.append(tube((0, 0.62, -0.10), (0, 0.84, -0.30), 0.03, tire))
    parts.append(loft([ellipse_ring((0, 0.86, -0.32), 0.20, 0.13, "z", 16),
                       ellipse_ring((0, 0.86, -0.36), 0.20, 0.13, "z", 16)], (36, 38, 46)))
    return parts


def helmet(cfg, c):
    col = rgb(cfg.get("capacete", "#101823"))
    rings = []
    for k in range(1, 8):
        a = math.pi * k / 8
        rings.append(ellipse_ring((c[0], c[1] + 0.27 * math.cos(a), c[2]), 0.26 * math.sin(a), 0.27 * math.sin(a), "y", 14))
    visor = loft([ellipse_ring((c[0], c[1] - 0.02, c[2] - 0.20), 0.17, 0.07, "z", 12),
                  ellipse_ring((c[0], c[1] - 0.02, c[2] - 0.26), 0.15, 0.06, "z", 12)], (40, 60, 92))
    return [loft(rings, col), visor]


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


def head_variants(head_path, hair_hex="#28211c"):
    """Retorna dict: 'lado' (olha à direita), 'costas' (nuca), por silhueta da ilustração."""
    if not head_path:
        return None
    src = Image.open(head_path).convert("RGBA")
    alpha = src.getchannel("A")
    sym = ImageChops.lighter(alpha, alpha.transpose(Image.FLIP_LEFT_RIGHT))  # silhueta simétrica
    w, h = src.size
    layer = Image.new("RGBA", src.size, (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)
    # nuca: cabelo escuro em cima, pescoço/orelhas embaixo, sombreado em planos
    hair = rgb(hair_hex)
    dr.rectangle((0, 0, w, int(h * 0.74)), fill=hair + (255,))
    dr.rectangle((0, int(h * 0.40), w // 2, int(h * 0.74)), fill=mul(hair, 0.78) + (255,))
    dr.rectangle((0, int(h * 0.74), w, h), fill=(150, 104, 76, 255))
    dr.rectangle((0, int(h * 0.74), w // 2, h), fill=(126, 86, 62, 255))
    dr.ellipse((int(w * 0.02), int(h * 0.42), int(w * 0.16), int(h * 0.62)), fill=(164, 114, 84, 255))
    dr.ellipse((int(w * 0.84), int(h * 0.42), int(w * 0.98), int(h * 0.62)), fill=(150, 104, 76, 255))
    back = Image.new("RGBA", src.size, (0, 0, 0, 0))
    back.paste(layer, (0, 0), sym)
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


def _shade(n):
    lit = Cam.dot(n, LIGHT)
    return 1.0 if lit > 0.55 else (0.84 if lit > 0.15 else 0.68)   # cel shading em planos


def render(cfg, heads, k):
    W = FRAME * SS
    cam = Cam(k * math.tau / FRAMES)
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    head_c = (0.0, 1.36, 0.30)
    head_h = 0.70
    parts = model(cfg)
    if not heads:
        parts += helmet(cfg, head_c)
    items = []
    for faces in parts:
        verts = [p for poly, _, _ in faces for p in poly]
        depth = sum(cam.depth(p) for p in verts) / len(verts)
        items.append((depth, "peca", faces))
    if heads:
        items.append((cam.depth(head_c) + 0.08, "cabeca", None))
    # sombra no chão
    sh = [cam.proj((x * 1.0, 0, z)) for x, z in ((-0.95, -1.25), (0.95, -1.25), (0.95, 1.25), (-0.95, 1.25))]
    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).polygon(sh, fill=(0, 0, 0, 80))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6 * SS)))
    items.sort(key=lambda t: t[0])
    grow = ImageFilter.MaxFilter(2 * SS + 1)
    for _, kind, faces in items:
        if kind == "peca":
            layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
            dr = ImageDraw.Draw(layer)
            vis = [(sum(cam.depth(p) for p in poly) / len(poly), poly, n, col) for poly, n, col in faces
                   if Cam.dot(n, cam.d) > 0.001]
            vis.sort(key=lambda t: t[0])
            for _, poly, n, col in vis:
                c = mul(col, _shade(n)) + (255,)
                dr.polygon([cam.proj(p) for p in poly], fill=c, outline=c)
            # contorno escuro fino só na silhueta da peça
            mask = layer.getchannel("A").filter(grow)
            ol = Image.new("RGBA", (W, W), OUTLINE + (255,))
            ol.putalpha(mask)
            img.alpha_composite(ol)
            img.alpha_composite(layer)
        else:
            hv = head_for_frame(heads, k)
            ph = int(head_h * SCALE)
            pw = int(hv.width * ph / hv.height)
            hv = hv.resize((pw, ph), Image.LANCZOS)
            cx, cy = cam.proj(head_c)
            img.alpha_composite(hv, (int(cx - pw / 2), int(cy - ph * 0.55)))
    return img.resize((FRAME, FRAME), Image.LANCZOS)


def main():
    kdir = pathlib.Path(sys.argv[1])
    cfg = json.loads((kdir / "kart.json").read_text(encoding="utf-8"))
    heads = head_variants(kdir / cfg["cabeca"], cfg.get("cabelo", "#28211c")) if cfg.get("cabeca") else None
    sheet = Image.new("RGBA", (FRAME * FRAMES, FRAME), (0, 0, 0, 0))
    for k in range(FRAMES):
        sheet.paste(render(cfg, heads, k), (k * FRAME, 0))
    out = kdir / cfg.get("sprite", "sprites/sheet.png")
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print("ok", out)


if __name__ == "__main__":
    main()
