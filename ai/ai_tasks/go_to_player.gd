extends BTAction


func _tick(delta: float) -> Status:
	blackboard.set_var("move_to_pos", agent.player.global_position)
	return SUCCESS
