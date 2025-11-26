extends Node2D

class_name Labyrinth_Generator

@export_category("Reference")
@export var tile_scene:PackedScene
@export var explorer_1: AStar
@export var explorer_2: Dijkstra

@export_category("LabGen")
@export var width:int = 10
@export var height:int = 10
@export_enum("Iterative randomized Prim's algorithm") var gen_algorythm:String = "Iterative randomized Prim's algorithm"

@export_category("Difficulty Paths")
@export var add_difficulty_paths:bool = true
@export_enum("Random Scattered", "Clustered Areas") var difficulty_pattern:String = "Random Scattered"
@export_range(0.1, 0.5, 0.05) var difficulty_path_percentage:float = 0.2  # % of passages to make harder
@export var min_difficulty:int = 2
@export var max_difficulty:int = 5

@onready var number_of_cells: int = width * height
#TODO decide on method

# Data based lab for pathfinding algo
var tile_labyrinth: Array # Array of Array[int] - 2D grid
var graph_labyrinth: Array[Lab_Node]  # Detailed graph (one node per tile)
var corridor_graph: Array[Lab_Node]   # Simplified graph (one node per corridor/junction)

# Where tile are keept
var render_lab_left: Array[Tile]
var render_lab_right: Array[Tile]

var start_tile_id:int
var end_tile_id:int

# ====================================================================
# MAIN
# ====================================================================
func _ready() -> void:
	generate_lab()

func regen_labs() -> void:
	print("Regenerating labyrinths...")
	UX_Manager.reset()
	
	# Reset tile IDs to force new start/end positions
	start_tile_id = -1
	end_tile_id = -1
	
	# Stop any current explorer movement
	if explorer_1:
		explorer_1.is_moving = false
		explorer_1.has_path = false
		explorer_1.is_finished = false
	if explorer_2:
		explorer_2.is_moving = false
		explorer_2.has_path = false
		explorer_2.is_finished = false
	
	# Generate new labyrinth layout
	generate_lab()

func generate_lab() -> void:
	match gen_algorythm:
		"Iterative randomized Prim's algorithm":
			iterative_rdm_prims_algo()
		_:
			push_error("Unknown gen method")
	
	# Add higher difficulty paths if enabled
	if add_difficulty_paths:
		match difficulty_pattern:
			"Random Scattered":
				add_random_difficulty_paths()
			"Clustered Areas":
				create_difficulty_clusters()
			_:
				add_random_difficulty_paths()  # Default fallback
	
	# Build graph from the labyrinth
	build_graph()
	
	# Place tiles after generating the labyrinth
	place_tiles()

	place_explorers()

	build_graph()

# ====================================================================
# UTILS
# ====================================================================
func id_to_xy(id:int) -> Vector2i:
	var x:int = id % width
	var y:int = int(id / width)

	return Vector2i(x, y)

func xy_to_id(x:int, y:int) -> int:
	return y * width + x

