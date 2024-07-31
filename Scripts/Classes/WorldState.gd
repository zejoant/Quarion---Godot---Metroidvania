extends Resource
class_name WorldState

#player positions
@export var checkpoint_room : Vector2
@export var checkpoint_pos : Vector2

#player states
@export var has_dash : bool
@export var has_double_jump : bool
@export var has_wall_climb : bool
@export var has_blue_blocks : bool
@export var has_freeze : bool

#world states
@export var collected_item_positions := PackedVector2Array()
@export var map := PackedVector2Array()

#boss states
@export var red_boss_state : int
@export var secret_boss_state : int



