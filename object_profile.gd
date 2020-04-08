extends HBoxContainer

func setup(cell_name):
	name = cell_name
	$tile.texture = AtlasTexture.new()
	me.set_texture($tile.texture, cell_name)
	get_node("label").text = "0"
	queue_sort()
	visible = false
