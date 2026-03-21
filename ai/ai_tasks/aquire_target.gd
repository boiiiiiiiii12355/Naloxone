extends BTAction

var potential_targets : Array

func _tick(delta: float) -> Status:
	potential_targets = agent.potential_targets
	if agent.target and potential_targets[0]:
		agent.target = potential_targets[0]
	return SUCCESS
