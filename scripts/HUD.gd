extends CanvasLayer
# كل اللي على الشاشة

signal start_pressed(player_name, buddy_name)

var name_edit
var buddy_edit
var title_screen
var end_screen
var hud

var clock_label
var period_label
var status_label
var strikes_label
var health_bar
var stamina_bar
var bag_label
var buddy_label
var missions_label
var prompt_box
var prompt_label
var progress_bar
var toast_box
var toast_label
var toasts = []
var dialog_box
var dialog_label
var end_title
var end_body


func _ready():
	layer = 10

	# ---- الهود ----
	hud = Control.new()
	hud.size = Vector2(1280, 720)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	add_child(hud)

	# فوق شمال
	var box1 = PanelContainer.new()
	box1.position = Vector2(5, 5)
	hud.add_child(box1)
	var v1 = VBoxContainer.new()
	box1.add_child(v1)
	clock_label = Label.new()
	v1.add_child(clock_label)
	period_label = Label.new()
	v1.add_child(period_label)
	status_label = Label.new()
	v1.add_child(status_label)

	# فوق يمين
	var box2 = PanelContainer.new()
	box2.position = Vector2(1010, 5)
	box2.custom_minimum_size = Vector2(265, 0)
	hud.add_child(box2)
	var v2 = VBoxContainer.new()
	box2.add_child(v2)
	strikes_label = Label.new()
	v2.add_child(strikes_label)
	var l1 = Label.new()
	l1.text = "health"
	v2.add_child(l1)
	health_bar = ProgressBar.new()
	v2.add_child(health_bar)
	var l2 = Label.new()
	l2.text = "stamina"
	v2.add_child(l2)
	stamina_bar = ProgressBar.new()
	v2.add_child(stamina_bar)
	bag_label = Label.new()
	v2.add_child(bag_label)
	buddy_label = Label.new()
	v2.add_child(buddy_label)

	# المهمات تحت شمال
	var box3 = PanelContainer.new()
	box3.position = Vector2(5, 480)
	hud.add_child(box3)
	missions_label = Label.new()
	box3.add_child(missions_label)

	# الرسايل اللي بتظهر فوق
	toast_box = PanelContainer.new()
	toast_box.position = Vector2(400, 110)
	toast_box.custom_minimum_size = Vector2(480, 0)
	toast_box.visible = false
	hud.add_child(toast_box)
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_box.add_child(toast_label)

	# اللي تحت في النص
	prompt_box = PanelContainer.new()
	prompt_box.position = Vector2(390, 640)
	prompt_box.custom_minimum_size = Vector2(500, 0)
	prompt_box.visible = false
	hud.add_child(prompt_box)
	var v3 = VBoxContainer.new()
	prompt_box.add_child(v3)
	progress_bar = ProgressBar.new()
	progress_bar.visible = false
	v3.add_child(progress_bar)
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v3.add_child(prompt_label)

	# ---- بوكس الكلام ----
	dialog_box = PanelContainer.new()
	dialog_box.position = Vector2(140, 530)
	dialog_box.custom_minimum_size = Vector2(1000, 150)
	dialog_box.visible = false
	add_child(dialog_box)
	var v4 = VBoxContainer.new()
	dialog_box.add_child(v4)
	dialog_label = Label.new()
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialog_label.custom_minimum_size = Vector2(990, 110)
	dialog_label.add_theme_font_size_override("font_size", 20)
	v4.add_child(dialog_label)
	var hint = Label.new()
	hint.text = "press enter"
	v4.add_child(hint)

	# ---- اول شاشة ----
	title_screen = VBoxContainer.new()
	title_screen.position = Vector2(440, 120)
	title_screen.custom_minimum_size = Vector2(400, 0)
	add_child(title_screen)
	var t = Label.new()
	t.text = Config.GAME_TITLE
	t.add_theme_font_size_override("font_size", 40)
	t.modulate = Color.YELLOW
	title_screen.add_child(t)
	var s = Label.new()
	s.text = Config.SCHOOL_SHORT + " - skip class and don't get caught"
	title_screen.add_child(s)
	var q = Label.new()
	q.text = "\nur name:"
	title_screen.add_child(q)
	name_edit = LineEdit.new()
	name_edit.text_submitted.connect(func(_t): buddy_edit.grab_focus())
	title_screen.add_child(name_edit)
	var q2 = Label.new()
	q2.text = "ur buddy (who's skipping with u):"
	title_screen.add_child(q2)
	buddy_edit = LineEdit.new()
	buddy_edit.placeholder_text = Config.DEFAULT_BUDDY_NAME
	buddy_edit.text_submitted.connect(func(_t): start_pressed.emit(name_edit.text, buddy_edit.text))
	title_screen.add_child(buddy_edit)
	var b = Button.new()
	b.text = "START"
	b.pressed.connect(func(): start_pressed.emit(name_edit.text, buddy_edit.text))
	title_screen.add_child(b)
	var c = Label.new()
	c.text = "\nWASD = move\nshift = run\nE = do stuff\nQ = send ur buddy back\n1 / 2 / 3 in class = noise / catch & throw / volleyball\n(only when the teacher isn't looking!!)"
	title_screen.add_child(c)

	# ---- اخر شاشة ----
	end_screen = ColorRect.new()
	end_screen.color = Color.BLACK
	end_screen.size = Vector2(1280, 720)
	end_screen.visible = false
	add_child(end_screen)
	end_title = Label.new()
	end_title.position = Vector2(450, 200)
	end_title.add_theme_font_size_override("font_size", 50)
	end_screen.add_child(end_title)
	end_body = Label.new()
	end_body.position = Vector2(450, 300)
	end_body.add_theme_font_size_override("font_size", 20)
	end_screen.add_child(end_body)
	var again = Label.new()
	again.text = "press enter to play again"
	again.position = Vector2(450, 450)
	end_screen.add_child(again)


