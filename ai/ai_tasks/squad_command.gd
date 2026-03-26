extends BTAction

@export var command : String

func  _tick(delta: float) -> Status:
	command_call(command)
	return SUCCESS

func command_call(command_text : String):
	var squadmates = agent.squadmates
	squadmates = squadmates.filter(agent.filter_invalid)
	if command_text == "fall in":
		for mate : grunt in squadmates:
			mate.target_follow_dist = 10
			mate.target_follow = agent
