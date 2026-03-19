extends CharacterBody3D
class_name grunt

@export var specified_target : Node3D
@export var model : Node3D
@export var check_player_sightline : RayCast3D
@export var nav_agent : NavigationAgent3D
@export var interaction_area : Area3D
@export var action_cooldown : Timer
@export var max_hp = 100
@export var area_scanner : Node3D
@export var cover_ignore_dist = 2
@export var team : String
@export var hostiles_list : PackedStringArray 
var hp = max_hp
var player_spotted : bool = false
var player_spot
var wishvelocity : Vector3 = Vector3.ZERO
var compvelocity : Vector3 = Vector3.ZERO
var target 

func _ready() -> void:
	print(owner)
	nav_agent.connect("velocity_computed", velocity_computed)
	
@export var curr_action : String
@export var state : String
@export var state_display : Label3D
func _physics_process(delta: float) -> void:
	velocity = lerp(velocity, compvelocity, 0.1)
	nav_agent.set_velocity(wishvelocity)
	scan_surroundings()
	move_and_slide()
	gravity()
	pathfinding()
	state_display.text = "State : " + state
	if check_action_queued():
		target_pos = action_queue[-1]
	else:
		target_pos = main_target_pos
		
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
		var entity : grunt = i
		var entity_dist = self.global_position.distance_to(entity.global_position)
		if entity_dist < 100 and entity != self and hostiles_list.has(entity.team) and !potential_targets.has(entity):
			add_potential_target(entity)
			print("new target")
			
var potential_targets : Array = [null]
func add_potential_target(entity_target):
	if potential_targets.size() <= 1:
		potential_targets.resize(1)
	if ! potential_targets[-1]:
		potential_targets[-1] = entity_target
	else:
		potential_targets.resize(potential_targets.size() + 1)
	potential_targets.sort_custom(sort_by_dist)
	target = potential_targets[0]
	
func sort_by_dist(a:Vector3, b:Vector3):
	var dist_a = global_position.distance_squared_to(a)
	var dist_b = global_position.distance_squared_to(b)
	
	if dist_a < dist_b:
		return true
	return false


#should finish all this once i figure out navigation meshes
var speed = 10
var action_queue : Array
func check_action_queued():
	if !action_queue.is_empty():
		if action_queue.back():
			return true
		else:
			return false
	
var main_target_pos : Vector3
var target_pos : Vector3
func pathfinding():
	if target_pos and action_cooldown.is_stopped():
		nav_agent.target_position =  target_pos
		var next_path_pos : Vector3 = nav_agent.get_next_path_position()
		var dir : Vector3 = self.global_position.direction_to(next_path_pos)
		apply_wishvel(dir, speed / 3, false)
		
		if nav_agent.is_navigation_finished():
			action_cooldown.start()
			apply_wishvel(dir, speed, true)
			if !action_queue.is_empty():
				action_queue.resize(action_queue.size() - 1)
				
		#rotate towards movement dir
		#var rotation_speed = 0.1
		
		#var target_rotation = dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
		#model.rotation.y = lerp(model.rotation.y, target_rotation, rotation_speed)
	
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
	print(action_queue)
	
#for testing combat ai only
@export var gun_ray : RayCast3D
func test_fire():
	model.look_at(target.global_position, Vector3(0, 1, 0))
	if gun_ray.is_colliding():
		var colider = gun_ray.get_collider()
		DrawLine3d.DrawLine(gun_ray.global_position, gun_ray.get_collision_point(), Color.FIREBRICK, 0.1)
		print(colider)
		if colider.is_in_group("player_hitbox"):
			var player_tar : Player = colider.owner
			player_tar.take_damage(10)
			
func target_in_range():
	pass

func target_out_of_range():
	pass
	
