extends Control

export var tileset:TileSet
export(NodePath) var lvl_up_stat
export(NodePath) var lvl_up_desc = "bubble/margin/texts/details/stat"

func setup(cell_name, description, category, conditions, cell_color):
	$bubble.visible = true
	$bubble/margin/texts/title/name.text = cell_name
	$bubble/margin/texts/content.text = description
	$bubble.self_modulate = cell_color
	get_node(lvl_up_stat).modulate = cell_color
	get_node(lvl_up_stat).visible = false
	get_node(lvl_up_desc).visible = true
	get_node(lvl_up_desc).modulate = cell_color
	get_node(lvl_up_desc).text = tr("view icon prompt")
	get_node(lvl_up_desc).category = category
	me.set_texture($bubble/margin/texts/title/icon.texture, cell_name)
	var icons = $bubble/margin/texts/details/lvl_up_options.get_children()
	for c in icons.size():
		icons[c].visible = c < conditions.size()
		if c < conditions.size():
			var icon = icons[c]
			icon.name = conditions[c]
			me.set_texture(icon.texture, conditions[c])

func show_lvl_up_stats(stats):
	var parent = get_node(lvl_up_stat)
	get_node(lvl_up_desc).visible = false
	parent.visible = true
	for i in parent.get_child_count():
		var child = parent.get_child(i)
		child.visible = i < stats.size()
		if child.visible:
			child.get_node("value").value = stats[i]
