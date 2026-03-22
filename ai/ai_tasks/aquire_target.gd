extends BTAction

var potential_targets : Array

func _tick(delta: float) -> Status:
	potential_targets = agent.potential_targets
	if agent.target_kill and potential_targets[0]:
		agent.target_kill = potential_targets[0]
	return SUCCESS
