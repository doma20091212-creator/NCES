extends Node2D
# الملف الكبير. هنا الجيم كله ماشي

const LevelScript = preload("res://scripts/Level.gd")
const PlayerScript = preload("res://scripts/Player.gd")
const ChaserScript = preload("res://scripts/Chaser.gd")
const WatcherScript = preload("res://scripts/Watcher.gd")
const HUDScript = preload("res://scripts/HUD.gd")
const StudentScript = preload("res://scripts/Student.gd")
const FieldMatchScript = preload("res://scripts/FieldMatch.gd")

var world
var level
var player
var camera
var hud
var fatma
var amr
var staff = []
var teachers = []
var students = []
var buddy = null
var buddy_seat = null
var lookout_cd = 0.0

var state = "title"   # title / playing / dialog / over
var catching = false
var dialog_lines = []
var dialog_done = null


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	hud = HUDScript.new()
	add_child(hud)
	hud.start_pressed.connect(start_game)
	Game.toast.connect(hud.show_toast)
	hud.show_title()


func start_game(name_text, buddy_text = ""):
	if state != "title":
		return
	Game.reset()
	Game.player_name = name_text.strip_edges()
	if Game.player_name == "":
		Game.player_name = "Student"
	Game.buddy_name = buddy_text.strip_edges()
	if Game.buddy_name == "":
		Game.buddy_name = Config.DEFAULT_BUDDY_NAME
	hud.hide_title()

	# الماب
	level = LevelScript.new()
	world.add_child(level)
	level.setup()

	# انتا
	player = PlayerScript.new()
	player.display_name = Game.player_name
	player.position = level.cell_to_pos(level.first_marker("P"))
	level.add_child(player)
	camera = Camera2D.new()
	camera.zoom = Vector2(Config.CAMERA_ZOOM, Config.CAMERA_ZOOM)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = level.w * 32
	camera.limit_bottom = level.h * 32
	player.add_child(camera)
	camera.make_current()

	spawn_staff()
	spawn_fatma()
	spawn_field_match()
	Game.period_index = Game.get_period_index()
	refresh_teachers()
	refresh_students()
	state = "playing"
	update_hud()
	dialog([
		"ahlan ya %s, welcome to %s" % [Game.player_name, Config.SCHOOL_SHORT],
		"ur class is %s. first session at 8:00... attend it or don't, ur choice" % Config.DEFAULT_CLASS,
		"watch out for %s!! if she sees u outside class or with stolen stuff RUN (shift). get out of her sight or go back to class and ur safe" % Config.SCHOOL_CHASER_NAME,
		"%s is sitting next to ur seat. go to him and press E to take him with u. he'll tell u if %s is coming + u need him for ping pong and catch & throw" % [Game.buddy_name, Config.SCHOOL_CHASER_NAME],
		"if u get caught %d times %s will kick u out for real" % [Config.MAX_STRIKES, Config.DEPUTY_NAME],
		"do all 8 missions (bottom left) and ur a legend. yalla",
	])


# ---- الناس ----
func spawn_staff():
	for ch in Config.STAFF.keys():
		for c in level.markers.get(ch, []):
			var d = Config.STAFF[ch]
			var wt = WatcherScript.new()
			wt.level = level
			wt.player = player
			wt.display_name = d["name"]
			wt.title = d["title"]
			wt.kind = d["kind"]
			wt.sight = d.get("sight", 5.0)
			wt.fill_time = d.get("fill", 0.6)
			wt.body_color = Color(d["color"])
			wt.position = level.cell_to_pos(c)
			wt.spotted.connect(got_caught)
			level.add_child(wt)
			staff.append(wt)
	# عم عمرو
	amr = ChaserScript.new()
	amr.level = level
	amr.player = player
	amr.display_name = Config.DORM_CHASER_NAME
	amr.body_color = Color.DARK_GREEN
	amr.chase_speed = Config.CHASER_CHASE_SPEED - 10
	amr.dorm_only = true
	amr.position = level.cell_to_pos(level.first_marker("M"))
	amr.caught_player.connect(got_caught)
	level.add_child(amr)


