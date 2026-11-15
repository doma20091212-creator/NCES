extends CharacterBody2D
# ده انتا

var display_name = "Student"
var frozen = false
var tired = false
var bob = 0.0


func _ready():
	collision_layer = 2
	collision_mask = 1
	var cs = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = 10
	cs.shape = c
	add_child(cs)
	z_index = 10


func _physics_process(delta):
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if frozen:
		dir = Vector2.ZERO
	var running = Input.is_action_pressed("run") and dir != Vector2.ZERO and not tired
	if running:
		Game.stamina = max(0.0, Game.stamina - delta / Config.STAMINA_SECONDS)
		if Game.stamina <= 0.0:
			tired = true
	else:
		Game.stamina = min(1.0, Game.stamina + delta / 4.0)
		if tired and Game.stamina > 0.35:
			tired = false
	var spd = Config.PLAYER_RUN if running else Config.PLAYER_WALK
	if tired:
		spd = Config.PLAYER_WALK * 0.85
	velocity = dir * spd
	move_and_slide()
	if dir != Vector2.ZERO:
		bob += delta * (14.0 if running else 9.0)
	queue_redraw()


func _draw():
	draw_circle(Vector2(0, 0), 11, Color.BLUE)
	draw_string(ThemeDB.fallback_font, Vector2(-20, -15), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
	if Game.inventory.get("football", false):
		draw_circle(Vector2(12, 8), 5, Color.WHITE)
	if Game.inventory.get("volleyball", false):
		draw_circle(Vector2(-12, 8), 5, Color.YELLOW)
