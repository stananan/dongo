extends Area2D

signal collected(body)

var pulse_time: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	collision_shape.shape = shape


func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()


func _draw() -> void:
	var s := 14.0 + sin(pulse_time * 6.0) * 2.5
	var points := PackedVector2Array([
		Vector2(0, -s), Vector2(s * 0.9, s * 0.75), Vector2(-s * 0.9, s * 0.75), Vector2(0, -s)
	])
	draw_colored_polygon(points, Color(0.15, 0.85, 0.3))
	draw_polyline(points, Color(0.75, 1.0, 0.8), 2.5)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("apply_jump_boost"):
		body.apply_jump_boost()
		collected.emit(body)
		queue_free()
