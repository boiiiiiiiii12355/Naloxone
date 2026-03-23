extends CharacterBody3D
class_name grunt

@export var state : String
@export var type : String
@export var squad : String
@export var team : String
@export var specified_target : Node3D
@export var model : Node3D
@export var sightline : RayCast3D
@export var nav_agent : NavigationAgent3D
@export var action_cooldown : Timer
@export var max_hp = 100
@export var area_scanner : Node3D
@export var cover_ignore_dist = 2
@export var hostiles_list : PackedStringArray 
@export var head : Node3D
var hp = max_hp
var player_spotted : bool = false
var player_spot
var wishvelocity : Vector3 = Vector3.ZERO
var compvelocity : Vector3 = Vector3.ZERO
var target_follow_dist : float  = 0.0
var target_follow
var target_kill

func _ready() -> void:
	print(owner)
	nav_agent.connect("velocity_computed", velocity_computed)
	state_display.text = "Team " + team
	environment_detector_setup()
	find_team()
	
@export var curr_action : String
@export var state_display : Label3D
@export var in_sight : bool = false
func _physics_process(delta: float) -> void:
	phy_stuff()
	ai_process()

func scan_area():
	environment_detector_process()
	#potential_target_list_update()
	pass
	
func ai_process():
	scan_area()

func phy_stuff():
	pathfinding()
	move_and_slide()
	gravity()
	velocity = lerp(velocity, compvelocity, 0.1)
	nav_agent.set_velocity(wishvelocity)
	if check_action_queued():
		target_pos = action_queue[-1]
	else:
		target_pos = main_target_pos
		
	if target_kill:
		sightline.look_at(target_kill.head.global_position, Vector3.UP, true)
	
	
func velocity_computed(safe_velocity : Vector3):
	compvelocity = safe_velocity
	
func gravity():
	if !is_on_floor():
		wishvelocity.y += -0.2
	else:
		wishvelocity.y = 0
	
	
@export var squadmates : Array
var commander : Object 
func find_team():
	for entity in get_tree().get_nodes_in_group("entity"):
		if entity.team == self.team and entity.squad == self.squad and type != "commander":
			squadmates.resize(squadmates.size() + 1)
			squadmates[-1] = entity
			if entity.type == "commander":
				commander = entity
		
		if self.type == "commander" and entity.type != "commander":
			squadmates.resize(squadmates.size() + 1)
			squadmates[-1] = entity
		
		
@export var potential_targets : Array 
func add_potential_target(entity_target):
	if potential_targets.size() <= 1:
		potential_targets.resize(1)
	if ! potential_targets[-1]:
		potential_targets[-1] = entity_target
	else:
		potential_targets.resize(potential_targets.size() + 1)
		potential_targets[-1] = entity_target

func potential_target_list_update():
	potential_targets = potential_targets.filter(filter_invalid)
	potential_targets.sort_custom(sort_by_target_dist)
	if !potential_targets.is_empty():
		target_kill = potential_targets[0]
		
func filter_invalid(value):
	return is_instance_valid(value)
	
func filter_null(value):
	return value != null
	
func sort_by_target_dist(a, b):
	if is_instance_valid(a) and is_instance_valid(b):
		var dist_a = self.global_position.distance_squared_to(a.global_position)
		var dist_b = self.global_position.distance_squared_to(b.global_position)
	
		if dist_a < dist_b:
			return true
		return false


var speed = 3
var action_queue : Array
func check_action_queued():
	if !action_queue.is_empty():
		target_pos = action_queue[-1]
		if action_queue.back():
			return true
		else:
			return false
	
var main_target_pos : Vector3
var target_pos : Vector3
func pathfinding():
	if action_queue.is_empty() and target_follow:
		target_pos = target_follow.global_position
		
	if target_pos and action_cooldown.is_stopped():
		nav_agent.target_position =  target_pos
		var next_path_pos : Vector3 = nav_agent.get_next_path_position()
		var dist_from_tar = target_follow.global_position.distance_squared_to(self.global_position)
		var dir : Vector3 = self.global_position.direction_to(next_path_pos)
		apply_wishvel(dir, speed / 3, false)
		
		if target_follow_dist >= dist_from_tar:
			apply_wishvel(dir, speed, true)
			
		if nav_agent.is_navigation_finished():
			action_cooldown.start()
			apply_wishvel(dir, speed, true)
			delete_curr_action()
			
		#rotate towards movement dir
		if ! in_sight:
			var rotation_speed = 0.1
			
			var target_rotation = dir.signed_angle_to(Vector3.MODEL_REAR, Vector3.DOWN)
			model.rotation.y = lerp(model.rotation.y, target_rotation, rotation_speed)
		
func delete_curr_action():
	if !action_queue.is_empty():
		action_queue.resize(action_queue.size() - 1)
				
func apply_wishvel(dir : Vector3, sped : float, decelerate : bool):
	if !decelerate:
		wishvelocity.x = dir.x * speed
		wishvelocity.z = dir.z * speed
	else:
		wishvelocity.x = 0
		wishvelocity.z = 0
		
	self.wishvelocity = wishvelocity
	
func add_action(position : Vector3):
	action_queue.resize(action_queue.size() + 1)
	action_queue[-1] = position
	
