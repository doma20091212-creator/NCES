extends CharacterBody2D
# ميس فاطمة و عم عمرو - بيلفوا ولو شافوك بيجروا وراك

signal caught_player(by_name)

var level
var player
var display_name = "Mrs. Fatma"
var title = "Supervisor"
var body_color = Color.DEEP_PINK
var patrol_speed = Config.CHASER_PATROL_SPEED
var chase_speed = Config.CHASER_CHASE_SPEED
var sight = Config.CHASER_SIGHT

var state = "patrol"   # patrol / chase / search / leave
var path = []
var repath = 0.0
var lost = 0.0
var last_seen = Vector2i.ZERO
var wait = 1.0
var bob = 0.0
var dorm_only = false   # عم عمرو مش بيطلع من السكن


func _ready():
	collision_layer = 4
	collision_mask = 1
	var cs = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = 10
	cs.shape = c
	add_child(cs)
	z_index = 9


func start_chase(cell):
	state = "chase"
	last_seen = cell
	lost = 0.0
	repath = 0.0


func _sees_player():
	if not Game.player_trouble:
		return false
	if dorm_only and not Game.player_in_dorm:
		return false
	if global_position.distance_to(player.global_position) > sight * 32.0:
		return false
	return level.has_los(level.pos_to_cell(global_position), level.pos_to_cell(player.global_position))


func _physics_process(delta):
	if level == null or player == null:
		return
	var pc = level.pos_to_cell(player.global_position)
	var sees = _sees_player()
	if sees:
		if state != "chase":
			Game.toast.emit("%s saw u!! RUN" % display_name)
		state = "chase"
		last_seen = pc
		lost = 0.0
	match state:
		"chase":
			if not sees:
				lost += delta
				if lost > Config.CHASER_GIVE_UP:
					state = "search"
					wait = 2.5
					_path_to(last_seen)
					Game.toast.emit("%s lost u... she's looking for u" % display_name)
			repath -= delta
			if repath <= 0.0 and state == "chase":
				repath = 0.25
				_path_to(pc if sees else last_seen)
			if sees and global_position.distance_to(player.global_position) < 40.0:
				velocity = global_position.direction_to(player.global_position) * chase_speed
				move_and_slide()
			else:
				_follow(chase_speed)
			if state == "chase" and global_position.distance_to(player.global_position) < 22.0:
				caught_player.emit(display_name)
		"search":
			if _follow(patrol_speed * 1.4):
				wait -= delta
				if wait <= 0.0:
					state = "patrol"
					path.clear()
		_:
			if _follow(patrol_speed):
				wait -= delta
				if wait <= 0.0:
					wait = randf_range(0.5, 2.0)
					if dorm_only:
						_path_to(level.dorm_cells.pick_random())
					else:
						_path_to(level.random_patrol_cell())
	if velocity.length() > 1.0:
		bob += delta * (14.0 if state == "chase" else 8.0)
	queue_redraw()


func _path_to(cell):
	path = level.find_path(level.pos_to_cell(global_position), cell)


func _follow(speed):
	while not path.is_empty() and global_position.distance_to(level.cell_to_pos(path[0])) < 4.0:
		path.pop_front()
	if path.is_empty():
		velocity = Vector2.ZERO
		return true
	velocity = global_position.direction_to(level.cell_to_pos(path[0])) * speed
	move_and_slide()
	return false


func _draw():
	draw_circle(Vector2(0, 0), 12, body_color)
	draw_string(ThemeDB.fallback_font, Vector2(-25, -16), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
	if state == "chase":
		draw_string(ThemeDB.fallback_font, Vector2(-4, -30), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.RED)
	if state == "search":
		draw_string(ThemeDB.fallback_font, Vector2(-4, -30), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.ORANGE)
