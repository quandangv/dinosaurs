extends Control

export var other: NodePath
export var margin:float = 20

func _ready():
	me.check_error(get_viewport().connect("size_changed", self, "resized"))
	call_deferred("resized")

func resized():
	margin_right = get_parent().rect_size.x - get_node(other).rect_size.x - margin