func spawn_fatma():
	fatma = ChaserScript.new()
	fatma.level = level
	fatma.player = player
	fatma.display_name = Config.SCHOOL_CHASER_NAME
	fatma.caught_player.connect(got_caught)
	level.add_child(fatma)
	reset_fatma()


func reset_fatma():
	# بنرجعها حته بعيدة عنك
	fatma.position = level.cell_to_pos(level.random_cell_far_from(level.pos_to_cell(player.position), 25))
	fatma.state = "patrol"
	fatma.path = []


func refresh_teachers():
	for t in teachers:
		t.queue_free()
	teachers.clear()
	if not Game.is_session():
		return
	for c in level.markers.get("T", []):
		if level.room_at(c).get("name", "") != Game.class_room():
			continue
		var subj = Game.current_subject()
		var t = WatcherScript.new()
		t.level = level
		t.player = player
		t.display_name = Config.TEACHERS.get(subj, "Teacher")
		t.title = subj
		t.kind = "teacher"
		t.fill_time = 0.35
		t.room_name = Game.class_room()
		t.body_color = Color.PURPLE
		t.position = level.cell_to_pos(c)
		t.spotted.connect(got_caught)
		level.add_child(t)
		teachers.append(t)


func make_student(mode, pos, seed_val):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	var s = StudentScript.new()
	s.mode = mode
	s.level = level
	s.player = player
	s.position = pos
	s.shirt = Color.from_hsv(rng.randf_range(0.5, 0.65), rng.randf_range(0.1, 0.45), rng.randf_range(0.75, 0.97))
	s.speed = rng.randf_range(55.0, 80.0)
	return s


func refresh_students():
	for s in students:
		s.queue_free()
	students.clear()
	if buddy_seat != null:
		buddy_seat.queue_free()
		buddy_seat = null
	var session = Game.is_session()
	var home = Config.DEFAULT_CLASS
	if session:
		home = Game.class_room()
	for room in level.rooms:
		var rname = room["name"]
		if not (rname.contains("Class") or rname.contains("Lab")):
			continue
		var seats = Config.SEATS.get(rname, {})
		var fill = 0.0
		if seats.size() > 0:
			if session and home == rname:
				fill = 1.0
			elif not session and rname == Config.DEFAULT_CLASS:
				fill = Config.SEAT_FILL_BREAK
		elif rname == "Fab Lab":
			if session:
				fill = 0.5
			else:
				fill = 0.1
		else:
			if session:
				fill = Config.SEAT_FILL_OTHER_CLASSES
			else:
				fill = Config.SEAT_FILL_BREAK
		var desks = level.desks_in(room)
		for i in desks.size():
			var d = desks[i]
			var seat_pos = level.cell_to_pos(d) + Vector2(0, 10)
			var seed_val = d.x * 1000 + d.y
			if seats.get("you", Vector2i(-1, -1)) == d:
				continue
			if seats.get("buddy", Vector2i(-1, -1)) == d:
				# صاحبك
				if not Game.buddy_following and home == rname:
					buddy_seat = make_student("seat", seat_pos, seed_val)
					buddy_seat.display_name = Game.buddy_name
					buddy_seat.always_show_name = true
					buddy_seat.is_buddy = true
					level.add_child(buddy_seat)
				continue
			var rng = RandomNumberGenerator.new()
			rng.seed = seed_val + Game.period_index * 7919 + Game.day * 104729
			if rng.randf() >= fill:
				continue
			var s = make_student("seat", seat_pos, seed_val)
			if seats.size() > 0:
				s.display_name = Config.CLASSMATES[i % Config.CLASSMATES.size()]
			level.add_child(s)
			students.append(s)
	# العيال اللي بتلف
	var n = Config.WANDERERS_BREAK
	if session:
		n = Config.WANDERERS_SESSION
	for i in n:
		var wd = make_student("wander", level.cell_to_pos(level.random_patrol_cell()), randi())
		level.add_child(wd)
		students.append(wd)


