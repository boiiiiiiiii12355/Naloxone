extends BTAction

func _tick(delta: float) -> Status:
	blackboard.set_var("move_to_pos", scan_for_cover())
	return SUCCESS

var nearby_cover : Array
var nearest3cover : Array
func scan_for_cover():
	if ! agent.get_tree().get_nodes_in_group("cover_point_collection").is_empty():
		var scanned_count = 0
		var cover_ignore_dist = agent.cover_ignore_dist
		nearby_cover.resize(agent.get_tree().get_node_count_in_group("cover_point_collection"))
		
		for cover : cover_point in agent.get_tree().get_nodes_in_group("cover_point_collection"):
			var availability = cover.check_cover_availability()
			var dist_from_cover = agent.global_position.distance_to(cover.global_position)
			nearby_cover[scanned_count] = null
			if availability and dist_from_cover > cover_ignore_dist:
				nearby_cover[scanned_count] = cover.check_cover_position()
			
				
			scanned_count += 1
		
		nearby_cover = nearby_cover.filter(not_null)
		nearby_cover.sort_custom(sort_by_dist)
		
		#selects top 3 closest and randomises them to decide which cover to go
		var cover_candidate_amount = 5
		if nearby_cover.size() < cover_candidate_amount:
			nearest3cover.resize(nearby_cover.size() - 1)
		else:
			nearest3cover.resize(cover_candidate_amount)
			
		
		for i in nearest3cover.size():
			if nearby_cover[i]:
				nearest3cover[i] = nearby_cover[i]
		
		nearest3cover.shuffle()
		if nearest3cover:
			return nearest3cover[0]

func sort_by_dist(a:Vector3, b:Vector3):
	var dist_a = agent.player.global_position.distance_squared_to(a)
	var dist_b = agent.player.global_position.distance_squared_to(b)
	
	if dist_a < dist_b:
		return true
	return false

func not_null(value):
	if value:
		return true
	else:
		return false
