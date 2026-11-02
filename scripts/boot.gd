extends Node
## Ponto de entrada: monta a tela principal. Argumentos de linha de comando (após --):
##   --qa=<cenário>  roda o roteiro de verificação visual (scripts/qa_tour.gd) e sai.


func _ready() -> void:
	var qa := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--qa="):
			qa = a.substr(5)
	if qa != "":
		G.no_save = true
		G.qa_frozen = qa == "tour" or qa == "boss"      # congela o tempo; os demais modos rodam em tempo real
	var main := Main.new()
	add_child(main)
	if qa != "":
		var tour := QaTour.new()
		tour.main = main
		tour.mode = qa
		add_child(tour)