func spawn_field_match():
	for room in level.rooms:
		if room.get("pitch", false):
			var rr = room["rect"]
			var fm = FieldMatchScript.new()
			fm.level = level
			fm.player = player
			fm.pitch = Rect2(rr[0] * 32, rr[1] * 32, rr[2] * 32, rr[3] * 32)
			level.add_child(fm)
			fm.setup(Config.FIELD_PLAYERS_BREAK)


# ---- صاحبك ----
func spawn_buddy(pos):
	buddy = make_student("buddy", pos, 12345)
	buddy.display_name = Game.buddy_name
	buddy.always_show_name = true
	buddy.is_buddy = true
	level.add_child(buddy)


func recruit_buddy():
	if Game.in_class():
		Game.mischief_timer = 0.8   # اتنين خارجين من الفصل مع بعض؟ مش هتعدي
	Game.buddy_following = true
	buddy_seat.queue_free()
	buddy_seat = null
	spawn_buddy(player.position)
	Game.toast.emit("%s: yalla bina" % Game.buddy_name)


func dismiss_buddy(msg):
	Game.buddy_following = false
	if buddy != null:
		buddy.queue_free()
		buddy = null
	if msg != "":
		Game.toast.emit(msg)
	refresh_students()


func buddy_near(tiles = 4.0):
	return buddy != null and buddy.position.distance_to(player.position) < tiles * 32


func update_lookout(delta):
	lookout_cd -= delta
	if lookout_cd > 0 or not buddy_near(8.0) or fatma.state == "chase":
		return
	var to = fatma.position - player.position
	if to.length() > Config.LOOKOUT_RANGE * 32:
		return
	lookout_cd = 8.0
	var where = "up"
	if abs(to.x) > abs(to.y):
		if to.x > 0:
			where = "right"
		else:
			where = "left"
	elif to.y > 0:
		where = "down"
	Game.toast.emit("%s: psst!! %s is coming, look %s" % [Game.buddy_name, Config.SCHOOL_CHASER_NAME, where])


# ده بيشتغل كل فريم
func _process(delta):
	if state != "playing" or get_tree().paused:
		return
	var dm = delta / Config.SECONDS_PER_GAME_MINUTE
	Game.minutes += dm
	check_period()
	if state != "playing":
		return
	var pcell = level.pos_to_cell(player.position)
	var room = level.room_at(pcell)
	Game.player_room = room.get("name", "")
	Game.player_in_dorm = room.get("dorm", false)
	Game.mischief_timer = max(0.0, Game.mischief_timer - delta)
	do_actions(delta, pcell)
	if state != "playing":
		return
	Game.player_trouble = Game.compute_trouble(room)

	# اتأخرت؟
	if Game.in_class():
		Game.session_presence += dm
		if not Game.entered_this_session:
			Game.entered_this_session = true
			var p = Game.current_period()
			var late = Game.minutes - p["start"]
			if p.get("after_break", false) and late >= Config.LATE_MIN_MINUTES:
				complete("late", "came in %d mins late like nothing happened lol" % int(late))
				if state != "playing":
					return

	# الصحرا
	if room.get("desert", false):
		Game.health -= Config.DESERT_DRAIN * delta
		if Game.health <= 0:
			faint()
			return
	else:
		Game.health = min(100.0, Game.health + Config.HEALTH_REGEN * delta)

	update_lookout(delta)
	update_hud()


