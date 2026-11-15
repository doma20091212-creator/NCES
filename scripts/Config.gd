extends Node

const GAME_TITLE = "New Cairo Escape School"
const SCHOOL_SHORT = "NCES"


const PRINCIPAL_NAME = "Mr. Mohamed Abd El-Aziz"
const DEPUTY_NAME = "Mr. Akef El-Tahawy"
const SCHOOL_CHASER_NAME = "Mrs. Fatma"   #دي مشرفة الدور اللي بتجري ورانا
const DORM_CHASER_NAME = "3m Amr"         # ده مشرف السكن غلبان صراحه مش بيعمل حاجه
const CANTEEN_NAME = "3m Emad"
const STAFF_MANAGER_NAME = "Mrs. Samah"
const PE_TEACHER_NAME = "Mr. Hany PE"    # وزير الشباب والرياضة والتربية والتعليم
const DOCTOR_NAME = "School Doctor"


const DEFAULT_BUDDY_NAME = "Youssef"   # ده اللي بيزوغ معاك وممكن تغيره يعني عادي
const CLASSMATES = ["Antika", "mahmoud ayman", "asser", "Bebo", "Sukar", "Zein", "Himer", "Keen", "Mazen Ragab", "Omar hesham", "3fifi", "Yamen", "Mo3az", "3othman", "Ahmed ramadan"]
const SEATS = {
	"G11 Class A (Your Class)": {"you": Vector2i(27, 5), "buddy": Vector2i(29, 5)},  #ده الكرسي بتاعك انتا وصاحبك
	"Chemistry Lab": {"you": Vector2i(6, 18), "buddy": Vector2i(7, 18)},
}
const SEAT_FILL_OTHER_CLASSES = 0.9   # الفصول التانيه مليانه قد اي
const SEAT_FILL_BREAK = 0.25          # الفصول فيها قد اي خلال البريك
const WANDERERS_BREAK = 12            # العيال اللي ماشية خلال البريك
const WANDERERS_SESSION = 2
const FIELD_PLAYERS_BREAK = 12        # العيال اللي بتلعب كورة
const FIELD_PLAYERS_SESSION = 8
const LOOKOUT_RANGE = 12.0            # ميس فاطمة هتمسكك ولا لا 

const TEACHERS = {
	"Arabic": "Mr. Mohamed El-Eraaky",
	"English": "Mrs. Naglaa",
	"Physics": "Mrs. Neven",
	"Chemistry": "Mr. Ayman",
	"Biology": "Mrs. Rahma",
	"Math": "Mr. Tarek Shawky",
	"Mechanics": "Mr. Essam",
}

# الناس اللي واقفين مكانهم. الحرف ده مكانهم في الماب
# none = مش بيعمل حاجه, omni = شايف كل حته, cone = شايف قدامه بس
const STAFF = {
	"E": {"name": CANTEEN_NAME, "title": "Canteen", "kind": "none", "color": "#b45309"},
	"R": {"name": PRINCIPAL_NAME, "title": "Principal", "kind": "omni", "sight": 5.0, "fill": 0.7, "color": "#111827"},
	"S": {"name": STAFF_MANAGER_NAME, "title": "Staff Management", "kind": "omni", "sight": 5.0, "fill": 0.8, "color": "#0f766e"},
	"Y": {"name": PE_TEACHER_NAME, "title": "P.E.", "kind": "cone", "sight": 7.0, "fill": 0.5, "color": "#dc2626"},
	"A": {"name": DEPUTY_NAME, "title": "Deputy", "kind": "none", "color": "#374151"},
	"O": {"name": DOCTOR_NAME, "title": "Doctor", "kind": "none", "color": "#0284c7"},
}


const SECONDS_PER_GAME_MINUTE = 1.5   # كل ما تكبرها اليوم يطول
const DAY_START = 7 * 60 + 45          # 7:45
const DAY_END = 13 * 60 + 30           # 1:30
const PERIODS = [
	{"start": 480, "end": 525, "type": "session"},
	{"start": 525, "end": 570, "type": "session"},
	{"start": 570, "end": 600, "type": "break"},
	{"start": 600, "end": 645, "type": "session", "after_break": true},
	{"start": 645, "end": 690, "type": "session"},
	{"start": 690, "end": 720, "type": "break"},
	{"start": 720, "end": 765, "type": "session", "after_break": true},
	{"start": 765, "end": 810, "type": "session"},
]
const SESSIONS_PER_DAY = 6
const SUBJECT_ROTATION = ["Physics", "Math", "Chemistry", "Arabic", "Biology", "English", "Mechanics"]
const ATTEND_MINUTES = 25.0     # لازم تقعد كام دقيقة عشان تتحسب حضرت
const LATE_MIN_MINUTES = 3.0    # تتأخر قد اي عشان مهمة التأخير

