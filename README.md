# NCES - New Cairo Escape School

a game about skipping class at NCSS without getting caught lol

everything is on one map now. school building on top, football field and the dorm outside

## how to run
open godot -> import -> pick project.godot -> press F5

## controls
- WASD / arrows = move
- shift = run (u get tired tho)
- E = do stuff (canteen, balls, ping pong, beds, take ur buddy)
- 1 / 2 / 3 in class = noise / catch & throw / volleyball (ONLY when the teacher is writing on the board)
- Q = send ur buddy back to class
- enter = next

## rules
- Mrs. Fatma walks around everywhere. if she sees u outside class in a session or with a stolen ball she runs after u. run away or go back to class
- Mr. Hany PE sees whatever he's facing (the red thing). the PE room is not allowed at all
- the principal and Mrs. Samah catch u if u pass by their office while ur skipping
- 3m Amr stays in the dorm and catches u if u go in
- the G10 classes are a desert, u lose health there. if it hits 0 u faint and wake up at the doctor
- u get caught = deputy office, Mr. Akef kicks u out. 3 times = expelled

## files
- scripts/Config.gd -> names, times, the map, missions (change whatever u want here)
- scripts/Main.gd -> the main game
- scripts/Level.gd -> makes the map
- scripts/Player.gd -> u
- scripts/Chaser.gd -> Mrs. Fatma + 3m Amr
- scripts/Watcher.gd -> teachers and staff
- scripts/Student.gd -> students + ur buddy
- scripts/FieldMatch.gd -> the football match
- scripts/HUD.gd -> everything on the screen
- scripts/Game.gd -> time, strikes, ur bag
