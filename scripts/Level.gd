extends Node2D
# بيحول الماب اللي في Config لحيطان وارضية

const TILE = 32
const SOLID = "#*ctzh "
const INTERACT = "cbvtfzh"

var grid = []
var w = 0
var h = 0
var rooms = []
var markers = {}
var astar
var patrol_cells = []
var dorm_cells = []


func setup():
	grid = Config.MAP
	h = grid.size()
	w = grid[0].length()
	rooms = Config.ROOMS
	# بندور على الحروف
	for y in h:
		for x in w:
			var c = Vector2i(x, y)
			var ch = char_at(c)
			if ch != "#" and ch != "." and ch != "*" and ch != " ":
				if not markers.has(ch):
					markers[ch] = []
				markers[ch].append(c)
			if not is_solid(c):
				var room = room_at(c)
				if room.get("dorm", false):
					dorm_cells.append(c)
				elif not room.get("restricted", false):
					patrol_cells.append(c)
	make_walls()
	make_astar()
	queue_redraw()


func char_at(c):
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return "#"
	return grid[c.y][c.x]


func is_solid(c):
	return SOLID.contains(char_at(c))


func cell_to_pos(c):
	return Vector2(c.x * TILE + 16, c.y * TILE + 16)


func pos_to_cell(p):
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


func room_at(c):
	for r in rooms:
		var rr = r["rect"]
		if c.x >= rr[0] and c.y >= rr[1] and c.x < rr[0] + rr[2] and c.y < rr[1] + rr[3]:
			return r
	return {}


func desks_in(room):
	var rr = room["rect"]
	var out = []
	for y in range(rr[1], rr[1] + rr[3]):
		for x in range(rr[0], rr[0] + rr[2]):
			if char_at(Vector2i(x, y)) == "*":
				out.append(Vector2i(x, y))
	return out


func first_marker(ch):
	return markers[ch][0]


func make_walls():
	var body = StaticBody2D.new()
	add_child(body)
	for y in h:
		for x in w:
			if is_solid(Vector2i(x, y)):
				var cs = CollisionShape2D.new()
				var rect = RectangleShape2D.new()
				rect.size = Vector2(TILE, TILE)
				cs.shape = rect
				cs.position = cell_to_pos(Vector2i(x, y))
				body.add_child(cs)


func make_astar():
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, w, h)
	astar.cell_size = Vector2(TILE, TILE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in h:
		for x in w:
			if is_solid(Vector2i(x, y)):
				astar.set_point_solid(Vector2i(x, y), true)


func find_path(from, to):
	if is_solid(from) or is_solid(to):
		return []
	var ids = astar.get_id_path(from, to)
	var out = []
	for i in range(1, ids.size()):
		out.append(ids[i])
	return out


func random_patrol_cell():
	return patrol_cells.pick_random()


func random_cell_far_from(c, min_dist):
	for i in 50:
		var p = patrol_cells.pick_random()
		if abs(p.x - c.x) + abs(p.y - c.y) >= min_dist:
			return p
	return patrol_cells.pick_random()


# بيشوف في حيطة في النص ولا لا
func has_los(a, b):
	var x0 = a.x
	var y0 = a.y
	var dx = abs(b.x - a.x)
	var dy = -abs(b.y - a.y)
	var sx = 1
	if a.x > b.x:
		sx = -1
	var sy = 1
	if a.y > b.y:
		sy = -1
	var err = dx + dy
	while true:
		if not (x0 == a.x and y0 == a.y) and not (x0 == b.x and y0 == b.y):
			if char_at(Vector2i(x0, y0)) == "#":
				return false
		if x0 == b.x and y0 == b.y:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return true


func find_interactable_near(c):
	for d in [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var cc = c + d
		var ch = char_at(cc)
		if INTERACT.contains(ch):
			if ch == "b" and not Game.ball_available("football"):
				continue
			if ch == "v" and not Game.ball_available("volleyball"):
				continue
			return {"ch": ch, "cell": cc}
	return {}


# الرسم
func _draw():
	var font = ThemeDB.fallback_font
	for y in h:
		for x in w:
			var ch = char_at(Vector2i(x, y))
			var r = Rect2(x * TILE, y * TILE, TILE, TILE)
			if ch == "#":
				draw_rect(r, Color(0.3, 0.3, 0.3))
				continue
			var room = room_at(Vector2i(x, y))
			var col = Color(Config.FLOOR_COLOR)
			if room.size() > 0:
				col = Color(room["color"])
			draw_rect(r, col)
			if ch == "*":
				if room.get("name", "") == "Outside":
					draw_circle(r.get_center(), 13, Color.DARK_GREEN)
				else:
					draw_rect(r.grow(-4), Color.SADDLE_BROWN)
			if ch == "X" or ch == "G":
				draw_rect(r, Color.DARK_RED)
			if ch == "c":
				draw_rect(r, Color.ORANGE)
			if ch == "t":
				draw_rect(r, Color.DARK_GREEN)
			if ch == "z" or ch == "h":
				draw_rect(r, Color.WHITE)
			if ch == "b" and Game.ball_available("football"):
				draw_circle(r.get_center(), 7, Color.WHITE)
			if ch == "v" and Game.ball_available("volleyball"):
				draw_circle(r.get_center(), 7, Color.YELLOW)
			if ch == "f":
				draw_circle(r.get_center(), 5, Color.WHITE)
			if Config.MARKER_LABELS.has(ch):
				draw_string(font, r.position + Vector2(-4, -2), Config.MARKER_LABELS[ch], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.BLACK)
	# خطوط الملعب
	for room in rooms:
		if room.get("pitch", false):
			var rr = room["rect"]
			var p = Rect2(rr[0] * TILE, rr[1] * TILE, rr[2] * TILE, rr[3] * TILE)
			draw_rect(p, Color.WHITE, false, 2)
			draw_line(Vector2(p.get_center().x, p.position.y), Vector2(p.get_center().x, p.end.y), Color.WHITE, 2)
			draw_arc(p.get_center(), 70, 0, TAU, 30, Color.WHITE, 2)
			draw_rect(Rect2(p.position.x - 10, p.get_center().y - 48, 10, 96), Color.WHITE, false, 2)
			draw_rect(Rect2(p.end.x, p.get_center().y - 48, 10, 96), Color.WHITE, false, 2)
	# اسامي الاوض
	for room in rooms:
		var rr = room["rect"]
		var txt = room["name"]
		if room.get("desert", false):
			txt += " (DESERT - ur health goes down here)"
		draw_string(font, Vector2(rr[0] * TILE + 4, rr[1] * TILE + 14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
