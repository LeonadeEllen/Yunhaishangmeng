class_name PaperFolk
## Layered paper-doll figures for the towns: the protagonist, companions and townsfolk.
## Every figure is built from a "look" (hair, hat, robe colours, a held prop) and drawn in one of
## four directions with a walk cycle, so the same person reads the same in every port.
##
## Coordinates: the figure stands with its feet on `pos`, about 64 px tall at scale 1.
## dir: 0 front (walking down), 1 left, 2 right, 3 back (walking up).

const SKINS := [Color("f3d7b9"), Color("e9c39e"), Color("d6a57c"), Color("b98560")]
const HAIRS := [Color("231a17"), Color("3a2a20"), Color("5a3a26"), Color("2b2730"), Color("8a8580")]
const ROBES := [Color("6f8a6a"), Color("8a6a4a"), Color("4f6f86"), Color("9a4a3a"), Color("7a6a8a"), Color("b08a5a"), Color("5a7a7a"), Color("a0785a"), Color("6a5a4a"), Color("8a9a7a")]
const STYLES := ["short", "tail", "bun", "long", "topknot", "wild", "twin", "bald"]
const HATS := ["", "", "", "brim", "bandana", "cap", "hood", "scholar"]

## The protagonists, the fourteen companions and the shop people. Colours follow docs/06-art-brief.md.
const LOOKS := {
	"hero_lamp":  {"skin": 0, "hair": Color("231a17"), "style": "tail", "robe": Color("b5583c"), "trim": Color("e3b45a"), "pants": Color("4a3428"), "prop": "lantern"},
	"hero_iron":  {"skin": 2, "hair": Color("1c1816"), "style": "short", "robe": Color("2c4a6e"), "trim": Color("b08a3e"), "pants": Color("2a2a30"), "short": true, "pauldron": true, "build": 1.1},
	"hero_tower": {"skin": 0, "hair": Color("221a20"), "style": "bun", "robe": Color("dcd9d0"), "trim": Color("2f6f6a"), "pants": Color("8a8a90"), "prop": "scroll", "female": true, "pin": Color("3f9a7a")},
	"xiaoman":  {"skin": 1, "hair": Color("2a1d16"), "style": "wild", "robe": Color("c2a77c"), "trim": Color("efe6d0"), "pants": Color("6a4a32"), "short": true, "apron": Color("f1ebdc"), "height": 0.86},
	"luqing":   {"skin": 1, "hair": Color("15181c"), "style": "long", "robe": Color("24524f"), "trim": Color("8fb9b0"), "pants": Color("1f3a48"), "female": true, "pin": Color("f4f4f0"), "prop": "pouch"},
	"qian":     {"skin": 0, "hair": Color("3a3430"), "style": "short", "hat": "scholar", "robe": Color("6b5a48"), "trim": Color("c9b48e"), "pants": Color("3a3028"), "glasses": true, "beard": Color("3a3430"), "prop": "abacus", "build": 0.85},
	"aman":     {"skin": 3, "hair": Color("231a17"), "style": "bald", "robe": Color("7a2e22"), "trim": Color("d9b45a"), "pants": Color("2c2622"), "short": true, "bare_arms": true, "scar": true, "build": 1.25},
	"shen":     {"skin": 0, "hair": Color("15151a"), "style": "topknot", "robe": Color("e8e4d8"), "trim": Color("8a9aa6"), "pants": Color("9aa0a6"), "prop": "sword"},
	"cen":      {"skin": 2, "hair": Color("bdb6aa"), "style": "short", "robe": Color("5c4a3a"), "trim": Color("a08a6a"), "pants": Color("3a3028"), "apron": Color("8a5a36"), "beard": Color("c8c2b6"), "prop": "hammer", "height": 0.95},
	"moyu":     {"skin": 0, "hair": Color("2a2220"), "style": "long", "hat": "brim", "hat_col": Color("c9a46a"), "robe": Color("5f7f8f"), "trim": Color("e7d9b8"), "pants": Color("3a4a52"), "female": true, "prop": "board"},
	"ning":     {"skin": 0, "hair": Color("1e1c22"), "style": "short", "hat": "scholar", "robe": Color("a8b4bc"), "trim": Color("2f4f6a"), "pants": Color("6a7480"), "prop": "scroll"},
	"feng":     {"skin": 1, "hair": Color("1a1418"), "style": "bun", "robe": Color("3a2a3a"), "trim": Color("d9b45a"), "pants": Color("2a2028"), "female": true, "cape": Color("6b2f5a"), "earring": true},
	"sang":     {"skin": 3, "hair": Color("4a4440"), "style": "short", "robe": Color("3c3632"), "trim": Color("8a6a4a"), "pants": Color("2a2624"), "apron": Color("6a4a30"), "brass_hand": true, "beard": Color("4a4440"), "build": 1.15},
	"helan":    {"skin": 2, "hair": Color("1a1614"), "style": "short", "hat": "turban", "hat_col": Color("d9b45a"), "robe": Color("8a4b2a"), "trim": Color("e0b860"), "pants": Color("4a2a1a"), "beard": Color("1a1614"), "buttons": true},
	"ling":     {"skin": 0, "hair": Color("e2eaf0"), "style": "long", "robe": Color("eef3f5"), "trim": Color("9fd0e0"), "pants": Color("cfe2ea"), "female": true, "pin": Color("f2ead8"), "glow": true, "height": 0.88},
	"duoyin":   {"skin": 1, "hair": Color("2a1d18"), "style": "bun", "hat": "bandana", "hat_col": Color("b5583c"), "robe": Color("8a5a2e"), "trim": Color("e0b060"), "pants": Color("4a3020"), "female": true, "apron": Color("5a3e2a"), "prop": "hammer"},
	"lusheng":  {"skin": 1, "hair": Color("2a1d16"), "style": "wild", "hat": "bandana", "hat_col": Color("c9b48e"), "robe": Color("6f8a4a"), "trim": Color("e8dcb0"), "pants": Color("4a4a2a"), "short": true, "prop": "jug", "height": 0.88},
}


