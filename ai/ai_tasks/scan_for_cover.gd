extends BTAction
class_name action_scan_cover

@export var cover_type : String = "agro"
func _tick(delta: float) -> Status:
	var grunt_ai : grunt = agent
	
	if scan_result(cover_type) and grunt_ai.action_queue.is_empty():
		grunt_ai.add_action(scan_result(cover_type))
		
		
		return SUCCESS
	elif ! grunt_ai.action_queue.is_empty():
		return SUCCESS
	else:
		return FAILURE

func scan_result(type : String):
	var grunt_ai : grunt = agent
	var nearest_cover_self = grunt_ai.get_nearest_from_self_cover()
	var furtherest_cover_self = grunt_ai.get_furtherest_cover_from_self()
	var nearest_cover_target = grunt_ai.get_nearest_cover_target()
	var furtherest_cover_target = grunt_ai.get_furtherest_cover_target()
	if type == "agro":
		return nearest_cover_target
	elif type == "evasive":
		return furtherest_cover_target
	else:
		return null
