extends Node
class_name SaveGame

#respawn pos
static var checkpoint_room: Vector2
static var checkpoint_pos: Vector2

#player states
static var has_dash: bool
static var has_double_jump: bool
static var has_wall_climb: bool
static var has_blue_blocks: bool
static var has_freeze: bool
static var amulet_pieces: String
static var has_shop_fast_travel: bool
static var has_item_map: bool
static var has_bubble: bool

static var green_key_state: String
static var red_key_state: String

#world state
static var room_state: Array

#map state
static var map_rooms: Array
static var map_items: Array


