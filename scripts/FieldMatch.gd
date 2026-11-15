extends Node2D
# الماتش اللي شغال في الملعب

const StudentScript = preload("res://scripts/Student.gd")

var level
var player
var pitch = Rect2()
var ball = Vector2.ZERO
var ball_vel = Vector2.ZERO
var kids = []
var homes = []
var teams = []
var kick_cd = []
var score = [0, 0]
var goal_timer = 0.0
var goal_text = ""

const TEAM_COLORS = [Color("#dc2626"), Color("#facc15")]


func setup(count):
	z_index = 6
	ball = pitch.get_center()
	var c = pitch.get_center()
	for i in count:
		var team = i % 2
		var s = StudentScript.new()
		s.mode = "play"
		s.level = level
		s.player = player
		s.shirt = TEAM_COLORS[team]
		s.speed = randf_range(95.0, 125.0)
		var hx
		if team == 0:
			hx = lerp(pitch.position.x + 50.0, c.x - 30.0, randf())
		else:
			hx = lerp(c.x + 30.0, pitch.end.x - 50.0, randf())
		var home = Vector2(hx, lerp(pitch.position.y + 40.0, pitch.end.y - 40.0, randf()))
		homes.append(home)
		teams.append(team)
		kick_cd.append(0.0)
		s.position = home
		s.target = home
		add_child(s)
		kids.append(s)


func _goal_y_ok(y):
	return abs(y - pitch.get_center().y) < 1.5 * 32.0


func _physics_process(delta):
	# الكورة
	ball += ball_vel * delta
	ball_vel *= pow(0.35, delta)
	if ball.y < pitch.position.y + 6.0 or ball.y > pitch.end.y - 6.0:
		ball_vel.y = -ball_vel.y
		ball.y = clamp(ball.y, pitch.position.y + 6.0, pitch.end.y - 6.0)
	if ball.x < pitch.position.x + 4.0:
		if _goal_y_ok(ball.y):
			_goal(1)
		else:
			ball_vel.x = abs(ball_vel.x)
			ball.x = pitch.position.x + 4.0
	elif ball.x > pitch.end.x - 4.0:
		if _goal_y_ok(ball.y):
			_goal(0)
		else:
			ball_vel.x = -abs(ball_vel.x)
			ball.x = pitch.end.x - 4.0

	# لو خبطت فيها بتشوطها
	if player != null and player.position.distance_to(ball) < 18.0:
		var push = (ball - player.position).normalized()
		ball_vel = push * 230.0 + player.velocity * 0.6

	# اقرب واحد من كل تيم بيجري ورا الكورة والباقي واقفين مكانهم تقريبا
	var chaser = [-1, -1]
	var best = [INF, INF]
	for i in kids.size():
		var d = kids[i].position.distance_to(ball)
		if d < best[teams[i]]:
			best[teams[i]] = d
			chaser[teams[i]] = i
	var c = pitch.get_center()
	for i in kids.size():
		kick_cd[i] = max(0.0, kick_cd[i] - delta)
		var k = kids[i]
		if i == chaser[teams[i]]:
			k.target = ball
		else:
			k.target = homes[i] + Vector2((ball.x - c.x) * 0.4, (ball.y - c.y) * 0.3)
		if k.position.distance_to(ball) < 14.0 and kick_cd[i] <= 0.0:
			var goal_x = pitch.end.x if teams[i] == 0 else pitch.position.x
			var dir = (Vector2(goal_x, c.y) - ball).normalized().rotated(randf_range(-0.7, 0.7))
			ball_vel = dir * randf_range(180.0, 320.0)
			kick_cd[i] = 0.4

	goal_timer = max(0.0, goal_timer - delta)
	queue_redraw()


func _goal(team):
	score[team] += 1
	goal_text = "GOAL!  %d - %d" % [score[0], score[1]]
	goal_timer = 2.0
	ball = pitch.get_center()
	ball_vel = Vector2(randf_range(-60, 60), randf_range(-60, 60))


func _draw():
	draw_circle(ball, 6, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(pitch.get_center().x - 45, pitch.position.y - 6), "red " + str(score[0]) + " - " + str(score[1]) + " yellow", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	if goal_timer > 0:
		draw_string(ThemeDB.fallback_font, pitch.get_center() + Vector2(-50, -60), goal_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.YELLOW)
