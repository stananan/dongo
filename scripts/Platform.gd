extends StaticBody2D

@export var size: Vector2 = Vector2(200, 32)
@export var color: Color = Color(0.35, 0.65, 0.35)

@onready var color_rect: ColorRect = $ColorRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape
	collision_shape.position = Vector2.ZERO

	color_rect.size = size
	color_rect.position = -size / 2.0
	color_rect.color = color
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bevel: float = max(3.0, size.y * 0.18)

	var highlight := ColorRect.new()
	highlight.size = Vector2(size.x, bevel)
	highlight.position = -size / 2.0
	highlight.color = color.lightened(0.35)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highlight)

	var shadow := ColorRect.new()
	shadow.size = Vector2(size.x, bevel)
	shadow.position = Vector2(-size.x / 2.0, size.y / 2.0 - bevel)
	shadow.color = color.darkened(0.35)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), Color(0.05, 0.05, 0.08, 0.85), false, 2.0)
