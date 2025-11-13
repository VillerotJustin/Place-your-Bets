extends Sprite2D

class_name Tile

# Sprite List
@export var sprite_list:Array[String] = [
	"res://world/tile/Tile_0.png",
	"res://world/tile/Tile_2.png",
	"res://world/tile/Tile_5.png",
	"res://world/tile/Tile_Wall.png",
	]
@export var tile_difficulty:int = 0
 
func initialise(difficulty: int) -> void:
	tile_difficulty = difficulty
	load_sprite()

func load_sprite() -> void:
	match tile_difficulty:
		0:
			texture = load(sprite_list[0])
		2:
			texture = load(sprite_list[1])
		5:
			texture = load(sprite_list[2])
		10:
			texture = load(sprite_list[3])
		_:
			push_error("Invalid tile difficulty")

func get_tile_difficulty() -> int:
	return tile_difficulty