func check_period():
	var idx = Game.get_period_index()
	if idx != Game.period_index:
		var prev = Game.period_index
		Game.period_index = idx
		# الحصة اللي خلصت
		if prev >= 0 and Config.PERIODS[prev]["type"] == "session":
			var subj = Game.subject_for(prev)
			if Game.session_presence >= Config.ATTEND_MINUTES:
				Game.attended += 1
				Game.toast.emit("attended %s" % subj)
			else:
				Game.skipped += 1
				Game.toast.emit("u got marked ABSENT from %s lol" % subj)
		# الحصة الجديدة
		if idx >= 0:
			var p = Config.PERIODS[idx]
			if p["type"] == "session":
				Game.session_presence = 0.0
				Game.entered_this_session = Game.player_room == Game.class_room()
				var subj2 = Game.current_subject()
				Game.toast.emit("BELL!! %s with %s in %s" % [subj2, Config.TEACHERS.get(subj2, "?"), Game.class_room()])
			else:
				Game.toast.emit("BREAK!! till %s" % Game.format_time(p["end"]))
		refresh_teachers()
		refresh_students()
	if Game.minutes >= Config.DAY_END:
		end_day()


func end_day():
	Game.day += 1
	Game.minutes = Config.DAY_START
	Game.period_index = -1
	Game.health = 100.0
	dialog([
		"last bell!! school's over for today",
		"day %d. back to %s again... (ur missions and strikes stay)" % [Game.day, Config.SCHOOL_SHORT],
	], back_to_lobby)


func back_to_lobby():
	player.position = level.cell_to_pos(level.first_marker("P"))
	reset_fatma()


func do_actions(delta, pcell):
	var prompt = ""
	var holding = ""
	var near = level.find_interactable_near(pcell)
	var pressed = Input.is_action_just_pressed("interact")
	var held = Input.is_action_pressed("interact")

	# صاحبك
	if Game.buddy_following and Input.is_action_just_pressed("buddy"):
		dismiss_buddy("%s went back to class" % Game.buddy_name)
	if buddy_seat != null and player.position.distance_to(buddy_seat.position) < 46:
		prompt = "[E] tell %s yalla" % Game.buddy_name
		if pressed:
			recruit_buddy()
			pressed = false

	if near.size() > 0:
		var ch = near["ch"]
		if ch == "c":
			prompt = "[E] buy from %s" % Config.CANTEEN_NAME
			if pressed:
				canteen()
		if ch == "b":
			prompt = "[E] take the ball"
			if pressed:
				Game.inventory["football"] = true
				Game.mischief_timer = 0.8
				Game.toast.emit("got the ball!! go to the field")
				level.queue_redraw()
		if ch == "v":
			prompt = "[E] take the volleyball"
			if pressed:
				Game.inventory["volleyball"] = true
				Game.mischief_timer = 0.8
				Game.toast.emit("volleyball in ur bag. play it in a session (press 3)")
				level.queue_redraw()
		if ch == "t" and not Game.mission_done.get("pingpong", false):
			if buddy_near():
				prompt = "hold [E] play ping pong with %s" % Game.buddy_name
				if held:
					holding = "pingpong"
			else:
				prompt = "u can't play ping pong alone bro, bring %s" % Game.buddy_name
		if ch == "f" and not Game.mission_done.get("football", false):
			if Game.inventory.get("football", false):
				prompt = "hold [E] play"
				if held:
					holding = "football"
			else:
				prompt = "u need a ball (it's in the PE room)"
		if ch == "z" and not Game.mission_done.get("dorm", false):
			prompt = "[E] jump on ur bed"
			if pressed:
				complete("dorm", "made it to the dorm. sleeping time")
				return
		if ch == "h":
			prompt = "[E] lay down (full health)"
			if pressed:
				Game.health = 100.0
				Game.toast.emit("%s: ur fine, just drink water" % Config.DOCTOR_NAME)

	# في الفصل
	if Game.in_class():
		var opts = []
		if not Game.mission_done.get("noise", false):
			opts.append("hold [1] make noise")
			if Input.is_action_pressed("act1"):
				holding = "noise"
		if not Game.mission_done.get("catch", false):
			if buddy_near(6.0):
				opts.append("hold [2] catch & throw with %s" % Game.buddy_name)
				if Input.is_action_pressed("act2"):
					holding = "catch"
			else:
				opts.append("(catch & throw = bring %s)" % Game.buddy_name)
		if not Game.mission_done.get("volleyball", false) and Game.inventory.get("volleyball", false):
			opts.append("hold [3] volleyball")
			if Input.is_action_pressed("act3"):
				holding = "volleyball"
		if opts.size() > 0 and prompt == "":
			prompt = "   ".join(opts) + "   (only when the teacher isn't looking!!)"

	player.frozen = holding != ""
	if holding != "":
		Game.mischief_timer = max(Game.mischief_timer, 0.15)
		var m = Config.mission(holding)
		Game.mission_progress[holding] = Game.mission_progress.get(holding, 0.0) + delta
		hud.set_progress(Game.mission_progress[holding] / m["hold"])
		if Game.mission_progress[holding] >= m["hold"]:
			var msgs = {
				"pingpong": "ping pong champion",
				"football": "GOOOOOAL",
				"noise": "everyone heard it and nobody knows it was u",
				"catch": "nobody saw anything",
				"volleyball": "volleyball in class?? ur crazy",
			}
			hud.set_progress(-1)
			player.frozen = false
			complete(holding, msgs[holding])
	else:
		hud.set_progress(-1)
	hud.set_prompt(prompt)


