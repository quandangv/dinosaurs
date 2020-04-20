extends Node2D

signal pressed
signal hovered

var selected_cell_type
var selected_choice

export var margin_size = Vector2(40,40)
export var map_size:float = 640
export var map_division = 10
export var submap_size = 40
export var island_land_ratio = 0.8
export var waves_preference = 3
export var tsunami_preference = 1
export(Array, String) var cell_types = [
	"Hungry Dino", "Shark", "Coral", "Field", "Lonely Dino", "Mountain",
	"Shrub", "Social Dino", "Tree", "Waves", "Chicken", "Wolf", "Tsunami",
	"Marsh", "Sunken Ship", "Forgotten Temple"
]

var atlas_tile_total = {}

var game_over
var current_flip_x = true
var cell_category = {
	"animal": ["Hungry Dino", "Lonely Dino", "Social Dino", "Shark", "Chicken"],
	"natural": ["Hungry Dino", "Lonely Dino", "Social Dino", "Shark", "Waves", "Tree", "Coral", "Shrub", "Mountain", "Field"],
	"plant": ["Tree", "Shrub", "Field"],
	"crowding": ["Tree", "Shrub"],
	"beast": ["Shark", "Hungry Dino", "Social Dino", "Wolf"],
	"waves": ["Waves", "Tsunami"]
	}
var exported_map
var enclosure_tile

onready var terrain_layers = [[$sand, "Sand"], [$land, "Land"]]
onready var blob_layer = [$marsh, "Marsh"]
var object_layer = "objects"
var blob_rates = {"Marsh":0.13}

var base_rate = 0.08
var rate_presets = {"dry":0.5, "animal":0.1}
var pref_presets = {"dry":[["dryness", [0.9, 1.4]]],
	"temperate":[["dryness", [0.5, 1.4]]],
	"non_marine":[["depth", [0, 1]]],
	"marine":[["depth", [1, 0.5]]],
	"dryness_neutral":[]}
# the pref of each object is like [base_rate, [presets]]
var object_prefs = {"Tree": [0.08, []], "Shrub": [0.04, []], "Hungry Dino":[0.04,["dryness_neutral"]]}
var base_prop = {"dryness":0, "depth":1}
var tile_props = {"Sand":{"dryness":1, "depth":0}, "Land":{"dryness":0.5}, "Marsh":{"dryness":0}}
var default_presets = [[["marine"], "non_marine"], [["dry", "dryness_neutral"], "temperate"]]
var tile_categories = {
	"marine":[ "Shark", "Coral", "Tsunami", "Waves", "Sunken Ship" ],
	"temperate":["Tree"],
	"dryness_neutral":["Hungry Dino"],
	"animal":["Hungry Dino"]
}

func _ready():
	$background.rect_size = map_size*$objects.scale + margin_size
	selected_choice = null
	export_map()
	enclosure_tile = $enclosure.tile_set.find_tile_by_name("enclosure")
	assert(enclosure_tile != -1)

	for obj in cell_types:
		if !object_prefs.has(obj):
			object_prefs[obj] = [base_rate,[]]
	for obj in cell_types:
		var obj_presets = object_prefs[obj][1]
		for meta_cat in default_presets:
			var no_preset = true
			for alt in meta_cat[0]:
				if obj_presets.has(alt):
					no_preset = false
					break
			if no_preset:
				obj_presets.push_back(meta_cat[1])

func generate_islands(land_ratio, wave_ratio):
	$sand.clear()
	$land.clear()
	$marsh.clear()
	$objects.clear()
	for cell in $map_generator.generate_blobs(land_ratio, null, map_division):
		set_env(cell, "Sand")
	print(land_ratio*island_land_ratio)
	for cell in $map_generator.generate_blobs(island_land_ratio, $sand, map_division):
		set_env(cell, "Land")

	for i in map_division:
		for j in map_division:
			var cell = Vector2(i,j)
			if get_env(cell) == "Ocean" and randf() < wave_ratio:
				set_object(cell, "Waves"if randf()*(waves_preference) < waves_preference else "Tsunami")

func get_random_subtile(tile_id):
	# Calculate the size of the autotile in number of tiles instead of in pixels
	# So that we can iterate the subtiles of the autotile
	var region = me.object_tileset.tile_get_region(tile_id).size
	var tile_size = me.object_tileset.autotile_get_size(tile_id)
	var subtile_size = Vector2(region.x/tile_size.x, region.y/tile_size.y)

	# if there is only 1 subtile, no randomization needed
	if subtile_size == Vector2(1,1):
		return Vector2.ZERO
	# calculate the total of all the priorities of the sutiles
	# I suggest that we cache this value in a Dictionary or something
	if !atlas_tile_total.has(tile_id):
		var total_priority = 0
		for x in int(subtile_size.x):
			for y in int(subtile_size.y):
				total_priority += me.object_tileset.autotile_get_subtile_priority(tile_id, Vector2(x,y))
		atlas_tile_total[tile_id] = total_priority
	# get a random value
	var priority = randi() % atlas_tile_total[tile_id]
	# determine the subtile that the random value corrensponds to
	for x in int(subtile_size.x):
		for y in int(subtile_size.y):
			var subtile = Vector2(x,y)
			priority -= me.object_tileset.autotile_get_subtile_priority(tile_id, subtile)
			if priority < 0:
				return subtile

