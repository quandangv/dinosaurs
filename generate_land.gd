extends Node

func _ready():
	yield(get_tree(), "idle_frame")
	seed(OS.get_system_time_secs())
	var p = get_parent()
	p.generate_islands()
