extends Sprite2D

@onready var follow_node = get_node("/root/World/Player/Sprite2D")

var pos_array: Array[Vector2]
var scale_array: Array[Vector2]
var region_array: Array[Rect2]

var follow_distance: int = 15

var invis_count: int

func _ready():
	invis_count = 0
	pos_array.resize(follow_distance)
	scale_array.resize(follow_distance)
	region_array.resize(follow_distance)

func _physics_process(_delta):
	pos_array.push_front(follow_node.global_position)#Vector2(follow_node.global_position.x - follow_offset, follow_node.global_position.y))
	scale_array.push_front(follow_node.scale)
	region_array.push_front(follow_node.region_rect)
	
	if pos_array[1].distance_to(follow_node.global_position) > 20*8:
		pos_array.fill(follow_node.global_position)
		invis_count = follow_distance

	if pos_array[follow_distance-1]:
		global_position = pos_array[follow_distance-1]
	if scale_array[follow_distance-1]:
		scale = scale_array[follow_distance-1]
	if region_array[follow_distance-1]:
		region_rect = region_array[follow_distance-1]
	
	if invis_count:
		visible = false
		invis_count -= 1
		if !invis_count:
			visible = true
