class_name Kit
extends RefCounted
## Construtores de widgets (UI toda criada por código): fontes, rótulos com contorno, botões "3D",
## painéis, barras e botão que repete ao segurar.

static var _font: FontFile = null
static var _fonts: Dictionary = {}


static func font(weight: int = 600) -> Font:
	if _fonts.has(weight):
		return _fonts[weight]
	if _font == null:
		_font = load("res://fonts/Fredoka.ttf")
	var fv := FontVariation.new()
	fv.base_font = _font
	var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	fv.variation_opentype = {tag: weight}
	_fonts[weight] = fv
	return fv


static func label(text: String, size: int = 28, color: Color = Color.WHITE, outline: int = 6, weight: int = 600) -> Label:
	var l := Label.new()
	l.text = text
	style_label(l, size, color, outline, weight)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func style_label(l: Label, size: int, color: Color = Color.WHITE, outline: int = 6, weight: int = 600) -> void:
	l.add_theme_font_override("font", font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Pal.OUTLINE)
		l.add_theme_constant_override("outline_size", outline)


static func box(color: Color, radius: int = 22, depth: int = 0, dark: Color = Color.BLACK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	if depth > 0:
		sb.border_width_bottom = depth
		sb.border_color = dark
	sb.anti_aliasing = true
	return sb


static func btn_style(color: Color, dark: Color, radius: int = 22, depth: int = 7, pressed: bool = false) -> StyleBoxFlat:
	var sb := box(color, radius, 2 if pressed else depth, dark)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10 + (depth - 2 if pressed else 0)
	sb.content_margin_bottom = 10 + (0 if pressed else depth - 2)
	sb.shadow_color = Color(0, 0, 0, 0.30)
	sb.shadow_size = 0 if pressed else 5
	sb.shadow_offset = Vector2(0, 3)
	return sb


static func style_button(b: Button, kind: String, size: int = 28, radius: int = 22, depth: int = 7) -> void:
	var c := Pal.kind(kind)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font(700))
	b.add_theme_font_size_override("font_size", size)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.55))
	b.add_theme_color_override("font_outline_color", Pal.OUTLINE)
	b.add_theme_constant_override("outline_size", maxi(4, size / 5))
	b.add_theme_stylebox_override("normal", btn_style(c[0], c[1], radius, depth))
	b.add_theme_stylebox_override("hover", btn_style(c[0], c[1], radius, depth))
	b.add_theme_stylebox_override("pressed", btn_style(c[0].darkened(0.1), c[1], radius, depth, true))
	b.add_theme_stylebox_override("disabled", btn_style(Pal.GRAY, Pal.GRAY_D, radius, depth))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func button(text: String, kind: String = "green", size: int = 28, min_size: Vector2 = Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = text
	style_button(b, kind, size)
	b.custom_minimum_size = min_size
	return b


static func panel(color: Color = Pal.PANEL, radius: int = 26, margin: int = 14, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(color, radius)
	sb.set_content_margin_all(margin)
	if bw > 0:
		sb.set_border_width_all(bw)
		sb.border_color = border
	p.add_theme_stylebox_override("panel", sb)
	return p


static func icon(name: String, size: int = 48) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.tex(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func bar(fill: Color, bg: Color = Color(0, 0, 0, 0.45), height: int = 22) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.min_value = 0.0
	pb.max_value = 1.0
	pb.step = 0.0
	pb.custom_minimum_size = Vector2(0, height)
	pb.add_theme_stylebox_override("background", box(bg, height / 2))
	pb.add_theme_stylebox_override("fill", box(fill, height / 2))
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pb


## Botão com título + ícone + valor (ex.: "ABRIR 1  🧀 30"), dentro do próprio botão.
class CostButton extends Button:
	var title_lbl: Label
	var cost_lbl: Label
	var cost_icon: TextureRect

	func build(icon_name: String, kind: String, size_px: int = 24) -> void:
		Kit.style_button(self, kind, size_px)
		var bc := VBoxContainer.new()
		bc.set_anchors_preset(Control.PRESET_FULL_RECT)
		bc.alignment = BoxContainer.ALIGNMENT_CENTER
		bc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bc.add_theme_constant_override("separation", -2)
		add_child(bc)
		title_lbl = Kit.label("", size_px, Color.WHITE, 6, 700)
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bc.add_child(title_lbl)
		var cr := HBoxContainer.new()
		cr.alignment = BoxContainer.ALIGNMENT_CENTER
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.add_theme_constant_override("separation", 6)
		bc.add_child(cr)
		cost_icon = Kit.icon(icon_name, size_px + 4)
		cr.add_child(cost_icon)
		cost_lbl = Kit.label("", size_px, Color.WHITE, 5, 700)
		cr.add_child(cost_lbl)

	func set_texts(title: String, cost: String) -> void:
		if title_lbl.text != title:
			title_lbl.text = title
		if cost_lbl.text != cost:
			cost_lbl.text = cost
		cost_icon.visible = cost != ""


static func cost_button(icon_name: String, kind: String = "green", size_px: int = 24, min_size: Vector2 = Vector2(200, 84)) -> CostButton:
	var b := CostButton.new()
	b.custom_minimum_size = min_size
	b.build(icon_name, kind, size_px)
	return b


static func scroll(sep: int = 10) -> Array:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := vbox(sep)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	return [sc, v]


static var _knob: Texture2D = null


static func _knob_tex() -> Texture2D:
	if _knob == null:
		var n := 44
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var dx := x - (n - 1) * 0.5
				var dy := y - (n - 1) * 0.5
				var r := sqrt(dx * dx + dy * dy)
				if r <= 21.0:
					img.set_pixel(x, y, Pal.OUTLINE if r > 17.0 else Color.WHITE)
		_knob = ImageTexture.create_from_image(img)
	return _knob


static func slider(value: float, on_change: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(0, 44)
	s.focus_mode = Control.FOCUS_NONE
	var track := box(Color(0, 0, 0, 0.45), 8)
	track.content_margin_top = 8
	track.content_margin_bottom = 8
	s.add_theme_stylebox_override("slider", track)
	var fill := box(Pal.GREEN, 8)
	fill.content_margin_top = 8
	fill.content_margin_bottom = 8
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	s.add_theme_icon_override("grabber", _knob_tex())
	s.add_theme_icon_override("grabber_highlight", _knob_tex())
	s.value_changed.connect(func(x: float): on_change.call(x))
	return s


static func spacer(h: int = 0, w: int = 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func hbox(sep: int = 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep: int = 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


## Botão que repete enquanto está pressionado (compra em sequência, acelerando).
class HoldButton extends Button:
	signal fired
	var _t := 0.0
	var _held := false
	var _next := 0.0
	var _interval := 0.35

	func _ready() -> void:
		button_down.connect(_on_down)
		button_up.connect(_on_up)
		set_process(false)

	func _on_down() -> void:
		_held = true
		_t = 0.0
		_next = 0.35
		_interval = 0.16
		fired.emit()
		set_process(true)

	func _on_up() -> void:
		_held = false
		set_process(false)

	func _process(delta: float) -> void:
		if not _held or disabled:
			return
		_t += delta
		if _t >= _next:
			_next = _t + _interval
			_interval = maxf(0.035, _interval * 0.88)
			fired.emit()


static func hold_button(text: String, kind: String = "green", size: int = 28) -> HoldButton:
	var b := HoldButton.new()
	b.text = text
	style_button(b, kind, size)
	return b
