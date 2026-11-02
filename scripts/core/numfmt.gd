class_name NumFmt
extends RefCounted
## Formatação de números estilo idle game: 1,23K · 4,5M · ... · 1.2e45, e de durações.

const SUFFIX: PackedStringArray = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

static var scientific := false


static func fmt(v: float) -> String:
	if is_nan(v):
		return "0"
	if is_inf(v):
		return "MAX"
	var neg := v < 0.0
	var a := absf(v)
	var s := ""
	if a < 1000.0:
		if a < 10.0 and a != floorf(a):
			s = _trim("%.1f" % a)
		else:
			s = str(int(floorf(a)))
	elif scientific or a >= 1.0e36:
		s = _sci(a)
	else:
		var tier := 0
		var x := a
		while x >= 1000.0:
			x /= 1000.0
			tier += 1
		var dec := 2 if x < 10.0 else (1 if x < 100.0 else 0)
		var m := pow(10.0, dec)
		x = roundf(x * m) / m
		if x >= 1000.0:
			x /= 1000.0
			tier += 1
			dec = 2
			x = roundf(x * 100.0) / 100.0
		s = _trim(("%." + str(dec) + "f") % x) + SUFFIX[tier]
	return ("-" if neg else "") + s


static func _trim(t: String) -> String:
	if t.contains("."):
		t = t.rstrip("0")
		t = t.rstrip(".")
	return t


static func _sci(a: float) -> String:
	var e := int(floorf(log(a) / log(10.0)))
	var mant := a / pow(10.0, e)
	if mant >= 10.0:
		mant /= 10.0
		e += 1
	elif mant < 1.0:
		mant *= 10.0
		e -= 1
	return _trim("%.2f" % mant) + "e" + str(e)


## "2h 15m", "4m 10s", "35s"
static func duration(sec: float) -> String:
	var s := maxi(int(sec), 0)
	var h := floori(s / 3600.0)
	var m := floori((s % 3600) / 60.0)
	var r := s % 60
	if h > 0:
		return "%dh %02dm" % [h, m]
	if m > 0:
		return "%dm %02ds" % [m, r]
	return "%ds" % r


## "01:23:45" ou "12:34"
static func clock(sec: float) -> String:
	var s := maxi(int(sec), 0)
	var h := floori(s / 3600.0)
	var m := floori((s % 3600) / 60.0)
	var r := s % 60
	if h > 0:
		return "%02d:%02d:%02d" % [h, m, r]
	return "%02d:%02d" % [m, r]


static func pct(v: float) -> String:
	var p := v * 100.0
	if absf(p - roundf(p)) < 0.05:
		return "%d%%" % int(roundf(p))
	return "%.1f%%" % p
