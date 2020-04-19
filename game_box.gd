extends Control

export var right_aligned = true
var working

func _ready():
	me.check_error(connect("resized", self, "resized"))
	call_deferred("resized")

func resized():
	if right_aligned:
		margin_left = -rect_size.y
	else:
		margin_right = rect_size.y
