extends Node2D

signal spotted(by_name)

var level
var player
var display_name = ""
var title = ""
var kind = "none"
var body_color = Color.PURPLE
var sight = 5.0
var fill_time = 0.6
var facing = Vector2.DOWN
var room_name = ""
var meter = 0.0
var fired = false
var tstate = "board"   
var timer = 2.0

const DIRS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]


func _ready():
	z_index = 8
	if kind == "teacher":
		timer = randf_range(Config.TEACHER_BOARD_MIN, Config.TEACHER_BOARD_MAX)
		facing = Vector2.UP
	else:
		timer = randf_range(1.5, 3.0)


func _process(delta):
	var sees = false
	match kind:
		"teacher":
			timer -= delta
			if timer <= 0.0:
				match tstate:
					"board":
						tstate = "turning"
						timer = Config.TEACHER_TURN_WARNING
					"turning":
						tstate = "watching"
						timer = randf_range(Config.TEACHER_WATCH_MIN, Config.TEACHER_WATCH_MAX)
					_:
						tstate = "board"
						timer = randf_range(Config.TEACHER_BOARD_MIN, Config.TEACHER_BOARD_MAX)
			facing = Vector2.DOWN if tstate == "watching" else Vector2.UP
			sees = tstate == "watching" and Game.player_trouble and Game.player_room == room_name
		"omni":
			sees = Game.player_trouble and _can_see(false)
		"cone":
			timer -= delta
			if timer <= 0.0:
				facing = DIRS.pick_random()
				timer = randf_range(1.8, 3.5)
			sees = Game.player_trouble and _can_see(true)
	if sees:
		meter += delta / fill_time
	else:
		meter = max(0.0, meter - delta * 0.7)
	if meter >= 1.0 and not fired:
		fired = true
		spotted.emit(display_name)
	queue_redraw()


func _can_see(cone):
	if player == null or level == null:
		return false
	var to = player.global_position - global_position
	if to.length() > sight * 32.0:
		return false
	if cone and to.length() > 6.0 and abs(facing.angle_to(to)) > deg_to_rad(50):
		return false
	return level.has_los(level.pos_to_cell(global_position), level.pos_to_cell(player.global_position))


func _draw():
	# المثلث الاحمر ده اللي بيشوفه
	if kind == "cone":
		var pts = PackedVector2Array([Vector2.ZERO])
		for i in 9:
			var a = facing.angle() - deg_to_rad(50) + deg_to_rad(100) * i / 8.0
			pts.append(Vector2.from_angle(a) * sight * 32.0)
		draw_colored_polygon(pts, Color(1, 0, 0, 0.2))
	draw_circle(Vector2(0, 0), 12, body_color)
	draw_line(Vector2(0, 0), facing * 16, Color.BLACK, 2)
	draw_string(ThemeDB.fallback_font, Vector2(-25, -16), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.BLACK)
	if kind == "teacher":
		var txt = title + " - writing on board"
		var col = Color.DARK_GREEN
		if tstate == "turning":
			txt = "turning..."
			col = Color.ORANGE
		if tstate == "watching":
			txt = "LOOKING!!"
			col = Color.RED
		draw_string(ThemeDB.fallback_font, Vector2(-25, 26), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(-25, 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.BLACK)
	if meter > 0:
		draw_rect(Rect2(-15, -38, 30 * meter, 5), Color.RED)
