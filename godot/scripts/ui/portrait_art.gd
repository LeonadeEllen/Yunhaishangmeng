class_name PortraitArt
## Paper-cut bust portraits for every named character, painted from the same "look" as their
## town figure (PaperFolk.LOOKS) plus a few face details. tools/render_portraits.gd renders them
## once into assets/art/portraits/<id>[_happy|_upset].webp; the game only loads those files, so a
## commissioned painting with the same file name simply replaces one.
##
## Canvas: 512 x 512. mood: "" (calm), "happy", "upset".

## Face details per character: face shape, brows, eyes, age, and the colour of the halo behind them.
const FACE := {
	"hero_lamp":  {"face": "oval", "brow": "soft", "eyes": "warm", "age": 0, "halo": Color("e3b45a")},
	"hero_iron":  {"face": "square", "brow": "stern", "eyes": "narrow", "age": 1, "halo": Color("6a8aa6"), "stubble": true},
	"hero_tower": {"face": "long", "brow": "thin", "eyes": "calm", "age": 1, "halo": Color("8fbfb0"), "lips": Color("b0504a")},
	"xiaoman":  {"face": "round", "brow": "soft", "eyes": "big", "age": -1, "halo": Color("e8c88a"), "freckles": true},
	"luqing":   {"face": "oval", "brow": "thin", "eyes": "calm", "age": 0, "halo": Color("8fb9b0"), "lips": Color("a8524a")},
	"qian":     {"face": "long", "brow": "thin", "eyes": "narrow", "age": 2, "halo": Color("c9b48e"), "mustache": true},
	"aman":     {"face": "square", "brow": "stern", "eyes": "narrow", "age": 1, "halo": Color("c9603e"), "stubble": true},
	"shen":     {"face": "long", "brow": "stern", "eyes": "narrow", "age": 0, "halo": Color("aab8c4")},
	"cen":      {"face": "square", "brow": "bushy", "eyes": "narrow", "age": 3, "halo": Color("b09070"), "mustache": true},
	"moyu":     {"face": "oval", "brow": "soft", "eyes": "calm", "age": 0, "halo": Color("9ab8c8"), "lips": Color("b8645a")},
	"ning":     {"face": "oval", "brow": "soft", "eyes": "warm", "age": 0, "halo": Color("b8c8d4")},
	"feng":     {"face": "oval", "brow": "thin", "eyes": "sly", "age": 1, "halo": Color("a86a9a"), "lips": Color("9a2e3e"), "mole": true},
	"sang":     {"face": "square", "brow": "bushy", "eyes": "narrow", "age": 2, "halo": Color("c9783e"), "soot": true},
	"helan":    {"face": "long", "brow": "stern", "eyes": "warm", "age": 1, "halo": Color("e0b860"), "mustache": true},
	"ling":     {"face": "round", "brow": "thin", "eyes": "big", "age": -1, "halo": Color("bfe6f2"), "lips": Color("c8787a")},
	"duoyin":   {"face": "oval", "brow": "soft", "eyes": "warm", "age": 0, "halo": Color("d9a050"), "lips": Color("a8524a")},
	"lusheng":  {"face": "round", "brow": "soft", "eyes": "big", "age": -1, "halo": Color("b8c88a"), "freckles": true},
	"shop_trade":  {"face": "round", "brow": "soft", "eyes": "warm", "age": 2, "halo": Color("d9b45a"), "mustache": true},
	"shop_yard":   {"face": "square", "brow": "bushy", "eyes": "narrow", "age": 1, "halo": Color("8a9aa6"), "stubble": true},
	"shop_hall":   {"face": "long", "brow": "stern", "eyes": "narrow", "age": 2, "halo": Color("a8463a"), "mustache": true},
	"shop_guild":  {"face": "oval", "brow": "thin", "eyes": "calm", "age": 1, "halo": Color("7a9a8a"), "lips": Color("a8524a")},
	"shop_tavern": {"face": "round", "brow": "soft", "eyes": "warm", "age": 1, "halo": Color("e8a070"), "lips": Color("b0403e")},
	"shop_bank":   {"face": "long", "brow": "thin", "eyes": "narrow", "age": 2, "halo": Color("b8a070"), "glasses": true},
}
## The shop people only appear as portraits, so their clothes live here.
const SHOP_LOOKS := {
	"shop_trade":  {"skin": 1, "hair": Color("4a4038"), "style": "short", "hat": "scholar", "robe": Color("8a5a2e"), "trim": Color("e0b860"), "prop": "abacus"},
	"shop_yard":   {"skin": 2, "hair": Color("2a2420"), "style": "short", "hat": "bandana", "hat_col": Color("3f5f7a"), "robe": Color("5a4a3a"), "trim": Color("a08a6a"), "apron": Color("8a5a36"), "bare_arms": true},
	"shop_hall":   {"skin": 0, "hair": Color("3a3430"), "style": "topknot", "hat": "scholar", "robe": Color("7a2a2a"), "trim": Color("e0b860")},
	"shop_guild":  {"skin": 0, "hair": Color("2a2220"), "style": "bun", "robe": Color("3f5f5a"), "trim": Color("c9b48e"), "female": true, "pin": Color("b08a3e"), "prop": "scroll"},
	"shop_tavern": {"skin": 1, "hair": Color("2a1d18"), "style": "bun", "robe": Color("a8463a"), "trim": Color("f0d8a0"), "female": true, "apron": Color("f1ebdc"), "pin": Color("d9402e"), "earring": true},
	"shop_bank":   {"skin": 0, "hair": Color("6a6058"), "style": "short", "hat": "scholar", "robe": Color("2f3f5a"), "trim": Color("b08a3e"), "prop": "abacus"},
}
const IDS := ["hero_lamp", "hero_iron", "hero_tower", "xiaoman", "luqing", "qian", "aman", "shen", "cen", "moyu", "ning", "feng", "sang",
	"helan", "ling", "duoyin", "lusheng", "shop_trade", "shop_yard", "shop_hall", "shop_guild", "shop_tavern", "shop_bank"]