# الكيميا في المعمل والباقي في الفصل
const DEFAULT_CLASS = "G11 Class A (Your Class)"
const SUBJECT_ROOMS = {
	"Chemistry": "Chemistry Lab",
}


const MAX_STRIKES = 3
const DESERT_DRAIN = 4.0        # ده الهيلث اللي بتخسره لما تطلع دور اولي
const HEALTH_REGEN = 2.0
const CAMERA_ZOOM = 1.7

const PLAYER_WALK = 140.0
const PLAYER_RUN = 225.0
const STAMINA_SECONDS = 3.0     # ده الوقت اللي بتقدر تعمل سبرينت فيه

const CHASER_PATROL_SPEED = 80.0
const CHASER_CHASE_SPEED = 155.0
const CHASER_SIGHT = 7.0        
const CHASER_GIVE_UP = 3.5      

const TEACHER_BOARD_MIN = 3.0   # الوقت اللي المدرس بيشرح فيه قبل ما يبصلك
const TEACHER_BOARD_MAX = 6.0
const TEACHER_WATCH_MIN = 2.0
const TEACHER_WATCH_MAX = 3.5
const TEACHER_TURN_WARNING = 0.8


const MISSIONS = [
	{"id": "canteen", "title": "get 1 ful + 1 baba from 3m Emad"},
	{"id": "football", "title": "steal the ball and play in the field", "hold": 6.0},
	{"id": "dorm", "title": "sneak to the dorm (watch out for 3m Amr)"},
	{"id": "pingpong", "title": "play ping pong in the PE room with ur buddy", "hold": 6.0},
	{"id": "volleyball", "title": "take the volleyball and play it in a session", "hold": 5.0},
	{"id": "late", "title": "come late to the session after the break"},
	{"id": "noise", "title": "make noise in a session and don't get caught", "hold": 4.0},
	{"id": "catch", "title": "play catch & throw in a session with ur buddy", "hold": 5.0},
]


# الماب كلها في حته واحدة
# # = حيطة  . = ارض  * = ديسك او شجرة
# P = بتبدأ هنا  a = مكتب الوكيل  r = الدكتور  k = بيرموك هنا بعد ما تتمسك
# c = الكانتين  t = بينج بونج  b = الكورة  v = الفولي  f = نص الملعب  z = سريرك  h = سرير الدكتور
# T = المدرس  M = عم عمرو  والحروف الكابيتال التانية من STAFF
const MAP = [
	"######################################################################",
	"#..........#..........#..........#..........#..........#.............#",
	"#..........#..........#....T.....#..........#..........#.............#",
	"#..*.*.*.*.#..*.*.*.*.#..*.*.*.*.#..*.*.*.*.#..*.*.*.*.#..*.*.*.*.*..#",
	"#..........#..........#..........#..........#..........#.............#",
	"#..*.*.*.*.#..*.*.*.*.#..*.*.*.*.#..*.*.*.*.#..*.*.*.*.#..*.*.*.*.*..#",
	"#..........#..........#..........#..........#..........#.............#",
	"#..........#..........#..........#..........#..........#.............#",
	"######.##########.##########.##########.##########.###########.#######",
	"#....................................................................#",
	"#....................................................................#",
	"#....................................................................#",
	"#####.########.########.#####...#####.######.######.######.######.####",
	"#.........#.......#........#.....#......#......#......#......#.......#",
	"#....T....#.......#....E...#.....#...R..#...S..#...A..#......#.....b.#",
	"#.........#.......#.***c***#.....#.****.#.****.#.****.#.O..h.#.tt....#",
	"#.***.***.#..**.*.#........#.....#......#......#......#....h.#.......#",
	"#.........#.......#........#..P..#......#......#......#......#...Y...#",
	"#.***.***.#..**.*.#........#.....#......#......#...a..#......#.......#",
	"#.........#.......#........#.....#......#......#......#..r...#....v..#",
	"#.........#.......#........#.....#......#......#......#......#.......#",
	"##############################X#######################################",
	"#....................................................................#",
	"#.*...........................k........................*............*#",
	"#.....................................*.......................*......#",
	"#....................................................................#",
	"#...........................................########################.#",
	"#...........................................#.......#.......#......#.#",
	"#...........................................#.*...*.#.*...*.#......#.#",
	"#...........................................#.......#.......#...M..#.#",
	"#.*.....................................*...#.......#.......#......#.#",
	"#...........................................#.......#.......#......#.#",
	"#...........................................####.#######.######.####.#",
	"#...................f.......................G......................#.#",
	"#..................................................................#.#",
	"#...........................................#####.##########.#######.#",
	"#...........................................#.........#............#.#",
	"#......................................*....#.........#............#.#",
	"#.*.........................................#.........#............#.#",
	"#...........................................#......zz.#............#.#",
	"#...........................................#.........#............#.#",
	"#.........*..............*...............*..########################.#",
	"#....................................................................#",
	"######################################################################",
]

