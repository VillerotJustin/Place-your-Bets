extends Node2D

@export_category("Reference")
@export var tile_scene:PackedScene

@export_category("LabGen")
@export var width:int = 10
@export var height:int = 10
@export_enum("Iterative randomized Prim's algorithm") var gen_algorythm:String = "Iterative randomized Prim's algorithm"

#TODO decide on method

# Data based lab for pathfinding algo
var tile_labyrinth: Array # Array of Array[int] - 2D grid
var graph_labyrinth: Array[Lab_Node]

# Where tile are keept
var render_lab_left: Array[Tile]
var render_lab_right: Array[Tile]

var start_tile_id:int
var end_tile_id:int

func generate_lab() -> void:
	match gen_algorythm:
		"Iterative randomized Prim's algorithm":
			iterative_rdm_prims_algo()
		_:
			push_error("Unknown gen method")

func iterative_rdm_prims_algo() -> void:
	# Initialize 2D array for the labyrinth
	tile_labyrinth = []
	for i in range(height):
		var row: Array[int] = []
		for j in range(width):
			row.append(10) # Default difficulty wall
		tile_labyrinth.append(row)

func get_tile_world_pos(_tile_id: int, _left_lab: bool = true) -> Vector2:
	# TODO: Implement tile world position calculation
	return Vector2.ZERO