const MOODS := ["", "happy", "upset"]
## Characters that now have a commissioned painting in assets/art/portraits; the renderer leaves them alone.
const PAINTED := ["luqing"]


static func look_of(id: String) -> Dictionary:
	if SHOP_LOOKS.has(id):
		return SHOP_LOOKS[id]
	return PaperFolk.LOOKS.get(id, PaperFolk.LOOKS["hero_lamp"])


# ------------------------------------------------------------------ helpers
static func _ell(c: Vector2, rx: float, ry: float, n: int = 40) -> PackedVector2Array:
	return PaperFolk._ell(c, rx, ry, n)


static func _paper(ci: CanvasItem, pts: PackedVector2Array, col: Color, depth: float = 4.0, outline: bool = true) -> void:
	var sh := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(depth * 0.7, depth))
	ci.draw_colored_polygon(sh, Color(0.18, 0.12, 0.08, 0.28))
	ci.draw_colored_polygon(pts, col)
	if outline:
		var ol := pts.duplicate()
		ol.append(pts[0])
		ci.draw_polyline(ol, Color(0.15, 0.1, 0.06, 0.45), 2.4, true)
		# the creamy cut edge of the card on the lit side
		var lit := PackedVector2Array()
		for i in pts.size():
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % pts.size()]
			if (b - a).x > 0 and (b - a).y < 0:
				ci.draw_line(a + Vector2(1, 1), b + Vector2(1, 1), Color(1, 0.97, 0.9, 0.35), 1.6, true)


