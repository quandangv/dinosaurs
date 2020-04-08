extends Node

var near_vectors = [Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1), Vector2(-1,0), Vector2(1,0), Vector2(-1,1), Vector2(0,1), Vector2(1,1)]
var near_vectors_env = [Vector2.ZERO, Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1), Vector2(-1,0), Vector2(1,0), Vector2(-1,1), Vector2(0,1), Vector2(1,1)]
var strict_near_vectors = [ Vector2(0,-1), Vector2(-1,0), Vector2(1,0), Vector2(0,1)]
var strict_near_vectors_env = [ Vector2(0,-1), Vector2(-1,0), Vector2(1,0), Vector2(0,1), Vector2.ZERO]
var corner_vectors = [ Vector2(1,-1), Vector2(-1,1), Vector2(1,1), Vector2(-1,-1), Vector2.ZERO]

var object_tileset = preload("res://tiles/object tileset.tres")
func set_texture(texture:AtlasTexture, cell_name:String):
	var tileset_id = get_preview_tile(cell_name)
	texture.atlas = object_tileset.tile_get_texture(tileset_id)
	texture.region = object_tileset.tile_get_region(tileset_id)


func get_preview_tile(cell_name):
	var tile_id = object_tileset.find_tile_by_name(cell_name+" preview")
	if tile_id == -1:
		tile_id = object_tileset.find_tile_by_name(cell_name)
	return tile_id

func get_tile_name(tilemap:TileMap, coord:Vector2):
	return tilemap.tile_set.tile_get_name(tilemap.get_cellv(coord))
