extends RefCounted

# Procedurally builds an enclosed, intentionally asymmetric arena.
# A random theme (color palette) is picked automatically; every platform
# position, size, and the pickup spots are randomized fresh each match.

const PLATFORM_SCENE: PackedScene = preload("res://scenes/Platform.tscn")

const THEMES: Array[Dictionary] = [
	{"bg": Color(0.15, 0.2, 0.3), "wall": Color(0.32, 0.24, 0.18), "ground": Color(0.4, 0.3, 0.2), "platform": Color(0.45, 0.65, 0.4)},
	{"bg": Color(0.2, 0.14, 0.24), "wall": Color(0.26, 0.2, 0.3), "ground": Color(0.3, 0.25, 0.35), "platform": Color(0.6, 0.4, 0.7)},
	{"bg": Color(0.12, 0.22, 0.18), "wall": Color(0.22, 0.3, 0.18), "ground": Color(0.28, 0.36, 0.22), "platform": Color(0.4, 0.7, 0.45)},
	{"bg": Color(0.1, 0.14, 0.24), "wall": Color(0.16, 0.2, 0.34), "ground": Color(0.2, 0.24, 0.4), "platform": Color(0.35, 0.55, 0.85)},
	{"bg": Color(0.24, 0.16, 0.12), "wall": Color(0.36, 0.26, 0.16), "ground": Color(0.45, 0.35, 0.2), "platform": Color(0.85, 0.55, 0.25)},
]

const X_MIN: float = 75.0
const X_MAX: float = 1205.0
const Y_MIN: float = 110.0
const Y_MAX: float = 560.0

# Padding used when checking for overlap between platforms: generous vertical
# padding leaves real jump clearance instead of stacking platforms right on
# top of each other; horizontal padding keeps a walkable/jumpable gap.
const PAD_X: float = 60.0
const PAD_Y: float = 100.0
const MAX_PLACEMENT_ATTEMPTS: int = 24


static func generate() -> Node2D:
	randomize()

	var theme: Dictionary = THEMES[randi_range(0, THEMES.size() - 1)]

	var map := Node2D.new()
	map.name = "GeneratedMap"

	var background := ColorRect.new()
	background.size = Vector2(1280, 720)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.color = theme["bg"]
	map.add_child(background)

	_add_block(map, Vector2(640, 705), Vector2(1300, 50), theme["ground"])
	_add_block(map, Vector2(15, 360), Vector2(30, 760), theme["wall"])
	_add_block(map, Vector2(1265, 360), Vector2(30, 760), theme["wall"])
	_add_block(map, Vector2(640, 15), Vector2(1300, 30), theme["wall"])

	var platform_rects: Array[Rect2] = []
	var platform_count: int = randi_range(8, 12)
	var base_color: Color = theme["platform"]

	for i in platform_count:
		var width: float = randf_range(90.0, 150.0)
		var height: float = randf_range(20.0, 26.0)
		var pos := Vector2.ZERO
		var attempts := 0
		var placed := false

		while attempts < MAX_PLACEMENT_ATTEMPTS and not placed:
			pos = Vector2(
				randf_range(X_MIN + width / 2.0, X_MAX - width / 2.0),
				randf_range(Y_MIN, Y_MAX)
			)
			var candidate := Rect2(pos - Vector2(width, height) / 2.0, Vector2(width, height))
			var padded := candidate.grow_individual(PAD_X, PAD_Y, PAD_X, PAD_Y)
			placed = true
			for existing in platform_rects:
				if padded.intersects(existing):
					placed = false
					break
			attempts += 1

		platform_rects.append(Rect2(pos - Vector2(width, height) / 2.0, Vector2(width, height)))

		var hue_shift: float = randf_range(-0.06, 0.06)
		var platform_color := Color.from_hsv(
			fmod(base_color.h + hue_shift + 1.0, 1.0), base_color.s, base_color.v
		)
		_add_block(map, pos, Vector2(width, height), platform_color)

	var spawn_a := Marker2D.new()
	spawn_a.name = "SpawnA"
	spawn_a.position = Vector2(randf_range(90.0, 220.0), 650.0)
	map.add_child(spawn_a)

	var spawn_b := Marker2D.new()
	spawn_b.name = "SpawnB"
	spawn_b.position = Vector2(randf_range(1060.0, 1190.0), 650.0)
	map.add_child(spawn_b)

	var boost := Marker2D.new()
	boost.name = "BoostSpawn"

	var jump_boost := Marker2D.new()
	jump_boost.name = "JumpBoostSpawn"

	if platform_rects.is_empty():
		boost.position = Vector2(480.0, 360.0)
		jump_boost.position = Vector2(800.0, 360.0)
	else:
		var boost_idx: int = randi_range(0, platform_rects.size() - 1)
		boost.position = platform_rects[boost_idx].get_center() + Vector2(0, -30)

		var jump_idx: int = boost_idx
		if platform_rects.size() > 1:
			while jump_idx == boost_idx:
				jump_idx = randi_range(0, platform_rects.size() - 1)
		jump_boost.position = platform_rects[jump_idx].get_center() + Vector2(0, -30)

	map.add_child(boost)
	map.add_child(jump_boost)

	return map


static func _add_block(parent: Node2D, pos: Vector2, size: Vector2, color: Color) -> void:
	var block := PLATFORM_SCENE.instantiate()
	block.position = pos
	block.size = size
	block.color = color
	parent.add_child(block)
