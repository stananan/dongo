extends CharacterBody2D

@export var player_id: String = "a" # "a" or "b"
@export var speed: float = 480.0
@export var jump_velocity: float = -680.0
@export var gravity: float = 1500.0
@export var wall_slide_speed: float = 260.0
@export var wall_jump_push: float = 460.0
@export var wall_jump_up: float = -640.0

const CUBE_SIZE: float = 48.0
const TAG_COOLDOWN_TIME: float = 0.5
const BOOST_DURATION: float = 4.0
const BOOST_SPEED_MULTIPLIER: float = 1.8
const JUMP_BOOST_DURATION: float = 5.0
const JUMP_BOOST_MULTIPLIER: float = 1.45

const BASE_COLOR: Color = Color(0.2, 0.45, 1.0)
const TAGGED_COLOR: Color = Color(1.0, 0.2, 0.2)

var is_tagged: bool = false
var other_player: CharacterBody2D = null
var tag_cooldown: float = 0.0
var facing: int = 1
var boost_time_left: float = 0.0
var jump_boost_time_left: float = 0.0

var input_left: String
var input_right: String
var input_jump: String

@onready var tagged_label: Label = $TaggedLabel
@onready var tag_area: Area2D = $TagArea


func _ready() -> void:
	if player_id == "a":
		input_left = "move_left_a"
		input_right = "move_right_a"
		input_jump = "jump_a"
	else:
		input_left = "move_left_b"
		input_right = "move_right_b"
		input_jump = "jump_b"

	tag_area.area_entered.connect(_on_tag_area_area_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if tag_cooldown > 0.0:
		tag_cooldown -= delta

	if boost_time_left > 0.0:
		boost_time_left -= delta
		if boost_time_left < 0.0:
			boost_time_left = 0.0

	if jump_boost_time_left > 0.0:
		jump_boost_time_left -= delta
		if jump_boost_time_left < 0.0:
			jump_boost_time_left = 0.0

	var direction := 0.0
	if Input.is_action_pressed(input_left):
		direction -= 1.0
	if Input.is_action_pressed(input_right):
		direction += 1.0

	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1

	var on_wall := is_on_wall_only()
	var pressing_into_wall := on_wall and direction != 0.0 and (direction * get_wall_normal().x) < 0.0
	var just_walljumped := false

	if is_on_floor():
		velocity.y = 0.0
	elif pressing_into_wall:
		velocity.y = min(velocity.y + gravity * delta, wall_slide_speed)
	else:
		velocity.y += gravity * delta

	var jump_multiplier := JUMP_BOOST_MULTIPLIER if jump_boost_time_left > 0.0 else 1.0

	if Input.is_action_just_pressed(input_jump):
		if is_on_floor():
			velocity.y = jump_velocity * jump_multiplier
		elif on_wall:
			velocity.y = wall_jump_up * jump_multiplier
			velocity.x = get_wall_normal().x * wall_jump_push
			facing = 1 if get_wall_normal().x > 0.0 else -1
			just_walljumped = true

	if not pressing_into_wall and not just_walljumped:
		var current_speed := speed
		if boost_time_left > 0.0:
			current_speed *= BOOST_SPEED_MULTIPLIER
		velocity.x = direction * current_speed

	move_and_slide()
	queue_redraw()


func apply_speed_boost() -> void:
	boost_time_left = BOOST_DURATION


func apply_jump_boost() -> void:
	jump_boost_time_left = JUMP_BOOST_DURATION


func set_tagged(value: bool) -> void:
	is_tagged = value
	if value:
		tag_cooldown = TAG_COOLDOWN_TIME
	tagged_label.visible = value
	queue_redraw()


func _draw() -> void:
	var half := CUBE_SIZE / 2.0
	var rect := Rect2(Vector2(-half, -half), Vector2(CUBE_SIZE, CUBE_SIZE))
	var fill_color := TAGGED_COLOR if is_tagged else BASE_COLOR
	if boost_time_left > 0.0:
		fill_color = fill_color.lightened(0.35)

	draw_rect(rect, fill_color, true)
	draw_rect(rect.grow(-2.0), fill_color.lightened(0.18), false, 3.0)
	draw_rect(rect, Color(0.05, 0.05, 0.08, 0.9), false, 3.0)

	if boost_time_left > 0.0:
		draw_rect(rect.grow(5.0), Color(1.0, 0.9, 0.2, 0.9), false, 3.0)
	if jump_boost_time_left > 0.0:
		draw_rect(rect.grow(9.0), Color(0.2, 0.9, 0.35, 0.9), false, 3.0)

	var eye_shift := 6.0 * facing
	var eye_y := -8.0
	draw_circle(Vector2(-10.0 + eye_shift, eye_y), 4.5, Color.WHITE)
	draw_circle(Vector2(8.0 + eye_shift, eye_y), 4.5, Color.WHITE)
	draw_circle(Vector2(-10.0 + eye_shift + 2.0 * facing, eye_y), 2.2, Color(0.05, 0.05, 0.08))
	draw_circle(Vector2(8.0 + eye_shift + 2.0 * facing, eye_y), 2.2, Color(0.05, 0.05, 0.08))


func _on_tag_area_area_entered(area: Area2D) -> void:
	if other_player == null:
		return
	if area.get_parent() != other_player:
		return
	if not is_tagged:
		return
	if tag_cooldown > 0.0:
		return
	if other_player.tag_cooldown > 0.0:
		return

	set_tagged(false)
	other_player.set_tagged(true)
