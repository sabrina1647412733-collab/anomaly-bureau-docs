# -*- coding: utf-8 -*-
"""生成入口页 OG 图与 favicon（无外部依赖，使用 Pillow + 系统微软雅黑）。"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
DEPLOY = ROOT / "deploy"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"
FONT_REG = r"C:\Windows\Fonts\msyh.ttc"

CYAN = (90, 209, 255)
GOLD = (255, 212, 121)
FG = (232, 238, 247)
DIM = (139, 152, 172)


def font(path, size, index=0):
    return ImageFont.truetype(path, size, index=index)


def make_og():
    W, H = 1200, 630
    img = Image.new("RGB", (W, H), (7, 9, 15))
    d = ImageDraw.Draw(img)

    # 纵向渐变
    top, bottom = (7, 9, 15), (13, 18, 25)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))

    # 轨道透视线
    track = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    td = ImageDraw.Draw(track)
    for i in range(-3, 9):
        x = i * 170
        td.line([(x, H), (W // 2 + (x - W // 2) * 0.18, 330)], fill=(90, 209, 255, 16), width=2)
    for y in (430, 470, 510, 550, 590):
        td.line([(0, y), (W, y)], fill=(90, 209, 255, 10), width=1)
    img = Image.alpha_composite(img.convert("RGBA"), track).convert("RGB")
    d = ImageDraw.Draw(img)

    # 左侧青色光带 + 右侧暖光
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-260, 260, 460, 760], fill=(90, 209, 255, 26))
    gd.ellipse([760, -220, 1360, 320], fill=(255, 212, 121, 20))
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    img = Image.alpha_composite(img.convert("RGBA"), glow).convert("RGB")
    d = ImageDraw.Draw(img)

    # 顶部标识
    d.rounded_rectangle([72, 66, 300, 104], radius=19, fill=(16, 26, 38), outline=(43, 74, 99), width=1)
    d.text((92, 73), "ANOMALY BUREAU", font=font(FONT_BOLD, 17), fill=CYAN)

    # 主标题
    d.text((72, 150), "诡异事务局", font=font(FONT_BOLD, 108), fill=FG)
    d.text((76, 286), "第一季「补丁」", font=font(FONT_BOLD, 44), fill=GOLD)

    # 状态行
    d.rounded_rectangle([74, 372, 98, 396], radius=12, fill=(72, 214, 164))
    d.text((114, 366), "首案 0017 已开启，其余案卷尚未开启",
           font=font(FONT_REG, 30), fill=(200, 226, 214))

    # 副信息
    d.text((76, 444), "夜班调度席 · 27 分钟 · Godot 实机 + 交互原型",
           font=font(FONT_REG, 23), fill=DIM)
    d.line([(72, 512), (1128, 512)], fill=(30, 37, 49), width=1)
    d.text((76, 534), "visionary-concha-bf9fea.netlify.app",
           font=font(FONT_REG, 19), fill=(92, 103, 121))

    # 右侧细描圆环装饰
    ring = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    for r, a in ((196, 34), (152, 22), (112, 16)):
        rd.ellipse([1010 - r, 330 - r, 1010 + r, 330 + r], outline=(90, 209, 255, a), width=2)
    rd.ellipse([1004, 324, 1016, 336], fill=(90, 209, 255, 180))
    img = Image.alpha_composite(img.convert("RGBA"), ring).convert("RGB")

    img.save(DEPLOY / "og-cover.png", optimize=True)


def make_icon(size):
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=(9, 15, 23))
    d.rounded_rectangle([int(s * 0.06), int(s * 0.06), int(s * 0.94), int(s * 0.94)],
                        radius=int(s * 0.18), outline=(43, 74, 99), width=max(2, s // 48))
    # 青色横向信号线
    d.rounded_rectangle([int(s * 0.2), int(s * 0.69), int(s * 0.8), int(s * 0.73)],
                        radius=s // 100, fill=(90, 209, 255, 210))
    f = font(FONT_BOLD, int(s * 0.52))
    text = "诡"
    box = d.textbbox((0, 0), text, font=f)
    tw, th = box[2] - box[0], box[3] - box[1]
    d.text(((s - tw) / 2 - box[0], (s - th) / 2 - box[1] - s * 0.035), text, font=f, fill=(232, 238, 247))
    return img.resize((size, size), Image.LANCZOS)


def main():
    DEPLOY.mkdir(exist_ok=True)
    make_og()
    for name, size in (("favicon-32.png", 32), ("favicon-192.png", 192),
                       ("apple-touch-icon.png", 180), ("favicon-512.png", 512)):
        make_icon(size).save(DEPLOY / name, optimize=True)
    # 兼容旧浏览器的 ico
    make_icon(64).save(DEPLOY / "favicon.ico", sizes=[(16, 16), (32, 32), (48, 48)])
    print("assets written to", DEPLOY)


if __name__ == "__main__":
    main()
