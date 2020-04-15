extends Panel

signal closed

export(NodePath) var center

var message_node

func get_center(node:Control):
	return node.rect_global_position + node.rect_size/2

func choose_message():
	var origin = get_node(center).rect_global_position
	var chosen = null
	var chosen_distance = 10000000000
	for node in get_children():
		var distance = (get_center(node)-origin).length_squared()
		if distance < chosen_distance:
			chosen_distance = distance
			chosen = node
	return chosen

func focus(target:Control, message):
	yield(get_tree(), "idle_frame")
	rect_global_position = me.check_null(target, "the focus target cannot be null").rect_global_position
	rect_size = target.rect_size
	message_node = choose_message()
	message_node.text = message
	message_node.visible = true
	visible = true

func _input(event):
	if visible and get_global_rect().has_point(get_global_mouse_position()) and event is InputEventMouseButton and event.button_index == BUTTON_LEFT and !event.pressed:
		visible = false
		if message_node != null:
			message_node.visible = false
		emit_signal("closed")
