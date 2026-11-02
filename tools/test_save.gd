extends SceneTree
## Testa persistência: salvar/carregar, números enormes, backup em caso de arquivo corrompido,
## save antigo sem campos novos (migração) e valores inválidos.
## Uso: Godot_console --headless --path . -s tools/test_save.gd

var _fails := 0
var _ran := false


func _init() -> void:
	process_frame.connect(_run)


func _expect(c: bool, msg: String) -> void:
	if c:
		print("  ok   ", msg)
	else:
		print("  FALHA ", msg)
		_fails += 1


func _run() -> void:
	if _ran:
		return
	_ran = true
	SaveIO.wipe()
	print("== test_save ==")
	# 1) ida e volta
	var d := GameData.new_data()
	d.cur.gold = 1.234e45
	d.cur.gems = 77
	d.stage.cleared = 123
	d.heroes["vovo"].owned = true
	d.heroes["vovo"].lvl = 250
	d.relics = {"cofrinho": {"lvl": 7}}
	d.bless = {"forca": 3}
	_expect(SaveIO.save(d), "salvar retorna true")
	var l := SaveIO.load_or_new()
	_expect(is_equal_approx(float(l.cur.gold) / 1.234e45, 1.0), "ouro enorme (1.234e45) volta igual")
	_expect(int(l.cur.gems) == 77 and int(l.stage.cleared) == 123, "gemas e estágio voltam como inteiros")
	_expect(int(l.heroes["vovo"].lvl) == 250 and l.heroes["vovo"].owned == true, "herói recrutado e nível")
	_expect(l.relics.has("cofrinho") and int(l.relics.cofrinho.lvl) == 7, "relíquia")
	_expect(int(l.bless.forca) == 3, "bênção")
	_expect(typeof(l.cur.gems) == TYPE_INT, "tipos normalizados (int)")
	# 2) segundo save cria o backup
	d.cur.gems = 78
	SaveIO.save(d)
	_expect(FileAccess.file_exists(SaveIO.BAK), "backup criado no segundo save")
	# 3) arquivo principal corrompido → carrega do backup
	var f := FileAccess.open(SaveIO.PATH, FileAccess.WRITE)
	f.store_string("{ isto nao eh json ]]]")
	f.close()
	var r := SaveIO.load_or_new()
	_expect(int(r.cur.gems) == 77 or int(r.cur.gems) == 78, "arquivo corrompido: recupera do backup (gemas=%d)" % int(r.cur.gems))
	# 4) tudo corrompido → jogo novo
	var f2 := FileAccess.open(SaveIO.BAK, FileAccess.WRITE)
	f2.store_string("lixo")
	f2.close()
	var n := SaveIO.load_or_new()
	_expect(int(n.stage.cleared) == 0 and n.heroes["neide"].owned == true, "tudo corrompido: começa jogo novo com a Neide")
	# 5) save antigo sem campos novos (migração)
	var old := {"v": 1, "cur": {"gold": 5.0, "gems": 3, "bless": 0}, "heroes": {"neide": {"owned": true, "lvl": 9}}, "party": ["neide", "fantasma"]}
	var f3 := FileAccess.open(SaveIO.PATH, FileAccess.WRITE)
	f3.store_string(JSON.stringify(old))
	f3.close()
	var m := SaveIO.load_or_new()
	_expect(m.has("settings") and m.has("daily") and m.has("fornada") and m.has("flags"), "migração: campos novos preenchidos")
	_expect(m.party == ["neide"], "migração: herói inexistente removido do time")
	_expect(int(m.heroes["neide"].lvl) == 9 and m.heroes.has("fofoca"), "migração: mantém níveis e completa heróis")
	# 6) valores inválidos
	var bad := GameData.new_data()
	bad.cur.gold = INF
	bad.stage.blocked_power = NAN
	bad.relics = {"nao_existe": {"lvl": 3}, "cofrinho": {"lvl": 9999}}
	bad.bless = {"forca": 999, "nao_existe": 2}
	var fx := GameData.fix(bad)
	_expect(is_finite(float(fx.cur.gold)) and is_finite(float(fx.stage.blocked_power)), "inf/NaN viram 0")
	_expect(not fx.relics.has("nao_existe") and int(fx.relics.cofrinho.lvl) == RelicDefs.MAX_LEVEL, "relíquia inválida some; nível limitado ao máximo")
	_expect(int(fx.bless.forca) == int(BlessDefs.DATA.forca.max) and not fx.bless.has("nao_existe"), "bênção inválida some; nível limitado")
	# 7) número formatado
	_expect(NumFmt.fmt(1234.0) == "1.23K" and NumFmt.fmt(999999.0) == "1M" and NumFmt.fmt(1.5e12) == "1.5T", "NumFmt: %s %s %s" % [NumFmt.fmt(1234.0), NumFmt.fmt(999999.0), NumFmt.fmt(1.5e12)])
	_expect(NumFmt.fmt(1e40).contains("e"), "NumFmt: notação científica acima de 1e36 (%s)" % NumFmt.fmt(1e40))
	SaveIO.wipe()
	print("== resultado: %s ==" % ("OK" if _fails == 0 else "%d FALHA(S)" % _fails))
	quit(1 if _fails > 0 else 0)
