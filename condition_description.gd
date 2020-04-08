extends Label

export(NodePath) var condition_box
var category

func _button_hover(button):
	text = tr(button.name) % category

func _ready():
	for button in get_node(condition_box).get_children():
		button.connect("mouse_entered", self, "_button_hover", [button])
