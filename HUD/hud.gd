extends Control

class_name HUD

@export_category("References")

# Score
@onready var build_time_label_astar: Label = $"Panel/Container/ScoreRows/BUILD/Content"
@onready var build_time_label_dijkstra: Label = $Panel/Container/ScoreRows/BUILD/Content2
@onready var walk_time_label_astar: Label = $Panel/Container/ScoreRows/WALK/Content
@onready var walk_time_label_dijkstra: Label = $Panel/Container/ScoreRows/WALK/Content2
@onready var points_label_astar: Label = $Panel/Container/ScoreRows/POINT/Content
@onready var points_label_dijkstra: Label = $Panel/Container/ScoreRows/POINT/Content2

# Message
@onready var message_node: Control = $Panel/Container/Message
@onready var message_label: Label = $Panel/Container/Message/Panel/MessageLabel
@onready var message_timer: Timer = $Panel/Container/Message/Panel/Timer

# Money
@onready var money_label: Label = $Panel/Container/VBoxContainer/Money/VBoxContainer/Money
@onready var bet_label: Label = $Panel/Container/VBoxContainer/Money/VBoxContainer/Bet
@onready var last_win_label: Label = $Panel/Container/VBoxContainer/Money/VBoxContainer/LastWin

func _ready() -> void:
	UX_Manager.load_HUD_instance(self)

# 0 to 4
func update_time_label(label_id: int, value:float)-> void:
	match  label_id:
		0:
			build_time_label_astar.text = str(value)
		1:
			build_time_label_dijkstra.text = str(value)
		2:
			walk_time_label_astar.text = str(value)
		3:
			walk_time_label_dijkstra.text = str(value)
		_:
			push_error("invalid label")

func update_points_labels(astar: int, dijkstra: int):
	points_label_astar.text = str(astar)
	points_label_dijkstra.text = str(dijkstra)
	
	if astar == dijkstra and dijkstra == 0:
		return
	
	if astar > dijkstra:
		show_message("A* Won")
	elif astar < dijkstra:
		show_message("Dijkstra Won")
	else:
		show_message("Equality")

func update_money(money: int, bet: int, last_win: int, side: bool) -> void:
	money_label.text = "Current: " + str(money)
	bet_label.text = "Bet: " + str(bet)
	
	# Set color based on side
	var color = Color.GREEN if side else Color.RED
	bet_label.add_theme_color_override("font_color", color)
	
	last_win_label.text = "Last Win: " + str(last_win)

func show_message(message: String) -> void:
	message_node.visible = true
	message_label.text = message
	message_timer.start()
	

func _on_timer_timeout() -> void:
	message_node.visible = false


func _on_a_star_bet_pressed() -> void:
	UX_Manager.increase_bet(true)

func _on_dijkstra_be_t_pressed() -> void:
	UX_Manager.increase_bet(false)
