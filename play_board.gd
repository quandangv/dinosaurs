extends Node2D

signal pressed

var selected_cell_type
var selected_choice

export var margin_size = Vector2(40,40)
export var map_size:float = 10
export var submap_size = 40
export var island_land_ratio = 0.8
export var waves_preference = 3
export var tsunami_preference = 1
export(Array, String) var cell_types = [
	"Hungry Dino", "Shark", "Coral", "Field", "Lonely Dino", "Mountain",
	"Shrub", "Social Dino", "Tree", "Waves", "Chicken", "Wolf", "Tsunami",
	"Marsh", "Sunken Ship", "Forgotten Temple"
]

var near_vectors = [Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1), Vector2(-1,0), Vector2(1,0), Vector2(-1,1), Vector2(0,1), Vector2(1,1)]
var near_vectors_env = [Vector2.ZERO, Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1), Vector2(-1,0), Vector2(1,0), Vector2(-1,1), Vector2(0,1), Vector2(1,1)]
var strict_near_vectors = [ Vector2(0,-1), Vector2(-1,0), Vector2(1,0), Vector2(0,1)]
var strict_near_vectors_env = [ Vector2(0,-1), Vector2(-1,0), Vector2(1,0), Vector2(0,1), Vector2.ZERO]
var corner_vectors = [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1), ]

onready var object_tileset = $objects.tile_set
var atlas_tile_total = {}
var placement = []

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
	$background.rect_size = map_size*$objects.cell_size*$objects.scale + margin_size
	$background.connect("pressed", self, "_pressed")
	selected_choice = null
	export_map()
	enclosure_tile = $enclosure.tile_set.find_tile_by_name("enclosure")
	assert(enclosure_tile != -1)
	
	for obj in cell_types:
		if !object_prefs.has(obj):
			object_prefs[obj] = [base_rate,[]]
	for cat in tile_categories.keys():
		if pref_presets.has(cat):
			for obj in tile_categories[cat]:
				object_prefs[obj][1].push_back(cat)
		if rate_presets.has(cat):
			var rate_multiplier = rate_presets[cat]
			for obj in tile_categories[cat]:
				object_prefs[obj][0]*=rate_multiplier
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

func _add_layer_props(layer, coord, dict, alpha):
	var cell_name = me.get_tile_name(layer, coord)
	var cell_props = tile_props.get(cell_name, null)
	if cell_props != null:
		for prop in cell_props.keys():
			dict[prop] = cell_props[prop] if !dict.has(prop) else (cell_props[prop]*(alpha) + dict[prop]*(1-alpha))
func get_props(coord):
	var dict = base_prop.duplicate()
	for pair in terrain_layers:
		_add_layer_props(pair[0], coord, dict, 1)
	_add_layer_props(blob_layer[0], coord, dict, 0.5)
	return dict

func calculate_rate(prefs, coord, mutiplier):
	var env_props = get_props(coord)
	var result = mutiplier
	for prop in prefs.keys():
		var pref = prefs[prop]
		if env_props.has(prop):
			# the first value is the ideal
			var delta = pref[0] - env_props[prop]
			# next values are the max and min
			result *= 1 - abs(delta)*pref[1]
		if result < 0:
			result = 0
	return result

func gather_prefs(tile_name):
	var result = {}
	assert(object_prefs.has(tile_name))
	var base_rate = object_prefs[tile_name][0]
	var presets = object_prefs[tile_name][1]
	for preset in presets:
		for pref in pref_presets[preset]:
			result[pref[0]] = pref[1]
	return [base_rate, result]

func generate_submap(map_coord):
	var map_size = submap_size
	var base_layer = null
	for pair in terrain_layers:
		$map_generator.generate_submap_layer(base_layer, pair[0], $map_generator.get_context(pair[0], map_coord, pair[1]), pair[1], map_size)
		base_layer = pair[0]
	
	base_layer = terrain_layers[0][0]
	var current_layer = blob_layer[0]
	var current_tile = current_layer.tile_set.find_tile_by_name(blob_layer[1])
	var presence = $map_generator.get_presence_multiplier(current_layer, map_coord, blob_layer[1])
	current_layer.clear()
	for cell in $map_generator.generate_blobs(blob_rates[blob_layer[1]]*presence, base_layer, map_size):
		current_layer.set_cellv(cell, current_tile)
	current_layer.update_bitmask_region()
	current_layer = get_node(object_layer)
	presence = $map_generator.get_all_presence_multiplier(current_layer, map_coord)
	current_layer.clear()
	for tile_name in presence.keys():
		current_tile = current_layer.tile_set.find_tile_by_name(tile_name)
		var prefs = gather_prefs(tile_name)
		for x in map_size:
			for y in map_size:
				var coord = Vector2(x,y)
				object_prefs.has(tile_name)
				if randf() < calculate_rate(prefs[1], coord, prefs[0] * presence[tile_name]):
					current_layer.set_cellv(coord, current_tile, randi() % 2 == 0)