static func hero_look(house_id: String) -> Dictionary:
	return LOOKS.get("hero_" + house_id, LOOKS["hero_lamp"])


static func crew_look(cid: String) -> Dictionary:
	return LOOKS.get(cid, random_look(cid.hash()))


## A townsperson: same seed, same person.
static func random_look(seed_v: int, job: String = "") -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var female := r.randf() < 0.45
	var lk := {
		"skin": r.randi_range(0, SKINS.size() - 1),
		"hair": HAIRS[r.randi_range(0, HAIRS.size() - 1)],
		"style": STYLES[r.randi_range(0, STYLES.size() - 1)],
		"hat": HATS[r.randi_range(0, HATS.size() - 1)],
		"robe": ROBES[r.randi_range(0, ROBES.size() - 1)],
		"pants": Color("3a3028").lerp(Color("5a5048"), r.randf()),
		"female": female,
		"short": not female and r.randf() < 0.5,
		"build": r.randf_range(0.9, 1.12),
		"height": r.randf_range(0.92, 1.04),
	}
	lk["trim"] = (lk["robe"] as Color).lightened(0.45)
	lk["hat_col"] = ROBES[r.randi_range(0, ROBES.size() - 1)].darkened(0.15)
	if lk["style"] == "bald" and female:
		lk["style"] = "bun"
	match job:
		"porter":
			lk["short"] = true
			lk["female"] = false
			lk["prop"] = "crate"
			lk["hat"] = "bandana"
		"sailor":
			lk["short"] = true
			lk["female"] = false
			lk["robe"] = Color("3f5f7a")
			lk["trim"] = Color("eeeeee")
			lk["hat"] = "cap"
			lk["hat_col"] = Color("2a3a4a")
		"kid":
			lk["height"] = 0.7
			lk["short"] = true
			lk["hat"] = ""
		"vendor":
			lk["apron"] = Color("efe6d0")
		"guard":
			lk["short"] = true
			lk["female"] = false
			lk["robe"] = Color("5a3a2a")
			lk["trim"] = Color("b08a3e")
			lk["hat"] = "cap"
			lk["hat_col"] = Color("2a2020")
			lk["prop"] = "spear"
			lk["pauldron"] = true
	if not lk.has("prop") and r.randf() < 0.25:
		lk["prop"] = ["basket", "pouch", "scroll", "jug"][r.randi_range(0, 3)]
	return lk


# ------------------------------------------------------------------ geometry helpers
static func _ell(c: Vector2, rx: float, ry: float, n: int = 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Paper shape: a darker cut edge offset down-right, the fill, and a fine ink outline.
static func _paper(ci: CanvasItem, pts: PackedVector2Array, col: Color, outline: bool = true) -> void:
	var sh := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(0.7, 1.1))
	ci.draw_colored_polygon(sh, Color(col.darkened(0.45), 0.55))
	ci.draw_colored_polygon(pts, col)
	if outline:
		var ol := pts.duplicate()
		ol.append(pts[0])
		ci.draw_polyline(ol, Color(0.12, 0.1, 0.08, 0.32), 0.9, true)


