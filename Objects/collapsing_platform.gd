#@tool
extends StaticBody2D

@export var width : int = 3
@export_enum("both", "left", "right", "none") var edge_type = "both"
@export_enum("gray", "red", "green") var color = "gray"

# Called when the node enters the scene tree for the first time.
func _ready():
	setup()

func setup():
	#temporary stuff for @tool
	$Center.position = Vector2(0, 0)
	$Left.visible = true
	$Right.visible = true
	
	$Solid.scale.x = width
	$PlayerDetection/CollisionShape2D.scale.x = width
	$"Center".region_rect = Rect2(0, 0, (width-2)*8, 8)
	$Right.position.x = 8 + 4*(width-3)
	$Left.position.x = -8 - 4*(width-3)
	
	#edge type setup
	if edge_type == "none":
		$"Center".region_rect = Rect2(0, 0, (width)*8, 8)
		$Left.visible = false
		$Right.visible = false
	elif edge_type == "left":
		$Center.position.x += 4
		$"Center".region_rect = Rect2(0, 0, (width-1)*8, 8)
		$Right.visible = false
	elif edge_type == "right":
		$Center.position.x -= 4
		$"Center".region_rect = Rect2(0, 0, (width-1)*8, 8)
		$Left.visible = false
	
	#color setup
	$"Center".region_rect.position = Vector2(0, 0)
	$"Left".region_rect.position = Vector2(0, 0)
	$"Right".region_rect.position = Vector2(8, 0)
	
	if color == "red":
		$"Center".region_rect.position = Vector2(0, 24)
		$"Left".region_rect.position = Vector2(0, 24)
		$"Right".region_rect.position = Vector2(8, 24)
	elif color == "green":
		$"Center".region_rect.position = Vector2(0, 48)
		$"Left".region_rect.position = Vector2(0, 48)
		$"Right".region_rect.position = Vector2(8, 48)

func _on_player_detection_body_entered(_body):
	$"Center".region_rect.position.y += 8
	$"Left".region_rect.position.y += 8
	$"Right".region_rect.position.y += 8
	await self.create_tween().tween_interval(0.2).finished
	$"Center".region_rect.position.y += 8
	$"Left".region_rect.position.y += 8
	$"Right".region_rect.position.y += 8
	await self.create_tween().tween_interval(0.2).finished
	$"Center".visible = false
	$"Left".visible = false
	$"Right".visible = false
	$Solid.disabled = true
	$PlayerDetection/CollisionShape2D.disabled = true