func generate_islands(land_ratio, wave_ratio):
	$sand.clear()
	$land.clear()
	$marsh.clear()
	$objects.clear()
	for cell in $map_generator.generate_blobs(land_ratio, null, map_size):
		set_env(cell, "Sand")
	print(land_ratio*island_land_ratio)
	for cell in $map_generator.generate_blobs(island_land_ratio, $sand, map_size):
		set_env(cell, "Land")
	
	for i in map_size:
		for j in map_size:
			var cell = Vector2(i,j)
			if get_env(cell) == "Ocean" and randf() < wave_ratio:
				set_object(cell, "Waves"if randf()*(waves_preference) < waves_preference else "Tsunami")

func clear_placement():
	placement.clear()

func get_random_subtile(tile_id):
	# Calculate the size of the autotile in number of tiles instead of in pixels
	# So that we can iterate the subtiles of the autotile
	var region = object_tileset.tile_get_region(tile_id).size
	var tile_size = object_tileset.autotile_get_size(tile_id)
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
				total_priority += object_tileset.autotile_get_subtile_priority(tile_id, Vector2(x,y))
		atlas_tile_total[tile_id] = total_priority
	# get a random value
	var priority = randi() % atlas_tile_total[tile_id]
	# determine the subtile that the random value corrensponds to
	for x in int(subtile_size.x):
		for y in int(subtile_size.y):
			var subtile = Vector2(x,y)
			priority -= object_tileset.autotile_get_subtile_priority(tile_id, subtile)
			if priority < 0:
				return subtile

func set_object(coord, cell_type, current_flip_x = false):
	var tile_id = object_tileset.find_tile_by_name(cell_type)
	$objects.set_cell(coord.x, coord.y, tile_id, current_flip_x,
		false,false,get_random_subtile(tile_id))
	if cell_type == "Marsh":
		$marsh.set_cellv(coord, $marsh.tile_set.find_tile_by_name("Marsh"))
		$marsh.update_bitmask_region()



func _to_dict(map):
	var coords = map.get_used_cells()
	var result = {}
	for coord in coords:
		var name = me.get_tile_name(map, coord)
		if name != "":
			result[coord] = name
	return result
func _export_map(map):
	var result = {}
	for cell in map.get_used_cells():
		result[cell] = me.get_tile_name(map, cell)
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
		"objects":_export_map($objects),
		"marsh":_export_map($marsh)
	}))

# clear all temporary tiles 
func clear_ghosts():
	$objects_ghost.clear()
	$overlay.clear()
	$enclosure.clear()

# visualize the effects of the object at a coordinate on other cell
# as well as the cells that have effects on the coordinate
func display_cell_detail(coord, object_name):
	var marked_cells = {}
	var tile_id = object_tileset.find_tile_by_name(object_name)
	for cell in $objects.get_used_cells():
		var cell_name = me.get_tile_name($objects, cell)
		var old_tile_id = $objects.get_cellv(coord)
		var is_flipped = $objects.is_cell_x_flipped(coord.x, coord.y)
		var other_effects = check_points(cell, cell_name, true)
		$objects.set_cellv(coord, tile_id)
		var other_effect_after = check_points(cell, cell_name, true)
		$objects.set_cellv(coord, old_tile_id, is_flipped)
		var difference = other_effect_after.get(coord, 0) - other_effects.get(coord, 0)
		if difference != 0:
			marked_cells[cell] = "up" if difference > 0 else "down"
	var effects = check_points(coord, object_name, true)
	for coord2 in effects.keys():
		var points = effects[coord2]
		if points != 0:
			marked_cells[coord2] = marked_cells.get(coord2, "") + ("positive" if points > 0 else "negative")
	for cell in marked_cells.keys():
		$overlay.set_cellv(cell, $overlay.tile_set.find_tile_by_name(marked_cells[cell]))
	return check_points(coord, object_name, false)

