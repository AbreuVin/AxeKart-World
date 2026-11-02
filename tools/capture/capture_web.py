"""Captura real da build Web: sobe um servidor local, abre no Chromium, dirige e fotografa.

Uso: python3 tools/capture/capture_web.py [pasta_saida]
"""
import functools
import http.server
import pathlib
import sys
import threading
import time

from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parents[2]
WEB = ROOT / "build" / "web"
OUT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / "scratch" / "capturas")
OUT.mkdir(parents=True, exist_ok=True)


def serve():
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(WEB))
    handler.log_message = lambda *a: None
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 8765), handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv


def main():
    srv = serve()
    logs = []
    with sync_playwright() as p:
        b = p.chromium.launch(args=["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"])
        pg = b.new_page(viewport={"width": 1280, "height": 720})
        pg.on("console", lambda m: logs.append(f"{m.type}: {m.text}"))
        pg.goto("http://127.0.0.1:8765/index.html")
        pg.wait_for_timeout(9000)
        pg.screenshot(path=str(OUT / "00_titulo.png"))
        pg.mouse.click(640, 360)
        pg.wait_for_timeout(1500)
        pg.screenshot(path=str(OUT / "01_largada.png"))
        pg.keyboard.down("ArrowUp")
        pg.wait_for_timeout(4500)
        pg.screenshot(path=str(OUT / "02_acelerando.png"))
        pg.keyboard.down("ArrowRight")
        pg.keyboard.down("Shift")
        pg.wait_for_timeout(1300)
        pg.screenshot(path=str(OUT / "03_drift.png"))
        pg.keyboard.up("Shift")
        pg.keyboard.up("ArrowRight")
        pg.wait_for_timeout(2500)
        pg.screenshot(path=str(OUT / "04_corrida.png"))
        b.close()
    srv.shutdown()
    errs = [l for l in logs if l.startswith("error")]
    print("\n".join(logs[-15:]))
    print("erros:", len(errs))


if __name__ == "__main__":
    main()