static func _arc_pts(c: Vector2, r: float, a0: float, a1: float, n: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / float(n))
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _skin(lk: Dictionary) -> Color:
	var s = lk.get("skin", 0)
	return s if s is Color else SKINS[clampi(int(s), 0, SKINS.size() - 1)]


# ------------------------------------------------------------------ the figure
## Draw a whole figure. `phase` advances with walking (radians); `t` is the clock for idle breathing.
static func draw(ci: CanvasItem, pos: Vector2, lk: Dictionary, dir: int, phase: float, moving: bool, t: float, sc: float = 1.0, alpha: float = 1.0) -> void:
	var b: float = lk.get("build", 1.0)
	var hgt: float = lk.get("height", 1.0)
	# shadow first, in screen space
	ci.draw_colored_polygon(_ell(pos + Vector2(0, 1), 13.0 * b * sc, 4.5 * sc), Color(0, 0, 0, 0.18 * alpha))
	if lk.get("glow", false):
		ci.draw_circle(pos + Vector2(0, -34 * sc * hgt), 30 * sc, Color(0.7, 0.9, 1.0, 0.12 + 0.05 * sin(t * 2.0)))
	var sx := -1.0 if dir == 2 else 1.0
	ci.draw_set_transform(pos, 0.0, Vector2(sx * sc * hgt, sc * hgt))
	var swing := sin(phase) if moving else 0.0
	var bob := absf(cos(phase)) * 1.8 if moving else sin(t * 2.2) * 0.5
	if dir == 1 or dir == 2:
		_side(ci, lk, swing, bob, b)
	else:
		_front(ci, lk, swing, bob, b, dir == 3)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _front(ci: CanvasItem, lk: Dictionary, swing: float, bob: float, b: float, back: bool) -> void:
	var skin := _skin(lk)
	var robe: Color = lk.get("robe", Color("8a6a4a"))
	var trim: Color = lk.get("trim", robe.lightened(0.4))
	var pants: Color = lk.get("pants", Color("3a3028"))
	var long_robe: bool = lk.get("female", false) or not lk.get("short", false)
	var hem := -4.0 if long_robe else -13.0
	var up := Vector2(0, -bob)
	# legs and feet
	var lift_l := maxf(0.0, swing) * 3.0
	var lift_r := maxf(0.0, -swing) * 3.0
	for side in [-1.0, 1.0]:
		var lift: float = lift_l if side < 0 else lift_r
		var x: float = side * 4.2 * b
		if not long_robe:
			ci.draw_rect(Rect2(Vector2(x - 2.4, -17 - lift) + up * 0.5, Vector2(4.8, 15)), pants)
		ci.draw_colored_polygon(_ell(Vector2(x, -1.5 - lift), 3.4, 2.0, 10), Color("2a211c"))
	if back and lk.has("prop"):
		_prop(ci, lk, swing, true, up)
	# hair hanging behind the body (front view)
	if not back:
		_hair_back(ci, lk, up)
	if lk.has("cape"):
		_paper(ci, PackedVector2Array([up + Vector2(-10 * b, -40), up + Vector2(10 * b, -40), up + Vector2(13 * b, hem + 1), up + Vector2(-13 * b, hem + 1)]), lk["cape"])
	# robe
	var sway := swing * 1.6
	var robe_pts := PackedVector2Array([
		up + Vector2(-9.5 * b, -40), up + Vector2(9.5 * b, -40),
		up + Vector2(8.5 * b, -28), up + Vector2(11.5 * b + sway, hem),
		up + Vector2(-11.5 * b + sway, hem), up + Vector2(-8.5 * b, -28)])
	_paper(ci, robe_pts, robe)
	# hem trim
	ci.draw_colored_polygon(PackedVector2Array([up + Vector2(-11.5 * b + sway, hem), up + Vector2(11.5 * b + sway, hem), up + Vector2(11.2 * b + sway, hem - 2.6), up + Vector2(-11.2 * b + sway, hem - 2.6)]), trim)
	if lk.has("apron") and not back:
		_paper(ci, PackedVector2Array([up + Vector2(-6.5 * b, -32), up + Vector2(6.5 * b, -32), up + Vector2(8 * b + sway, hem + 2), up + Vector2(-8 * b + sway, hem + 2)]), lk["apron"], false)
	# sash
	ci.draw_rect(Rect2(up + Vector2(-8.8 * b, -30), Vector2(17.6 * b, 3.2)), trim.darkened(0.25))
	if not back:
		# collar
		ci.draw_polyline(PackedVector2Array([up + Vector2(-4.5, -40), up + Vector2(0, -33), up + Vector2(4.5, -40)]), trim, 2.0, true)
		if lk.get("buttons", false):
			for k in 3:
				ci.draw_circle(up + Vector2(1.5, -36 + k * 3.2), 0.9, Color("e0b860"))
	if lk.get("pauldron", false):
		ci.draw_colored_polygon(_ell(up + Vector2(-9.5 * b, -38.5), 4.2, 2.6, 10), Color("b08a3e"))
	# arms: sleeves swing opposite to the legs
	for side in [-1.0, 1.0]:
		var sw: float = -swing * side * 2.2
		var sh_p: Vector2 = up + Vector2(side * 9.0 * b, -38.5)
		var hand: Vector2 = up + Vector2(side * 11.5 * b, -24.0 + sw)
		if lk.get("prop", "") == "crate":
			hand = up + Vector2(side * 7.0, -60.0)
		var sleeve: Color = skin if lk.get("bare_arms", false) else robe.darkened(0.1)
		ci.draw_line(sh_p, hand, Color(sleeve.darkened(0.4), 0.6), 5.6, true)
		ci.draw_line(sh_p, hand, sleeve, 4.6, true)
		var hand_col: Color = Color("c9a24a") if (lk.get("brass_hand", false) and side > 0) else skin
		ci.draw_circle(hand, 2.3, hand_col)
	# neck + head
	ci.draw_rect(Rect2(up + Vector2(-2.2, -43), Vector2(4.4, 4)), skin.darkened(0.08))
	var hc := up + Vector2(0, -50.5)
	if back:
		var hairc: Color = skin if lk.get("style", "") == "bald" else lk.get("hair", Color("231a17"))
		_paper(ci, _ell(hc, 9.6, 10.2, 20), hairc)
		_hair_extras(ci, lk, hc, true)
	else:
		_paper(ci, _ell(hc, 9.4, 10.0, 20), skin)
		_face(ci, lk, hc)
		_hair_front(ci, lk, hc)
	_hat(ci, lk, hc, back)
	if not back and lk.has("prop"):
		_prop(ci, lk, swing, false, up)


