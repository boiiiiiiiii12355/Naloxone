extends BTAction



func _tick(delta: float) -> Status:
	var stop_shoot_chance = randi_range(0, 1)
	agent.test_fire()
	if stop_shoot_chance == 0:
		return SUCCESS
	else:
		return FAILURE
