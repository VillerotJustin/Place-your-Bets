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

# Race completion tracking
var race_completed := false
var both_algorithms_built := false
var both_algorithms_walked := false

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
	race_completed = false
	both_algorithms_built = false
	both_algorithms_walked = false

func calculate_points() -> void:
	points_astar = 0
	points_dijkstra = 0

	# Check if both building phases are complete
	if build_time_astar > 0 and build_time_dijkstra > 0:
		both_algorithms_built = true
		if build_time_astar > build_time_dijkstra:
			points_dijkstra += 1
		elif build_time_astar < build_time_dijkstra:
			points_astar += 1
		else:
			points_astar += 1
			points_dijkstra += 1

	# Check if both walking phases are complete
	if walk_time_astar > 0 and walk_time_dijkstra > 0:
		both_algorithms_walked = true
		if walk_time_astar > walk_time_dijkstra:
			points_dijkstra += 1
		elif walk_time_astar < walk_time_dijkstra:
			points_astar += 1
		else:
			points_astar += 1
			points_dijkstra += 1

	# Only determine winner and process bets when both phases are complete
	if both_algorithms_built and both_algorithms_walked and not race_completed:
		race_completed = true
		_process_bet_results()

func _process_bet_results() -> void:
	# Only process bets if there was actually a bet placed
	if bet == 0:
		return
		
	if points_astar == 0 and points_dijkstra == 0:
		return

	var astar_wins: bool = points_astar > points_dijkstra
	var is_tie: bool = points_astar == points_dijkstra
	
	if is_tie:
		HUD_instance.show_message("It's a tie! Bet returned")
		# Return the bet, don't add or subtract
		last_win = 0
	elif astar_wins and betting_for_astar:
		HUD_instance.show_message("You won your bet on A*!")
		last_win = bet * 2
		money += last_win
	elif not astar_wins and not betting_for_astar:
		HUD_instance.show_message("You won your bet on Dijkstra!")
		last_win = bet * 2 
		money += last_win
	else:
		if betting_for_astar:
			HUD_instance.show_message("You lost your bet on A*")
		else:
			HUD_instance.show_message("You lost your bet on Dijkstra")
		money -= bet
		last_win = -bet
	
	# Reset bet for next round
	bet = 0

func increase_bet(side: bool) -> void:
	# Don't allow betting during a race
	if _is_race_in_progress():
		HUD_instance.show_message("Cannot bet during race!")
		return
		
	bet += 1
	bet = min(money, bet)
	betting_for_astar = side

func _is_race_in_progress() -> bool:
	# Race is in progress if any timing is happening or race isn't complete
	return (build_time_astar > 0 or build_time_dijkstra > 0 or 
			walk_time_astar > 0 or walk_time_dijkstra > 0) and not race_completed


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

	# Only calculate points and check for race completion
	calculate_points()

	HUD_instance.update_points_labels(points_astar, points_dijkstra)
	HUD_instance.update_money(money, bet, last_win, betting_for_astar)
	
	is_refreshing = false