static func _side(ci: CanvasItem, lk: Dictionary, swing: float, bob: float, b: float) -> void:
	# drawn facing left (−x); the caller mirrors it for the right
	var skin := _skin(lk)
	var robe: Color = lk.get("robe", Color("8a6a4a"))
	var trim: Color = lk.get("trim", robe.lightened(0.4))
	var pants: Color = lk.get("pants", Color("3a3028"))
	var long_robe: bool = lk.get("female", false) or not lk.get("short", false)
	var hem := -4.0 if long_robe else -13.0
	var up := Vector2(0, -bob)
	# legs pivot at the hip
	var hip := up + Vector2(0, -17)
	for k in 2:
		var ang: float = swing * 0.55 * (1.0 if k == 0 else -1.0)
		var foot: Vector2 = hip + Vector2(sin(ang) * -16.0, cos(ang) * 16.0)
		var col: Color = pants.darkened(0.25) if k == 1 else pants
		if not long_robe or absf(foot.x) > 6.0:
			ci.draw_line(hip, foot, col, 4.6, true)
		ci.draw_colored_polygon(_ell(foot + Vector2(-1.5, -0.6), 3.8, 1.9, 10), Color("2a211c"))
	# back arm (behind body)
	var sh_p := up + Vector2(0, -38)
	var back_hand := sh_p + Vector2(swing * 5.0, 14.0)
	ci.draw_line(sh_p, back_hand, robe.darkened(0.3), 4.4, true)
	_hair_back_side(ci, lk, up)
	if lk.has("cape"):
		_paper(ci, PackedVector2Array([up + Vector2(-2, -41), up + Vector2(6, -40), up + Vector2(10 + swing, hem), up + Vector2(-2 + swing, hem)]), lk["cape"])
	var sway := swing * 1.4
	var robe_pts := PackedVector2Array([
		up + Vector2(-5.5 * b, -40), up + Vector2(5.5 * b, -40),
		up + Vector2(6.5 * b, -28), up + Vector2(8.5 * b + sway, hem),
		up + Vector2(-8.0 * b + sway, hem), up + Vector2(-6.0 * b, -28)])
	_paper(ci, robe_pts, robe)
	ci.draw_colored_polygon(PackedVector2Array([up + Vector2(-8 * b + sway, hem), up + Vector2(8.5 * b + sway, hem), up + Vector2(8.2 * b + sway, hem - 2.6), up + Vector2(-7.7 * b + sway, hem - 2.6)]), trim)
	if lk.has("apron"):
		_paper(ci, PackedVector2Array([up + Vector2(-6.5 * b, -32), up + Vector2(-3 * b, -32), up + Vector2(-4 * b + sway, hem + 2), up + Vector2(-9 * b + sway, hem + 2)]), lk["apron"], false)
	ci.draw_rect(Rect2(up + Vector2(-6 * b, -30), Vector2(12 * b, 3.2)), trim.darkened(0.25))
	if lk.has("prop"):
		_prop_side(ci, lk, swing, up)
	# front arm
	var hand := sh_p + Vector2(-swing * 6.0, 14.0)
	if lk.get("prop", "") == "crate":
		hand = up + Vector2(-2, -60)
	var sleeve: Color = skin if lk.get("bare_arms", false) else robe.darkened(0.08)
	ci.draw_line(sh_p, hand, Color(sleeve.darkened(0.4), 0.6), 5.4, true)
	ci.draw_line(sh_p, hand, sleeve, 4.4, true)
	ci.draw_circle(hand, 2.3, skin)
	if lk.get("pauldron", false):
		ci.draw_colored_polygon(_ell(sh_p + Vector2(0, -0.5), 4.2, 2.6, 10), Color("b08a3e"))
	# head
	ci.draw_rect(Rect2(up + Vector2(-2.2, -43), Vector2(4.4, 4)), skin.darkened(0.08))
	var hc := up + Vector2(0, -50.5)
	_paper(ci, _ell(hc, 9.0, 10.0, 20), skin)
	# eye, brow, nose, mouth
	ci.draw_circle(hc + Vector2(-5.0, 0.5), 1.3, Color("1c1814"))
	ci.draw_line(hc + Vector2(-7, -2.8), hc + Vector2(-3.6, -3.2), Color(lk.get("hair", Color.BLACK), 0.8), 1.1)
	ci.draw_colored_polygon(PackedVector2Array([hc + Vector2(-9, 1), hc + Vector2(-10.6, 3.6), hc + Vector2(-8.6, 4.0)]), skin.darkened(0.06))
	ci.draw_circle(hc + Vector2(-5.5, 4.5), 1.7, Color(0.95, 0.5, 0.45, 0.28))
	if lk.get("glasses", false):
		ci.draw_arc(hc + Vector2(-5.0, 0.5), 2.8, 0, TAU, 12, Color("b08a3e"), 0.9)
	if lk.has("beard"):
		_paper(ci, PackedVector2Array([hc + Vector2(-8.5, 4), hc + Vector2(-2, 6), hc + Vector2(-4, 12), hc + Vector2(-8, 9)]), lk["beard"], false)
	_hair_side(ci, lk, hc)
	_hat(ci, lk, hc, false, true)


