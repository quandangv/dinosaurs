extends Control

export(Array, String) var condition_names
export var tileset:TileSet

func setup(cell_name, description, category, conditions, cell_color):
	$bubble.visible = true
	$bubble/margin/texts/title/name.text = cell_name
	$bubble/margin/texts/content.text = description
	$bubble.self_modulate = cell_color
	$bubble/margin/texts/stat.self_modulate = cell_color
	$bubble/margin/texts/stat.text = tr("view icon prompt")
	$bubble/margin/texts/stat.category = category
	me.set_texture($bubble/margin/texts/title/icon.texture, cell_name)
	var icons = $bubble/margin/texts/title/conditions.get_children()
	for c in icons.size():
		icons[c].visible = c < conditions.size()
		if c < conditions.size():
			var icon = icons[c]
			icon.name = conditions[c]
			me.set_texture(icon.texture, conditions[c])
