extends SceneTree
## Compila todos os scripts do projeto de uma vez (depois que os autoloads existem).
## Uso: Godot_console --headless --path . -s tools/check_all.gd

var _done := false
var _ran := false


func _init() -> void:
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	if _ran:
		return
	_ran = true
	var bad := 0
	var total := 0
	for root in ["res://scripts", "res://tools", "res://art/src"]:
		for path in _collect(root):
			total += 1
			var s: Variant = load(path)
			var ok := s != null
			if ok and s is GDScript:
				ok = (s as GDScript).can_instantiate()
			if not ok:
				bad += 1
				print("FALHOU: ", path)
	print("== check_all: %d scripts, %d com erro ==" % [total, bad])
	_done = true
	quit(1 if bad > 0 else 0)


func _collect(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var da := DirAccess.open(dir_path)
	if da == null:
		return out
	da.list_dir_begin()
	var n := da.get_next()
	while n != "":
		if da.current_is_dir():
			if not n.begins_with("."):
				out.append_array(_collect(dir_path.path_join(n)))
		elif n.ends_with(".gd"):
			out.append(dir_path.path_join(n))
		n = da.get_next()
	da.list_dir_end()
	return out
