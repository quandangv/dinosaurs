#extends Control
#
#
#func _ready():
#	connect("resized", self, "resized")
#	call_deferred("resized")
#
#func resized():
#	var real_size = $world/background.rect_size
#	$world.scale = Vector2(rect_size.x/real_size.x, rect_size.y/real_size.y)
extends Viewport


func _ready():
	connect("size_changed", self, "size_changed")

func size_changed():
	var real_size = $world/background.rect_size
	$world.scale = Vector2(size.x/real_size.x, size.y/real_size.y)
