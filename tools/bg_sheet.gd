extends SceneTree
## Junta os 5 cenários em uma única imagem (res://qa/bgs.png) para conferência visual.


func _init() -> void:
	var names := ["cozinha", "quintal", "rua", "escritorio", "banco"]
	var sheet := Image.create(720, 750, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.BLACK)
	for i in names.size():
		var img := Image.load_from_file("res://art/baked/bg_%s.png" % names[i])
		if img == null or img.is_empty():
			print("falta bg_", names[i])
			continue
		img.resize(360, 250, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(img, Rect2i(0, 0, 360, 250), Vector2i((i % 2) * 360, (i / 2) * 250))
	sheet.save_png("res://qa/bgs.png")
	print("ok bgs.png")
	quit()
