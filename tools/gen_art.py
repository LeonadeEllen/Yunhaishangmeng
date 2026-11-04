#!/usr/bin/env python3
"""Generate 云海商盟 portraits with the Gemini image API (style: 纸雕国风 · 云海蒸汽).

Usage: GEMINI_API_KEY=... python3 tools/gen_art.py luqing [--ref godot/assets/art/leaders/05.webp]
Writes raw PNGs to art-in/gen/<id>_<mood>_<n>.png and the chosen cut-out to
godot/assets/art/portraits/<id>[_mood].webp (384x384, transparent bg, eyes aligned).
"""
import argparse, base64, io, json, os, sys, urllib.request
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"
MODELS = ["gemini-3-pro-image-preview", "gemini-2.5-flash-image", "gemini-2.5-flash-image-preview"]

STYLE = ("纸雕立体插画风格，多层手工剪纸叠出的人物胸像，纸张边缘清晰可见，层与层之间有柔和投影；"
         "国风服饰融合黄铜蒸汽朋克小机件（齿轮、铜扣、罗盘、铆钉），机件不超过三处；不描粗黑线；"
         "柔和顶光从左上方打来，右下方阴影；整体色调米白、靛青、黄铜，少量朱红点缀；"
         "三分之四侧面，胸像构图，头顶留 15% 空白，竖构图 2:3；背景为纯平的浅米色 #F0E8D7，无任何图案；"
         "高细节，无文字，无水印，无边框。")
CHARS = {
    "luqing": "人物：陆青，二十岁的霞鲸台采珠女，冷静寡言，正在寻找失踪的父亲。银白长发编成侧辫，额前碎发，"
              "羽毛披肩，靛青交领短褂，腰间挂珍珠网兜和小铜罗盘。",
}
MOODS = {"": "神情平静，目光略带忧郁，嘴角放平。",
         "happy": "浅浅一笑，眼睛微弯，神情放松。",
         "upset": "眉头微皱，嘴角向下，目光移开。"}
EDIT = "保持这张图的人物、服饰、角度、构图、光线和纸雕质感完全不变，只改表情：%s"


def call(model, parts):
    body = {"contents": [{"parts": parts}],
            "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": "2:3"}}}
    req = urllib.request.Request(API % model, json.dumps(body).encode(),
                                 {"Content-Type": "application/json", "x-goog-api-key": os.environ["GEMINI_API_KEY"]})
    with urllib.request.urlopen(req, timeout=180) as r:
        data = json.load(r)
    for c in data.get("candidates", []):
        for p in c.get("content", {}).get("parts", []):
            if "inlineData" in p:
                return Image.open(io.BytesIO(base64.b64decode(p["inlineData"]["data"]))).convert("RGBA")
    raise RuntimeError("no image: %s" % json.dumps(data)[:400])


def img_part(im):
    b = io.BytesIO(); im.convert("RGB").save(b, "PNG")
    return {"inlineData": {"mimeType": "image/png", "data": base64.b64encode(b.getvalue()).decode()}}


def cutout(im, tol=28):
    """Key out the flat background by flood fill from the borders."""
    rgb = im.convert("RGB"); w, h = rgb.size
    mask = Image.new("L", (w, h), 0)
    seed_col = rgb.getpixel((2, 2))
    from collections import deque
    px = rgb.load(); mp = mask.load(); q = deque()
    for x in range(w): q += [(x, 0), (x, h - 1)]
    for y in range(h): q += [(0, y), (w - 1, y)]
    while q:
        x, y = q.popleft()
        if mp[x, y]: continue
        r, g, b = px[x, y]
        if abs(r - seed_col[0]) + abs(g - seed_col[1]) + abs(b - seed_col[2]) > tol * 3: continue
        mp[x, y] = 255
        if x > 0: q.append((x - 1, y))
        if x < w - 1: q.append((x + 1, y))
        if y > 0: q.append((x, y - 1))
        if y < h - 1: q.append((x, y + 1))
    alpha = Image.eval(mask.filter(ImageFilter.GaussianBlur(1.2)), lambda v: 255 - v)
    out = im.copy(); out.putalpha(alpha)
    return out


def to_portrait(im, size=384):
    """Square 384 frame: head-and-shoulders crop from the top of the bust, like the old procedural files."""
    bbox = im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox() or (0, 0) + im.size
    l, t, r, b = bbox
    side = int((r - l) * 1.0)
    cx = (l + r) // 2
    top = max(0, t - int(side * 0.06))
    crop = im.crop((cx - side // 2, top, cx + side // 2, top + side))
    return crop.resize((size, size), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("id"); ap.add_argument("--ref"); ap.add_argument("--n", type=int, default=2)
    ap.add_argument("--model"); ap.add_argument("--moods", default=",happy,upset")
    a = ap.parse_args()
    out_dir = os.path.join(ROOT, "art-in", "gen"); os.makedirs(out_dir, exist_ok=True)
    ref = Image.open(a.ref) if a.ref else None
    models = [a.model] if a.model else MODELS
    base = None
    for mood in a.moods.split(","):
        for n in range(a.n if mood == "" else 1):
            if mood == "" or base is None:
                parts = [{"text": STYLE + CHARS[a.id] + MOODS[mood]}]
                if ref is not None:
                    parts = [img_part(ref), {"text": "参考这张图的人物长相和纸雕画风，重新画一张："}] + parts
            else:
                parts = [img_part(base), {"text": EDIT % MOODS[mood]}]
            for m in models:
                try:
                    im = call(m, parts); break
                except Exception as e:
                    print("model", m, "failed:", e, file=sys.stderr)
            else:
                sys.exit(1)
            name = "%s%s_%d.png" % (a.id, "_" + mood if mood else "", n)
            im.save(os.path.join(out_dir, name)); print("saved", name, "via", m)
            if mood == "" and n == 0:
                base = im
            if n == 0:
                fn = a.id + ("_" + mood if mood else "") + ".webp"
                to_portrait(cutout(im)).save(os.path.join(ROOT, "godot/assets/art/portraits", fn), "WEBP", quality=90)


if __name__ == "__main__":
    main()
