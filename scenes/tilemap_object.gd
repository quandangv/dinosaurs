extends Sprite

export var default_offset = Vector2(0, -32)

var object_id

func set_tile(tileset:TileSet, id):
	object_id = id
	texture = tileset.tile_get_texture(id)
	region_enabled = true
	region_rect = tileset.tile_get_region(id)

	# align to bottom
	offset = tileset.tile_get_texture_offset(id) - Vector2(0,region_rect.size.y/2) + default_offset