static func _curve(a: Vector2, ctrl: Vector2, b: Vector2, n: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return pts


static func _skin(lk: Dictionary) -> Color:
	return PaperFolk._skin(lk)


# ------------------------------------------------------------------ the portrait
static func draw(ci: CanvasItem, id: String, mood: String = "") -> void:
	var lk := look_of(id)
	var fc: Dictionary = FACE.get(id, FACE["hero_lamp"])
	var skin := _skin(lk)
	var hair: Color = lk.get("hair", Color("231a17"))
	var robe: Color = lk.get("robe", Color("8a6a4a"))
	var trim: Color = lk.get("trim", robe.lightened(0.4))
	var halo: Color = fc.get("halo", trim)
	# backdrop: parchment, a faint cloud pattern, the halo
	ci.draw_rect(Rect2(0, 0, 512, 512), Color("efe4c8"))
	for k in 6:
		var cy := 80.0 + k * 80.0
		for j in 4:
			var cx := 40.0 + j * 140.0 + (70.0 if k % 2 == 1 else 0.0)
			ci.draw_arc(Vector2(cx, cy), 26.0, PI, TAU, 16, Color(0.7, 0.6, 0.42, 0.18), 2.0, true)
			ci.draw_arc(Vector2(cx + 30, cy + 6), 18.0, PI, TAU, 14, Color(0.7, 0.6, 0.42, 0.18), 2.0, true)
	ci.draw_colored_polygon(_ell(Vector2(256, 230), 205, 205, 64), Color(halo, 0.28))
	ci.draw_colored_polygon(_ell(Vector2(256, 230), 172, 172, 64), Color(halo, 0.22))
	if lk.get("glow", false):
		for k in 5:
			ci.draw_colored_polygon(_ell(Vector2(256, 220), 120 + k * 22, 120 + k * 22, 48), Color(0.8, 0.95, 1.0, 0.07))
	var age: int = fc.get("age", 0)
	var young: bool = age < 0
	var fem: bool = lk.get("female", false)
	var wide: float = lk.get("build", 1.0)
	# hair that falls behind the shoulders
	_hair_behind(ci, lk, fc)
	if lk.has("cape"):
		_paper(ci, PackedVector2Array([Vector2(30, 512), Vector2(80, 330), Vector2(256, 300), Vector2(432, 330), Vector2(482, 512)]), lk["cape"], 5.0)
	# shoulders and robe with a crossed collar (left over right)
	var sw := 175.0 * clampf(wide, 0.85, 1.25) * (0.9 if young or fem else 1.0)
	var body := PackedVector2Array([Vector2(256 - sw - 30, 512), Vector2(256 - sw, 390), Vector2(256 - sw * 0.6, 342), Vector2(256, 330),
		Vector2(256 + sw * 0.6, 342), Vector2(256 + sw, 390), Vector2(256 + sw + 30, 512)])
	if lk.get("bare_arms", false):
		# a sleeveless vest over bare shoulders
		_paper(ci, body, skin.darkened(0.06), 5.0)
		_paper(ci, PackedVector2Array([Vector2(256 - sw * 0.62, 512), Vector2(256 - sw * 0.62, 352), Vector2(256, 334), Vector2(256 + sw * 0.62, 352), Vector2(256 + sw * 0.62, 512)]), robe, 5.0)
	else:
		_paper(ci, body, robe, 5.0)
		# sleeve folds
		ci.draw_polyline(_curve(Vector2(256 - sw * 0.82, 512), Vector2(256 - sw * 0.9, 430), Vector2(256 - sw * 0.7, 380)), robe.darkened(0.2), 3.0, true)
		ci.draw_polyline(_curve(Vector2(256 + sw * 0.82, 512), Vector2(256 + sw * 0.9, 430), Vector2(256 + sw * 0.7, 380)), robe.darkened(0.2), 3.0, true)
	if lk.has("apron"):
		_paper(ci, PackedVector2Array([Vector2(170, 512), Vector2(180, 420), Vector2(332, 420), Vector2(342, 512)]), lk["apron"], 3.0)
		ci.draw_line(Vector2(180, 424), Vector2(256 - sw * 0.6, 350), Color(lk["apron"]).darkened(0.2), 5.0, true)
		ci.draw_line(Vector2(332, 424), Vector2(256 + sw * 0.6, 350), Color(lk["apron"]).darkened(0.2), 5.0, true)
	# inner white robe, then the collar bands
	_paper(ci, PackedVector2Array([Vector2(214, 336), Vector2(256, 420), Vector2(298, 336)]), Color("f4efe2"), 2.0)
	var col_l := PackedVector2Array([Vector2(206, 334), Vector2(226, 330), Vector2(300, 470), Vector2(280, 482)])
	var col_r := PackedVector2Array([Vector2(306, 334), Vector2(286, 330), Vector2(240, 410), Vector2(252, 424)])
	_paper(ci, col_r, trim, 2.5)
	_paper(ci, col_l, trim, 3.0)
	if lk.get("buttons", false):
		for k in 4:
			ci.draw_circle(Vector2(300 + k * 6, 380 + k * 28), 6.0, Color("e0b860"))
	if lk.get("pauldron", false):
		_paper(ci, _ell(Vector2(256 - sw * 0.82, 382), 58, 32, 28), Color("b08a3e"), 4.0)
		for k in 3:
			ci.draw_arc(Vector2(256 - sw * 0.82, 382 + k * 8), 46 - k * 6, PI * 1.1, PI * 1.9, 12, Color("7a5a2a"), 2.0, true)
	# sash
	ci.draw_rect(Rect2(256 - sw * 0.75, 486, sw * 1.5, 26), trim.darkened(0.3))
	# neck
	_paper(ci, PackedVector2Array([Vector2(222, 260), Vector2(290, 260), Vector2(294, 340), Vector2(256, 352), Vector2(218, 340)]), skin.darkened(0.07), 2.0, false)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(222, 280), Vector2(290, 280), Vector2(290, 300), Vector2(256, 312), Vector2(222, 300)]), Color(0.4, 0.2, 0.1, 0.12))
	# ears
	var face_c := Vector2(256, 200)
	var rx := 88.0
	var ry := 108.0
	match fc.get("face", "oval"):
		"round": rx = 94.0; ry = 100.0
		"long": rx = 82.0; ry = 114.0
		"square": rx = 92.0; ry = 106.0
	if young:
		face_c.y += 10
		ry -= 8
	_paper(ci, _ell(face_c + Vector2(-rx + 4, 18), 17, 25, 20), skin.darkened(0.05), 2.0)
	_paper(ci, _ell(face_c + Vector2(rx - 4, 18), 17, 25, 20), skin.darkened(0.05), 2.0)
	if lk.get("earring", false):
		ci.draw_circle(face_c + Vector2(-rx + 2, 48), 8, Color("e3b45a"))
		ci.draw_circle(face_c + Vector2(rx - 2, 48), 8, Color("e3b45a"))
	# face: an ellipse whose jaw narrows (squarer for "square")
	var face := PackedVector2Array()
	for i in 64:
		var a := TAU * float(i) / 64.0
		var p := Vector2(cos(a) * rx, sin(a) * ry)
		if p.y > 0:
			var narrow := 0.78 if fc.get("face", "") != "square" else 0.92
			p.x *= lerpf(1.0, narrow, p.y / ry)
		face.append(face_c + p)
	_paper(ci, face, skin, 4.0)
	# shading on the shadow side and under the brow
	ci.draw_colored_polygon(_ell(face_c + Vector2(rx * 0.55, 30), rx * 0.32, ry * 0.65, 24), Color(0.5, 0.25, 0.1, 0.07))
	_features(ci, lk, fc, face_c, rx, ry, mood)
	_hair_front(ci, lk, fc, face_c, rx, ry)
	_hat(ci, lk, face_c, rx, ry)
	_prop(ci, lk)
	# brass frame
	ci.draw_rect(Rect2(6, 6, 500, 500), Color("b08a3e"), false, 6.0)
	ci.draw_rect(Rect2(16, 16, 480, 480), Color(0.69, 0.54, 0.24, 0.5), false, 2.0)