static func _face(ci: CanvasItem, lk: Dictionary, hc: Vector2) -> void:
	var ink := Color("1c1814")
	ci.draw_circle(hc + Vector2(-3.6, 0.8), 1.35, ink)
	ci.draw_circle(hc + Vector2(3.6, 0.8), 1.35, ink)
	var hair: Color = lk.get("hair", Color.BLACK)
	ci.draw_line(hc + Vector2(-5.4, -2.6), hc + Vector2(-2.2, -3.0), Color(hair, 0.85), 1.1)
	ci.draw_line(hc + Vector2(2.2, -3.0), hc + Vector2(5.4, -2.6), Color(hair, 0.85), 1.1)
	ci.draw_circle(hc + Vector2(-5.6, 3.8), 1.8, Color(0.95, 0.5, 0.45, 0.28))
	ci.draw_circle(hc + Vector2(5.6, 3.8), 1.8, Color(0.95, 0.5, 0.45, 0.28))
	ci.draw_line(hc + Vector2(-1.4, 5.2), hc + Vector2(1.4, 5.2), Color(0.55, 0.3, 0.25, 0.8), 1.0)
	if lk.get("glasses", false):
		ci.draw_arc(hc + Vector2(-3.6, 0.8), 2.8, 0, TAU, 12, Color("b08a3e"), 0.9)
		ci.draw_arc(hc + Vector2(3.6, 0.8), 2.8, 0, TAU, 12, Color("b08a3e"), 0.9)
	if lk.get("scar", false):
		ci.draw_line(hc + Vector2(2.5, -5), hc + Vector2(6, 1), Color(0.6, 0.25, 0.2, 0.8), 1.0)
	if lk.has("beard"):
		_paper(ci, PackedVector2Array([hc + Vector2(-5, 5), hc + Vector2(5, 5), hc + Vector2(3, 11), hc + Vector2(0, 12.5), hc + Vector2(-3, 11)]), lk["beard"], false)
	if lk.get("earring", false):
		ci.draw_circle(hc + Vector2(-9.2, 3), 1.5, Color("e3b45a"))
		ci.draw_circle(hc + Vector2(9.2, 3), 1.5, Color("e3b45a"))


