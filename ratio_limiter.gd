extends Control

export var max_h_v_ratio = 16.0/9
export var margin = 20

func _ready():
	me.check_error(get_viewport().connect("size_changed", self, "resized"))
	resized()

func resized():
	var size = get_viewport().size
	if size.x/size.y > max_h_v_ratio:
		rect_size.x = rect_size.y * max_h_v_ratio
		set_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	else:
		margin_top = margin
		margin_bottom = -margin
		margin_left = margin
		margin_right = -margin
