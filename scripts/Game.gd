extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const SPEED_BOOST_SCENE: PackedScene = preload("res://scenes/SpeedBoost.tscn")
const JUMP_BOOST_SCENE: PackedScene = preload("res://scenes/JumpBoost.tscn")
const MapGenerator: GDScript = preload("res://scripts/MapGenerator.gd")

const BOOST_RESPAWN_TIME: float = 7.0
const JUMP_BOOST_RESPAWN_TIME: float = 9.0

const PICKER_DELAYS: Array[float] = [
	0.08, 0.08, 0.09, 0.1, 0.11, 0.13, 0.15, 0.18, 0.22, 0.27, 0.34, 0.44, 0.58
]

var time_left: float = 60.0
var game_over: bool = false
var intro_done: bool = false

var player_a: CharacterBody2D
var player_b: CharacterBody2D

var player_a_tagged_time: float = 0.0
var player_b_tagged_time: float = 0.0

var boost_spawn_marker: Marker2D
var boost_respawn_timer: float = -1.0

var jump_boost_spawn_marker: Marker2D
var jump_boost_respawn_timer: float = -1.0

@onready var map_container: Node2D = $MapContainer
@onready var timer_label: Label = $UI/TimerLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var time_a_label: Label = $UI/TimeALabel
@onready var time_b_label: Label = $UI/TimeBLabel
@onready var picker_label: Label = $UI/PickerPanel/PickerLabel
@onready var picker_panel: Panel = $UI/PickerPanel
@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var game_over_label: Label = $UI/GameOverPanel/GameOverLabel
@onready var back_button: Button = $UI/GameOverPanel/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	time_left = Global.selected_time

	var map_instance: Node2D = MapGenerator.generate()
	map_container.add_child(map_instance)

	var spawn_a: Marker2D = map_instance.get_node("SpawnA")
	var spawn_b: Marker2D = map_instance.get_node("SpawnB")

	player_a = PLAYER_SCENE.instantiate()
	player_a.player_id = "a"
	player_a.position = spawn_a.position
	add_child(player_a)

	player_b = PLAYER_SCENE.instantiate()
	player_b.player_id = "b"
	player_b.position = spawn_b.position
	add_child(player_b)

	player_a.other_player = player_b
	player_b.other_player = player_a

	player_a.set_tagged(false)
	player_b.set_tagged(false)

	if map_instance.has_node("BoostSpawn"):
		boost_spawn_marker = map_instance.get_node("BoostSpawn")
		_spawn_boost()

	if map_instance.has_node("JumpBoostSpawn"):
		jump_boost_spawn_marker = map_instance.get_node("JumpBoostSpawn")
		_spawn_jump_boost()

	_update_timer_label()
	_update_time_labels()
	status_label.text = "Waiting to see who's IT..."

	await _run_tag_picker_intro()


func _run_tag_picker_intro() -> void:
	var chosen_a: bool = randi() % 2 == 0

	picker_panel.visible = true
	for i in PICKER_DELAYS.size():
		var show_a: bool = i % 2 == 0
		picker_label.text = "PLAYER A?" if show_a else "PLAYER B?"
		await get_tree().create_timer(PICKER_DELAYS[i]).timeout

	picker_label.text = "PLAYER A IS IT!" if chosen_a else "PLAYER B IS IT!"
	await get_tree().create_timer(1.0).timeout
	picker_panel.visible = false

	player_a.set_tagged(chosen_a)
	player_b.set_tagged(not chosen_a)

	intro_done = true
	_update_status_label()


func _spawn_boost() -> void:
	if boost_spawn_marker == null:
		return
	var boost: Area2D = SPEED_BOOST_SCENE.instantiate()
	boost.position = boost_spawn_marker.position
	boost.collected.connect(_on_boost_collected)
	map_container.add_child(boost)


func _spawn_jump_boost() -> void:
	if jump_boost_spawn_marker == null:
		return
	var boost: Area2D = JUMP_BOOST_SCENE.instantiate()
	boost.position = jump_boost_spawn_marker.position
	boost.collected.connect(_on_jump_boost_collected)
	map_container.add_child(boost)


func _on_boost_collected(_body: Node2D) -> void:
	boost_respawn_timer = BOOST_RESPAWN_TIME


func _on_jump_boost_collected(_body: Node2D) -> void:
	jump_boost_respawn_timer = JUMP_BOOST_RESPAWN_TIME


func _process(delta: float) -> void:
	if game_over or not intro_done:
		return

	if boost_respawn_timer > 0.0:
		boost_respawn_timer -= delta
		if boost_respawn_timer <= 0.0:
			boost_respawn_timer = -1.0
			_spawn_boost()

	if jump_boost_respawn_timer > 0.0:
		jump_boost_respawn_timer -= delta
		if jump_boost_respawn_timer <= 0.0:
			jump_boost_respawn_timer = -1.0
			_spawn_jump_boost()

	if player_a.is_tagged:
		player_a_tagged_time += delta
	elif player_b.is_tagged:
		player_b_tagged_time += delta

	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_update_timer_label()
		_update_time_labels()
		_end_game()
		return

	_update_timer_label()
	_update_time_labels()
	_update_status_label()


func _update_timer_label() -> void:
	timer_label.text = "Time: %d" % int(ceil(time_left))


func _update_time_labels() -> void:
	time_a_label.text = "A Tagged: %.1fs" % player_a_tagged_time
	time_b_label.text = "B Tagged: %.1fs" % player_b_tagged_time


func _update_status_label() -> void:
	if player_a.is_tagged:
		status_label.text = "Player A is TAGGED!"
	else:
		status_label.text = "Player B is TAGGED!"


func _end_game() -> void:
	game_over = true

	if is_equal_approx(player_a_tagged_time, player_b_tagged_time):
		game_over_label.text = "It's a Tie!"
	else:
		var loser: String = "A" if player_a_tagged_time > player_b_tagged_time else "B"
		game_over_label.text = "Player %s Loses!\n(Tagged longest: %.1fs vs %.1fs)" % [
			loser, max(player_a_tagged_time, player_b_tagged_time), min(player_a_tagged_time, player_b_tagged_time)
		]

	game_over_panel.visible = true
	get_tree().paused = true


func _on_back_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
