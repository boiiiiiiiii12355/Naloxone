extends BTAction



func _tick(delta: float) -> Status:
	agent.test_fire()
	return SUCCESS
