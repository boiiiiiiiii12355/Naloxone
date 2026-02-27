extends Node
class_name  player_hp_management

@export var player_hitbox : Area3D
@export var environment_damage_timer : Timer
@export var maximum_hp = 100
@export var player_model : playermodel
@export var player_ragdoll : ragdoll
var player = owner
var hp = maximum_hp
var dead : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	owner.hud.update_hp_bar(hp, 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	check_env()
	owner.hud.update_hp_bar(hp, 2)
	if hp <= 0 and !dead:
		spawn_dead_player()
		dead = true
	

func spawn_dead_player():
	var player_skeleton : Skeleton3D = player_model.skeleton
	var ragdoll_skeleton : Skeleton3D = player_ragdoll.skeleton
		
	var cam : Camera3D = owner.player_cam
	owner.dead = true
	cam.dead = true
	var look_dir = Vector3(player_model.legs_point.global_position.x, 0, player_model.legs_point.global_position.z)
	player_ragdoll.look_at(look_dir, Vector3(0, 1, 0), true)
	player_ragdoll.start_phy()
	player_model.player_dead()
	for i in player_skeleton.get_bone_count():
		var bone_pos = player_skeleton.get_bone_pose_position(i)
		var bone_rotation = player_skeleton.get_bone_pose_rotation(i)
		ragdoll_skeleton.set_bone_pose_position(i, bone_pos)
		ragdoll_skeleton.set_bone_pose_rotation(i, bone_rotation)
	cam.reparent(player_ragdoll.head_tracker)
	
	
	
func check_env():
	if player_hitbox.get_overlapping_areas() and environment_damage_timer.is_stopped():
		for i in player_hitbox.get_overlapping_areas():
			if i.is_in_group("env_player_hurt"):
				hp -= 25
				environment_damage_timer.start()