static func _features(ci: CanvasItem, lk: Dictionary, fc: Dictionary, c: Vector2, rx: float, ry: float, mood: String) -> void:
	var skin := _skin(lk)
	var hair: Color = lk.get("hair", Color("231a17"))
	var ink := Color("1e1612")
	var age: int = fc.get("age", 0)
	var eyes: String = fc.get("eyes", "calm")
	var ey := c.y + 14
	var ex := rx * 0.42
	var iris := hair.lerp(Color("3a2414"), 0.5) if hair.v < 0.6 else Color("4a6a7a")
	if lk.get("glow", false):
		iris = Color("4a9ab8")
	for side in [-1.0, 1.0]:
		var e := Vector2(c.x + side * ex, ey)
		var w := 24.0 if eyes != "big" else 27.0
		var h := 12.0 if eyes in ["narrow", "sly"] else (17.0 if eyes == "big" else 14.0)
		if mood == "happy":
			# smiling eyes: closed arcs
			ci.draw_polyline(_curve(e + Vector2(-w, 4), e + Vector2(0, -h * 1.1), e + Vector2(w, 4)), ink, 5.0, true)
			continue
		var droop := 4.0 if mood == "upset" and side * 1.0 > 0 else 0.0
		var almond := PackedVector2Array()
		for i in 21:
			var t := float(i) / 20.0
			var x := lerpf(-w, w, t)
			var top := -h * sin(t * PI) * (1.0 if eyes != "sly" else 0.8)
			almond.append(e + Vector2(x, top))
		for i in range(19, 0, -1):
			var t := float(i) / 20.0
			var x := lerpf(-w, w, t)
			almond.append(e + Vector2(x, h * 0.55 * sin(t * PI)))
		ci.draw_colored_polygon(almond, Color("fbf7ee"))
		ci.draw_circle(e + Vector2(side * -2.0, -1), h * 0.78, iris)
		ci.draw_circle(e + Vector2(side * -2.0, -1), h * 0.4, ink)
		ci.draw_circle(e + Vector2(side * -2.0 - 4, -6), 3.6, Color.WHITE)
		# upper lid
		var lid := PackedVector2Array()
		for i in 21:
			var t := float(i) / 20.0
			lid.append(e + Vector2(lerpf(-w - 3, w + 3, t), -h * sin(t * PI) - 1 + (droop * t if side > 0 else droop * (1.0 - t))))
		ci.draw_polyline(lid, ink, 5.0, true)
		if eyes == "sly":
			ci.draw_line(e + Vector2(side * w, -2), e + Vector2(side * (w + 10), -8), ink, 3.0, true)
		# lashes for the women
		if lk.get("female", false):
			ci.draw_line(e + Vector2(side * w, -3), e + Vector2(side * (w + 9), -10), ink, 3.0, true)
		if lk.get("glasses", false) or fc.get("glasses", false):
			ci.draw_arc(e, 30, 0, TAU, 32, Color("b08a3e"), 4.0, true)
		# age lines
		if age >= 2:
			ci.draw_polyline(_curve(e + Vector2(-w * 0.7, h * 0.9), e + Vector2(0, h * 1.4), e + Vector2(w * 0.7, h * 0.9), 8), Color(0.45, 0.25, 0.15, 0.4), 2.0, true)
			ci.draw_line(e + Vector2(side * (w + 6), 2), e + Vector2(side * (w + 16), 8), Color(0.45, 0.25, 0.15, 0.4), 2.0, true)
	if lk.get("glasses", false) or fc.get("glasses", false):
		ci.draw_line(Vector2(c.x - ex + 30, ey - 4), Vector2(c.x + ex - 30, ey - 4), Color("b08a3e"), 4.0, true)
	# brows: their angle carries most of the mood
	var brow: String = fc.get("brow", "soft")
	var bw: float = {"soft": 5.0, "thin": 3.6, "stern": 7.0, "bushy": 10.0}.get(brow, 5.0)
	var bcol := hair.darkened(0.1) if hair.v < 0.7 else hair.darkened(0.3)
	for side in [-1.0, 1.0]:
		var inner := Vector2(c.x + side * (ex - 26), ey - 30)
		var outer := Vector2(c.x + side * (ex + 30), ey - 32)
		match mood:
			"upset":
				inner.y += 10 if brow in ["stern", "bushy"] else -6
			"happy":
				inner.y -= 4
				outer.y -= 2
		if brow == "stern":
			outer.y -= 6
		ci.draw_polyline(_curve(inner, (inner + outer) * 0.5 + Vector2(0, -8), outer, 10), bcol, bw, true)
	# nose
	ci.draw_polyline(_curve(Vector2(c.x + 4, ey + 8), Vector2(c.x + 10, ey + 34), Vector2(c.x - 2, ey + 44), 8), Color(0.45, 0.25, 0.15, 0.55), 3.0, true)
	ci.draw_colored_polygon(_ell(Vector2(c.x - 4, ey + 46), 9, 4, 12), Color(0.45, 0.22, 0.12, 0.25))
	# cheeks
	ci.draw_colored_polygon(_ell(Vector2(c.x - rx * 0.55, ey + 36), 20, 11, 16), Color(0.95, 0.45, 0.4, 0.22 if mood != "upset" else 0.12))
	ci.draw_colored_polygon(_ell(Vector2(c.x + rx * 0.55, ey + 36), 20, 11, 16), Color(0.95, 0.45, 0.4, 0.22 if mood != "upset" else 0.12))
	if fc.get("freckles", false):
		for k in 6:
			ci.draw_circle(Vector2(c.x + (-1 if k < 3 else 1) * (rx * 0.45 + (k % 3) * 8), ey + 28 + (k % 2) * 6), 2.0, Color(0.55, 0.32, 0.2, 0.5))
	if fc.get("soot", false):
		ci.draw_colored_polygon(_ell(Vector2(c.x + rx * 0.4, ey + 50), 22, 14, 16), Color(0.15, 0.12, 0.1, 0.22))
	if fc.get("mole", false):
		ci.draw_circle(Vector2(c.x + 30, ey + 68), 3.0, ink)
	if lk.get("scar", false):
		ci.draw_line(Vector2(c.x + ex - 22, ey - 48), Vector2(c.x + ex + 16, ey + 22), Color(0.6, 0.25, 0.2, 0.75), 4.0, true)
	if fc.get("stubble", false) or lk.has("beard"):
		var jaw := PackedVector2Array()
		for i in 25:
			var a := PI * float(i) / 24.0
			jaw.append(c + Vector2(cos(a) * rx * 0.8, sin(a) * ry * 0.98))
		jaw.append(c + Vector2(-rx * 0.6, ry * 0.42))
		jaw.append(c + Vector2(rx * 0.6, ry * 0.42))
		if lk.has("beard"):
			var bd: Color = lk["beard"]
			var beard := PackedVector2Array([c + Vector2(-rx * 0.72, ry * 0.35), c + Vector2(-rx * 0.4, ry * 0.62), c + Vector2(-26, ry * 0.58),
				c + Vector2(26, ry * 0.58), c + Vector2(rx * 0.4, ry * 0.62), c + Vector2(rx * 0.72, ry * 0.35), c + Vector2(rx * 0.5, ry * 1.0),
				c + Vector2(0, ry * 1.32), c + Vector2(-rx * 0.5, ry * 1.0)])
			_paper(ci, beard, bd, 3.0)
		else:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-rx * 0.7, ry * 0.4), c + Vector2(rx * 0.7, ry * 0.4), c + Vector2(rx * 0.45, ry * 0.92), c + Vector2(0, ry * 1.0), c + Vector2(-rx * 0.45, ry * 0.92)]), Color(0.2, 0.16, 0.14, 0.14))
	# mouth
	var m := Vector2(c.x, ey + 70)
	var lips: Color = fc.get("lips", Color(0.62, 0.32, 0.28))
	match mood:
		"happy":
			var smile := _curve(m + Vector2(-26, -4), m + Vector2(0, 30), m + Vector2(26, -4), 14)
			ci.draw_colored_polygon(smile, Color("7a2a26"))
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-20, -1), m + Vector2(20, -1), m + Vector2(14, 6), m + Vector2(-14, 6)]), Color("fbf7ee"))
			ci.draw_polyline(smile, lips.darkened(0.2), 3.0, true)
		"upset":
			ci.draw_polyline(_curve(m + Vector2(-20, 8), m + Vector2(0, -6), m + Vector2(20, 8), 10), lips.darkened(0.2), 4.0, true)
		_:
			ci.draw_polyline(_curve(m + Vector2(-18, 0), m + Vector2(0, 6), m + Vector2(18, 0), 10), lips.darkened(0.15), 4.0, true)
			if fc.has("lips"):
				ci.draw_colored_polygon(_ell(m + Vector2(0, 6), 10, 4, 12), Color(lips, 0.7))
	if fc.get("mustache", false):
		var mc: Color = lk.get("beard", hair)
		for side in [-1.0, 1.0]:
			ci.draw_polyline(_curve(m + Vector2(0, -12), m + Vector2(side * 22, -16), m + Vector2(side * 38, 4), 10), mc, 7.0, true)
	if age >= 3:
		for side in [-1.0, 1.0]:
			ci.draw_polyline(_curve(Vector2(c.x + side * 34, ey + 40), Vector2(c.x + side * 44, ey + 62), Vector2(c.x + side * 34, ey + 82), 8), Color(0.45, 0.25, 0.15, 0.4), 2.4, true)
		ci.draw_line(Vector2(c.x - 30, c.y - 70), Vector2(c.x + 30, c.y - 72), Color(0.45, 0.25, 0.15, 0.3), 2.4)


