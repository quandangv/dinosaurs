extends Button

export var target: NodePath

func _pressed():
	get_node(target).visible = true
