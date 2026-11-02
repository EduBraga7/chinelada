extends SceneTree
## Junta screenshots lado a lado numa só imagem.
## Uso: ... -s tools/montage.gd -- --files=04_aba1,04_aba2 --out=m1 [--scale=0.5]


func _init() -> void:
	var files: PackedStringArray = []
	var out := "montage"
	var sc := 0.5
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--files="):
			files = a.substr(8).split(",")
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--scale="):
			sc = float(a.substr(8))
	var imgs: Array[Image] = []
	for f in files:
		var im := Image.load_from_file("res://qa/%s.png" % f)
		if im == null or im.is_empty():
			print("falta ", f)
			continue
		im.resize(int(im.get_width() * sc), int(im.get_height() * sc), Image.INTERPOLATE_LANCZOS)
		imgs.append(im)
	if imgs.is_empty():
		quit(1)
		return
	var w := 0
	var h := 0
	for im in imgs:
		w += im.get_width() + 6
		h = maxi(h, im.get_height())
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.12))
	var x := 0
	for im in imgs:
		sheet.blit_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(x, 0))
		x += im.get_width() + 6
	sheet.save_png("res://qa/%s.png" % out)
	print("montagem ", out, " ", sheet.get_size())
	quit()
