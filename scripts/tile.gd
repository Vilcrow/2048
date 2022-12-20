extends TextureRect

onready var label := $ValueLabel

const COLOR_0    := "00a5a2a2" #transparent
const COLOR_2    := "e3eb03"
const COLOR_4    := "8c8c00" 
const COLOR_8    := "c57a05"
const COLOR_16   := "ee9100"
const COLOR_32   := "26d4fc"
const COLOR_64   := "2633fc"
const COLOR_128  := "481289"
const COLOR_256  := "9d4cff"
const COLOR_512  := "82009d"
const COLOR_1024 := "b000d4"
const COLOR_2048 := "c40b10"
const COLOR_MORE := "ba0099"

var value := 0

func _ready():
	if value:
		label.text = str(value)
	else:
		label.text = ""
	set_modulate(COLOR_0)

func set_value(var val):
	value = val
	if value:
		label.text = str(value)
	else:
		label.text = ""
	update_color()

func get_value() -> int:
	return value

func update_color():
	match value:
		0:
			set_modulate(COLOR_0)
		2:
			set_modulate(COLOR_2)
		4:
			set_modulate(COLOR_4)
		8:
			set_modulate(COLOR_8)
		16:
			set_modulate(COLOR_16)
		32:
			set_modulate(COLOR_32)
		64:
			set_modulate(COLOR_64)
		128:
			set_modulate(COLOR_128)
		256:
			set_modulate(COLOR_256)
		512:
			set_modulate(COLOR_512)
		1024:
			set_modulate(COLOR_1024)
		2048:
			set_modulate(COLOR_2048)
		_:
			set_modulate(COLOR_MORE)

func play_doubling_animation():
	$AnimationPlayer.play("doubling")
	$DoublingPlayer.play()