func create_object(object_id):
	var result = preload("res://scenes/object.tscn").instance()
	result.set_tile(object_id)
	return result

func set_object(coord, cell_type):
	var tile_id = me.object_tileset.find_tile_by_name(cell_type)
	$objects.set_cell(coord.x, coord.y, tile_id, current_flip_x,
		false,false,get_random_subtile(tile_id))
	if cell_type == "Marsh":
		$marsh.set_cellv(coord, $marsh.tile_set.find_tile_by_name("Marsh"))
		$marsh.update_bitmask_region()



func _to_dict(map):
	var coords = map.get_used_cells()
	var result = {}
	for coord in coords:
		var name = me.name_by_coord(map, coord)
		if name != "":
			result[coord] = name
	return result
func _export_map(map):
	var result = {}
	for cell in map.get_used_cells():
		result[cell] = me.name_by_coord(map, cell)
	return result
func _string2vector2(cords):
	cords.erase(cords.find("("),1)
	cords.erase(cords.find(")"),1)
	cords.erase(cords.find(","),1)
	var x = cords.left(cords.find(" "))
	var y = cords.right(cords.find(" "))
	return Vector2(x,y)
func _import_map(map, dict, randomized = false):
	for cell in dict.keys():
		map.set_cellv(_string2vector2(cell), map.tile_set.find_tile_by_name(dict[cell]), randomized and randi() % 2 == 0)
	map.update_bitmask_region()

# import and display a map configuration from a string
func import_map(string):
	clear()
	var dict = parse_json(string)
	for key in dict.keys():
		_import_map(get_node(key), dict[key], key == "objects")

# write the current map configuration into `exported_map` which can be copied from the inspector
func export_map():
	exported_map = (to_json({
		"sand":_export_map($sand),
		"land":_export_map($land),
		"marsh":_export_map($marsh)
	}))

# get the environment of coord
func get_env(coord):
	if $sand.get_cellv(coord) == -1:
		return "Ocean"
	elif $land.get_cellv(coord) == -1:
		return "Sand"
	else:
		return "Land"

# set the environment of coord
func set_env(coord, env_name):
	match env_name:
		"Land":
			$sand.set_cellv(coord, $sand.tile_set.find_tile_by_name("Sand"))
			$sand.update_bitmask_region()
			$land.set_cellv(coord, $land.tile_set.find_tile_by_name("Land"))
			$land.update_bitmask_region()
		"Sand":
			$sand.set_cellv(coord, $sand.tile_set.find_tile_by_name("Sand"))
			$sand.update_bitmask_region()
			$land.set_cellv(coord, -1)
			$land.update_bitmask_region()
		"Ocean":
			$sand.set_cellv(coord, -1)
			$sand.update_bitmask_region()
			$land.set_cellv(coord, -1)
			$land.update_bitmask_region()
		_:
			assert(false)

func get_used_cell_names():
	var result = {}
	for obj in $objects.get_children():
		result[obj.position] = obj.object_id



var current_operation_linker

func put_object(object_id, choice):
	current_operation_linker["object_id"] = object_id
	current_operation_linker["choice"] = choice
	_put_object(current_operation_linker)

func _put_object(data):
	var object = create_object(data["object_id"])
	object.modulate = Color(1,1,1,0.5)
	while true:
		yield(get_tree(),"idle_frame")
		var coord = $objects.get_local_mouse_position()
		if in_board(coord):
			emit_signal("hovered", coord, data["object_id"])
			object.position = coord
			if Input.is_action_just_released("mouse_click"):
				object.modulate = Color(1,1,1,1)
				emit_signal("pressed", data["choice"])



#func _pressed():
#	if _finalize_ghosts():
#		selected_cell_type = null
#		$overlay.clear()
#		emit_signal("pressed", selected_choice)
#		current_flip_x = randi()%2 == 0

# clear all tiles
func clear():
	$sand.clear()
	$land.clear()
	$objects.clear()
	$marsh.clear()
	$enclosure.clear()

var map_region = Rect2(0,0,map_size,map_size)
func in_board(coord):
	return map_region.has_point(coord)

func focus(coord):
	$enclosure.clear()
	$enclosure.set_cellv(coord, enclosure_tile)
