extends ScreenScaler



func resized():
	.resized()
	yield(get_tree(), "idle_frame")
	get_parent().get_parent().rect_min_size.y = get_parent().rect_size.y