# get the list of occupied cells
func get_used_cell_names():
	var result = {}
	for coord in placement:
		result[coord] = me.get_tile_name($objects, coord)
	return result

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

# turn all ghosts into real object
func _finalize_ghosts():
	for coord in $objects_ghost.get_used_cells():
		set_object(coord, selected_cell_type, current_flip_x)
		placement.push_back(coord)
	if $objects_ghost.get_used_cells().size() != 0:
		clear_ghosts()
		return true

func _put_ghost(coord, object_name):
	if object_name != null:
		$overlay.clear()
		display_cell_detail(coord, object_name)
		$objects_ghost.set_cellv(coord, me.get_preview_tile(object_name), current_flip_x)

func _pressed():
	if _finalize_ghosts():
		selected_cell_type = null
		$overlay.clear()
		emit_signal("pressed", selected_choice)
		current_flip_x = randi()%2 == 0

# clear all tiles
func clear():
	$sand.clear()
	$land.clear()
	$objects.clear()
	$marsh.clear()
	$enclosure.clear()

func in_board(coord):
	return Rect2(0,0,map_size,map_size).has_point(coord)

func _process(delta):
	if !game_over:
		clear_ghosts()
		var coord = $objects.world_to_map($objects.get_local_mouse_position())
		if in_board(coord):
			if $objects.get_cell(coord.x, coord.y) == -1:
				_put_ghost(coord, selected_cell_type)

func focus(coord):
	$enclosure.clear()
	$enclosure.set_cellv(coord, enclosure_tile)

func get_tilemap_cell(tilemap, coord):
	var cell = $objects.get_cellv(coord)
	if cell != -1:
		return object_tileset.tile_get_name(cell)

func _add_point(dict, key, point):
	dict[key] = dict.get(key,0)+point
# check for all cells that effect the point of the current cell
func check_points(coord, object_name, is_preview):
	var result = {}
	var game_master = get_node("/root/game_master")
	var near_map = {}
	for cell in near_vectors:
		cell += coord
		near_map[cell] = get_tilemap_cell($objects, cell)
	var conditions = game_master.get_conditions(object_name)
	for cond in conditions:
		var map = {}
		match cond:
			"land", "sand":
				map[coord] = get_env(coord)
			"no_sand":
				for cell in near_vectors_env:
					cell += coord
					map[cell] = get_env(cell)
			_:
				map = near_map
		for cell in map.keys():
			match cond:
				"land":
					if map[cell] == 'Land':
						_add_point(result, cell, 1)
				"sand", "no_sand":
					if map[cell] == 'Sand':
						_add_point(result, cell, 1 if cond == "sand" else -1)
				"waves", "no_waves":
					if cell_category["waves"].find(map[cell]) != -1:
						_add_point(result, cell, 1 if cond == "waves" else -1)
				"meat":
					if cell_category["animal"].find(map[cell]) != -1:
						_add_point(result, cell, 1)
				"plant":
					if cell_category["plant"].find(map[cell]) != -1:
						_add_point(result, cell, 1)
				"crowded", "uncrowded":
					if cell_category["crowding"].find(map[cell]) != -1:
						_add_point(result, cell, 1 if cond == "crowded" else -1)
		if !is_preview:
			match cond:
				"no_waves", "uncrowded", "no_sand":
					_add_point(result, coord, 2)
	if conditions.find("invincible") == -1:
		for cell in near_map.keys():
			if near_map[cell] != null:
				var conditions2 = game_master.get_conditions(near_map[cell])
				for cond in conditions2:
					var point_added = 0
					match cond:
						"heart":
							point_added = 1
						"skull":
							point_added = -1
						"green_heart":
							if cell_category["plant"].find(object_name) != -1:
								point_added = 1
						"bloody_heart":
							if cell_category["beast"].find(object_name) != -1:
								point_added = 1
						"guardian":
							point_added = -1 if conditions.find("skull") != -1 else 1
					_add_point(result, cell, point_added)
	if conditions.find("skull") != -1:
		result[coord] = result.get(coord, 0)*2
	var is_ocean = tile_categories["marine"].find(object_name) != -1
	if is_ocean != (get_env(coord) == "Ocean"):
		_add_point(result, coord, -10)
	return result
