class_name UiKit
## Palette, theme and small widget helpers (see docs/03-art-style.md).

const JADE := Color("2f6f6a")
const PARCH := Color("f3e9d2")
const PARCH_DARK := Color("e6d8b8")
const INK := Color("1f3a48")
const BRASS := Color("b08a3e")
const TERRA := Color("b5583c")
const CLOUD := Color("e7eef0")
const UP := Color("3e8e5a")
const DOWN := Color("b5583c")
const MUTED := Color("6b6a5e")

static var _tex_cache := {}
static var font_regular: Font
static var font_bold: Font


static func tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]


static func sprite(atlas: String, idx: int) -> Texture2D:
	return tex("res://assets/art/%s/%02d.webp" % [atlas, idx])


## A character's bust portrait (finish plan, phase C): hero_<house>, a companion id or shop_<kind>.
## mood "happy" / "upset" falls back to the calm face when that file is missing.
static func portrait(id: String, mood: String = "") -> Texture2D:
	if mood != "":
		var pm := "res://assets/art/portraits/%s_%s.webp" % [id, mood]
		if ResourceLoader.exists(pm):
			return tex(pm)
	return tex("res://assets/art/portraits/%s.webp" % id)


static func scene_art(id: String) -> Texture2D:
	if "/" in id:
		return tex("res://assets/art/%s.webp" % id)
	return tex("res://assets/art/scenes/%s.webp" % id)


static func box(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 6, border_w: int = 1, pad: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w if border.a > 0.0 else 0)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad)
	return sb


static func build_theme() -> Theme:
	font_regular = load("res://assets/fonts/NotoSerifSC-Regular.otf")
	font_bold = load("res://assets/fonts/NotoSerifSC-Bold.otf")
	var t := Theme.new()
	t.default_font = font_regular
	t.default_font_size = 17
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", box(PARCH, Color(BRASS, 0.55), 8, 1, 14))
	t.set_stylebox("panel", "Panel", box(PARCH, Color(BRASS, 0.55), 8, 1, 14))
	# buttons
	var normal := box(JADE, Color("24524f"), 5, 1, 8)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover := normal.duplicate()
	hover.bg_color = Color("3a8580")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("24524f")
	var disabled := normal.duplicate()
	disabled.bg_color = Color("a9b3ad")
	disabled.border_color = Color("98a29c")
	for st in [["normal", normal], ["hover", hover], ["pressed", pressed], ["disabled", disabled], ["focus", StyleBoxEmpty.new()]]:
		t.set_stylebox(st[0], "Button", st[1])
	t.set_color("font_color", "Button", Color("fbf6ea"))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("eef0ec"))
	t.set_font("font", "Button", font_bold)
	t.set_font_size("font_size", "Button", 16)
	# secondary button variant
	t.set_type_variation("Ghost", "Button")
	var g_normal := box(Color(PARCH_DARK, 0.9), Color(BRASS, 0.7), 5, 1, 7)
	g_normal.content_margin_left = 12
	g_normal.content_margin_right = 12
	var g_hover := g_normal.duplicate()
	g_hover.bg_color = Color("efe2c2")
	var g_pressed := g_normal.duplicate()
	g_pressed.bg_color = Color("d9c79f")
	var g_dis := g_normal.duplicate()
	g_dis.bg_color = Color("e9e3d5")
	g_dis.border_color = Color("d6ccb4")
	for st in [["normal", g_normal], ["hover", g_hover], ["pressed", g_pressed], ["disabled", g_dis], ["focus", StyleBoxEmpty.new()]]:
		t.set_stylebox(st[0], "Ghost", st[1])
	t.set_color("font_color", "Ghost", INK)
	t.set_color("font_hover_color", "Ghost", INK)
	t.set_color("font_pressed_color", "Ghost", INK)
	t.set_color("font_disabled_color", "Ghost", Color("a9a493"))
	# tabs
	t.set_stylebox("tab_selected", "TabContainer", box(PARCH, Color(BRASS, 0.55), 5, 1, 8))
	t.set_stylebox("tab_unselected", "TabContainer", box(PARCH_DARK, Color.TRANSPARENT, 5, 0, 8))
	t.set_stylebox("tab_hovered", "TabContainer", box(Color("efe2c2"), Color.TRANSPARENT, 5, 0, 8))
	t.set_stylebox("panel", "TabContainer", box(PARCH, Color(BRASS, 0.55), 6, 1, 12))
	t.set_color("font_selected_color", "TabContainer", INK)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	t.set_color("font_hovered_color", "TabContainer", INK)
	t.set_font("font", "TabContainer", font_bold)
	# option buttons / popups
	t.set_stylebox("normal", "OptionButton", g_normal)
	t.set_stylebox("hover", "OptionButton", g_hover)
	t.set_stylebox("pressed", "OptionButton", g_pressed)
	t.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	t.set_color("font_color", "OptionButton", INK)
	t.set_color("font_hover_color", "OptionButton", INK)
	t.set_stylebox("panel", "PopupMenu", box(PARCH, BRASS, 4, 1, 6))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_stylebox("hover", "PopupMenu", box(JADE, Color.TRANSPARENT, 3, 0, 4))
	t.set_stylebox("panel", "TooltipPanel", box(Color("fffaf0"), BRASS, 4, 1, 8))
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_stylebox("background", "ProgressBar", box(Color("d9cdb0"), Color.TRANSPARENT, 4, 0, 0))
	t.set_stylebox("fill", "ProgressBar", box(BRASS, Color.TRANSPARENT, 4, 0, 0))
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 8)
	return t


static func label(text: String, size: int = 17, color: Color = INK, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold and font_bold:
		l.add_theme_font_override("font", font_bold)
	return l


static func para(text: String, size: int = 16, color: Color = INK) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	return l


static func button(text: String, cb: Callable, ghost: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	if ghost:
		b.theme_type_variation = "Ghost"
	b.pressed.connect(cb)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func icon(t: Texture2D, size: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func money(v: float) -> String:
	var n := int(round(v))
	var neg := n < 0
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if neg else "") + s + out


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()
