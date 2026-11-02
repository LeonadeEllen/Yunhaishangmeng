"""Extract the embedded art atlases from the HTML prototype into PNG/WebP files for Godot.
Usage: python3 tools/extract_art.py prototype/yunhai-v4.0.html godot/assets/art
"""
import base64, io, json, os, sys
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
text = open(src, encoding='utf8').read()
start = text.index('const entries=[')
line = text[start:text.index('\n', start)]
entries = json.loads(line[line.index('['):line.rindex(']') + 1])
os.makedirs(out, exist_ok=True)
index = {}
for e in entries:
    img = Image.open(io.BytesIO(base64.b64decode(e['base64']))).convert('RGBA')
    frames = e.get('frames') or []
    if frames:
        d = os.path.join(out, e['id']); os.makedirs(d, exist_ok=True)
        names = []
        for i, f in enumerate(frames):
            x, y, w, h = f['rect']
            crop = img.crop((x, y, x + w, y + h))
            bbox = crop.getbbox()
            if bbox: crop = crop.crop(bbox)
            p = os.path.join(d, f'{i:02d}.webp'); crop.save(p, quality=90, method=6); names.append(p)
        index[e['id']] = {'frames': len(frames)}
    else:
        d = os.path.join(out, 'scenes'); os.makedirs(d, exist_ok=True)
        if img.width > 1600: img = img.resize((1600, round(img.height * 1600 / img.width)), Image.LANCZOS)
        img.convert('RGB').save(os.path.join(d, e['id'] + '.webp'), quality=88)
        index[e['id']] = {'scene': True}
json.dump(index, open(os.path.join(out, 'index.json'), 'w'), indent=1)
print(len(index), 'sheets')
