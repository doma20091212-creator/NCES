extends Node
# هنا كل حاجة الجيم فاكرها (الوقت والمسكات والشنطة)

signal toast(text)

var player_name = "Student"
var buddy_name = "Youssef"
var buddy_following = false
var minutes = 0.0
var day = 1
var strikes = 0
var health = 100.0
var stamina = 1.0
var inventory = {}
var mission_done = {}
var mission_progress = {}
var attended = 0
var skipped = 0
var session_presence = 0.0
var entered_this_session = false
var period_index = -1
var mischief_timer = 0.0

# دول بيتحدثوا كل فريم من Main
var player_room = ""
var player_in_dorm = false
var player_trouble = false


func _ready():
	# الزراير
	add_key("move_up", [KEY_W, KEY_UP])
	add_key("move_down", [KEY_S, KEY_DOWN])
	add_key("move_left", [KEY_A, KEY_LEFT])
	add_key("move_right", [KEY_D, KEY_RIGHT])
	add_key("run", [KEY_SHIFT])
	add_key("interact", [KEY_E])
	add_key("act1", [KEY_1])
	add_key("act2", [KEY_2])
	add_key("act3", [KEY_3])
	add_key("buddy", [KEY_Q])
	add_key("advance", [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER])
	reset()


func add_key(action, keys):
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev = InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func reset():
	minutes = Config.DAY_START
	day = 1
	strikes = 0
	health = 100.0
	stamina = 1.0
	inventory = {}
	mission_done = {}
	mission_progress = {}
	attended = 0
	skipped = 0
	session_presence = 0.0
	entered_this_session = false
	period_index = -1
	mischief_timer = 0.0
	buddy_following = false
	player_room = ""
	player_in_dorm = false
	player_trouble = false


# ---- الوقت والجدول ----
func get_period_index():
	for i in Config.PERIODS.size():
		var p = Config.PERIODS[i]
		if minutes >= p["start"] and minutes < p["end"]:
			return i
	return -1


func current_period():
	var i = get_period_index()
	if i == -1:
		return {}
	return Config.PERIODS[i]


func is_session():
	return current_period().get("type", "") == "session"


func subject_for(idx):
	# بنعد الحصص اللي قبلها
	var n = 0
	for i in idx:
		if Config.PERIODS[i]["type"] == "session":
			n += 1
	n += (day - 1) * Config.SESSIONS_PER_DAY
	return Config.SUBJECT_ROTATION[n % Config.SUBJECT_ROTATION.size()]


func current_subject():
	var i = get_period_index()
	if i == -1:
		return ""
	return subject_for(i)


func class_room():
	# الفصل اللي المفروض تكون فيه دلوقتي
	return Config.SUBJECT_ROOMS.get(current_subject(), Config.DEFAULT_CLASS)


func in_class():
	return is_session() and player_room == class_room()


func format_time(m):
	var mi = int(m)
	return "%02d:%02d" % [mi / 60, mi % 60]


# ---- المشاكل ----
func has_stolen_stuff():
	return inventory.get("football", false) or inventory.get("volleyball", false)


func ball_available(id):
	return not inventory.get(id, false) and not mission_done.get(id, false)


# انتا في مشكلة ولا لا؟ لو اه اي حد يشوفك يمسكك
func compute_trouble(room):
	if mischief_timer > 0:
		return true
	if room.get("dorm", false):
		return true
	if room.get("restricted", false):
		return true
	if is_session() and not in_class() and not room.get("safe", false):
		return true
	if has_stolen_stuff() and not in_class():
		return true
	return false


func all_missions_done():
	for m in Config.MISSIONS:
		if not mission_done.get(m["id"], false):
			return false
	return true
