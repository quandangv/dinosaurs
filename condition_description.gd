extends Label

export(NodePath) var condition_box
export(NodePath) var stat_box
var category

func _button_hover(button):
	text = tr(button.name) % category
	visible = true
	get_node(stat_box).visible = false

func _ready():
	for button in get_node(condition_box).get_children():
		button.connect("mouse_entered", self, "_button_hover", [button])
