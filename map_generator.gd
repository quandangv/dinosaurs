extends Node

enum MapSizeType {map, submap}
onready var map_sizes = [get_parent().map_size, get_parent().submap_size]
onready var map_areas = []

export var natural_spawning_object = ["Tree", "Shrub"]
export var base_natural_presence = 0.15
export var blob_roundness = 0.7
export var map_border_deviation = 0.007
var map_border_shrink = {"Land":0.02, "Sand":-0.02}

func _ready():
	for size in map_sizes:
		map_areas.push_back(size*size)

func get_context(layer, map_coord, tile_name):
	var tile_id = layer.tile_set.find_tile_by_name(tile_name)
	assert(tile_id!= -1)
	var context = [[0,0,0],[0,0,0],[0,0,0]]
	for x in 3:
		for y in 3:
			var coord = map_coord+Vector2(x-1, y-1)
			context[x][y] = layer.get_cellv(coord) == tile_id
	return context

func get_presence_multiplier(layer, map_coord, tile_name):
	var context = get_context(layer, map_coord, tile_name)
	if context == null:
		return 0
	var presence = 0
	if context[1][1]:
		presence += 1
	for cell in me.strict_near_vectors:
		if context[cell.x+1][cell.y+1]:
			presence += 0.77
	for cell in me.corner_vectors:
		if context[cell.x+1][cell.y+1]:
			presence += 0.5
	return presence

func get_all_presence_multiplier(layer, map_coord):
	var result = {}
	for x in 3:
		for y in 3:
			var coord = Vector2(x-1,y-1) + map_coord
			var tile_name = layer.tile_set.tile_get_name(layer.get_cellv(coord))
			if !result.has(tile_name) and tile_name != "":
				result[tile_name] = get_presence_multiplier(layer, map_coord, tile_name)
	for object in natural_spawning_object:
		result[object] = result.get(object, 0) + base_natural_presence
	return result

func in_board(coord, map_size):
	return Rect2(0,0,map_size,map_size).has_point(coord)

func _insert_random(array, item):
	array.insert(randi()%(array.size()+1), item)

# return in the style of [is_border, is_empty]
func _is_border(base_layer, current_layer, coord, map_size):
	var is_empty = current_layer.get_cellv(coord) == -1
	var edge_count = 0
	for cell in me.strict_near_vectors:
		cell += coord
		if in_board(cell, map_size) and (base_layer == null or base_layer.get_cellv(cell) != -1):
			var is_empty2 = current_layer.get_cellv(cell) == -1
			if is_empty != is_empty2:
				edge_count+=1
	return [edge_count, is_empty]

func _find_borders(base_layer, current_layer:TileMap, empty, tile, map_size):
	empty.clear()
	tile.clear()
	for x in map_size:
		for y in map_size:
			var coord = Vector2(x,y)
			if in_board(coord, map_size) and (base_layer == null or base_layer.get_cellv(coord) != -1):
				var is_border = _is_border(base_layer, current_layer, coord, map_size)
				if is_border[0] != 0:
					var array = empty if is_border[1] else tile
					if is_border[0] >=3:
						array.push_back(coord)
					else:
						_insert_random(array, coord)
	return empty.size() + tile.size()
# update border status for strict adjacent cells of coord
func _update_borders(base_layer, current_layer, empty, tile, coord, map_size):
	for cell in me.strict_near_vectors_env:
		cell += coord
		if in_board(cell, map_size) and (base_layer == null or base_layer.get_cellv(cell) != -1):
			var prev_empty = empty.find(cell)
			var prev_tile = tile.find(cell)
			var current = _is_border(base_layer, current_layer, cell, map_size)
			if !current[0]:
				if prev_empty != -1: empty.remove(prev_empty)
				if prev_tile != -1: tile.remove(prev_tile)
			elif current[1]:
				if prev_empty == -1: _insert_random(empty, cell)
				if prev_tile != -1: tile.remove(prev_tile)
			else:
				if prev_tile == -1: _insert_random(tile, cell)
				if prev_empty != -1: empty.remove(prev_empty)
