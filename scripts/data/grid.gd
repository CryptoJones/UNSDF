class_name Grid
extends RefCounted
## Static grid constants + helpers. One screen == one room == the whole viewport.
## 320x240 viewport / 16px tiles = 20 columns x 15 rows.

const TILE := 16
const COLS := 20
const ROWS := 15
const SCREEN := Vector2(COLS * TILE, ROWS * TILE)   # 320 x 240

# The painted rooms carry a ~2-cell wall border around an open floor, so the
# walkable interior is inset by this many cells on every side (door tunnels
# excepted).
const WALL_INSET := 2

# Door gaps are centered on each wall, two cells wide. The interior spawn cell
# is the tile just inside that gap (past the wall border).
const NS_DOOR_COLS := [9, 10]   # north/south gap columns
const EW_DOOR_ROWS := [7, 8]    # east/west gap rows


static func cell_to_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE * 0.5, cell.y * TILE + TILE * 0.5)


static func dir_vec(side: String) -> Vector2i:
	match side:
		"north": return Vector2i(0, -1)
		"south": return Vector2i(0, 1)
		"west": return Vector2i(-1, 0)
		"east": return Vector2i(1, 0)
	return Vector2i.ZERO


static func opposite(side: String) -> String:
	match side:
		"north": return "south"
		"south": return "north"
		"west": return "east"
		"east": return "west"
	return ""


## Tile just inside the door gap on the given side — where the player materializes
## when they enter a room from that side.
static func spawn_cell_for(side: String) -> Vector2i:
	match side:
		"north": return Vector2i(NS_DOOR_COLS[0], WALL_INSET)
		"south": return Vector2i(NS_DOOR_COLS[0], ROWS - 1 - WALL_INSET)
		"west": return Vector2i(WALL_INSET, EW_DOOR_ROWS[0])
		"east": return Vector2i(COLS - 1 - WALL_INSET, EW_DOOR_ROWS[0])
	return Vector2i(COLS / 2, ROWS / 2)
