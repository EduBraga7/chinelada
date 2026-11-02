class_name SaveIO
extends RefCounted
## Leitura/gravação do save em JSON com backup e escrita atômica (tmp → troca).
## Se o arquivo principal estiver corrompido, cai para o backup; sem nenhum dos dois, começa um jogo novo.

const PATH := "user://save.json"
const BAK := "user://save.bak.json"
const TMP := "user://save.tmp"


static func load_or_new() -> Dictionary:
	for p in [PATH, BAK]:
		var d := _read(p)
		if not d.is_empty():
			return GameData.fix(d)
	return GameData.fix(GameData.new_data())


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:           # arquivo corrompido: sem barulho no log, cai para o backup
		return {}
	var parsed: Variant = json.data
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("v") and parsed.has("cur"):
		return parsed
	return {}


## Grava o save. Devolve false se algo falhar (o jogo segue rodando; tenta de novo no próximo autosave).
static func save(d: Dictionary) -> bool:
	d.t_last = Time.get_unix_time_from_system()
	var text := JSON.stringify(d)
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	var wrote_ok := f.get_error() == OK
	f.close()
	var da := DirAccess.open("user://")
	if da == null:
		return false
	if not wrote_ok:                                # disco cheio etc.: não troca um save bom por um truncado
		da.remove("save.tmp")
		return false
	if da.file_exists("save.json"):
		da.copy(PATH, BAK)                          # copy() não resolve caminho relativo: precisa do user:// completo
		da.remove("save.json")
	return da.rename("save.tmp", "save.json") == OK


static func wipe() -> void:
	var da := DirAccess.open("user://")
	if da == null:
		return
	for n in ["save.json", "save.bak.json", "save.tmp"]:
		if da.file_exists(n):
			da.remove(n)