func _process(delta):
	# الرسايل بتختفي بعد 3 ثواني
	if toasts.size() > 0:
		for i in range(toasts.size() - 1, -1, -1):
			toasts[i][1] -= delta
			if toasts[i][1] <= 0:
				toasts.remove_at(i)
		var txt = ""
		for tt in toasts:
			txt += tt[0] + "\n"
		toast_label.text = txt.strip_edges()
		toast_box.visible = toasts.size() > 0


func show_title():
	title_screen.visible = true
	hud.visible = false
	name_edit.grab_focus()


func hide_title():
	title_screen.visible = false
	hud.visible = true
	name_edit.release_focus()
	buddy_edit.release_focus()


func show_dialog(text):
	dialog_label.text = text
	dialog_box.visible = true
	hud.visible = false   # عشان الكلام يبان


func hide_dialog():
	dialog_box.visible = false
	hud.visible = true


func show_end(title_text, body, win):
	end_title.text = title_text
	if win:
		end_title.modulate = Color.GREEN
	else:
		end_title.modulate = Color.RED
	end_body.text = body
	end_screen.visible = true


func set_location(text):
	# المكان بيظهر في البوكس اللي فوق
	period_label.set_meta("where", text)


func set_prompt(text):
	prompt_label.text = text
	prompt_box.visible = text != "" or progress_bar.visible


func set_progress(value):
	if value < 0:
		progress_bar.visible = false
	else:
		progress_bar.visible = true
		progress_bar.value = value * 100
	prompt_box.visible = prompt_label.text != "" or progress_bar.visible


func show_toast(text):
	toasts.append([text, 3.0])
	if toasts.size() > 4:
		toasts.remove_at(0)


func refresh(period_text, status_text, status_color):
	clock_label.text = Game.player_name + "  |  day " + str(Game.day) + "  |  " + Game.format_time(Game.minutes)
	period_label.text = str(period_label.get_meta("where", "")) + "\n" + period_text
	status_label.text = status_text
	status_label.modulate = status_color
	strikes_label.text = "caught: " + str(Game.strikes) + "/" + str(Config.MAX_STRIKES)
	health_bar.value = Game.health
	stamina_bar.value = Game.stamina * 100
	var bag = ""
	if Game.inventory.get("ful", false):
		bag += "ful "
	if Game.inventory.get("baba", false):
		bag += "baba "
	if Game.inventory.get("football", false):
		bag += "football "
	if Game.inventory.get("volleyball", false):
		bag += "volleyball "
	if bag == "":
		bag = "nothing"
	bag_label.text = "bag: " + bag
	if Game.buddy_following:
		buddy_label.text = Game.buddy_name + " is with u\n[Q] send him back"
	else:
		buddy_label.text = Game.buddy_name + " is in class\n(go to him + press E)"
	var txt = "missions  (attended " + str(Game.attended) + " / skipped " + str(Game.skipped) + ")\n"
	var i = 1
	for m in Config.MISSIONS:
		if Game.mission_done.get(m["id"], false):
			txt += "[X] "
		else:
			txt += "[  ] "
		txt += str(i) + ". " + m["title"]
		if not Game.mission_done.get(m["id"], false) and m.has("hold") and Game.mission_progress.get(m["id"], 0.0) > 0:
			txt += "  (" + str(int(100 * Game.mission_progress[m["id"]] / m["hold"])) + "%)"
		txt += "\n"
		i += 1
	missions_label.text = txt.strip_edges()