static func _hair_back(ci: CanvasItem, lk: Dictionary, up: Vector2) -> void:
	var hair: Color = lk.get("hair", Color.BLACK)
	if lk.get("style", "") == "long":
		_paper(ci, PackedVector2Array([up + Vector2(-10.5, -54), up + Vector2(10.5, -54), up + Vector2(11.5, -33), up + Vector2(-11.5, -33)]), hair)


static func _hair_back_side(ci: CanvasItem, lk: Dictionary, up: Vector2) -> void:
	var hair: Color = lk.get("hair", Color.BLACK)
	match lk.get("style", ""):
		"long":
			_paper(ci, PackedVector2Array([up + Vector2(0, -58), up + Vector2(10, -54), up + Vector2(11, -33), up + Vector2(3, -34)]), hair)
		"tail":
			_paper(ci, PackedVector2Array([up + Vector2(7, -55), up + Vector2(11, -54), up + Vector2(14, -40), up + Vector2(10, -38)]), hair)


static func _hair_front(ci: CanvasItem, lk: Dictionary, hc: Vector2) -> void:
	var hair: Color = lk.get("hair", Color.BLACK)
	var style: String = lk.get("style", "short")
	if style == "bald":
		ci.draw_arc(hc + Vector2(-2, -4), 5.5, PI * 1.1, PI * 1.5, 6, Color(1, 1, 1, 0.35), 1.6)
		return
	var cap := _arc_pts(hc + Vector2(0, -0.5), 10.4, PI * 1.02, PI * 1.98, 14)
	# fringe
	if style == "wild":
		cap.append(hc + Vector2(9, -2))
		cap.append(hc + Vector2(6, -5.5))
		cap.append(hc + Vector2(3.5, -2.5))
		cap.append(hc + Vector2(0, -6))
		cap.append(hc + Vector2(-3.5, -2.5))
		cap.append(hc + Vector2(-6, -5.5))
		cap.append(hc + Vector2(-9, -2))
	elif style in ["long", "twin"]:
		cap.append(hc + Vector2(10.4, 6))
		cap.append(hc + Vector2(7.5, 4))
		cap.append(hc + Vector2(5.5, -4.5))
		cap.append(hc + Vector2(-5.5, -4.5))
		cap.append(hc + Vector2(-7.5, 4))
		cap.append(hc + Vector2(-10.4, 6))
	else:
		cap.append(hc + Vector2(8, -4))
		cap.append(hc + Vector2(2, -5.5))
		cap.append(hc + Vector2(-3, -4.0))
		cap.append(hc + Vector2(-8, -4.5))
	_paper(ci, cap, hair)
	_hair_extras(ci, lk, hc, false)


static func _hair_side(ci: CanvasItem, lk: Dictionary, hc: Vector2) -> void:
	var hair: Color = lk.get("hair", Color.BLACK)
	var style: String = lk.get("style", "short")
	if style == "bald":
		return
	# a convex cap over the crown and the back of the head; the face stays clear
	var cap := _arc_pts(hc + Vector2(1.6, -0.8), 10.4, deg_to_rad(218.0), deg_to_rad(402.0), 16)
	_paper(ci, cap, hair)
	if style == "wild":
		ci.draw_colored_polygon(PackedVector2Array([hc + Vector2(-9, -4), hc + Vector2(-12, -1), hc + Vector2(-7, -2)]), hair)
	_hair_extras(ci, lk, hc, false)