# ====================================================================
# MAZE GENERATION (RANDOMIZED PRIM)
# ====================================================================
func iterative_rdm_prims_algo() -> void:
	# Reset tile IDs for new generation
	start_tile_id = -1
	end_tile_id = -1
	
	# Initialize whole labyrinth as walls
	tile_labyrinth = []
	for y in range(height):
		var row: Array[int] = []
		for x in range(width):
			row.append(10)   # Wall
		tile_labyrinth.append(row)

	# Pick random start cell (ensure it's not on the 1-tile border)
	var start_x = randi_range(1, width - 1)
	var start_y = randi_range(1, height - 1)
	tile_labyrinth[start_y][start_x] = 0   # passage

	# Keep track of frontier cells (walls that could become passages)
	var frontier: Array[Vector2i] = []
	add_frontiers(Vector2i(start_x, start_y), frontier)

	# Main loop: process frontier cells
	while frontier.size() > 0:
		# Pick a random frontier cell
		var fi = randi_range(0, frontier.size() - 1)
		var wall_pos = frontier[fi]
		frontier.remove_at(fi)

		# Skip if wall is on the 1-tile border (outer edge only)
		if (wall_pos.x == 0 or wall_pos.x == width - 1 or 
			wall_pos.y == 0 or wall_pos.y == height - 1):
			continue
		
		# Check if this wall can connect two separate areas
		var passage_neighbors: Array[Vector2i] = []
		var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		
		for d in dirs:
			var nx = wall_pos.x + d.x
			var ny = wall_pos.y + d.y
			
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				if tile_labyrinth[ny][nx] == 0:  # Found a passage
					passage_neighbors.append(Vector2i(nx, ny))

		# Only carve if exactly one passage neighbor (prevents loops)
		if passage_neighbors.size() == 1:
			# Carve the wall
			tile_labyrinth[wall_pos.y][wall_pos.x] = 0
			
			# Find the opposite side and carve it too
			var passage_pos = passage_neighbors[0]
			var direction = wall_pos - passage_pos
			var new_cell = wall_pos + direction
			
			# Don't carve if new cell would be on the 1-tile border
			if (new_cell.x > 0 and new_cell.x < width - 1 and 
				new_cell.y > 0 and new_cell.y < height - 1):
				if tile_labyrinth[new_cell.y][new_cell.x] == 10:  # Still a wall
					tile_labyrinth[new_cell.y][new_cell.x] = 0
					add_frontiers(new_cell, frontier)

func add_frontiers(pos: Vector2i, frontier: Array[Vector2i]) -> void:
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for d in dirs:
		var wall_x = pos.x + d.x
		var wall_y = pos.y + d.y
		var next_x = pos.x + d.x * 2
		var next_y = pos.y + d.y * 2
		
		# Check bounds and ensure we're not adding border walls as frontiers
		if (next_x > 0 and next_x < width - 1 and next_y > 0 and next_y < height - 1 and
			wall_x > 0 and wall_x < width - 1 and wall_y > 0 and wall_y < height - 1):
			
			if (tile_labyrinth[next_y][next_x] == 10 and 
				tile_labyrinth[wall_y][wall_x] == 10):
				var wall_pos = Vector2i(wall_x, wall_y)
				if not frontier.has(wall_pos):
					frontier.append(wall_pos)

# ====================================================================
# DIFFICULTY PATH GENERATION
# ====================================================================

func add_random_difficulty_paths() -> void:
	print("Adding random difficulty paths...")
	
	# Collect all passage tiles (difficulty 0)
	var passage_tiles: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			if tile_labyrinth[y][x] == 0:  # Passage tile
				passage_tiles.append(Vector2i(x, y))
	
	if passage_tiles.size() == 0:
		print("No passage tiles found, skipping difficulty paths")
		return
	
	# Calculate how many tiles to make more difficult
	var num_difficulty_tiles = int(passage_tiles.size() * difficulty_path_percentage)
	num_difficulty_tiles = max(1, num_difficulty_tiles)  # At least 1 tile
	
	print("Making ", num_difficulty_tiles, " out of ", passage_tiles.size(), " passage tiles more difficult")
	
	# Randomly select tiles and assign higher difficulty
	var selected_tiles: Array[Vector2i] = []
	for i in range(num_difficulty_tiles):
		if passage_tiles.size() == 0:
			break
			
		var random_index = randi_range(0, passage_tiles.size() - 1)
		var selected_tile = passage_tiles[random_index]
		passage_tiles.remove_at(random_index)
		
		# Assign random difficulty between min and max
		var difficulty = randi_range(min_difficulty, max_difficulty)

		# Make difficulty either 2 or 5 for more contrast
		if difficulty < (min_difficulty + max_difficulty) / 2:
			difficulty = min_difficulty
		else:
			difficulty = max_difficulty
		
		tile_labyrinth[selected_tile.y][selected_tile.x] = difficulty
		selected_tiles.append(selected_tile)
	
	print("Added ", selected_tiles.size(), " difficulty paths with difficulties ranging from ", min_difficulty, " to ", max_difficulty)

