extends Node
class_name ScreenScaler, "res://arts/icon.png"

onready var original_size = get_parent().rect_size
var scale_factor = 1.0/6.0

func _ready():
	get_viewport().connect("size_changed", self, "resized")
	resized()

func resized():
	var window_size = get_viewport().size
	get_parent().rect_min_size = original_size*scale_factor*min(window_size.x, window_size.y)/100
