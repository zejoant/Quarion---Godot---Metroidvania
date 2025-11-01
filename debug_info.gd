extends CanvasLayer

@onready var player = get_node_or_null("/root/World/Player")
@onready var world = get_node_or_null("/root/World/")

var sun_boss
var red_boss
var hermit

func _ready():
	if !player:
		queue_free()

func _process(_delta):
	$XPos.text = "x_pos: " + str(snapped(player.position.x, 0.001))
	$YPos.text = "y_pos: " + str(snapped(player.position.y, 0.001))
	$XSpeed.text = "x_speed: " + str(snapped(player.velocity.x, 0.001))
	$YSpeed.text = "y_speed: " + str(player.velocity.y)
	$CanJump.text = "can_jump: " + str(player.can_jump or (player.has_double_jump and player.can_double_jump))
	if player.has_bubble:
		$Force.text = "force: " + str(player.affecting_force)
	$JumpCount.text = "jump_count: " + str(player.jump_count)
	$DeathCount.text = "death_count: " + str(player.death_count)
	$CheckpointRoom.text = "cp_room: " + str(world.checkpoint_room)
	$CheckpointPos.text = "cp_pos: " + str(world.checkpoint_pos)
	
	if world.get_room().has_node("StarlightGuardian"):
		if !sun_boss:
			$BossLabels.visible = true
			sun_boss = world.get_room().get_node("StarlightGuardian")
		$BossLabels/Health.text = "health: " + str(sun_boss.health)
		$BossLabels/BossState.text = "boss_state: " + str(sun_boss.boss_state)
		$BossLabels/AttackState.text = "attack_state: " + str(sun_boss.attack_state)
		$BossLabels/Other1.text = "aim: " + str(sun_boss.aim)
	elif world.get_room().has_node("RedBossArea"):
		if !red_boss:
			$BossLabels.visible = true
			red_boss = world.get_room().get_node("RedBossArea")
		$BossLabels/Health.text = "health: " + str(red_boss.health)
		$BossLabels/BossState.text = "boss_state: " + str(red_boss.BossState.keys()[red_boss.boss_state])
		$BossLabels/AttackState.text = "attack_state: " + str(red_boss.attack_state)
		$BossLabels/Other1.text = "attack_sub_state: " + str(red_boss.attack_sub_state)
		$BossLabels/Other2.text = "attack_cooldown: " + str(red_boss.attack_cooldown)
	elif world.get_room().has_node("BossEnvironment/AncientHermit"):
		if !hermit:
			$BossLabels.visible = true
			hermit = world.get_room().get_node("BossEnvironment/AncientHermit")
		$BossLabels/Health.text = "health: " + str(hermit.health)
		$BossLabels/BossState.text = "boss_state: " + str(hermit.BossState.keys()[hermit.boss_state])
		$BossLabels/AttackState.text = "attack_state: " + str(hermit.attack_state)
		$BossLabels/Other1.text = "attack_sub_state: " + str(hermit.attack_sub_state)
		$BossLabels/Other2.text = "attack_cooldown: " + str(hermit.attack_cooldown)
		$BossLabels/Other3.text = "air_state: " + str(hermit.AirState.keys()[hermit.air_state])
	else:
		$BossLabels.visible = false
