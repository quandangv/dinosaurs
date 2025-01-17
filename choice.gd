extends Control

signal selected

var cell_name
var description
var conditions
var category

func get_size():
	return $minimized.rect_size.x +30
func get_cell_name():
	return cell_name

func _ready():
	me.check_error($minimized.connect("pressed", self, "_pressed"))
	me.check_error($minimized.connect("focus_entered", self, "_focused"))
	$minimized/tile.texture = AtlasTexture.new()
func setup(_cell_name, _description, _category, _conditions, cell_color):
	self.cell_name = _cell_name
	self.description = _description
	self.conditions = _conditions
	self.category = _category
	me.set_texture($minimized/tile.texture, cell_name)
	$minimized.self_modulate = cell_color
func _pressed():
	get_node("../../description").setup(cell_name, description, category, conditions, $minimized.self_modulate)
func _focused():
	emit_signal("selected")
