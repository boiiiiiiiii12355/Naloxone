extends BTAction

var potential_targets : Array

func _tick(delta: float) -> Status:
	potential_targets = agent.potential_targets
	if potential_targets[0]:
		blackboard.set_var("move_to_pos", potential_targets[0].global_position)
	return SUCCESS
