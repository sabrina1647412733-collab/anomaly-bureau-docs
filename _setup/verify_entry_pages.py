# -*- coding: utf-8 -*-
"""本地静态验收：入口入口数、标题、旧链接、OG/favicon 资源。"""
import re
import threading
import urllib.request
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent.parent
DEPLOY = ROOT / "deploy"
PORT = 8765


class Quiet(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def fetch(path):
    url = f"http://127.0.0.1:{PORT}/{quote(path)}"
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, ""


def title_of(html):
    m = re.search(r"<title>(.*?)</title>", html, re.S | re.I)
    return m.group(1).strip() if m else None


def main():
    handler = partial(Quiet, directory=str(DEPLOY))
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()

    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("PASS  " if cond else "FAIL  ") + msg)
        if not cond:
            ok = False

    st, html = fetch("")
    cards = re.findall(r'<a class="card[^"]*" href="([^"]+)"', html)
    check(st == 200, "入口页 200")
    check(len(cards) == 2, f"入口页只有 2 个入口：{cards}")
    check(cards == ["game/", "v6-人话版.html"], "两个入口是 game/ 与 v6-人话版.html")
    check("首案 0017 已开启，其余案卷尚未开启" in html, "入口页状态文案正确")
    check("第二次作业" not in html, "已去掉「第二次作业交付」课程口径")
    check("setInterval" not in html, "入口页无 setInterval")
    check(title_of(html) == "诡异事务局 · 第一季「补丁」", f"入口页标签：{title_of(html)}")
    check("0017" not in (title_of(html) or ""), "入口页标签不含 0017")
    for asset in ("og-cover.png", "favicon.ico", "favicon-32.png", "apple-touch-icon.png"):
        code, _ = fetch(asset)
        check(code == 200, f"资源可访问 {asset}")

    st, v6 = fetch("v6-人话版.html")
    check(st == 200, "v6 原型 200")
    check("0017" not in (title_of(v6) or ""), f"v6 标签不含 0017：{title_of(v6)}")

    old = ["v2.html", "v3.html", "v4.html", "v5-值班台版.html", "3d-岚桥站.html", "角色互动版.html"]
    for name in old:
        code, body = fetch(name)
        check(code == 200 and 'http-equiv="refresh"' in body and 'location.replace("/")' in body,
              f"旧链接不 404 且跳回入口 {name}")

    st, game = fetch("game/index.html")
    check(st == 200, "game/index.html 200")
    check("setInterval" not in game, "游戏页已移除 setInterval hack")
    check("document.title = '诡异事务局 · 第一季「补丁」'" in game, "游戏页启动后设置一次标题")
    check("0017" not in (title_of(game) or ""), f"游戏页标签不含 0017：{title_of(game)}")

    srv.shutdown()
    print("\nRESULT:", "ALL PASS" if ok else "HAS FAILURES")
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