# fill the submap for current_layer with tile_name, all the tiles are on top of base_layer, provided context as value of neighbor map cells
func generate_submap_layer(base_layer:TileMap, current_layer:TileMap, context, tile_name, map_size):
	if context == null:
		return
	var guides = [0, round((map_size)/6.0), round((map_size)*5.0/6.0), map_size]
	var tile_id = current_layer.tile_set.find_tile_by_name(tile_name)
	current_layer.clear()
	for x in 3:
		for y in 3:
			if context[x][y]:
				for x2 in range(guides[x], guides[x+1]):
					for y2 in range(guides[y], guides[y+1]):
						if base_layer == null or base_layer.get_cell(x2, y2) != -1:
							current_layer.set_cell(x2, y2, tile_id)
	var empty_border = []
	var tile_border = []
	var border_size = _find_borders(null, current_layer, empty_border, tile_border, map_size)
	var swap_count = border_size * map_border_deviation * map_size
	var border_shrink = border_size * map_border_shrink.get(tile_name, 0) * map_size
	if border_shrink > 0:
		for i in border_shrink:
			var coord = tile_border.pop_back()
			if coord == null:
				break
			current_layer.set_cellv(coord, -1)
			_update_borders(null, current_layer, empty_border, tile_border, coord, map_size)
	else:
		for i in -border_shrink:
			var coord = empty_border.pop_back()
			if coord == null:
				break
			if base_layer == null or base_layer.get_cellv(coord) != -1:
				current_layer.set_cellv(coord, tile_id)
				_update_borders(null, current_layer, empty_border, tile_border, coord, map_size)
	_find_borders(base_layer, current_layer, empty_border, tile_border, map_size)
	for i in swap_count:
		# swap tiles between empty_border and tile_border
		var empty_coord = empty_border.back()
		var tile_coord = tile_border.back()
		if empty_coord == null or tile_coord == null:
			break
		current_layer.set_cellv(empty_coord, tile_id)
		current_layer.set_cellv(tile_coord, -1)
		_update_borders(base_layer, current_layer, empty_border, tile_border, empty_coord, map_size)
		_update_borders(base_layer, current_layer, empty_border, tile_border, tile_coord, map_size)
	current_layer.update_bitmask_region()

func fill_all_cells(region, base_positions = null):
	var result = []
	for i in range(region.position.x, region.end.x):
		for j in range(region.position.y, region.end.y):
			var coord = Vector2(i,j)
			if base_positions == null or base_positions.has(coord):
				_insert_random(result, coord)
	return result

func generate_positions(rate, base_positions, region:Rect2, neighbors):
	var far_cells = fill_all_cells(region, base_positions)
	var near_cells = []
	var near_cell_preference = region.get_area()*blob_roundness
	var count = round(far_cells.size()*rate)
	var result = []
	while true:
		var selected_cell
		# chance that we will choose a cell that is not adjacent to already chosen cells
		var far_cell_rate = 1*far_cells.size()
		# chance we choose one of the adjacent cells
		var near_cell_rate = near_cell_preference*near_cells.size()
		# the random value to choose between far and near
		var select_rate = randf()*(far_cell_rate+near_cell_rate)
		# take a cell from either near_cells or far_cells depending on the select_rate
		# both arrays are radomized by creation so that we just need to select the back
		selected_cell = (far_cells if select_rate<far_cell_rate else near_cells).pop_back()
		# if the desired cell count is reached or no cell is left then stop
		if selected_cell == null or count <= 0:
			break
		# double check that the selected cell is of the desired environment
		if (base_positions == null or base_positions.has(selected_cell)) and result.find(selected_cell) == -1:
			result.push_back(selected_cell)
			count -= 1
			# add all adjacent cells of the selected cell to near_cells
			# this will create duplicates in this array that will favor the selection of cells with more adjacents
			# this will effectively make more blob-shaped generation
			for cell in neighbors:
				cell += selected_cell
				# remove the cell from far_cells since it is already adjacent to a chosen cell
				var far_index = far_cells.find(cell)
				if far_index != -1:
					far_cells.remove(far_index)
				if region.has_point(cell) and (base_positions == null or base_positions.has(cell))  and result.find(cell) == -1:
					_insert_random(near_cells, cell)
		# remove all the duplicates of the selected cells from near_cells
		# far_cells doesn't contain duplicates and its element does not appear in near_cells so we don't have to worry about them
		while true:
			var index = near_cells.find(selected_cell)
			if index != -1:
				near_cells.remove(index)
			else: break
	return result

var axonometric_neighbors = [Vector2(0,1), Vector2(0,-1), Vector2(1,-1), Vector2(1,0), Vector2(-1,-1), Vector2(-1,0)]
var sqrt3div2 = 0.86602540378443864676372317075294

func world_to_axonometric(position, axo_unit_size):
	position /= axo_unit_size;
	position.x /= sqrt3div2
	position.y -= abs(fposmod(position.x+1,2)-1)/2
	return position

func axonometric_to_world(position, axo_unit_size):
	position.y += abs(fposmod(position.x+1,2)-1)/2
	position.x *= sqrt3div2
	position *= axo_unit_size;
	return position

func generate_blobs(rate, base_blobs, region, neighbors, size_min, size_max, max_mul = 1):
	var positions = generate_positions(rate, null if base_blobs == null else base_blobs.keys(), region, neighbors);
	var result = {}
	for blob in positions:
		result[blob] = lerp(size_min, (size_max if base_blobs == null else base_blobs[blob])*max_mul, randf())
	return result
