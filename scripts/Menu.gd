extends Control

@onready var time15: Button = $VBox/TimeRow/Time15
@onready var time60: Button = $VBox/TimeRow/Time60
@onready var time120: Button = $VBox/TimeRow/Time120

@onready var start_button: Button = $VBox/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	if time15.button_pressed:
		Global.selected_time = 15.0
	elif time120.button_pressed:
		Global.selected_time = 120.0
	else:
		Global.selected_time = 60.0

	get_tree().change_scene_to_file("res://scenes/Game.tscn")
