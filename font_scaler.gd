extends Node

export(Array, DynamicFont) var scaled_font
var original_sizes = {}
var font_scale = 1.0/7

func _ready():
	for font in scaled_font:
		original_sizes[[font, "size"]] = font.size
		original_sizes[[font, "outline"]] = font.outline_size
	get_viewport().connect("size_changed", self, "resized")
	call_deferred("resized")

func resized():
	var window_size = get_viewport().size
	var scale_factor = font_scale * min(window_size.x, window_size.y)/100
	for font in scaled_font:
		font.size = original_sizes[[font, "size"]] * scale_factor
		font.outline_size = original_sizes[[font, "outline"]] * scale_factor
		font.update_changes()