#for testing combat ai only
@export var gun_ray : RayCast3D
func test_fire():
	if is_instance_valid(target_kill):
		model.look_at(target_kill.global_position, Vector3(0, 1, 0))
	if gun_ray.is_colliding():
		var colider = gun_ray.get_collider()
		DrawLine3d.DrawLine(gun_ray.global_position, gun_ray.get_collision_point(), Color(team), 0.1)
		if colider.owner.is_in_group("entity"):
			var tar = colider.owner
			tar.take_damage(30)

func take_damage(value):
	hp -= value
	if hp <= 0:
		call_deferred("queue_free")
	
	
#this section is for environment raycasting
@export var cover_detector : Node3D
@export var hotzone_detector : Node3D
var cover_detector_radius : float = 30.0
func environment_detector_setup():
	var ray_num = 0
	for i in range(0, 360, 5):
		var cover_detector_raycast : RayCast3D = RayCast3D.new()
		cover_detector.add_child(cover_detector_raycast)
		
		var ray_pos_x = cos(i) * cover_detector_radius
		var ray_pos_z = sin(i) * cover_detector_radius
		
		cover_detector_raycast.position = Vector3(ray_pos_x, 0, ray_pos_z)
		cover_detector_raycast.name = "r" + str(ray_num)
		ray_num += 1
	cover_ray_hits.resize(cover_detector.get_children().size())
	
	ray_num = 0
	for i in range(0, 360, 5):
		var hotzone_detector_raycast : RayCast3D = RayCast3D.new()
		hotzone_detector.add_child(hotzone_detector_raycast)
		hotzone_detector_raycast.position = Vector3.ZERO
		hotzone_detector_raycast.target_position = Vector3(0, 0, cover_detector_radius)
		hotzone_detector_raycast.rotation_degrees.y = i
		hotzone_detector_raycast.name = "r" + str(ray_num)
		ray_num += 1

func environment_detector_process():
	if sightline.is_colliding() and sightline.get_collider() != null and sightline.get_collider().is_in_group("entity"):
		in_sight = true
	else:
		in_sight = false
	#cover_detect()
	hot_zone_detect()
	
		
var hot_zone_array : Array
func hot_zone_detect():
	hot_zone_array.resize(hotzone_detector.get_children().size())
	for ray : RayCast3D in hotzone_detector.get_children():
		var idx = ray.get_index()
		hot_zone_array[idx] = ray.get_collision_point()
		
	hot_zone_array = hot_zone_array.filter(filter_null)
	hot_zone_array.sort_custom(sort_by_self_dist_furtherest)
	
	if !hot_zone_array.is_empty():
		
		DrawLine3d.DrawLine(self.head.global_position, hot_zone_array[0], Color.PURPLE, 0.1)
		DrawLine3d.DrawLine(self.head.global_position, hot_zone_array[1], Color.PURPLE, 0.1)
		DrawLine3d.DrawLine(self.head.global_position, hot_zone_array[2], Color.PURPLE, 0.1)
		DrawLine3d.DrawLine(self.head.global_position, hot_zone_array[3], Color.PURPLE, 0.1)
		DrawLine3d.DrawLine(self.head.global_position, hot_zone_array[4], Color.PURPLE, 0.1)
		
	
var cover_ray_hits : Array
func cover_detect():
	if target_kill:
		for raycast : RayCast3D in cover_detector.get_children():
			var idx = raycast.get_index()
			raycast.target_position = target_kill.head.global_position - raycast.global_position
			
			var collide_pos = raycast.get_collision_point()
			cover_ray_hits[idx] = collide_pos
					
		if cover_ray_hits[0] != null:
			cover_ray_hits.filter(filter_invalid)
			cover_ray_hits.sort_custom(sort_by_self_dist_nearest)
			DrawLine3d.DrawLine(cover_ray_hits[0], self.global_position, Color.REBECCA_PURPLE, 0.1)
			
func get_nearest_from_self_cover():
	cover_ray_hits.sort_custom(sort_by_self_dist_nearest)
	return cover_ray_hits[0]
	
func get_furtherest_cover_from_self():
	cover_ray_hits.sort_custom(sort_by_self_dist_furtherest)
	return cover_ray_hits[0]
	
func get_nearest_cover_target():
	cover_ray_hits.sort_custom(sort_by_target_from_cover_dist_closest)
	return cover_ray_hits[0]
	
func get_furtherest_cover_target():
	cover_ray_hits.sort_custom(sort_by_target_from_cover_dist_furtherest)
	return cover_ray_hits[0]
	
func sort_by_self_dist_nearest(a : Vector3, b : Vector3):
	var dist_a = self.global_position.distance_squared_to(a)
	var dist_b = self.global_position.distance_squared_to(b)
	if dist_a < dist_b:
		return true
	else:
		return false

func sort_by_self_dist_furtherest(a : Vector3, b : Vector3):
	var dist_a = self.global_position.distance_squared_to(a)
	var dist_b = self.global_position.distance_squared_to(b)
	if dist_a > dist_b:
		return true
	else:
		return false
		
func sort_by_target_from_cover_dist_closest(a : Vector3, b : Vector3):
	var dist_a = self.global_position.distance_squared_to(a)
	var dist_b = self.global_position.distance_squared_to(b)
	if dist_a < dist_b:
		return true
	else:
		return false

func sort_by_target_from_cover_dist_furtherest(a : Vector3, b : Vector3):
	var dist_a = self.global_position.distance_squared_to(a)
	var dist_b = self.global_position.distance_squared_to(b)
	if dist_a > dist_b:
		return true
	else:
		return false