static func _hair_behind(ci: CanvasItem, lk: Dictionary, fc: Dictionary) -> void:
	var hair: Color = lk.get("hair", Color("231a17"))
	match lk.get("style", "short"):
		"long":
			_paper(ci, PackedVector2Array([Vector2(140, 150), Vector2(372, 150), Vector2(400, 300), Vector2(392, 470), Vector2(330, 450), Vector2(256, 380), Vector2(182, 450), Vector2(120, 470), Vector2(112, 300)]), hair, 5.0)
		"tail":
			_paper(ci, PackedVector2Array([Vector2(330, 120), Vector2(372, 140), Vector2(400, 260), Vector2(390, 380), Vector2(360, 370), Vector2(352, 250)]), hair, 4.0)
		"twin":
			_paper(ci, _ell(Vector2(150, 140), 44, 44, 28), hair, 4.0)
			_paper(ci, _ell(Vector2(362, 140), 44, 44, 28), hair, 4.0)


static func _hair_front(ci: CanvasItem, lk: Dictionary, fc: Dictionary, c: Vector2, rx: float, ry: float) -> void:
	var hair: Color = lk.get("hair", Color("231a17"))
	var style: String = lk.get("style", "short")
	if style == "bald":
		ci.draw_arc(c + Vector2(-20, -60), 46, PI * 1.1, PI * 1.5, 12, Color(1, 1, 1, 0.3), 6.0, true)
		return
	# the hair cap: the top of the head down to the brow line
	var cap := PackedVector2Array()
	for i in 33:
		var a := PI + PI * float(i) / 32.0
		cap.append(c + Vector2(cos(a) * (rx + 10), sin(a) * (ry + 12) - 4))
	var hl := c.y - ry * 0.42
	match style:
		"wild":
			for k in range(8, -1, -1):
				var x := lerpf(-rx - 6, rx + 6, float(k) / 8.0)
				cap.append(Vector2(c.x + x, hl + (16.0 if k % 2 == 0 else -14.0)))
		"long", "twin":
			# centre part with locks framing the face
			cap.append(c + Vector2(rx + 10, 60))
			cap.append(c + Vector2(rx - 16, 50))
			cap.append(c + Vector2(rx - 22, -40))
			cap.append(Vector2(c.x + 8, hl - 22))
			cap.append(Vector2(c.x - 8, hl - 22))
			cap.append(c + Vector2(-rx + 22, -40))
			cap.append(c + Vector2(-rx + 16, 50))
			cap.append(c + Vector2(-rx - 10, 60))
		"bun", "topknot":
			# swept back neatly
			cap.append(c + Vector2(rx + 6, -10))
			cap.append(Vector2(c.x + rx * 0.5, hl - 6))
			cap.append(Vector2(c.x, hl - 14))
			cap.append(Vector2(c.x - rx * 0.5, hl - 6))
			cap.append(c + Vector2(-rx - 6, -10))
		_:
			# short fringe
			cap.append(c + Vector2(rx + 8, -8))
			cap.append(Vector2(c.x + rx * 0.6, hl + 6))
			cap.append(Vector2(c.x + rx * 0.2, hl - 8))
			cap.append(Vector2(c.x - rx * 0.15, hl + 10))
			cap.append(Vector2(c.x - rx * 0.55, hl - 2))
			cap.append(c + Vector2(-rx - 8, -8))
	_paper(ci, cap, hair, 4.0)
	# a highlight strand
	ci.draw_polyline(_curve(c + Vector2(-rx * 0.5, -ry * 0.9), c + Vector2(-rx * 0.1, -ry * 1.12), c + Vector2(rx * 0.4, -ry * 0.92), 10), Color(1, 1, 1, 0.16), 6.0, true)
	match style:
		"bun":
			_paper(ci, _ell(c + Vector2(0, -ry - 22), 42, 34, 28), hair, 4.0)
		"topknot":
			_paper(ci, _ell(c + Vector2(0, -ry - 20), 26, 24, 24), hair, 4.0)
			ci.draw_rect(Rect2(c + Vector2(-24, -ry - 6), Vector2(48, 10)), lk.get("trim", Color("e0b860")))
	if lk.has("pin"):
		var pc: Color = lk["pin"]
		ci.draw_line(c + Vector2(30, -ry - 10), c + Vector2(80, -ry - 40), Color("b08a3e"), 4.0, true)
		ci.draw_circle(c + Vector2(80, -ry - 40), 10.0, pc)


