extends BTAction

func _tick(delta: float) -> Status:
	print("set_cover")
	var nearest_cover = agent.get_nearest_cover()
	if nearest_cover and agent.action_queue.is_empty():
		agent.add_action(nearest_cover)
		return SUCCESS
	elif ! agent.action_queue.is_empty():
		print("already moving to cover")
		return SUCCESS
	else:
		print(nearest_cover)
		return FAILURE
