extends Node
## Áudio: efeitos (pool de vozes) e música em loop com crossfade. Os WAVs vêm de tools/gen_audio.py.
## Arquivo ausente não quebra nada: só não toca.

const POOL := 14
## Ajuste fino de volume por som (dB) — os sons frequentes ficam mais baixos
const GAIN_DB := {
	"hit": -9.0, "crit": -5.0, "kill": -6.0, "coin": -10.0, "tab": -10.0, "deny": -7.0, "upgrade": -5.0, "recruit": -4.0,
	"fury": -3.0, "skill_neide": -4.0, "heal": -6.0, "fanfare": -4.0, "fail": -6.0, "boss_roar": -4.0, "marmita": -5.0,
	"bless": -4.0, "parrot": -6.0, "pop": -8.0,
}
## Intervalo mínimo entre repetições do mesmo som (s)
const THROTTLE := {"hit": 0.05, "kill": 0.07, "coin": 0.05, "crit": 0.08, "tab": 0.05}

var haptics := true
var sfx_vol := 1.0
var music_vol := 0.7

var _streams: Dictionary = {}
var _missing: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _last: Dictionary = {}
var _music: Array[AudioStreamPlayer] = []
var _music_idx := 0
var _music_name := ""
var _sfx_bus := -1
var _music_bus := -1


func _ready() -> void:
	_sfx_bus = _ensure_bus("SFX")
	_music_bus = _ensure_bus("Music")
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -60.0
		add_child(m)
		_music.append(m)
	set_volumes(sfx_vol, music_vol)


func _ensure_bus(bus_name: String) -> int:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")
	return i


func set_volumes(sfx: float, music: float) -> void:
	sfx_vol = clampf(sfx, 0.0, 1.0)
	music_vol = clampf(music, 0.0, 1.0)
	if _sfx_bus >= 0:
		AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(maxf(sfx_vol, 0.0001)))
		AudioServer.set_bus_mute(_sfx_bus, sfx_vol <= 0.01)
		AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(music_vol, 0.0001)) - 8.0)
		AudioServer.set_bus_mute(_music_bus, music_vol <= 0.01)


func _stream(n: String) -> AudioStream:
	if _streams.has(n):
		return _streams[n]
	var path := "res://audio/sfx/%s.wav" % n
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	elif not _missing.has(n):
		_missing[n] = true
		push_warning("som ausente: " + n)
	_streams[n] = s
	return s


func play(n: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if sfx_vol <= 0.01:
		return
	var now := float(Time.get_ticks_msec()) / 1000.0
	if THROTTLE.has(n) and now - float(_last.get(n, -9.0)) < float(THROTTLE[n]):
		return
	_last[n] = now
	var st := _stream(n)
	if st == null:
		return
	var p: AudioStreamPlayer = null
	for q in _players:
		if not q.playing:
			p = q
			break
	if p == null:
		p = _players[randi() % POOL]
	p.stream = st
	p.pitch_scale = clampf(pitch, 0.5, 2.0)
	p.volume_db = float(GAIN_DB.get(n, 0.0)) + vol_db
	p.play()


## Toca (em loop) a música `n`, com crossfade. Chamar de novo com o mesmo nome não faz nada.
func play_music(n: String) -> void:
	if n == _music_name:
		return
	_music_name = n
	var path := "res://audio/music/%s.wav" % n
	var old := _music[_music_idx]
	_music_idx = 1 - _music_idx
	var cur := _music[_music_idx]
	var tw := create_tween()
	if old.playing:
		tw.tween_property(old, "volume_db", -50.0, 0.7)
		tw.parallel().tween_callback(old.stop).set_delay(0.75)
	if not ResourceLoader.exists(path):
		return
	var st: AudioStreamWAV = load(path)
	if st == null:
		return
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	var bytes := 2 if st.format == AudioStreamWAV.FORMAT_16_BITS else 1
	st.loop_end = st.data.size() / (bytes * (2 if st.stereo else 1))
	cur.stream = st
	cur.volume_db = -50.0
	cur.play()
	tw.parallel().tween_property(cur, "volume_db", 0.0, 0.9)


func stop_music() -> void:
	_music_name = ""
	for m in _music:
		m.stop()


func vibrate(ms: int) -> void:
	if haptics:
		Input.vibrate_handheld(ms)
