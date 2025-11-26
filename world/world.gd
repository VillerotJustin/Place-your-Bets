extends Node2D

class_name BetMaster

# References to explorers & labyrinth generator
var labyrinth_generator: Labyrinth_Generator
var a_star_explorer: AStar
var dijkstra_explorer: Dijkstra


var a_star_process_time: float = 0.0
var dijkstra_process_time: float = 0.0

var a_star_walk_time: float = 0.0
var dijkstra_walk_time: float = 0.0

# Start times for measuring performance
var a_star_build_start_time: float = 0.0
var dijkstra_build_start_time: float = 0.0
var a_star_walk_start_time: float = 0.0
var dijkstra_walk_start_time: float = 0.0

# Flags to track if timing is active
var timing_a_star_build: bool = false
var timing_dijkstra_build: bool = false
var timing_a_star_walk: bool = false
var timing_dijkstra_walk: bool = false

func _ready() -> void:
	# Get references to child nodes
	labyrinth_generator = $Labyrinth_Generator as Labyrinth_Generator
	a_star_explorer = $A_Star as AStar
	dijkstra_explorer = $dijkstra as Dijkstra
	
	# Set up labyrinth generator references in explorers
	if a_star_explorer:
		a_star_explorer.labyrinth_generator = labyrinth_generator
		# Connect A* signals
		a_star_explorer.path_built.connect(_on_astar_path_built)
		a_star_explorer.walk_finished.connect(_on_astar_walk_finished)
	if dijkstra_explorer:
		dijkstra_explorer.labyrinth_generator = labyrinth_generator
		# Connect Dijkstra signals
		dijkstra_explorer.path_built.connect(_on_dijkstra_path_built)
		dijkstra_explorer.walk_finished.connect(_on_dijkstra_walk_finished)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				if labyrinth_generator:
					print("Regenerating labyrinths...")
					labyrinth_generator.regen_labs()
			
			KEY_SPACE:
				if labyrinth_generator and a_star_explorer and dijkstra_explorer:
					print("Building paths for both explorers...")
					# Start timing for path building
					_start_build_timing()
					a_star_explorer.build_path(labyrinth_generator.tile_labyrinth)
					_start_build_timing(false)
					dijkstra_explorer.build_path(labyrinth_generator.corridor_graph)
			
			KEY_ENTER:
				if a_star_explorer and dijkstra_explorer:
					print("Starting path walking for both explorers...")
					# Start timing for path walking
					_start_walk_timing()
					a_star_explorer.walk_path()
					_start_walk_timing(false)
					dijkstra_explorer.walk_path()

func _physics_process(_delta: float) -> void:
	# This function can be used for continuous updates if needed
	pass

# ====================================================================
# TIMING FUNCTIONS
# ====================================================================

func _start_build_timing(astar: bool = true) -> void:
	# Start timing for both algorithms (using milliseconds for precision)
	if astar:
		a_star_build_start_time = Time.get_ticks_msec()
		timing_a_star_build = true
	else:
		dijkstra_build_start_time = Time.get_ticks_msec()
		timing_dijkstra_build = true
	print("Started timing path building...")

func _start_walk_timing(astar: bool = true) -> void:
	# Start timing for both algorithms (using milliseconds for precision)
	if astar:
		a_star_walk_start_time = Time.get_ticks_msec()
		timing_a_star_walk = true
	else:
		dijkstra_walk_start_time = Time.get_ticks_msec()		
		timing_dijkstra_walk = true
	print("Started timing path walking...")

# ====================================================================
# SIGNAL HANDLERS
# ====================================================================

func _on_astar_path_built() -> void:
	if timing_a_star_build:
		var end_time = Time.get_ticks_msec()
		a_star_process_time = (end_time - a_star_build_start_time) / 1000.0  # Convert to seconds
		timing_a_star_build = false
		print("A* path building completed in: ", a_star_process_time, " seconds")
		UX_Manager.build_time_astar = a_star_process_time

func _on_astar_walk_finished() -> void:
	if timing_a_star_walk:
		var end_time = Time.get_ticks_msec()
		a_star_walk_time = (end_time - a_star_walk_start_time) / 1000.0  # Convert to seconds
		timing_a_star_walk = false
		print("A* walk completed in: ", a_star_walk_time, " seconds")
		UX_Manager.walk_time_astar = a_star_walk_time

func _on_dijkstra_path_built() -> void:
	if timing_dijkstra_build:
		var end_time = Time.get_ticks_msec()
		dijkstra_process_time = (end_time - dijkstra_build_start_time) / 1000.0  # Convert to seconds
		timing_dijkstra_build = false
		print("Dijkstra path building completed in: ", dijkstra_process_time, " seconds")
		UX_Manager.build_time_dijkstra = dijkstra_process_time

func _on_dijkstra_walk_finished() -> void:
	if timing_dijkstra_walk:
		var end_time = Time.get_ticks_msec()
		dijkstra_walk_time = (end_time - dijkstra_walk_start_time) / 1000.0  # Convert to seconds
		timing_dijkstra_walk = false
		print("Dijkstra walk completed in: ", dijkstra_walk_time, " seconds")
		UX_Manager.walk_time_dijkstra = dijkstra_walk_time
		
	# Check if both algorithms have finished and display comparison
	if not timing_a_star_walk and not timing_dijkstra_walk:
		_display_performance_comparison()

func _display_performance_comparison() -> void:
	print("\n=== PERFORMANCE COMPARISON ===")
	print("Path Building Times:")
	print("  A*: ", a_star_process_time, " seconds")
	print("  Dijkstra: ", dijkstra_process_time, " seconds")
	print("Path Walking Times:")
	print("  A*: ", a_star_walk_time, " seconds")  
	print("  Dijkstra: ", dijkstra_walk_time, " seconds")
	
	if a_star_process_time < dijkstra_process_time:
		print("A* was faster at building paths!")
	elif dijkstra_process_time < a_star_process_time:
		print("Dijkstra was faster at building paths!")
	else:
		print("Both algorithms took the same time to build paths!")
	
	if a_star_walk_time < dijkstra_walk_time:
		print("A* was faster at walking paths!")
	elif dijkstra_walk_time < a_star_walk_time:
		print("Dijkstra was faster at walking paths!")
	else:
		print("Both algorithms took the same time to walk paths!")
	print("==============================\n")
	
