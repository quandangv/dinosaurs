extends Timer

export(Array, NodePath) var wiggle_targets
export var wiggle_range = 5
export(Array, String) var map_layouts
export(NodePath) var map
export var color_swap_rate = 6

var rotate_direction = 1
var color_swap_count = 0
var map_swap_count = 0

func _ready():
	for i in wiggle_targets.size():
		wiggle_targets[i] = get_node(wiggle_targets[i])
	connect("timeout", self, "wiggle")
	map = get_node(map)
	call_deferred("wiggle")

func wiggle():
	rotate_direction = -rotate_direction
	for node in wiggle_targets:
		assert(node != null)
		node.rect_rotation = rotate_direction * wiggle_range
	
	if wiggle_targets.size()>=2 and color_swap_count == 0:
		var temp_color = wiggle_targets[0].modulate
		wiggle_targets[0].modulate = wiggle_targets[1].modulate
		wiggle_targets[1].modulate = temp_color
		
		map.import_map(map_layouts[map_swap_count])
		map_swap_count = (map_swap_count +1)%map_layouts.size()
	color_swap_count = (color_swap_count+1)%color_swap_rate
