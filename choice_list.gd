extends GridContainer

func _ready():
	connect("resized", self, "_resized")

func _resized():
	prints(get_child(0).get_size(), get_parent().rect_size.x)
	set_columns(floor(get_parent().rect_size.x/get_child(0).get_size()))