func canteen():
	if not Game.inventory.get("ful", false):
		Game.inventory["ful"] = true
		Game.toast.emit("%s: 1 ful, here u go" % Config.CANTEEN_NAME)
	elif not Game.inventory.get("baba", false):
		Game.inventory["baba"] = true
		Game.toast.emit("%s: and 1 baba, bel hana" % Config.CANTEEN_NAME)
		complete("canteen", "ful + baba DONE")
	else:
		Game.toast.emit("%s: u already got ur food, yalla go" % Config.CANTEEN_NAME)


func complete(id, msg):
	if Game.mission_done.get(id, false):
		return
	Game.mission_done[id] = true
	print("mission done: ", id)
	if id == "football" or id == "volleyball":
		Game.inventory.erase(id)
	Game.toast.emit("mission done: " + Config.mission(id)["title"])
	if msg != "":
		Game.toast.emit(msg)
	level.queue_redraw()
	if Game.all_missions_done():
		dialog([
			"u did it ya %s, ALL the missions" % Game.player_name,
			"%s will remember u forever" % Config.SCHOOL_SHORT,
		], win)


func update_hud():
	var p = Game.current_period()
	var period_text = ""
	var status = "free time"
	var col = Color.GREEN
	if p.size() == 0:
		if Game.minutes < Config.PERIODS[0]["start"]:
			period_text = "school starts at %s" % Game.format_time(Config.PERIODS[0]["start"])
		else:
			period_text = "school is over"
	elif p["type"] == "session":
		var subj = Game.current_subject()
		period_text = "%s - %s (%s) till %s" % [subj, Config.TEACHERS.get(subj, "?"), Game.class_room(), Game.format_time(p["end"])]
		if Game.in_class():
			status = "in class. ur safe (for now)"
		elif Game.player_room == "Doctor Room":
			status = "at the doctor, ur excused"
		else:
			status = "SKIPPING CLASS!! don't let anyone see u"
			col = Color.RED
	else:
		period_text = "BREAK till %s" % Game.format_time(p["end"])
	if Game.player_trouble and status == "free time":
		status = "u shouldn't be here!!"
		col = Color.ORANGE
	if fatma.state == "chase":
		status += "\n%s IS AFTER U!!" % Config.SCHOOL_CHASER_NAME.to_upper()
		col = Color.RED
	if amr.state == "chase":
		status += "\n%s IS AFTER U!!" % Config.DORM_CHASER_NAME.to_upper()
		col = Color.RED
	if Game.health < 100 and level.room_at(level.pos_to_cell(player.position)).get("desert", false):
		status += "\nit's sooo hot here (losing health)"
	var where = Game.player_room
	if where == "":
		where = "corridor"
	hud.set_location(where)
	hud.refresh(period_text, status, col)


