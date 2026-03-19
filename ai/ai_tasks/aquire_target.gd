extends BTAction

var potential_targets : Array

func _tick(delta: float) -> Status:
	potential_targets = agent.potential_targets
	if potential_targets[0] and !agent.target:
		agent.target = potential_targets[0]
	return SUCCESS