static func _hair_extras(ci: CanvasItem, lk: Dictionary, hc: Vector2, back: bool) -> void:
	var hair: Color = lk.get("hair", Color.BLACK)
	match lk.get("style", ""):
		"bun":
			_paper(ci, _ell(hc + Vector2(0, -11), 5.0, 4.2, 12), hair)
		"topknot":
			_paper(ci, _ell(hc + Vector2(0, -12), 3.6, 3.6, 10), hair)
			ci.draw_line(hc + Vector2(-3, -9.5), hc + Vector2(3, -9.5), lk.get("trim", Color.WHITE), 1.6)
		"twin":
			_paper(ci, _ell(hc + Vector2(-9, -7), 4.0, 4.0, 10), hair)
			_paper(ci, _ell(hc + Vector2(9, -7), 4.0, 4.0, 10), hair)
		"tail":
			if back:
				_paper(ci, PackedVector2Array([hc + Vector2(-2.5, 4), hc + Vector2(2.5, 4), hc + Vector2(2, 15), hc + Vector2(-2, 15)]), hair)
	if lk.has("pin"):
		ci.draw_circle(hc + Vector2(6, -8), 2.0, lk["pin"])


static func _hat(ci: CanvasItem, lk: Dictionary, hc: Vector2, back: bool, side: bool = false) -> void:
	var col: Color = lk.get("hat_col", Color("3a2e26"))
	match lk.get("hat", ""):
		"brim":
			_paper(ci, _ell(hc + Vector2(0, -7), 17.0, 4.2, 20), col)
			_paper(ci, _ell(hc + Vector2(0, -11), 8.0, 5.2, 14), col.lightened(0.08))
			ci.draw_line(hc + Vector2(-7.5, -8.5), hc + Vector2(7.5, -8.5), Color("8a3a2a"), 1.6)
		"scholar":
			_paper(ci, PackedVector2Array([hc + Vector2(-8, -7), hc + Vector2(8, -7), hc + Vector2(7, -15), hc + Vector2(-7, -15)]), Color("201c1c"))
			if not side:
				ci.draw_line(hc + Vector2(-8, -9), hc + Vector2(-14, -11), Color("201c1c"), 1.8)
				ci.draw_line(hc + Vector2(8, -9), hc + Vector2(14, -11), Color("201c1c"), 1.8)
		"bandana":
			ci.draw_colored_polygon(PackedVector2Array([hc + Vector2(-10, -4.5), hc + Vector2(10, -4.5), hc + Vector2(9.6, -8), hc + Vector2(-9.6, -8)]), col)
			if back or side:
				ci.draw_line(hc + Vector2(7, -6), hc + Vector2(12, 0), col, 2.2)
		"cap":
			_paper(ci, _arc_pts(hc + Vector2(0, -3), 10.4, PI, TAU, 12), col)
			if not back:
				_paper(ci, _ell(hc + Vector2(-4 if side else 0, -3), 8.0 if side else 10.0, 2.0, 10), col.darkened(0.2))
		"hood":
			var hood := _arc_pts(hc, 12.0, PI * 0.85, PI * 2.15, 16)
			hood.append(hc + Vector2(9, 6))
			hood.append(hc + Vector2(-9, 6))
			if back:
				_paper(ci, _ell(hc, 12.0, 12.0, 18), col)
			else:
				ci.draw_polyline(hood, col, 4.0, true)
		"turban":
			_paper(ci, _ell(hc + Vector2(0, -7), 11.0, 6.0, 16), col)
			_paper(ci, _ell(hc + Vector2(1, -11), 8.5, 5.0, 14), col.lightened(0.1))
			ci.draw_circle(hc + Vector2(0, -8), 1.8, Color("2f6f6a"))


