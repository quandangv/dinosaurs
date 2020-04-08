extends Control

func _ready():
	for child in get_children():
		child.connect("resized", self, "resized", [child])
		call_deferred("resized", child)

func resized(child):
	child.rect_pivot_offset = child.rect_size/2
