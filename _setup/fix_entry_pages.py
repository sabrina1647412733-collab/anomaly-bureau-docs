# -*- coding: utf-8 -*-
"""把已下线的历史入口替换为跳转桩，并生成 Netlify 301 规则。"""
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent.parent
DEPLOY = ROOT / "deploy"

OLD = [
    "v2.html",
    "v3.html",
    "v4.html",
    "v5-值班台版.html",
    "3d-岚桥站.html",
    "角色互动版.html",
]

STUB = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>已下线 · 诡异事务局</title>
<meta name="robots" content="noindex,follow">
<link rel="canonical" href="https://visionary-concha-bf9fea.netlify.app/">
<meta http-equiv="refresh" content="0; url=/">
<script>location.replace("/");</script>
<style>
  body{{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
       background:#07090f;color:#8b98ac;font:15px/1.8 "Microsoft YaHei",system-ui,sans-serif}}
  a{{color:#5ad1ff;text-decoration:none}} a:hover{{text-decoration:underline}}
  .box{{text-align:center;padding:24px}}
  b{{color:#e8eef7;font-size:18px;display:block;margin-bottom:6px}}
</style>
</head>
<body>
<div class="box">
  <b>该版本已下线</b>
  正在返回《诡异事务局》入口……<br>
  如果没有自动跳转，请<a href="/">点此进入</a>。
</div>
</body>
</html>
"""

lines = ["# 历史版本入口 → 新入口（301）", "# 由 _setup/fix_entry_pages.py 生成", ""]
for name in OLD:
    stem = name[:-5]
    lines.append(f"/{name} / 301!")
    lines.append(f"/{quote(name)} / 301!")
    lines.append(f"/{stem} / 301!")
    lines.append(f"/{quote(stem)} / 301!")
    (DEPLOY / name).write_text(STUB, encoding="utf-8")

# 旧式短名
for alias in ("v5.html", "3d.html", "角色互动.html"):
    lines.append(f"/{alias} / 301!")
    lines.append(f"/{quote(alias)} / 301!")

lines += [
    "",
    "# 注意：不要使用 /*.html 兜底，避免误伤 v6-人话版.html",
]

# 去重并保持顺序
seen = set()
uniq = []
for line in lines:
    if line.startswith("/") or line.startswith("#") or not line:
        if line in seen:
            continue
        seen.add(line)
    uniq.append(line)

(DEPLOY / "_redirects").write_text("\n".join(uniq) + "\n", encoding="utf-8")
print("stubs:", len(OLD), "redirects:", len(lines))