const FLOOR_COLOR = "#cfc8b8"

# الاوض: الاسم و [x, y, العرض, الطول] واللون
# restricted = ممنوع تتشاف فيها, safe = محدش يقدر يعملك حاجه, desert = بتخسر هيلث, dorm = السكن
const ROOMS = [
	{"name": "G12 Class A", "rect": [1, 1, 10, 7], "color": "#c7d3e6"},
	{"name": "G12 Class B", "rect": [12, 1, 10, 7], "color": "#c7d3e6"},
	{"name": "G11 Class A (Your Class)", "rect": [23, 1, 10, 7], "color": "#cdd9c4"},
	{"name": "G11 Class B", "rect": [34, 1, 10, 7], "color": "#cdd9c4"},
	{"name": "G10 Class A", "rect": [45, 1, 10, 7], "color": "#e3c48d", "desert": true},
	{"name": "G10 Class B", "rect": [56, 1, 13, 7], "color": "#e3c48d", "desert": true},
	{"name": "Chemistry Lab", "rect": [1, 13, 9, 8], "color": "#cfe3dc"},
	{"name": "Fab Lab", "rect": [11, 13, 7, 8], "color": "#b9c7d6"},
	{"name": "3m Emad's Canteen", "rect": [19, 13, 8, 8], "color": "#e8c9a0"},
	{"name": "Lobby", "rect": [28, 13, 5, 8], "color": "#d8d2c4"},
	{"name": "Principal's Office", "rect": [34, 13, 6, 8], "color": "#c9b3d9"},
	{"name": "Staff Management", "rect": [41, 13, 6, 8], "color": "#b8d8c8"},
	{"name": "Deputy Office", "rect": [48, 13, 6, 8], "color": "#d9c3b0"},
	{"name": "Doctor Room", "rect": [55, 13, 6, 8], "color": "#e9eef2", "safe": true},
	{"name": "P.E. Room", "rect": [62, 13, 7, 8], "color": "#9fc5a8", "restricted": true},
	{"name": "Football Field", "rect": [4, 25, 32, 16], "color": "#4f9a4a", "pitch": true},
	{"name": "Room 101", "rect": [45, 27, 7, 5], "color": "#d6cbe0", "dorm": true},
	{"name": "Room 102", "rect": [53, 27, 7, 5], "color": "#d6cbe0", "dorm": true},
	{"name": "Supervisor Office", "rect": [61, 27, 6, 5], "color": "#cbb8a0", "dorm": true},
	{"name": "Dorm Hall", "rect": [45, 33, 22, 2], "color": "#cdbfa8", "dorm": true},
	{"name": "Your Room", "rect": [45, 36, 9, 5], "color": "#f0d9b5", "dorm": true},
	{"name": "Common Room", "rect": [55, 36, 12, 5], "color": "#d6cbe0", "dorm": true},
	{"name": "Outside", "rect": [1, 22, 68, 21], "color": "#6fae5f"},
]

const MARKER_LABELS = {
	"X": "main door", "G": "dorm door",
	"c": "3m Emad", "t": "ping pong", "z": "ur bed", "h": "bed",
}

func mission(id):
	for m in MISSIONS:
		if m["id"] == id:
			return m
	return {}