static func _prop(ci: CanvasItem, lk: Dictionary, swing: float, back: bool, up: Vector2) -> void:
	var hand := up + Vector2(11.5 * lk.get("build", 1.0), -24.0 - swing * 2.2)
	match lk.get("prop", ""):
		"lantern":
			ci.draw_line(hand, hand + Vector2(0, 6), Color("4a3a2a"), 1.0)
			_paper(ci, PackedVector2Array([hand + Vector2(-3, 6), hand + Vector2(3, 6), hand + Vector2(3.5, 13), hand + Vector2(-3.5, 13)]), Color("e8742e"))
			ci.draw_circle(hand + Vector2(0, 9.5), 5.5, Color(1.0, 0.75, 0.35, 0.25))
		"sword":
			var hip := up + Vector2(-10, -26)
			ci.draw_line(hip, hip + Vector2(-6, 20), Color("3a3a40"), 2.2)
			ci.draw_line(hip + Vector2(-2, -1), hip + Vector2(2, 2), Color("b08a3e"), 2.6)
		"abacus":
			var a := up + Vector2(-6, -34)
			_paper(ci, PackedVector2Array([a, a + Vector2(12, 0), a + Vector2(12, 7), a + Vector2(0, 7)]), Color("6a4228"))
			for k in 4:
				ci.draw_circle(a + Vector2(2.5 + k * 2.4, 3.5), 1.0, Color("e0c080"))
		"scroll":
			ci.draw_line(hand + Vector2(-2, -4), hand + Vector2(-2, 6), Color("efe3c0"), 4.0)
			ci.draw_line(hand + Vector2(-2, -5), hand + Vector2(-2, -3.5), Color("8a5a36"), 4.6)
		"board":
			_paper(ci, PackedVector2Array([up + Vector2(-17, -34), up + Vector2(-9, -36), up + Vector2(-8, -18), up + Vector2(-16, -16)]), Color("c9a46a"))
		"hammer":
			ci.draw_line(hand, hand + Vector2(2, 10), Color("6a4a30"), 2.0)
			ci.draw_rect(Rect2(hand + Vector2(-1.5, 9), Vector2(7, 4)), Color("5a5a60"))
		"pouch":
			_paper(ci, _ell(up + Vector2(-9, -24), 3.6, 4.4, 10), Color("8a6a4a"), false)
		"jug":
			_paper(ci, _ell(hand + Vector2(0, 6), 4.5, 5.5, 12), Color("a0603a"))
			ci.draw_rect(Rect2(hand + Vector2(-1.5, -0.5), Vector2(3, 2)), Color("e8dcb0"))
		"basket":
			_paper(ci, PackedVector2Array([hand + Vector2(-5, 2), hand + Vector2(5, 2), hand + Vector2(4, 9), hand + Vector2(-4, 9)]), Color("b8955a"))
			ci.draw_arc(hand + Vector2(0, 2), 4.5, PI, TAU, 8, Color("8a6a3a"), 1.2)
		"crate":
			_paper(ci, PackedVector2Array([up + Vector2(-10, -72), up + Vector2(10, -72), up + Vector2(10, -59), up + Vector2(-10, -59)]), Color("b0834e"))
			ci.draw_line(up + Vector2(-10, -72), up + Vector2(10, -59), Color("7a5530"), 1.2)
		"spear":
			var s0 := up + Vector2(13, -2)
			ci.draw_line(s0, s0 + Vector2(0, -70), Color("5a4030"), 2.0)
			ci.draw_colored_polygon(PackedVector2Array([s0 + Vector2(-2.5, -70), s0 + Vector2(2.5, -70), s0 + Vector2(0, -78)]), Color("c0c4c8"))


static func _prop_side(ci: CanvasItem, lk: Dictionary, swing: float, up: Vector2) -> void:
	match lk.get("prop", ""):
		"lantern":
			var hand := up + Vector2(-swing * 6.0, -24.0)
			ci.draw_line(hand, hand + Vector2(0, 6), Color("4a3a2a"), 1.0)
			_paper(ci, PackedVector2Array([hand + Vector2(-3, 6), hand + Vector2(3, 6), hand + Vector2(3.5, 13), hand + Vector2(-3.5, 13)]), Color("e8742e"))
			ci.draw_circle(hand + Vector2(0, 9.5), 5.5, Color(1.0, 0.75, 0.35, 0.25))
		"sword":
			ci.draw_line(up + Vector2(2, -27), up + Vector2(12, -12), Color("3a3a40"), 2.2)
		"crate":
			_paper(ci, PackedVector2Array([up + Vector2(-9, -72), up + Vector2(9, -72), up + Vector2(9, -59), up + Vector2(-9, -59)]), Color("b0834e"))
		"spear":
			ci.draw_line(up + Vector2(-6, 0), up + Vector2(-6, -72), Color("5a4030"), 2.0)
			ci.draw_colored_polygon(PackedVector2Array([up + Vector2(-8.5, -72), up + Vector2(-3.5, -72), up + Vector2(-6, -80)]), Color("c0c4c8"))
		"board":
			_paper(ci, PackedVector2Array([up + Vector2(-4, -36), up + Vector2(4, -36), up + Vector2(4, -18), up + Vector2(-4, -18)]), Color("c9a46a"))
		"jug", "basket", "pouch":
			_paper(ci, _ell(up + Vector2(-3, -20), 4.5, 5.0, 12), Color("a0603a") if lk["prop"] == "jug" else Color("b8955a"))
