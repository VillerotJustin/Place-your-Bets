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
var default_speed: float = 100.0 
var current_speed: float = 100.0 
var movement_threshold: float = 5.0

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

func build_path(graph: Array[Lab_Node]) -> void:
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
	
	if graph.size() == 0:
		print("Dijkstra: Empty graph provided")
		path_built.emit()
		return
	
	# Convert world positions to tile IDs (adjust for right labyrinth)
	var start_world_adjusted = start
	var end_world_adjusted = end
	var tile_size = 16
	start_world_adjusted.x -= (lab_gen.width + 2) * tile_size
	end_world_adjusted.x -= (lab_gen.width + 2) * tile_size
	
	var start_grid = Vector2i(int(start_world_adjusted.x / tile_size), int(start_world_adjusted.y / tile_size))
	var end_grid = Vector2i(int(end_world_adjusted.x / tile_size), int(end_world_adjusted.y / tile_size))
	
	var start_id = lab_gen.xy_to_id(start_grid.x, start_grid.y)
	var end_id = lab_gen.xy_to_id(end_grid.x, end_grid.y)
	
	print("Dijkstra: Start grid: ", start_grid, " ID: ", start_id)
	print("Dijkstra: End grid: ", end_grid, " ID: ", end_id)
	print("Dijkstra: Graph size: ", graph.size())
	
	# Find start and end nodes in the graph (try exact match first)
	var start_node_idx = -1
	var end_node_idx = -1
	
	for i in range(graph.size()):
		if graph[i].id == start_id:
			start_node_idx = i
		if graph[i].id == end_id:
			end_node_idx = i
	
	# If exact match not found, find nearest corridor nodes
	if start_node_idx == -1:
		start_node_idx = _find_nearest_corridor_node(start_grid, graph, lab_gen)
		print("Dijkstra: Using nearest start node: ", start_node_idx)
	
	if end_node_idx == -1:
		end_node_idx = _find_nearest_corridor_node(end_grid, graph, lab_gen)
		print("Dijkstra: Using nearest end node: ", end_node_idx)
	
	if start_node_idx == -1 or end_node_idx == -1:
		print("Dijkstra: Could not find suitable start or end nodes in corridor graph")
		path_built.emit()
		return
	
	# Dijkstra's algorithm on the corridor graph
	var distances: Array[float] = []
	var previous: Array[int] = []
	var visited: Array[bool] = []
	
	# Initialize arrays
	for i in range(graph.size()):
		distances.append(INF)
		previous.append(-1)
		visited.append(false)
	
	distances[start_node_idx] = 0.0
	
	# Main Dijkstra loop
	for _iteration in range(graph.size()):
		# Find unvisited node with minimum distance
		var current_idx = -1
		var min_distance = INF
		
		for i in range(graph.size()):
			if not visited[i] and distances[i] < min_distance:
				min_distance = distances[i]
				current_idx = i
		
		if current_idx == -1 or min_distance == INF:
			break  # No more reachable nodes
		
		visited[current_idx] = true
		
		# Check if we reached the goal
		if current_idx == end_node_idx:
			break
		
		# Update distances to neighbors
		var current_node = graph[current_idx]
		# print("Dijkstra: Processing node ", current_idx, " with ID ", current_node.id, " (", current_node.neighbours.size(), " neighbors)")
		
		for i in range(current_node.neighbours.size()):
			var neighbor_idx = current_node.neighbours[i]  # This is already a graph index, not a tile ID
			var edge_cost = current_node.neighbours_difficulty[i]
			
			# Validate neighbor index
			if neighbor_idx >= 0 and neighbor_idx < graph.size() and not visited[neighbor_idx]:
				var alt_distance = distances[current_idx] + edge_cost
				if alt_distance < distances[neighbor_idx]:
					distances[neighbor_idx] = alt_distance
					previous[neighbor_idx] = current_idx
					# print("Dijkstra: Updated distance to node ", neighbor_idx, " = ", alt_distance)
	
	# Reconstruct path if found
	print("Dijkstra: Final distance to end: ", distances[end_node_idx])
	if distances[end_node_idx] != INF:
		_reconstruct_corridor_path(graph, previous, end_node_idx, start_node_idx, lab_gen)
		has_path = true
		print("Dijkstra: Path found with ", path.size(), " waypoints")
		path_built.emit()
	else:
		print("Dijkstra: No path found - distance is infinite")
		# Debug: show which nodes were reachable
		var reachable_count = 0
		for i in range(distances.size()):
			if distances[i] != INF:
				reachable_count += 1
		print("Dijkstra: ", reachable_count, " out of ", graph.size(), " nodes were reachable")
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

func _grid_to_key(pos) -> String:
	if pos is Vector2i:
		return str(pos.x) + "," + str(pos.y)
	elif pos is Vector2:
		return str(int(pos.x)) + "," + str(int(pos.y))
	else:
		return "0,0"

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

