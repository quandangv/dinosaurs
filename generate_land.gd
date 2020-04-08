extends Node

func _ready():
	yield(get_tree(), "idle_frame")
	seed(OS.get_system_time_secs())
	var p = get_parent()
	var g = get_node("../map_generator")
#	p.generate_islands(0.55, 0.15)
	p.generate_submap(Vector2(1,2))
