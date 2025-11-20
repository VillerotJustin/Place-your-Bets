extends CharacterBody2D

class_name AStar

# Signals
signal path_built()
signal walk_finished()

# References
var labyrinth_generator: Node2D

# Path var
var start:Vector2
var end:Vector2
var path:Array[Vector2]
var current_target_index: int = 0

# Mouvement var
var is_moving: bool = false
var default_speed: float = 100.0  # pixels per second
var current_speed: float = 100.0 # Change with terrain difficulty
var movement_threshold: float = 5.0  # How close to get to target before moving to next

# Pathfinding state
var has_path: bool = false
var is_finished: bool = false

func set_start_and_end(start_pos: Vector2, end_pos: Vector2, ) -> void:
	start = start_pos
	end = end_pos
	
	global_position = start_pos
	
	# Reset pathfinding state
	path.clear()
	has_path = false
	is_moving = false
	is_finished = false
	current_target_index = 0

func build_path(_labyrinth: Array) -> void:
	print("A*: Building path from ", start, " to ", end)
	
	# Clear any existing path
	path.clear()
	has_path = false
	
	if not labyrinth_generator:
		print("A*: No labyrinth generator reference")
		path_built.emit()
		return
	
	var lab_gen = labyrinth_generator as Labyrinth_Generator
	if not lab_gen:
		print("A*: Invalid labyrinth generator")
		path_built.emit()
		return
	
	# Convert world positions to grid coordinates
	var start_grid = world_to_grid(start)
	var end_grid = world_to_grid(end)
	
	# Validate start and end positions
	if not _is_valid_position(start_grid, lab_gen) or not _is_valid_position(end_grid, lab_gen):
		print("A*: Invalid start or end position")
		path_built.emit()
		return
	
	# A* algorithm implementation
	var open_set: Array[Dictionary] = []
	var closed_set: Dictionary = {}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}
	
	# Initialize start node
	var start_key = _grid_to_key(start_grid)
	
	g_score[start_key] = 0
	f_score[start_key] = _heuristic_cost(start_grid, end_grid)
	
	open_set.append({
		"pos": start_grid,
		"key": start_key,
		"f_score": f_score[start_key]
	})
	
	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	
	while open_set.size() > 0:
		# Find node with lowest f_score
		var current_idx = 0
		for i in range(1, open_set.size()):
			if open_set[i]["f_score"] < open_set[current_idx]["f_score"]:
				current_idx = i
		
		var current = open_set[current_idx]
		var current_pos = current["pos"]
		var current_key = current["key"]
		
		# Remove current from open set and add to closed set
		open_set.remove_at(current_idx)
		closed_set[current_key] = true
		
		# Check if we reached the goal
		if current_pos == end_grid:
			# Reconstruct path
			_reconstruct_path(came_from, current_key, start_key)
			has_path = true
			print("A*: Path found with ", path.size(), " waypoints")
			path_built.emit()
			return
		
		# Check all neighbors
		for dir in directions:
			var neighbor_pos = current_pos + dir
			var neighbor_key = _grid_to_key(neighbor_pos)
			
			# Skip if already in closed set or invalid position
			if closed_set.has(neighbor_key) or not _is_valid_position(neighbor_pos, lab_gen):
				continue
			
			# Skip walls
			var tile_difficulty = lab_gen.tile_labyrinth[neighbor_pos.y][neighbor_pos.x]
			if tile_difficulty >= 10:  # Wall
				continue
			
			# Calculate tentative g_score (include tile difficulty as movement cost)
			var movement_cost = 1.0
			if tile_difficulty == 2:
				movement_cost = 1.5  # Medium difficulty
			elif tile_difficulty == 5:
				movement_cost = 3.0  # Hard difficulty
			# tile_difficulty 0 (passages) use base cost of 1.0
			var tentative_g = g_score[current_key] + movement_cost
			
			# Check if this path to neighbor is better
			if not g_score.has(neighbor_key) or tentative_g < g_score[neighbor_key]:
				came_from[neighbor_key] = current_key
				g_score[neighbor_key] = tentative_g
				f_score[neighbor_key] = tentative_g + _heuristic_cost(neighbor_pos, end_grid)
				
				# Add to open set if not already there
				var in_open_set = false
				for node in open_set:
					if node["key"] == neighbor_key:
						node["f_score"] = f_score[neighbor_key]  # Update f_score
						in_open_set = true
						break
				
				if not in_open_set:
					open_set.append({
						"pos": neighbor_pos,
						"key": neighbor_key,
						"f_score": f_score[neighbor_key]
					})
	
	# No path found
	print("A*: No path found")
	path_built.emit()