static func _hat(ci: CanvasItem, lk: Dictionary, c: Vector2, rx: float, ry: float) -> void:
	var col: Color = lk.get("hat_col", Color("3a2e26"))
	match lk.get("hat", ""):
		"brim":
			_paper(ci, _ell(c + Vector2(0, -ry * 0.62), 200, 40, 48), col, 5.0)
			_paper(ci, PackedVector2Array([c + Vector2(-82, -ry * 0.62), c + Vector2(-60, -ry * 1.28), c + Vector2(60, -ry * 1.28), c + Vector2(82, -ry * 0.62)]), col.lightened(0.08), 4.0)
			ci.draw_line(c + Vector2(-80, -ry * 0.7), c + Vector2(80, -ry * 0.7), Color("8a3a2a"), 8.0)
		"scholar":
			_paper(ci, PackedVector2Array([c + Vector2(-rx - 4, -ry * 0.48), c + Vector2(rx + 4, -ry * 0.48), c + Vector2(rx - 6, -ry * 1.3), c + Vector2(-rx + 6, -ry * 1.3)]), Color("201c1c"), 5.0)
			for side in [-1.0, 1.0]:
				_paper(ci, PackedVector2Array([c + Vector2(side * (rx - 10), -ry * 0.82), c + Vector2(side * (rx + 90), -ry * 0.9), c + Vector2(side * (rx + 90), -ry * 0.82), c + Vector2(side * (rx - 10), -ry * 0.7)]), Color("201c1c"), 3.0)
		"bandana":
			_paper(ci, PackedVector2Array([c + Vector2(-rx - 8, -ry * 0.38), c + Vector2(rx + 8, -ry * 0.38), c + Vector2(rx + 4, -ry * 0.72), c + Vector2(-rx - 4, -ry * 0.72)]), col, 4.0)
			_paper(ci, PackedVector2Array([c + Vector2(rx, -ry * 0.55), c + Vector2(rx + 50, -ry * 0.2), c + Vector2(rx + 40, -ry * 0.1), c + Vector2(rx - 4, -ry * 0.4)]), col.darkened(0.1), 3.0)
		"cap":
			_paper(ci, _ell(c + Vector2(0, -ry * 0.62), rx + 14, ry * 0.5, 32), col, 4.0)
		"turban":
			for k in 3:
				_paper(ci, _ell(c + Vector2(0, -ry * (0.62 + k * 0.22)), rx + 22 - k * 16, ry * 0.3, 32), col.lightened(0.06 * k), 4.0)
			ci.draw_circle(c + Vector2(0, -ry * 0.66), 14, Color("2f6f6a"))
			ci.draw_circle(c + Vector2(0, -ry * 0.66), 7, Color("e0b860"))
		"hood":
			var hood := PackedVector2Array()
			for i in 33:
				var a := PI * 0.9 + PI * 1.2 * float(i) / 32.0
				hood.append(c + Vector2(cos(a) * (rx + 30), sin(a) * (ry + 30)))
			ci.draw_polyline(hood, col, 30.0, true)


