extends PlayerInputs
class_name Player

@onready var bonker = $Headbonk
@export var mySkin : MeshInstance3D
@export var myShape : CollisionShape3D
@export var spring : SpringArm3D
@export var camera_dist = 0
@export var camera_spine : Node3D
@export var player_body : playermodel
@export var player_cam : Camera3D
@onready var coyoteTimer = $CoyoteTime

var pickup_point 
var default_camera_pos
var randm = RandomNumberGenerator.new()
var height = 2 #the model is 2 meter tall


func _ready():
	preselect_timer.timeout.connect(preselect_timer_end)
	mySkin.set_sorting_offset(1)
	pickup_point = pickup_hold_area.get_child(0)
	#get_viewport().get_camera_3d()
	default_camera_pos = view.transform.origin
	camera = get_node(stats.camPath)
	print(stats.vel)
	spring.spring_length = 0
	spring.margin = 8
	stats.on_floor = false
	spring.add_excluded_object(self.get_rid())
	
@export var chest_point_target : Node3D
func _physics_process(delta: float) -> void:
	if !dead:
		phy_pro(delta)
	else:
		velocity = Vector3.ZERO
		
func phy_pro(delta):
	camera_dist = clamp(4+(sqrt(stats.vel.length())/1.5),8, 100)
	#view.fov = clamp(70+sqrt(stats.vel.length()*7),90, 180)
	preselect_check()
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		InputKeys()
		
		ViewAngles(delta)
	
	stats.snap = -get_floor_normal()

	stats.wasOnFloor = stats.on_floor

	
	velocity = stats.vel
	move_and_slide_own()
	stats.vel = velocity
	
	if stats.wasOnFloor && !stats.on_floor:
		view.fall_impact()
		print("start timer")
		coyoteTimer.start()
	
	if stats.on_floor and stats.shouldJump == false:
		pass
		
	if(stats.on_floor):
		stats.shouldJump = true
	else:
		if coyoteTimer.is_stopped():
			stats.shouldJump = false
			#print("timer stopped")
			pass
	
	if hold_target:
		hold(hold_target)
	
	player_body.chest_point_at(chest_point_target.global_position)
	player_body.walk_anim_update(movement_local_dir)
	
	if interact_check():
		player_body.interact_detect()
	else:
		player_body.interact_none()
		
func clearCoyote():
	coyoteTimer.stop()
	stats.shouldJump = false
	stats.on_floor = false

func CheckVelocity():
	# bound velocity
	# Bound it.
	if stats.vel.length() > stats.ply_maxvelocity:
		stats.vel = stats.vel.normalized() * stats.ply_maxvelocity

	elif stats.vel.length() < -stats.ply_maxvelocity:
		stats.vel = stats.vel.normalized() * stats.ply_maxvelocity

func kick_charging():
	player_body.kick_charging()
	
func kick():
	player_body.kick()
	
## Perform a move-and-slide along the set velocity vector. If the body collides
## with another, it will slide along the other body rather than stop immediately.
## The method returns whether or not it collided with anything.
func move_and_slide_own() -> bool:
	var collided := false

	# Reset previously detected floor
	stats.on_floor  = false


	#check floor
	var checkMotion := velocity * (1/60.)
	checkMotion.y  -= stats.ply_gravity * (1/360.)
		
	var testcol := move_and_collide(checkMotion, true)

	if testcol:
		var testNormal = testcol.get_normal()
		if testNormal.angle_to(up_direction) < stats.ply_maxslopeangle:
			stats.on_floor = true

	# Loop performing the move
	var motion := velocity * get_delta_time()
	

	for step in max_slides:
		
		
		var collision := move_and_collide(motion)
		
		if not collision:
			# No collision, so move has finished
		
			break

		# Calculate velocity to slide along the surface
	
		var normal = collision.get_normal()
		
		motion = collision.get_remainder().slide(normal)
		velocity = velocity.slide(normal)


		# Collision has occurred
		collided = true


	return collided
	
func get_delta_time() -> float:
	if Engine.is_in_physics_frame():
		return get_physics_process_delta_time()

	return get_process_delta_time()


func pickup(object : Object):
	print("picked up  " + str(object))
	hud.show_inventory()
	inventory.pickup(object, (selected_inventory_slot - 1))

@export var hp_system : player_hp_management
func take_damage(amount : int):
	hp_system.hp -= amount