func walk_path() -> void:
	if has_path:
		is_moving = true
		is_finished = false
		current_target_index = 0
		print("A*: Starting to walk path")
	else:
		print("A*: No path to walk")

func _physics_process(_delta: float) -> void:
	if not is_moving or is_finished or not has_path:
		return
	
	# Check if we have a valid target
	if current_target_index >= path.size():
		# Reached the end
		is_moving = false
		is_finished = true
		#print("A*: Reached destination!")
		walk_finished.emit()
		return
	
	# Move towards current target
	var target = path[current_target_index]
	var distance = global_position.distance_to(target)
	
	if distance <= movement_threshold:
		# Reached current waypoint, move to next
		current_target_index += 1
		if current_target_index < path.size():
			pass
			#print("A*: Reached waypoint ", current_target_index - 1, ", moving to next")
	else:
		# Adjust speed based on current tile difficulty
		_update_speed_for_current_tile()
		
		# Move towards target
		var direction = (target - global_position).normalized()
		velocity = direction * current_speed
		move_and_slide()

func world_to_grid(world_pos: Vector2) -> Vector2i:
	if not labyrinth_generator:
		return Vector2i.ZERO
	
	var tile_size = 16  # Should match labyrinth_generator tile size
	var grid_x = int(world_pos.x / tile_size)
	var grid_y = int(world_pos.y / tile_size)
	return Vector2i(grid_x, grid_y)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if not labyrinth_generator:
		return Vector2.ZERO
	
	var tile_size = 16  # Should match labyrinth_generator tile size
	return Vector2(grid_pos.x * tile_size + tile_size * 0.5, grid_pos.y * tile_size + tile_size * 0.5)

func _update_speed_for_current_tile() -> void:
	if not labyrinth_generator:
		current_speed = default_speed
		return
	
	# Get current tile position
	var grid_pos = world_to_grid(global_position)
	
	# Get labyrinth reference and check bounds
	var lab_gen = labyrinth_generator as Labyrinth_Generator
	if not lab_gen or grid_pos.x < 0 or grid_pos.y < 0 or grid_pos.x >= lab_gen.width or grid_pos.y >= lab_gen.height:
		current_speed = default_speed
		return
	
	# Get tile difficulty
	var tile_difficulty = lab_gen.tile_labyrinth[grid_pos.y][grid_pos.x]
	
	# Adjust speed based on difficulty
	match tile_difficulty:
		0:  # Easy passage
			current_speed = default_speed
		2:  # Medium difficulty
			current_speed = default_speed * 0.7
		5:  # Hard difficulty
			current_speed = default_speed * 0.4
		10: # Wall (shouldn't happen but just in case)
			current_speed = default_speed * 0.1
		_:  # Default for any other value
			current_speed = default_speed

# ====================================================================
# A* ALGORITHM HELPER FUNCTIONS
# ====================================================================

func _is_valid_position(pos: Vector2i, lab_gen: Labyrinth_Generator) -> bool:
	return (pos.x >= 0 and pos.x < lab_gen.width and 
			pos.y >= 0 and pos.y < lab_gen.height)

func _grid_to_key(pos: Vector2i) -> String:
	return str(pos.x) + "," + str(pos.y)

func _heuristic_cost(from: Vector2i, to: Vector2i) -> float:
	# Manhattan distance heuristic (admissible for grid-based pathfinding)
	return abs(from.x - to.x) + abs(from.y - to.y)

func _reconstruct_path(came_from: Dictionary, current_key: String, start_key: String) -> void:
	var path_keys: Array[String] = []
	var current = current_key
	
	# Trace back from goal to start
	while current != start_key:
		path_keys.append(current)
		if not came_from.has(current):
			print("A*: Error in path reconstruction")
			return
		current = came_from[current]
	
	path_keys.append(start_key)
	path_keys.reverse()
	
	# Convert keys back to world positions
	path.clear()
	for key in path_keys:
		var coords = key.split(",")
		var grid_pos = Vector2i(int(coords[0]), int(coords[1]))
		var world_pos = grid_to_world(grid_pos)
		path.append(world_pos)
