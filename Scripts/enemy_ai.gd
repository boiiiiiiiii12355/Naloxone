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
var hp = max_hp
var player_spotted : bool = false
var player_spot
var player : Player
var wishvelocity : Vector3 = Vector3.ZERO
var compvelocity : Vector3 = Vector3.ZERO

func _ready() -> void:
	print(owner)
	player = owner.player
	nav_agent.connect("velocity_computed", velocity_computed)
	
	
func _physics_process(delta: float) -> void:
	velocity = lerp(velocity, compvelocity, 0.1)
	nav_agent.set_velocity(wishvelocity)
	move_and_slide()
	gravity()
	variable_update()
	scan_for_player()
	pathfinding()

func velocity_computed(safe_velocity : Vector3):
	compvelocity = safe_velocity
	
func gravity():
	if !is_on_floor():
		wishvelocity.y += -0.2
	else:
		wishvelocity.y = 0
	
#should finish all this once i figure out navigation meshes
var speed = 10
var player_chase_dist = 5 #meter
#this controls how far away the ai should stop when chasing the player

func scan_for_player():
	if target_pos:
		check_player_sightline.target_position = target_pos - check_player_sightline.global_position
		
	if check_player_sightline.is_colliding():
		if check_player_sightline.get_collider().is_in_group("player_hitbox"):
			player_spotted = true
			main_target_pos = player.global_position
			
	if check_action_queued():
		target_pos = action_queue[-1]
	else:
		target_pos = main_target_pos
	
var player_dist
func variable_update():
	player = self.player
	if player:
		player_dist = (player.global_position - self.global_position).length()
	
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
	model.look_at(player.global_position, Vector3(0, 1, 0), true)
	if gun_ray.is_colliding():
		var colider = gun_ray.get_collider()
		var colide_pos = gun_ray.get_collision_point()
		DrawLine3d.DrawLine(gun_ray.global_position, gun_ray.get_collision_point(), Color.YELLOW, 0.01)
		print(colider)
		if colider.is_in_group("player_hitbox"):
			var player_tar : Player = colider.owner
			player_tar.take_damage(10)
			
func target_in_range():
	pass

func target_out_of_range():
	pass
	
