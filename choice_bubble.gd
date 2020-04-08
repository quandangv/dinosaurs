extends Control

var position_type
var position_number1
var position_number2

func get_cell_name():
	return $margin/texts/title/name.text

func setup(cell_name, description, stat, cell_color, position_type, position_texture, number1, number2):
	self.position_type = position_type
	self.position_number1 = number1
	self.position_number2 = number2
	$margin/texts/title/name.text = cell_name
	$margin/texts/content.text = description
	$margin/texts/stat.text = stat
	$margin/cell_display.set_cell(0,0,$margin/cell_display.tile_set.find_tile_by_name(cell_name))
	$margin/position_display.texture = position_texture
	self_modulate = cell_color
	$margin/texts/stat.self_modulate = cell_color
