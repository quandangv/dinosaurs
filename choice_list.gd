extends GridContainer

func _ready():
	me.check_error(connect("resized", self, "_resized"))

func _resized():
	prints(get_child(0).get_size(), get_parent().rect_size.x)
	set_columns(int(get_parent().rect_size.x/get_child(0).get_size()))
