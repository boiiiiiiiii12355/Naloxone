extends Camera3D

var change_magnitude = 0.2
var fall_displacement = .02
var fall_cam_bob = Vector3.ZERO
var dead : bool = false
func  _physics_process(delta: float) -> void:
	if !dead:
		stored_velocity()
		#bunch of camera effects when moving
		#var req_view_transform = owner.default_camera_pos + fall_cam_bob
		rotation.z = lerp(rotation.z, movement_tilt(), 0.07)
			
		if owner.velocity.length():
			step_time += (delta * owner.stats.vel.length() * float(owner.stats.on_floor))
		else:
			step_time = 1
		
func fall_impact():
	fall_cam_bob.y = (-fall_displacement * abs(stored_vel.y))
	print(owner.velocity.length())
	change_magnitude = 1
	await get_tree().create_timer(0.001).timeout
	change_magnitude = 0.1
	fall_cam_bob.y = 0
	
var stored_vel = Vector3.ZERO
func stored_velocity():
	if owner.velocity:
		stored_vel = owner.velocity

var step_time = 0.0
var headbob_frequency = 2.5
var headbob_amplitude = 0.04
func camera_bob(headbob_time):
	var headbob_position = Vector3.ZERO
	#headbob_position.y = sin(headbob_time * headbob_frequency) * headbob_amplitude
	#headbob_position.x = cos(headbob_time * headbob_frequency / 2) * headbob_amplitude
	headbob_position = Vector3.ZERO
	return headbob_position
	
@export var cam_tilt_init = 10.0
@export var tilt_magnitude = 0.1 
func movement_tilt():
	if owner.stats.sidemove and tilt_magnitude:
		var tilt_ratio = owner.stats.sidemove / 4096.0
		var tilt_equation = tilt_ratio * tilt_magnitude
		if owner.stats.sidemove > cam_tilt_init or owner.stats.sidemove < -cam_tilt_init:
			return tilt_equation
		else:
			return 0.0
	else:
		return 0.0

func dialogue_cam():
	pass
