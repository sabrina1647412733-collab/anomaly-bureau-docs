# -*- coding: utf-8 -*-
"""线上验收：旧地址 301、入口标题、OG/favicon。"""
import re
import urllib.request
from urllib.parse import quote

BASE = "https://visionary-concha-bf9fea.netlify.app"


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


opener = urllib.request.build_opener(NoRedirect)


def get(path):
    req = urllib.request.Request(BASE + "/" + quote(path), headers={"User-Agent": "Mozilla/5.0"})
    try:
        with opener.open(req, timeout=30) as r:
            return r.status, dict(r.headers), r.read()
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers), e.read()


def title(html):
    m = re.search(rb"<title>(.*?)</title>", html, re.S | re.I)
    return m.group(1).decode("utf-8", "replace").strip() if m else None


ok = True


def check(cond, msg):
    global ok
    print(("PASS  " if cond else "FAIL  ") + msg)
    if not cond:
        ok = False


# 入口
st, h, body = get("")
check(st == 200, f"入口 200（实际 {st}）")
t = title(body)
check("0017" not in (t or ""), f"入口标签不含 0017：{t}")
check(body.count(b'class="card') == 2, "入口只有 2 个入口卡片")
check("首案 0017 已开启，其余案卷尚未开启" in body.decode("utf-8", "replace"), "状态文案正确")
check("第二次作业" not in body.decode("utf-8", "replace"), "无课程口径")
check('property="og:image"' in body.decode("utf-8", "replace"), "入口含 OG 图")
check(b"setInterval" not in body, "入口无 setInterval")

# 旧地址
for name in ["v2.html", "v2", "v3.html", "v4.html", "v5-值班台版.html",
             "3d-岚桥站.html", "角色互动版.html", "v5.html", "3d.html"]:
    st, h, _ = get(name)
    loc = h.get("Location", "")
    check(st == 301 and loc in ("/", BASE + "/"), f"/{name} → {st} {loc}")

# 新入口与资源
for path, ctype in [("v6-人话版.html", "text/html"), ("game/", "text/html"),
                    ("og-cover.png", "image/png"), ("favicon.ico", "image"),
                    ("favicon-32.png", "image/png")]:
    st, h, body = get(path)
    ct = h.get("Content-Type", "")
    check(st == 200 and ctype in ct, f"/{path} → {st} {ct}")
    if path.endswith(".html"):
        t = title(body)
        check("0017" not in (t or ""), f"/{path} 标签不含 0017：{t}")

st, h, body = get("game/index.html")
check(st == 200, "game/index.html 200")
check(b"setInterval" not in body, "游戏页无 setInterval")
check(b"document.title = " in body, "启动后设置一次标题")

print("\nRESULT:", "ALL PASS" if ok else "HAS FAILURES")
raise SystemExit(0 if ok else 1)
