extends SceneTree
## "Assa" todos os sprites: gera os SVGs por código, rasteriza com ThorVG e salva PNGs em res://art/baked.
## Também monta folhas de contato em res://qa/ para eu conferir o visual.
## Uso: Godot_console --headless --path . -s tools/bake_art.gd [-- --only=hero_,en_]
## Depois rode --import para o Godot criar as texturas.

const OUT_DIR := "res://art/baked"
const SHEET_DIR := "res://qa"
const CELL := 220
const COLS := 6
const ROWS := 4

var _done := false


func _init() -> void:
	process_frame.connect(_watchdog)
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for p in a.substr(7).split(","):
				only.append(p)
	var all := {}
	HeroArt.build(all)
	EnemyArt.build(all)
	IconArt.build(all)
	BgArt.build(all)
	AppIconArt.build(all)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://icon"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHEET_DIR))
	var names: Array = all.keys()
	names.sort()
	var images: Array[Image] = []
	var labels: Array[String] = []
	var bad := 0
	for n in names:
		if not only.is_empty():
			var ok := false
			for p in only:
				if String(n).begins_with(p):
					ok = true
			if not ok:
				continue
		var spec: Dictionary = all[n]
		var img := Image.new()
		var err := img.load_svg_from_string(String(spec.svg), 1.0)
		if err != OK or img.is_empty():
			print("ERRO ao rasterizar ", n, " (", err, ")")
			bad += 1
			continue
		img.convert(Image.FORMAT_RGBA8)
		if String(n).begins_with("app_icon"):
			img.save_png("res://icon/%s.png" % n)            # ícones do app ficam fora de art/baked (não são sprites do jogo)
			if n == "app_icon":
				var small := img.duplicate()
				small.resize(192, 192, Image.INTERPOLATE_LANCZOS)
				small.save_png("res://icon/app_icon_192.png")
				var f := FileAccess.open("res://icon.svg", FileAccess.WRITE)
				f.store_string(String(spec.svg))
				f.close()
		else:
			img.save_png("%s/%s.png" % [OUT_DIR, n])
		images.append(img)
		labels.append(String(n))
	print("sprites assados: %d (erros: %d)" % [images.size(), bad])
	_sheets(images, labels)
	_done = true
	quit(1 if bad > 0 else 0)


func _watchdog() -> void:
	if not _done:
		print("bake_art terminou sem concluir (erro)")
		quit(2)


func _sheets(images: Array[Image], labels: Array[String]) -> void:
	var per := COLS * ROWS
	var page := 0
	var i := 0
	while i < images.size():
		var sheet := Image.create(COLS * CELL, ROWS * CELL, false, Image.FORMAT_RGBA8)
		# fundo xadrez cinza para ver transparência
		for y in range(0, ROWS * CELL, 20):
			for x in range(0, COLS * CELL, 20):
				var c := Color(0.82, 0.82, 0.86) if ((x + y) / 20) % 2 == 0 else Color(0.74, 0.74, 0.8)
				sheet.fill_rect(Rect2i(x, y, 20, 20), c)
		var legend: Array[String] = []
		for k in per:
			if i >= images.size():
				break
			var src: Image = images[i].duplicate()
			var s := minf(float(CELL - 8) / src.get_width(), float(CELL - 8) / src.get_height())
			if s < 1.0:
				src.resize(maxi(1, int(src.get_width() * s)), maxi(1, int(src.get_height() * s)), Image.INTERPOLATE_LANCZOS)
			var cx := (k % COLS) * CELL + (CELL - src.get_width()) / 2
			var cy := (k / COLS) * CELL + (CELL - src.get_height()) / 2
			sheet.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(cx, cy))
			legend.append("[%d,%d]=%s" % [k / COLS, k % COLS, labels[i]])
			i += 1
		var path := "%s/contact_%02d.png" % [SHEET_DIR, page]
		sheet.save_png(path)
		print("folha ", page, ": ", path, "  ", " ".join(legend))
		page += 1