func create_difficulty_clusters() -> void:
	# Alternative method: Create clustered areas of higher difficulty
	print("Creating difficulty clusters...")
	
	var num_clusters = max(1, int(width * height * difficulty_path_percentage / 20))  # Fewer, larger clusters
	
	for cluster in range(num_clusters):
		# Pick a random starting point for the cluster
		var center_x = randi_range(1, width - 2)
		var center_y = randi_range(1, height - 2)
		
		# Only create cluster if center is a passage
		if tile_labyrinth[center_y][center_x] != 0:
			continue
			
		var cluster_size = randi_range(2, 5)  # Cluster radius
		var difficulty = randi_range(min_difficulty, max_difficulty)

		# Make difficulty either 2 or 5 for more contrast
		if difficulty < (min_difficulty + max_difficulty) / 2:
			difficulty = min_difficulty
		else:
			difficulty = max_difficulty
		
		# Apply difficulty to nearby tiles
		for dy in range(-cluster_size, cluster_size + 1):
			for dx in range(-cluster_size, cluster_size + 1):
				var tx = center_x + dx
				var ty = center_y + dy
				
				# Check bounds and if it's a passage
				if (tx >= 0 and tx < width and ty >= 0 and ty < height and
					tile_labyrinth[ty][tx] == 0):
					
					# Use distance to determine if tile should be affected
					var distance = sqrt(dx * dx + dy * dy)
					if distance <= cluster_size and randf() < 0.7:  # 70% chance within radius
						tile_labyrinth[ty][tx] = difficulty

# ====================================================================

# ====================================================================
# TILE PLACEMENT
# ====================================================================

func place_tiles() -> void:
	print("Placing tiles for labyrinth of size: ", width, "x", height)
	
	if not tile_scene:
		push_error("tile_scene is not assigned!")
		return
	
	# Clear existing tiles
	for tile in render_lab_left:
		if tile:
			tile.queue_free()
	for tile in render_lab_right:
		if tile:
			tile.queue_free()
	
	render_lab_left.clear()
	render_lab_right.clear()
	
	# Create tiles for each cell in the labyrinth
	for y in range(height):
		for x in range(width):
			var tile_id = xy_to_id(x, y)
			var difficulty = tile_labyrinth[y][x]
			
			# Create tile for left labyrinth
			var tile_left = tile_scene.instantiate() as Tile
			if not tile_left:
				push_error("Failed to instantiate tile from scene")
				continue
			tile_left.initialise(difficulty)
			tile_left.position = get_tile_world_pos(tile_id, true)
			add_child(tile_left)
			render_lab_left.append(tile_left)
			
			# Create tile for right labyrinth
			var tile_right = tile_scene.instantiate() as Tile
			if not tile_right:
				push_error("Failed to instantiate tile from scene")
				continue
			tile_right.initialise(difficulty)
			tile_right.position = get_tile_world_pos(tile_id, false)
			add_child(tile_right)
			render_lab_right.append(tile_right)
	
	print("Placed ", render_lab_left.size(), " tiles for left lab and ", render_lab_right.size(), " tiles for right lab")

# ====================================================================
# TILE PLACEMENT Utils
# ====================================================================

func get_tile_world_pos(tile_id:int, left_lab:bool=true) -> Vector2:
	var xy = id_to_xy(tile_id)
	var tile_size = 16  # Assuming 64x64 pixel tiles, adjust as needed
	
	# Calculate base position
	var base_x = xy.x * tile_size
	var base_y = xy.y * tile_size
	
	# Offset for left/right labyrinth
	var offset_x = 0
	if not left_lab:
		# Right labyrinth offset (place it to the right of left labyrinth)
		offset_x = (width + 2) * tile_size  # Add some spacing between labs
	
	return Vector2(base_x + offset_x, base_y)

