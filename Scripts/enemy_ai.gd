extends CharacterBody3D
class_name grunt

@export var specified_target : Node3D
@export var model : Node3D
@export var sightline : RayCast3D
@export var nav_agent : NavigationAgent3D
@export var interaction_area : Area3D
@export var action_cooldown : Timer
@export var max_hp = 100
@export var area_scanner : Node3D
@export var cover_ignore_dist = 2
@export var team : String
@export var hostiles_list : PackedStringArray 
@export var head : Node3D
var hp = max_hp
var player_spotted : bool = false
var player_spot
var wishvelocity : Vector3 = Vector3.ZERO
var compvelocity : Vector3 = Vector3.ZERO
var target 

func _ready() -> void:
	print(owner)
	nav_agent.connect("velocity_computed", velocity_computed)
	state_display.text = "Team " + team
	cover_detector_setup()
	
@export var curr_action : String
@export var state : String
@export var state_display : Label3D
@export var in_sight : bool = false
func _physics_process(delta: float) -> void:
	velocity = lerp(velocity, compvelocity, 0.1)
	nav_agent.set_velocity(wishvelocity)
	scan_surroundings()
	potential_target_list_update()
	move_and_slide()
	gravity()
	pathfinding()
	cover_detector_process()
	if check_action_queued():
		target_pos = action_queue[-1]
	else:
		target_pos = main_target_pos
		
	if target:
		sightline.look_at(target.head.global_position, Vector3.UP, true)
	
func velocity_computed(safe_velocity : Vector3):
	compvelocity = safe_velocity
	
func gravity():
	if !is_on_floor():
		wishvelocity.y += -0.2
	else:
		wishvelocity.y = 0
	
func scan_surroundings():
	var entity_list : Array = get_tree().get_nodes_in_group("entity")
	for i in entity_list:
		var entity  = i
		var entity_dist = self.global_position.distance_to(entity.global_position)
		if entity != self and hostiles_list.has(entity.team):
			if potential_targets.has(entity):
				pass
			else:
				add_potential_target(entity)
			
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
		target = potential_targets[0]
		
func filter_invalid(value):
	return is_instance_valid(value) and value != null
	
func sort_by_target_dist(a, b):
	if is_instance_valid(a) and is_instance_valid(b):
		var dist_a = self.global_position.distance_squared_to(a.global_position)
		var dist_b = self.global_position.distance_squared_to(b.global_position)
	
		if dist_a < dist_b:
			return true
		return false


var speed = 5
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
	if action_queue.is_empty() and target:
		target_pos = target.global_position
		
	if target_pos and action_cooldown.is_stopped():
		nav_agent.target_position =  target_pos
		var next_path_pos : Vector3 = nav_agent.get_next_path_position()
		var dir : Vector3 = self.global_position.direction_to(next_path_pos)
		apply_wishvel(dir, speed / 3, false)
		
		if nav_agent.is_navigation_finished():
			action_cooldown.start()
			apply_wishvel(dir, speed, true)
			delete_curr_action()
			
		#rotate towards movement dir
		#var rotation_speed = 0.1
		
		#var target_rotation = dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
		#model.rotation.y = lerp(model.rotation.y, target_rotation, rotation_speed)
		
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
	if is_instance_valid(target):
		model.look_at(target.global_position, Vector3(0, 1, 0))
	if gun_ray.is_colliding():
		var colider = gun_ray.get_collider()
		DrawLine3d.DrawLine(gun_ray.global_position, gun_ray.get_collision_point(), Color(team), 0.1)
		if colider.owner.is_in_group("entity"):
			var tar = colider.owner
			tar.take_damage(10)

func take_damage(value):
	hp -= value
	if hp <= 0:
		call_deferred("queue_free")
#this section is for circle raycasting
@export var cover_detector : Node3D
var cover_detector_radius : float = 5.0
func cover_detector_setup():
	var ray_num = 0
	for i in range(0, 360, 10):
		var cover_detector_raycast : RayCast3D = RayCast3D.new()
		cover_detector.add_child(cover_detector_raycast)
		
		var ray_pos_x = cos(i) * cover_detector_radius
		var ray_pos_z = sin(i) * cover_detector_radius
		
		cover_detector_raycast.position = Vector3(ray_pos_x, 2, ray_pos_z)
		cover_detector_raycast.name = "r" + str(ray_num)
		ray_num += 1
	cover_ray_hits.resize(cover_detector.get_children().size())
	
var cover_ray_hits : Array
func cover_detector_process():
	if target:
		if sightline.is_colliding() and sightline.get_collider() != null and sightline.get_collider().is_in_group("entity"):
			in_sight = true
		else:
			in_sight = false
			
		for raycast : RayCast3D in cover_detector.get_children():
			var idx = raycast.get_index()
			raycast.target_position = target.head.global_position - raycast.global_position
			
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
