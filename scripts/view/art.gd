class_name Art
extends RefCounted
## Acesso às texturas assadas em res://art/baked (geradas por tools/bake_art.gd).
## Textura ausente vira um quadrado magenta bem visível, para o erro aparecer nos screenshots.

static var _cache: Dictionary = {}
static var _missing: Texture2D = null


static func tex(n: String) -> Texture2D:
	if _cache.has(n):
		return _cache[n]
	var path := "res://art/baked/%s.png" % n
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	if t == null:
		push_warning("arte ausente: " + n)
		t = _placeholder()
	_cache[n] = t
	return t


static func has(n: String) -> bool:
	return ResourceLoader.exists("res://art/baked/%s.png" % n)


static func _placeholder() -> Texture2D:
	if _missing == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(1.0, 0.0, 1.0))
		img.fill_rect(Rect2i(0, 0, 32, 32), Color(0.2, 0.0, 0.2))
		img.fill_rect(Rect2i(32, 32, 32, 32), Color(0.2, 0.0, 0.2))
		_missing = ImageTexture.create_from_image(img)
	return _missing