# اتمسكت :(
func got_caught(by_name):
	if state != "playing" or catching:
		return
	catching = true
	print("caught by ", by_name)
	Game.strikes += 1
	Game.inventory.erase("football")
	Game.inventory.erase("volleyball")
	Game.mischief_timer = 0.0
	player.frozen = false
	hud.set_progress(-1)
	hud.set_prompt("")
	level.queue_redraw()
	var had_buddy = Game.buddy_following
	if had_buddy:
		dismiss_buddy("")
	# على مكتب الوكيل
	player.position = level.cell_to_pos(level.first_marker("a"))
	reset_fatma()
	amr.state = "patrol"
	amr.path = []
	amr.position = level.cell_to_pos(level.first_marker("M"))
	for wt in staff + teachers:
		wt.meter = 0.0
		wt.fired = false
	var dep = Config.DEPUTY_NAME
	var lines = [
		"%s caught u!!" % by_name,
		"and now ur going to the deputy office...",
		"%s: %s?! what were u doing outside??" % [dep, Game.player_name],
	]
	if had_buddy:
		lines.insert(2, "%s got sent back to class" % Game.buddy_name)
	if Game.strikes >= Config.MAX_STRIKES:
		lines.append("%s: that's %d times. ur EXPELLED from %s. khalas" % [dep, Game.strikes, Config.SCHOOL_SHORT])
		dialog(lines, game_over)
	else:
		lines.append("%s: that's %d out of %d. now get out of my school!!" % [dep, Game.strikes, Config.MAX_STRIKES])
		lines.append("(u got kicked out. %d more and ur done)" % (Config.MAX_STRIKES - Game.strikes))
		dialog(lines, kicked_out)


func kicked_out():
	player.position = level.cell_to_pos(level.first_marker("k"))
	catching = false


func faint():
	Game.health = 60.0
	Game.minutes += 10.0
	player.position = level.cell_to_pos(level.first_marker("r"))
	dialog([
		"the G10 classes were too hot and u fainted lol",
		"%s: drink water and don't stay up there too long" % Config.DOCTOR_NAME,
	])


func game_over():
	state = "over"
	get_tree().paused = true
	var done = 0
	for m in Config.MISSIONS:
		if Game.mission_done.get(m["id"], false):
			done += 1
	hud.show_end("EXPELLED", "%s got kicked out of %s on day %d\nmissions: %d/%d\nattended %d, skipped %d" % [
		Game.player_name, Config.SCHOOL_SHORT, Game.day, done, Config.MISSIONS.size(), Game.attended, Game.skipped], false)


func win():
	state = "over"
	get_tree().paused = true
	hud.show_end("LEGEND OF %s" % Config.SCHOOL_SHORT, "%s did all %d missions in %d day(s)\ngot caught %d times\nattended %d, skipped %d" % [
		Game.player_name, Config.MISSIONS.size(), Game.day, Game.strikes, Game.attended, Game.skipped], true)


# ---- الكلام ----
func dialog(lines, on_done = null):
	dialog_lines = lines.duplicate()
	dialog_done = on_done
	state = "dialog"
	get_tree().paused = true
	hud.set_prompt("")
	hud.show_dialog(dialog_lines.pop_front())


func _unhandled_input(event):
	if state == "dialog" and event.is_action_pressed("advance"):
		get_viewport().set_input_as_handled()
		if dialog_lines.size() == 0:
			hud.hide_dialog()
			get_tree().paused = false
			state = "playing"
			var cb = dialog_done
			dialog_done = null
			if cb is Callable:
				cb.call()
		else:
			hud.show_dialog(dialog_lines.pop_front())
	elif state == "over" and event.is_action_pressed("advance"):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		Game.reset()
		get_tree().reload_current_scene()
