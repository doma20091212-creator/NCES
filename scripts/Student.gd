extends CharacterBody2D
# الطلبة. seat = قاعد, wander = بيلف, buddy = صاحبك, play = بيلعب كورة

var level
var player
var mode = "seat"
var display_name = ""
var always_show_name = false
var is_buddy = false
var shirt = Color.WHITE
var speed = 70.0
var target = Vector2.ZERO
var path = []
var repath = 0.0
var wait = 0.0
var bob = 0.0


func _ready():
	z_index = 7
	if mode == "wander" or mode == "buddy":
		collision_layer = 8
		collision_mask = 1
		var cs = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = 8
		cs.shape = c
		add_child(cs)
	else:
		collision_layer = 0
		collision_mask = 0
	if mode == "buddy":
		z_index = 9
	wait = randf_range(0.0, 2.0)


func _physics_process(delta):
	match mode:
		"wander":
			if _follow(speed):
				wait -= delta
				if wait <= 0.0:
					wait = randf_range(1.0, 4.0)
					path = level.find_path(level.pos_to_cell(position), level.random_patrol_cell())
		"buddy":
			_buddy(delta)
		"play":
			var to = target - position
			if to.length() > 3.0:
				position += to.normalized() * min(speed * delta, to.length())
				bob += delta * 12.0
	queue_redraw()


func _buddy(delta):
	var d = position.distance_to(player.position)
	if d > 500.0:
		position = player.position
		path.clear()
		return
	if d < 38.0:
		velocity = Vector2.ZERO
		return
	var running = Input.is_action_pressed("run")
	var spd = Config.PLAYER_RUN if running else Config.PLAYER_WALK * 1.1
	var my = level.pos_to_cell(position)
	var pc = level.pos_to_cell(player.position)
	if d < 80.0 and level.has_los(my, pc):
		velocity = position.direction_to(player.position) * spd
		move_and_slide()
	else:
		repath -= delta
		if repath <= 0.0:
			repath = 0.25
			path = level.find_path(my, pc)
		_follow(spd)
	bob += delta * (14.0 if running else 9.0)


func _follow(spd):
	while not path.is_empty() and position.distance_to(level.cell_to_pos(path[0])) < 4.0:
		path.pop_front()
	if path.is_empty():
		velocity = Vector2.ZERO
		return true
	velocity = position.direction_to(level.cell_to_pos(path[0])) * spd
	move_and_slide()
	bob += get_physics_process_delta_time() * 9.0
	return false


func _draw():
	draw_circle(Vector2(0, 0), 9, shirt)
	if is_buddy:
		draw_arc(Vector2(0, 0), 12, 0, TAU, 20, Color.GREEN, 2)
	var show = always_show_name
	if display_name != "" and player != null and is_instance_valid(player):
		if position.distance_to(player.position) < 80:
			show = true
	if show and display_name != "":
		draw_string(ThemeDB.fallback_font, Vector2(-20, -13), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.BLACK)