# ====================================================================
# Path Utils
# ====================================================================
func get_start_tile_id() -> int:
	if start_tile_id == -1:
		# Find a passage tile in the upper-left area (but not too close to border)
		for y in range(1, int(height / 2)):
			for x in range(1, int(width / 2)):
				if tile_labyrinth[y][x] == 0:
					start_tile_id = xy_to_id(x, y)
					return start_tile_id
		# Fallback: find any passage tile not on the border
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				if tile_labyrinth[y][x] == 0:
					start_tile_id = xy_to_id(x, y)
					return start_tile_id
	return start_tile_id

func get_end_tile_id() -> int:
	if end_tile_id == -1:
		# Find a passage tile in the lower-right area (but not too close to border)
		for y in range(height - 1, int(height / 2), -1):
			for x in range(width - 1, int(width / 2), -1):
				if y < height - 2 and x < width - 2 and tile_labyrinth[y][x] == 0:
					end_tile_id = xy_to_id(x, y)
					return end_tile_id
		# Fallback: find any passage tile not on the border (different from start)
		for y in range(height - 2, 0, -1):
			for x in range(width - 2, 0, -1):
				if tile_labyrinth[y][x] == 0:
					var candidate_id = xy_to_id(x, y)
					if candidate_id != start_tile_id:
						end_tile_id = candidate_id
						return end_tile_id
	return end_tile_id

func place_explorers() -> void:
	if not explorer_1 or not explorer_2:
		print("Explorers not assigned, skipping explorer placement")
		return
	
	var start_id = get_start_tile_id()
	var end_id = get_end_tile_id()
	
	if start_id == -1 or end_id == -1:
		push_error("Start or End tile ID is null, cannot place explorers")
		return
	
	print("Placing explorers - Start ID: ", start_id, ", End ID: ", end_id)
	
	var start_pos_left:Vector2 = get_tile_world_pos(start_id, true)
	var end_pos_left:Vector2 = get_tile_world_pos(end_id, true)
	
	var start_pos_right:Vector2 = get_tile_world_pos(start_id, false)
	var end_pos_right:Vector2 = get_tile_world_pos(end_id, false)
	
	print("Explorer positions - Left start: ", start_pos_left, ", Right start: ", start_pos_right)
	
	explorer_1.set_start_and_end(start_pos_left, end_pos_left)
	explorer_2.set_start_and_end(start_pos_right, end_pos_right)

func build_graph() -> void:
	print("Building graphs from labyrinth...")
	
	# Clear existing graphs
	graph_labyrinth.clear()
	corridor_graph.clear()
	
	# Build detailed graph (one node per tile)
	build_detailed_graph()
	
	# Debug: Check connectivity of start and end nodes
	var start_id = get_start_tile_id()
	var end_id = get_end_tile_id()
	if start_id >= 0 and start_id < graph_labyrinth.size():
		print("Start node ", start_id, " has ", graph_labyrinth[start_id].neighbours.size(), " neighbors")
	if end_id >= 0 and end_id < graph_labyrinth.size():
		print("End node ", end_id, " has ", graph_labyrinth[end_id].neighbours.size(), " neighbors")
	
	# Count connected nodes
	var connected_count = 0
	for node in graph_labyrinth:
		if node.neighbours.size() > 0:
			connected_count += 1
	print("Connected nodes in detailed graph: ", connected_count, "/", graph_labyrinth.size())
	
	# Build simplified corridor graph
	build_corridor_graph()
	
	print("Graphs built - Detailed nodes: ", graph_labyrinth.size(), ", Corridor nodes: ", corridor_graph.size())

