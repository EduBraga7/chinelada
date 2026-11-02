extends Node
## Tradução. Uso: Loc.t("chave", [args]). Marcadores {0}, {1}... Cai para o português se faltar a chave.

var lang := "pt"
var _tables: Dictionary = {}


func _ensure() -> void:
	if _tables.is_empty():
		_tables = {"pt": StringsPT.D, "en": StringsEN.D}


func set_language(code: String) -> void:
	_ensure()
	if code == "auto":
		code = "pt" if OS.get_locale_language() == "pt" else "en"
	lang = code if _tables.has(code) else "en"


func has_key(key: String) -> bool:
	_ensure()
	return _tables[lang].has(key) or _tables["pt"].has(key)


func t(key: String, args: Array = []) -> String:
	_ensure()
	var s := ""
	var tbl: Dictionary = _tables[lang]
	if tbl.has(key):
		s = tbl[key]
	elif _tables["pt"].has(key):
		s = _tables["pt"][key]
	else:
		return key
	for i in args.size():
		s = s.replace("{%d}" % i, str(args[i]))
	return s


## Texto de um bônus: "+25% Dano" etc.
func stat_text(stat: String, value: float) -> String:
	match stat:
		"revive":
			return t("stat.revive")
		"auto_fury", "fornada_slots":
			return t("stat." + stat)
		"fury_dur", "boss_time":
			return "+%s s %s" % [NumFmt.fmt(value), t("stat." + stat)]
		"off_cap":
			return "+%s h %s" % [NumFmt.fmt(value / 3600.0), t("stat." + stat)]
		"start_stage":
			return "+%d %s" % [int(value), t("stat." + stat)]
		"pity_cut":
			return "-%d %s" % [int(value), t("stat." + stat)]
		"regen":
			return "+%s/s %s" % [NumFmt.pct(value), t("stat.regen")]
		"haste":
			return "+%s %s" % [NumFmt.pct(value), t("stat.haste")]
		_:
			return "+%s %s" % [NumFmt.pct(value), t("stat." + stat)]
