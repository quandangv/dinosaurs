extends Node

func _insert_random(array, item):
	array.insert(randi()%(array.size()+1), item)
func fill_all_cells(region, base_positions = null):
	var result = []
	for i in range(region.position.x, region.end.x):
		for j in range(region.position.y, region.end.y):
			var coord = Vector2(i,j)
			if base_positions == null or base_positions.has(coord):
				_insert_random(result, coord)
	return result

export var blob_roundness = 0.7
func generate_positions(rate, base_positions, region:Rect2, neighbors):
	var far_cells = fill_all_cells(region, base_positions)
	var near_cells = []
	var near_cell_preference = region.get_area()*blob_roundness
	var count = round(far_cells.size()*rate)
	var result = []
	while true:
		var selected_cell
		var far_cell_rate = 1*far_cells.size()
		var near_cell_rate = near_cell_preference*near_cells.size()
		var select_rate = randf()*(far_cell_rate+near_cell_rate)
		selected_cell = (far_cells if select_rate<far_cell_rate else near_cells).pop_back()
		if selected_cell == null or count <= 0:
			break
		if (base_positions == null or base_positions.has(selected_cell)) and result.find(selected_cell) == -1:
			result.push_back(selected_cell)
			count -= 1
			for cell in neighbors:
				cell += selected_cell
				var far_index = far_cells.find(cell)
				if far_index != -1:
					far_cells.remove(far_index)
				if region.has_point(cell) and (base_positions == null or base_positions.has(cell))  and result.find(cell) == -1:
					_insert_random(near_cells, cell)
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
