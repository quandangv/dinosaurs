extends Control

export var right_aligned = true
var working

func _ready():
	me.check_error(connect("resized", self, "resized"))
	call_deferred("resized")

func resized():
	rect_size.x = rect_size.y
	rect_min_size.x = rect_size.y
