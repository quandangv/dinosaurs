extends Button

export var closing:NodePath = "../"

func _pressed():
	get_node(closing).visible = false