func _reconstruct_corridor_path(graph: Array[Lab_Node], previous: Array[int], end_idx: int, start_idx: int, lab_gen: Labyrinth_Generator) -> void:
	var node_path: Array[int] = []
	var current_idx = end_idx
	
	# Trace back from goal to start to get corridor nodes
	while current_idx != start_idx:
		node_path.append(current_idx)
		if previous[current_idx] == -1:
			print("Dijkstra: Error in corridor path reconstruction")
			return
		current_idx = previous[current_idx]
	
	node_path.append(start_idx)
	node_path.reverse()
	
	# Now expand the path to include all cells along corridors
	path.clear()
	var tile_size = 16
	
	for i in range(node_path.size()):
		var current_node_idx = node_path[i]
		var current_node = graph[current_node_idx]
		var current_tile_id = current_node.id
		
		# Always add the current corridor node
		var current_grid_pos = lab_gen.id_to_xy(current_tile_id)
		var current_world_pos = Vector2(
			current_grid_pos.x * tile_size + tile_size * 0.5 + (lab_gen.width + 2) * tile_size,
			current_grid_pos.y * tile_size + tile_size * 0.5
		)
		path.append(current_world_pos)
		
		# If this is not the last node, find and add all intermediate cells
		if i < node_path.size() - 1:
			var next_node_idx = node_path[i + 1]
			var next_node = graph[next_node_idx]
			var next_tile_id = next_node.id
			
			# Find the corridor path between these two nodes using BFS
			var corridor_cells = _find_corridor_between_nodes(current_tile_id, next_tile_id, lab_gen)
			
			# Add intermediate cells (skip first and last as they're the corridor nodes themselves)
			for j in range(1, corridor_cells.size() - 1):
				var cell_grid_pos = lab_gen.id_to_xy(corridor_cells[j])
				var cell_world_pos = Vector2(
					cell_grid_pos.x * tile_size + tile_size * 0.5 + (lab_gen.width + 2) * tile_size,
					cell_grid_pos.y * tile_size + tile_size * 0.5
				)
				path.append(cell_world_pos)

func _find_nearest_corridor_node(target_pos: Vector2i, graph: Array[Lab_Node], lab_gen: Labyrinth_Generator) -> int:
	var nearest_idx = -1
	var min_distance = INF
	
	for i in range(graph.size()):
		var node = graph[i]
		var node_pos = lab_gen.id_to_xy(node.id)
		var distance = target_pos.distance_squared_to(node_pos)
		
		if distance < min_distance:
			min_distance = distance
			nearest_idx = i
	
	if nearest_idx != -1:
		var nearest_node = graph[nearest_idx]
		var nearest_pos = lab_gen.id_to_xy(nearest_node.id)
		print("Dijkstra: Found nearest node at ", nearest_pos, " (distance: ", sqrt(min_distance), ")")
	
	return nearest_idx

func _find_corridor_between_nodes(start_tile_id: int, end_tile_id: int, lab_gen: Labyrinth_Generator) -> Array[int]:
	# Use BFS to find the shortest path between two corridor nodes
	var visited: Dictionary = {}
	var start_path: Array[int] = [start_tile_id]
	var queue: Array = [{"id": start_tile_id, "path": start_path}]
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	visited[start_tile_id] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_id = current["id"]
		var current_path = current["path"]
		
		# Check if we reached the destination
		if current_id == end_tile_id:
			var typed_path: Array[int] = []
			for cell_id in current_path:
				typed_path.append(cell_id)
			return typed_path
		
		# Get current position
		var current_pos = lab_gen.id_to_xy(current_id)
		
		# Explore neighbors
		for d in dirs:
			var neighbor_x = current_pos.x + d.x
			var neighbor_y = current_pos.y + d.y
			
			# Check bounds
			if (neighbor_x >= 0 and neighbor_x < lab_gen.width and 
				neighbor_y >= 0 and neighbor_y < lab_gen.height):
				
				var neighbor_id = lab_gen.xy_to_id(neighbor_x, neighbor_y)
				
				# Check if neighbor is a passage (not a wall) and not visited
				if (lab_gen.tile_labyrinth[neighbor_y][neighbor_x] != 10 and 
					not visited.has(neighbor_id)):
					
					visited[neighbor_id] = true
					var new_path: Array[int] = current_path.duplicate()
					new_path.append(neighbor_id)
					
					queue.append({
						"id": neighbor_id,
						"path": new_path
					})
	
	# If no path found, return just the start and end points
	print("Dijkstra: Warning - No corridor path found between nodes ", start_tile_id, " and ", end_tile_id)
	var fallback_path: Array[int] = [start_tile_id, end_tile_id]
	return fallback_path
