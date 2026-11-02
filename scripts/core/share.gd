class_name Share
extends RefCounted
## Compartilhamento sem plugin: copia o texto e abre WhatsApp/Telegram pelo link de compartilhamento.
## (No Android, OS.shell_open dispara a intent do app; no PC abre o navegador.)


static func copy(text: String) -> void:
	DisplayServer.clipboard_set(text)


static func whatsapp(text: String) -> void:
	copy(text)
	OS.shell_open("https://wa.me/?text=" + text.uri_encode())


static func telegram(text: String) -> void:
	copy(text)
	OS.shell_open("https://t.me/share/url?url=%20&text=" + text.uri_encode())


## Texto de progresso para compartilhar.
static func progress_text() -> String:
	var d: Dictionary = G.d
	return Loc.t("share.text", [int(d.stage.best), NumFmt.fmt(G.dir.power), NumFmt.fmt(float(d.stats.kills))])


static func diary_text(report: Dictionary) -> String:
	return Loc.t("share.diary", [NumFmt.fmt(float(report.kills)), int(report.stage_to)])
