extends Node2D

signal pressed
signal hovered

var selected_cell_type

export var margin_size = Vector2(40,40)
export var map_size:float = 640
export var map_division = 15
export var island_land_ratio = 0.8
export var waves_preference = 3
export var tsunami_preference = 1

var atlas_tile_total = {}
var current_flip_x = true
var tile_categories = {
	"marine":[ "Shark", "Coral", "Tsunami", "Waves", "Sunken Ship" ],
	"temperate":["Tree"],
	"dryness_neutral":["Hungry Dino"],
	"animal":["Hungry Dino"]
}

func _ready():
	$background.rect_size = map_size*$objects.scale + margin_size

func _put_blobs(blob, unit_size, color, _pos, _size):
	blob.modulate = color
	blob.rect_position = $map_generator.axonometric_to_world(_pos, unit_size)
	blob.rect_min_size = Vector2(1,1)*_size*unit_size

func put_blobs(blobs, color, unit_size):
	for position in blobs.keys():
		var blob = preload("res://scenes/terrain_blob.tscn").instance()
		$terrain.add_child(blob)
		_put_blobs(blob, unit_size, color, position, blobs[position])
	return blobs

export var land_ratio = 0.4
export var sand_color:Color
export var land_color:Color
export var blob_min = 1.1547005383792515290182975610039
export var blob_max = 3.0
func generate_islands():
	$objects.clear()
	var blobs = null
	var unit_size = map_size / map_division
	var region_min = Vector2(-1,-1) * unit_size
	var region_max = Vector2(map_size, map_size) + Vector2(1,1) * unit_size - region_min
	region_min = ($map_generator.world_to_axonometric(region_min, unit_size)).round()
	region_max = ($map_generator.world_to_axonometric(region_max, unit_size)).round()
	blobs = put_blobs($map_generator.generate_blobs(land_ratio, blobs, Rect2(region_min, region_max-region_min), $map_generator.axonometric_neighbors, blob_min, blob_max), sand_color, unit_size)
	blobs = put_blobs($map_generator.generate_blobs(island_land_ratio, blobs, Rect2(region_min, region_max-region_min), $map_generator.axonometric_neighbors, blob_min, blob_max, 0.7), land_color, unit_size)



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
	if object_id != null:
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

# clear all tiles
func clear():
	$objects.clear()

var map_region = Rect2(0,0,map_size,map_size)
func in_board(coord):
	return map_region.has_point(coord)
