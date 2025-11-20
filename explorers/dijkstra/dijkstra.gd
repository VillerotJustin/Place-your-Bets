extends CharacterBody2D

class_name  Dijkstra

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
var default_speed: float = 80.0  # pixels per second (slightly slower than A*)
var current_speed: float = 80.0 # Change with terrain difficulty
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

func build_path(_graph:Array[Lab_Node]) -> void:
	print("Dijkstra: Building path from ", start, " to ", end)
	
	# Clear any existing path
	path.clear()
	has_path = false
	
	if not labyrinth_generator:
		print("Dijkstra: No labyrinth generator reference")
		path_built.emit()
		return
	
	var lab_gen = labyrinth_generator as Labyrinth_Generator
	if not lab_gen:
		print("Dijkstra: Invalid labyrinth generator")
		path_built.emit()
		return
	
	# Convert world positions to grid coordinates (adjust for right labyrinth)
	var start_world_adjusted = start
	var end_world_adjusted = end
	var tile_size = 16
	start_world_adjusted.x -= (lab_gen.width + 2) * tile_size
	end_world_adjusted.x -= (lab_gen.width + 2) * tile_size
	
	var start_grid = Vector2i(int(start_world_adjusted.x / tile_size), int(start_world_adjusted.y / tile_size))
	var end_grid = Vector2i(int(end_world_adjusted.x / tile_size), int(end_world_adjusted.y / tile_size))
	
	# Validate start and end positions
	if not _is_valid_position(start_grid, lab_gen) or not _is_valid_position(end_grid, lab_gen):
		print("Dijkstra: Invalid start or end position")
		path_built.emit()
		return
	
	# Dijkstra's algorithm implementation
	var distances: Dictionary = {}
	var previous: Dictionary = {}
	var unvisited: Array[String] = []
	
	# Initialize all nodes
	for y in range(lab_gen.height):
		for x in range(lab_gen.width):
			if lab_gen.tile_labyrinth[y][x] < 10:  # Not a wall
				var key = _grid_to_key(Vector2i(x, y))
				distances[key] = INF
				unvisited.append(key)
	
	# Set start distance to 0
	var start_key = _grid_to_key(start_grid)
	var end_key = _grid_to_key(end_grid)
	distances[start_key] = 0.0
	
	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	
	while unvisited.size() > 0:
		# Find unvisited node with minimum distance
		var current_key = ""
		var min_distance = INF
		for key in unvisited:
			if distances[key] < min_distance:
				min_distance = distances[key]
				current_key = key
		
		if current_key == "" or min_distance == INF:
			break  # No more reachable nodes
		
		# Remove current from unvisited
		unvisited.erase(current_key)
		
		# Check if we reached the goal
		if current_key == end_key:
			# Reconstruct path
			_reconstruct_dijkstra_path(previous, current_key, start_key, lab_gen)
			has_path = true
			print("Dijkstra: Path found with ", path.size(), " waypoints")
			path_built.emit()
			return
		
		# Get current position
		var coords = current_key.split(",")
		var current_pos = Vector2i(int(coords[0]), int(coords[1]))
		
		# Check all neighbors
		for dir in directions:
			var neighbor_pos = current_pos + dir
			var neighbor_key = _grid_to_key(neighbor_pos)
			
			# Skip if not in unvisited or invalid position
			if not unvisited.has(neighbor_key) or not _is_valid_position(neighbor_pos, lab_gen):
				continue
			
			# Skip walls
			var tile_difficulty = lab_gen.tile_labyrinth[neighbor_pos.y][neighbor_pos.x]
			if tile_difficulty >= 10:
				continue
			
			# Calculate movement cost
			var movement_cost = 1.0
			if tile_difficulty == 2:
				movement_cost = 1.5  # Medium difficulty
			elif tile_difficulty == 5:
				movement_cost = 3.0  # Hard difficulty
			
			var alt_distance = distances[current_key] + movement_cost
			
			# Update if we found a better path
			if alt_distance < distances[neighbor_key]:
				distances[neighbor_key] = alt_distance
				previous[neighbor_key] = current_key
	
	# No path found
	print("Dijkstra: No path found")
	path_built.emit()

func walk_path() -> void:
	if has_path:
		is_moving = true
		is_finished = false
		current_target_index = 0
		print("Dijkstra: Starting to walk path")
	else:
		print("Dijkstra: No path to walk")

func _physics_process(_delta: float) -> void:
	if not is_moving or is_finished or not has_path:
		return
	
	# Check if we have a valid target
	if current_target_index >= path.size():
		# Reached the end
		is_moving = false
		is_finished = true
		print("Dijkstra: Reached destination!")
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
			#print("Dijkstra: Reached waypoint ", current_target_index - 1, ", moving to next")
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
	return Vector2(grid_pos.x * tile_size + tile_size * 0.5 + (labyrinth_generator.width + 2) * tile_size, grid_pos.y * tile_size + tile_size * 0.5)

func _update_speed_for_current_tile() -> void:
	if not labyrinth_generator:
		current_speed = default_speed
		return
	
	# Get current tile position (adjust for right labyrinth offset)
	var world_pos_adjusted = global_position
	var lab_gen = labyrinth_generator as Labyrinth_Generator
	if lab_gen:
		# Remove the offset for right labyrinth to get correct grid position
		var tile_size = 16
		world_pos_adjusted.x -= (lab_gen.width + 2) * tile_size
	
	var grid_pos = Vector2i(int(world_pos_adjusted.x / 16), int(world_pos_adjusted.y / 16))
	
	# Check bounds
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
# DIJKSTRA ALGORITHM HELPER FUNCTIONS
# ====================================================================

func _is_valid_position(pos: Vector2i, lab_gen: Labyrinth_Generator) -> bool:
	return (pos.x >= 0 and pos.x < lab_gen.width and 
			pos.y >= 0 and pos.y < lab_gen.height)

func _grid_to_key(pos: Vector2i) -> String:
	return str(pos.x) + "," + str(pos.y)

func _reconstruct_dijkstra_path(previous: Dictionary, current_key: String, start_key: String, lab_gen: Labyrinth_Generator) -> void:
	var path_keys: Array[String] = []
	var current = current_key
	
	# Trace back from goal to start
	while current != start_key:
		path_keys.append(current)
		if not previous.has(current):
			print("Dijkstra: Error in path reconstruction")
			return
		current = previous[current]
	
	path_keys.append(start_key)
	path_keys.reverse()
	
	# Convert keys back to world positions (with right labyrinth offset)
	path.clear()
	var tile_size = 16
	for key in path_keys:
		var coords = key.split(",")
		var grid_pos = Vector2i(int(coords[0]), int(coords[1]))
		# Add back the offset for right labyrinth
		var world_pos = Vector2(
			grid_pos.x * tile_size + tile_size * 0.5 + (lab_gen.width + 2) * tile_size,
			grid_pos.y * tile_size + tile_size * 0.5
		)
		path.append(world_pos)
