extends Node

var HUD_instance: HUD

var is_refreshing = false

# --- Backing variables ---
var _build_time_astar := 0.0
var _build_time_dijkstra := 0.0
var _walk_time_astar := 0.0
var _walk_time_dijkstra := 0.0
var _points_astar := -1
var _points_dijkstra := -1
var _money := 10
var _bet := 0
var _last_win := 0

@export_category("Scores")

@export var build_time_astar: float:
	get: return _build_time_astar
	set(value):
		_build_time_astar = value
		refresh()

@export var build_time_dijkstra: float:
	get: return _build_time_dijkstra
	set(value):
		_build_time_dijkstra = value
		refresh()

@export var walk_time_astar: float:
	get: return _walk_time_astar
	set(value):
		_walk_time_astar = value
		refresh()

@export var walk_time_dijkstra: float:
	get: return _walk_time_dijkstra
	set(value):
		_walk_time_dijkstra = value
		refresh()

@export var points_astar: int:
	get: return _points_astar
	set(value):
		_points_astar = value

@export var points_dijkstra: int:
	get: return _points_dijkstra
	set(value):
		_points_dijkstra = value

@export_category("Betting")

@export var money: int:
	get: return _money
	set(value):
		_money = value
		refresh()

@export var bet: int:
	get: return _bet
	set(value):
		_bet = value
		refresh()

@export var last_win: int:
	get: return _last_win
	set(value):
		_last_win = value
		refresh()

@export var betting_for_astar: bool = true

func load_HUD_instance(instance:HUD) -> void:
	HUD_instance = instance
	refresh()

func reset() -> void:
	bet = 0
	build_time_astar = 0
	build_time_dijkstra = 0
	walk_time_astar = 0
	walk_time_dijkstra = 0

func calculate_points() -> void:
	points_astar = 0
	points_dijkstra = 0

	if build_time_astar > build_time_dijkstra:
		points_dijkstra += 1
	elif build_time_astar < build_time_dijkstra:
		points_astar += 1
	elif build_time_astar != 0:
		points_astar += 1
		points_dijkstra += 1

	if walk_time_astar > walk_time_dijkstra:
		points_dijkstra += 1
	elif walk_time_astar < walk_time_dijkstra:
		points_astar += 1
	elif walk_time_astar != 0:
		points_astar += 1
		points_dijkstra += 1

	if points_astar == 0 and points_dijkstra == 0:
		return

	var astar_win: bool = points_astar > points_dijkstra

	if astar_win and betting_for_astar:
		HUD_instance.show_message("You won your bet")
		money += bet * 2
	elif not astar_win and not betting_for_astar:
		HUD_instance.show_message("You won your bet")
		money += bet * 2
	else:
		money -= bet

	#reset()

func increase_bet(side: bool) -> void:
	bet += 1
	bet = min(money, bet)
	betting_for_astar = side


func refresh() -> void:
	if HUD_instance == null:
		return
		
	if is_refreshing:
		return
	
	is_refreshing = true

	# Time labels
	HUD_instance.update_time_label(0, build_time_astar)
	HUD_instance.update_time_label(1, build_time_dijkstra)
	HUD_instance.update_time_label(2, walk_time_astar)
	HUD_instance.update_time_label(3, walk_time_dijkstra)

	calculate_points()

	HUD_instance.update_points_labels(points_astar, points_dijkstra)

	HUD_instance.update_money(money, bet, last_win, betting_for_astar)
	
	is_refreshing = false
