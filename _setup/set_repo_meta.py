import json, subprocess, sys, pathlib

token = pathlib.Path(r"F:\诡异事务局\_setup\.gh_token2").read_text(encoding="utf-8").strip()
api = "https://api.github.com"
repos = {
    "anomaly-bureau-docs": ("诡异事务局 — 剧本、世界观圣经、Codex 交接文档与 Web 原型页面",
                            ["godot", "game-design", "screenplay", "chinese", "visual-novel"]),
    "anomaly-bureau-game": ("诡异事务局 · 第一季「补丁」— Godot 4.7 主工程（岚桥站 0017 序章 / 便利店 / 铁路）",
                            ["godot", "gdscript", "game", "horror", "3d"]),
}

for name, (desc, topics) in repos.items():
    body = json.dumps({"description": desc, "topics": topics, "has_wiki": False}).encode("utf-8")
    p = subprocess.run([
        "curl", "-sS", "-m", "40", "--proxy", "http://127.0.0.1:7897",
        "-o", "/tmp/patch.json", "-w", "%{http_code}", "-X", "PATCH",
        "-H", "Authorization: token " + token,
        "-H", "Accept: application/vnd.github+json",
        "-H", "Content-Type: application/json; charset=utf-8",
        "--data-binary", "@-",
        api + "/repos/sabrina1647412733-collab/" + name,
    ], input=body, capture_output=True)
    resp = json.load(open("/tmp/patch.json", encoding="utf-8"))
    print(name, "->", p.stdout, resp.get("description", resp.get("message")))
