extends Node

signal language_changed

export var skip_game = false
export (NodePath) var tilemap
export (NodePath) var main_menu
export (NodePath) var game_choices
export (NodePath) var descriptions
export (NodePath) var game_over
export (NodePath) var message
export (NodePath) var focus
export var sumnary_theme:Theme
export var final_theme:Theme
export var object_profile:PackedScene
export (Array, AudioStream) var ticks

export var sea_color:Color
export var land_color:Color
export var sand_color:Color
export var wave_ratio = 0.07
export var land_ratio = 0.55

export(Array, String) var cell_types
export(Array, Array, String) var cell_conditions
export(Array, Array, String) var choice_steps
export(Array, int) var object_count
export(Array, String) var plants
export(Array, String) var animals
export(Array, String) var structures
export(Array, NodePath) var instructions_focus
export(Array, String) var instructions_message

var show_instructions

var auto_next
var _game_progress
onready var object_categories = {"plant":plants, "animal": animals, "structure":structures}

func _show_instructions():
	for i in instructions_focus.size():
		focus.focus(instructions_focus[i], instructions_message[i])
		yield(focus, "closed")
	show_instructions = false

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		show_instructions = config.get_value("general", "show_instructions", true)
	else:
		show_instructions = true

func save_settings():
	var config = ConfigFile.new()
	config.set_value("general", "show_instructions", show_instructions)
	config.save("user://settings.cfg")

func get_conditions(cell_type):
	var cell_id = cell_types.find(cell_type)
	assert(cell_id != -1)
	return cell_conditions[cell_id]

# choice_bubble parameters:
# func setup(cell_name, description, stat, cell_color, position_type, position_texture, position_number):
func set_bubble(choice_bubble, cell_index):
	var name = cell_types[cell_index]
	var description = tr(name+" text")
	var conditions = cell_conditions[cell_index]
	var color = sea_color if tilemap.sea_cells.find(name) != -1 else sand_color if name == "Sand" else land_color
	choice_bubble.setup(name, description, object_categories.get(name, "object"), conditions, color)

func set_bubble_random(choice_bubble, names):
	# there must be at least one choice to choose from
	assert(names.size() > 0)
	var cell_types_count = names.size()
	var cell_index = randi()%cell_types_count
	cell_index = cell_types.find(names[cell_index])
	assert(cell_index != -1)
	set_bubble(choice_bubble, cell_index)

func _init_paths():
	tilemap = get_node(tilemap)
	main_menu = get_node(main_menu)
	game_choices = get_node(game_choices)
	descriptions = get_node(descriptions)
	game_over = get_node(game_over)
	message = get_node(message)
	focus = get_node(focus)
	for i in instructions_focus.size():
		instructions_focus[i] = get_node(instructions_focus[i])

func _ready():
	randomize()
	_init_paths()
	load_settings()
	game_over.get_node("margin/bottom/next").connect("pressed", self, "game_next")
	message.get_node("close").connect("pressed", self, "game_next")
	tilemap.connect("pressed", self, "game_next")
	for category in object_categories.keys():
		var array = object_categories[category]
		object_categories.erase(category)
		for object in array:
			object_categories[object] = category
	for bubble in game_choices.get_children():
		bubble.connect("selected", self, "bubble_selected", [bubble])
	var object_list = game_over.get_node("margin/scroll/object_list")
	for name in cell_types:
		var profile = object_profile.instance()
		profile.setup(name)
		object_list.add_child(profile)

func _exit_tree():
	save_settings()

func bubble_selected(bubble):
	var selection_map:TileMap = tilemap.get_node("borders")
	var object_map:TileMap = tilemap.get_node("objects")
	tilemap.selected_cell_type = bubble.get_cell_name()
	tilemap.selected_choice = bubble

func reset_objects(step):
	tilemap.selected_cell_type = null
	var bubbles = game_choices.get_children()
	for i in bubbles.size():
		var bubble = bubbles[i]
		bubble.visible = i < object_count[step]
		if bubble.visible:
			bubble.release_focus()
			set_bubble_random(bubble, choice_steps[step])

func _process(event):
	if auto_next and Input.is_action_just_pressed("ui_accept"):
		game_next()

func game_progress():
	$wiggles.stop()
	main_menu.visible = false
	_show_instructions()
	
	if !skip_game:
		tilemap.generate_islands(land_ratio, wave_ratio)
		game_choices.get_parent().visible = true
		for step in choice_steps.size():
			reset_objects(step)
			for i in object_count[step]:
				descriptions.visible = false
				yield().visible = false
				$sfx.stream = ticks[randi()%ticks.size()]
				$sfx.play()
		game_choices.get_parent().visible = false
	
	# tallying the score
	var next_button = game_over.get_node("margin/bottom/next")
	next_button.text = "Next"
	game_over.visible = true
	auto_next = true
	tilemap.game_over = true
	next_button.visible = false
	var used_cell = tilemap.get_used_cell_names()
	var grand_total = 0
	
	game_over.get_node("margin/bottom/grand_total").text = String(grand_total)
	for profile in game_over.get_node("margin/scroll/object_list").get_children():
		profile.visible = false
	for profile in game_over.get_node("margin/scroll/object_list").get_children():
		var total = 0
		for cell in used_cell.keys():
			if used_cell[cell] == profile.name:
				profile.visible = true
				for point in tilemap.display_cell_detail(cell, profile.name).values():
					total += point
					profile.get_node("label").text = String(total)
				tilemap.focus(cell)
				yield()
				tilemap.clear_ghosts()
		profile.get_node("label").text = String(total)
		grand_total += total
		game_over.get_node("margin/bottom/grand_total").text = String(grand_total)
	next_button.visible = true
	auto_next = false
	tilemap.clear_ghosts()
	yield()
	tilemap.game_over = false
	game_over.visible = false
	
	message.visible = true
	yield()
	
	main_menu.visible = true
	$wiggles.start()

func start_game(game_seed):
	tilemap.clear()
	seed(hash(game_seed))
	_game_progress = game_progress()
	tilemap.clear_placement()

func daily_game():
	var date = OS.get_date()
	var _seed = String(date["year"])+String(date["month"])+String(date["day"])
	start_game(_seed)

func game_next(arg = null):
	if _game_progress == null:
		main_menu.visible = true
		$wiggles.start()
	else:
		_game_progress = _game_progress.resume(arg)

func random_game():
	start_game(OS.get_system_time_secs())

func cancel_placement():
	game_next("skip")