static func _prop(ci: CanvasItem, lk: Dictionary) -> void:
	match lk.get("prop", ""):
		"abacus":
			_paper(ci, PackedVector2Array([Vector2(300, 420), Vector2(460, 420), Vector2(460, 500), Vector2(300, 500)]), Color("6a4228"), 4.0)
			for row in 3:
				ci.draw_line(Vector2(306, 440 + row * 22), Vector2(454, 440 + row * 22), Color("3a2414"), 2.0)
				for k in 8:
					ci.draw_circle(Vector2(318 + k * 18, 440 + row * 22), 7, Color("d9b070").darkened(0.1 * (k % 2)))
		"sword":
			ci.draw_line(Vector2(70, 512), Vector2(150, 300), Color("3a3a40"), 12.0, true)
			ci.draw_line(Vector2(120, 332), Vector2(180, 356), Color("b08a3e"), 10.0, true)
			ci.draw_line(Vector2(150, 300), Vector2(172, 250), Color("5a3a2a"), 10.0, true)
		"lantern":
			ci.draw_line(Vector2(420, 330), Vector2(420, 380), Color("4a3a2a"), 3.0)
			ci.draw_colored_polygon(_ell(Vector2(420, 420), 70, 70, 32), Color(1.0, 0.75, 0.35, 0.25))
			_paper(ci, _ell(Vector2(420, 420), 36, 44, 28), Color("e8742e"), 4.0)
			ci.draw_rect(Rect2(396, 372, 48, 10), Color("d9b45a"))
			ci.draw_rect(Rect2(396, 458, 48, 10), Color("d9b45a"))
		"scroll":
			_paper(ci, PackedVector2Array([Vector2(330, 512), Vector2(350, 410), Vector2(410, 420), Vector2(392, 512)]), Color("efe3c0"), 3.0)
			ci.draw_line(Vector2(346, 408), Vector2(416, 420), Color("8a5a36"), 12.0, true)
		"board":
			_paper(ci, PackedVector2Array([Vector2(310, 512), Vector2(330, 400), Vector2(480, 420), Vector2(470, 512)]), Color("c9a46a"), 4.0)
			ci.draw_polyline(_curve(Vector2(350, 470), Vector2(400, 420), Vector2(450, 470)), Color("3a3028"), 3.0, true)
		"hammer":
			ci.draw_line(Vector2(400, 512), Vector2(440, 380), Color("6a4a30"), 10.0, true)
			_paper(ci, PackedVector2Array([Vector2(408, 360), Vector2(476, 380), Vector2(468, 410), Vector2(400, 390)]), Color("5a5a60"), 4.0)
		"jug":
			_paper(ci, _ell(Vector2(410, 450), 48, 56, 28), Color("a0603a"), 4.0)
			ci.draw_rect(Rect2(392, 386, 36, 16), Color("e8dcb0"))
		"pouch":
			_paper(ci, _ell(Vector2(380, 470), 38, 44, 24), Color("8a6a4a"), 3.0)
			ci.draw_circle(Vector2(380, 440), 10, Color("f4f4f0"))
	if lk.get("brass_hand", false):
		_paper(ci, PackedVector2Array([Vector2(360, 512), Vector2(372, 430), Vector2(420, 420), Vector2(440, 450), Vector2(430, 512)]), Color("c9a24a"), 4.0)
		for k in 3:
			ci.draw_line(Vector2(380 + k * 16, 432), Vector2(386 + k * 16, 404), Color("a07a2a"), 9.0, true)
			ci.draw_circle(Vector2(386 + k * 16, 432), 4, Color("7a5a2a"))