func build_detailed_graph() -> void:
	# Initialize nodes for all cells
	graph_labyrinth.resize(number_of_cells)
	
	for i in range(number_of_cells):
		graph_labyrinth[i] = Lab_Node.new()
		graph_labyrinth[i].id = i
	
	# Connect neighboring passage tiles
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for y in range(height):
		for x in range(width):
			var current_id = xy_to_id(x, y)
			
			# Only process passage tiles (not walls with difficulty 10)
			if tile_labyrinth[y][x] != 10:
				for d in dirs:
					var nx = x + d.x
					var ny = y + d.y
					
					# Check if neighbor is within bounds and is also a passage (not wall)
					if (nx >= 0 and nx < width and ny >= 0 and ny < height and 
						tile_labyrinth[ny][nx] != 10):  # Adjacent passage (any difficulty except wall)
						
						var neighbor_id = xy_to_id(nx, ny)
						var difficulty = tile_labyrinth[ny][nx]
						
						graph_labyrinth[current_id].neighbours.append(neighbor_id)
						graph_labyrinth[current_id].neighbours_difficulty.append(difficulty)

func build_corridor_graph() -> void:
	# Build simplified graph with one node per corridor/junction

	# Identify key points (junctions and dead-ends) - only from passage tiles
	var key_points: Array[int] = []

	for i in range(number_of_cells):
		var pos = id_to_xy(i)
		# Only consider passage tiles (not walls)
		if tile_labyrinth[pos.y][pos.x] != 10:
			var node = graph_labyrinth[i]
			var num_neighbors = node.neighbours.size()
			
			# Key points: junctions (3+ neighbors) and dead-ends (1 neighbor)
			if num_neighbors == 1 or num_neighbors >= 3:
				key_points.append(i)

	# Check if start and end tiles are key points, if not add them
	var start_id = get_start_tile_id()
	var end_id = get_end_tile_id()
	if not key_points.has(start_id):
		key_points.append(start_id)
	if not key_points.has(end_id):
		key_points.append(end_id)
	
	# Create a mapping from tile ID to corridor graph index
	var id_to_corridor_index: Dictionary = {}
	for j in range(key_points.size()):
		id_to_corridor_index[key_points[j]] = j
	
	# Create corridor graph nodes
	corridor_graph.resize(key_points.size())
	for j in range(key_points.size()):
		corridor_graph[j] = Lab_Node.new()
		corridor_graph[j].id = key_points[j]

		# Find direct corridors between key points
		var connections = find_direct_corridors(key_points[j], key_points)
		for conn in connections:
			var target_id = conn["point"]
			var difficulty = conn["difficulty"]
			
			# Convert target tile ID to corridor graph index
			if id_to_corridor_index.has(target_id):
				var target_corridor_index = id_to_corridor_index[target_id]
				corridor_graph[j].neighbours.append(target_corridor_index)
				corridor_graph[j].neighbours_difficulty.append(difficulty)
	
		


func find_direct_corridors(from_point: int, key_points: Array[int]) -> Array:
	# Use BFS to find direct corridors from a key point to other key points
	var connections: Array = []
	var visited: Dictionary = {}
	var queue: Array = [{"id": from_point, "path": [from_point], "difficulty": 0}]
	
	visited[from_point] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_id = current["id"]
		var path = current["path"]
		var total_difficulty = current["difficulty"]
		
		# Check if we reached another key point (not the starting one)
		if key_points.has(current_id) and current_id != from_point:
			connections.append({
				"point": current_id,
				"difficulty": total_difficulty,
				"path": path
			})
			continue  # Don't explore further from this key point
		
		# Explore neighbors
		for neighbor_id in graph_labyrinth[current_id].neighbours:
			if not visited.has(neighbor_id):
				visited[neighbor_id] = true
				var neighbor_pos = id_to_xy(neighbor_id)
				var neighbor_difficulty = tile_labyrinth[neighbor_pos.y][neighbor_pos.x]
				
				var new_path = path.duplicate()
				new_path.append(neighbor_id)
				
				queue.append({
					"id": neighbor_id,
					"path": new_path,
					"difficulty": total_difficulty + neighbor_difficulty
				})
	
	return connections
