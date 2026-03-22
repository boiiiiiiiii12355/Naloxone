extends Node3D
class_name playermodel

@export var skeleton : Skeleton3D
@export var camera_point : Node3D
@export var legs_point : Node3D
@export var animation_tree : AnimationTree
@export var head_tracker : BoneAttachment3D
@export var camera_spine : Node3D
@export var gun_point : Node3D
@export var upper_chest_attach : BoneAttachment3D
@export var upper_chest_lookat : Node3D
@export var copy_transform : CopyTransformModifier3D
@export var head_remote_transform : RemoteTransform3D
@export var hud : player_hud 
@export var player_cam : Camera3D
@export var dialogue_cam_root : Node3D
var chest_angle : float = 0.0
var rtc_blend_amount = 0.0
var kick_blend_amount = 0.0
var talking : bool = false
var arms_action
var stand_to_crouch = "parameters/stand_to_crouch/blend_amount"
var arms_action_blend = "parameters/arms_action_blend/blend_amount"
var interact_blend = "parameters/interact_blend/blend_amount"
var arms_action_timeseek = "parameters/arms_action_timeseek/seek_request"
var kick_oneshot = "parameters/kick_oneshot/request"
var kick_timeseek = "parameters/kick_timeseek/seek_request"
var falling_blend = "parameters/falling_blend/blend_amount"
var fall_landing = "parameters/fall_landing/request"
var dialogue_anim_seek = "parameters/dialogue_anim_seek/seek_request"
var dialogue_pose_blend = "parameters/dialogue_pose_blend/blend_amount"

#these are variables for physical slot nodes
@export var equip_node : Node3D
@export var slot1 : Node3D
@export var slot2 : Node3D
@export var slot3 : Node3D

func _ready() -> void:
	arms_action = animation_tree.tree_root.get_node("arms_action")
	head_remote_transform.remote_path = camera_spine.get_path()
	
func _physics_process(delta: float) -> void:
	if alive:
		equip_node.get_parent().scale = Vector3(1, 1, 1)
		animation_tree.set(stand_to_crouch, lerp(animation_tree.get(stand_to_crouch), rtc_blend_amount, 0.1))
		animation_tree.set(arms_action_blend, lerp(animation_tree.get(arms_action_blend), float(equipstatus_check(false)), 0.2))
		animation_tree.set(falling_blend, lerp(animation_tree.get(falling_blend), 0.0, 0.05))

func equipstatus_check(checkoffset:bool):
	if !checkoffset:
		var equipstatus : float = 0
		equipstatus = equip_node.get_children().size()
		return equipstatus
	else:
		var offset = equip_node.get_child(0).chest_twist_offset
		return offset
		
var recoil_pos : Vector3 = Vector3.ZERO
var upperchest_offset :Vector3 = Vector3(0.3, 0, 0)
func chest_point_at(r_position : Vector3):
	var end_position = r_position + recoil_pos 
	var upper_torso_copy_amount = copy_transform.get("settings/0/amount")
	copy_transform.set("settings/0/amount", lerp(upper_torso_copy_amount, (equipstatus_check(false) * 0.7) + 0.3, 0.1))
	camera_point.global_position = lerp(camera_point.global_position, end_position, 0.5)
	upper_chest_lookat.look_at(camera_point.global_position, Vector3.UP, true)
	upper_chest_lookat.global_position = owner.camera.global_position
	recoil_process()
	apply_camera_influence()
	turn_body_to_cam()
	
var alive : bool = true
func player_dead():
	alive = false
	visible = false
	
var camera_influence : float = 50.0 #percentage
func apply_camera_influence():
	var head_angl = head_tracker.quaternion
	camera_spine.quaternion.slerp(head_tracker.quaternion, camera_influence / 100)
	
var recoil_rand = RandomNumberGenerator.new()
func apply_recoil(amount : Vector3):
	recoil_pos.y += recoil_rand.randf_range(-amount.y / 2, amount.y)
	recoil_pos.x += recoil_rand.randf_range(-amount.x, amount.x)
	
@export var gun_ray : RayCast3D
func recoil_process():
	recoil_pos = lerp(recoil_pos, Vector3.ZERO, 0.1)
	if gun_ray.is_colliding():
		var recoil_pos_dist_scale = recoil_pos * (gun_ray.get_collision_point() - gun_ray.global_position).length() / 2
		var final_pos = gun_ray.get_collision_point() + recoil_pos_dist_scale
		gun_point.global_position = lerp(gun_point.global_position, final_pos, 0.5)
	else:
		gun_point.global_position = lerp(gun_point.global_position, camera_point.global_position, 0.1)
	
func turn_body_to_cam():
	legs_point.global_position = lerp(legs_point.global_position, camera_point.global_position, 0.05)
	if get_parent().velocity:
		legs_point.global_position = lerp(legs_point.global_position, camera_point.global_position, 0.1)
	
func crouch_enter():
	rtc_blend_amount = 1.0
	self.position.y = .4
	
func crouch_exit():
	rtc_blend_amount = 0.0
	self.position.y = 0
 
func kick_charging():
	pass

func falling():
	animation_tree.set(falling_blend, lerp(animation_tree.get(falling_blend), 1.0, 0.1))
	
func fall_landing_set():
	animation_tree.set(fall_landing, 1)
	
func kick():
	if !kicking:
		animation_tree.set(kick_oneshot, 1)
		animation_tree.set(kick_timeseek, 0.25)
		check_kick()
	else:
		print("already_kicking")

var kicking : bool = false
func check_kick():
	if animation_tree.get(kick_oneshot) == 1:
		kicking = true
		await animation_tree.animation_finished
		kicking = false

func dialogue_start():
	animation_tree.set(dialogue_anim_seek, 0)
	var dialogue_blend_tween : Tween = get_tree().create_tween()
	var dialogue_cam_tween : Tween = get_tree().create_tween()
	var dialogue_cam_rotation_tween : Tween = get_tree().create_tween()
	dialogue_cam_tween.set_ease(Tween.EASE_IN_OUT)
	dialogue_cam_tween.set_trans(Tween.TRANS_CUBIC)
	dialogue_cam_rotation_tween.set_ease(Tween.EASE_IN_OUT)
	dialogue_cam_rotation_tween.set_trans(Tween.TRANS_CUBIC)
	dialogue_blend_tween.tween_method(set_dialogue_blend, 0, 1, 0.3)
	dialogue_cam_tween.tween_property(player_cam, "position", dialogue_cam_root.position, 0.5)
	dialogue_cam_rotation_tween.tween_property(player_cam, "global_rotation", dialogue_cam_root.get_child(0).global_rotation, 0.5)

func dialogue_end():
	var dialogue_blend_tween : Tween = get_tree().create_tween()
	var dialogue_cam_tween : Tween = get_tree().create_tween()
	var dialogue_cam_rotation_tween : Tween = get_tree().create_tween()
	dialogue_cam_tween.set_ease(Tween.EASE_IN_OUT)
	dialogue_cam_tween.set_trans(Tween.TRANS_CUBIC)
	dialogue_cam_rotation_tween.set_ease(Tween.EASE_IN_OUT)
	dialogue_cam_rotation_tween.set_trans(Tween.TRANS_CUBIC)
	dialogue_blend_tween.tween_method(set_dialogue_blend, 1, 0, 0.3)
	dialogue_cam_tween.tween_property(player_cam, "position", Vector3.ZERO, 0.2)
	dialogue_cam_rotation_tween.tween_property(player_cam, "rotation" ,Vector3.ZERO, 0.5)
	
func set_dialogue_blend(value : float):
	animation_tree.set(dialogue_pose_blend, value)
	
var interact_blend_var = 1.0
func interact_detect():
	interact_blend_var = lerp(interact_blend_var, 1.0, 0.1)
	animation_tree.set(interact_blend, interact_blend_var)
		
func interact_none():
	interact_blend_var = lerp(interact_blend_var, 0.0, 0.1)
	animation_tree.set(interact_blend, interact_blend_var)
	
var local_vel_mag : Vector2 = Vector2.ZERO
func walk_anim_update(velocity_magnitude : Vector2):
	local_vel_mag = lerp(local_vel_mag, velocity_magnitude, 0.2)
	animation_tree.set("parameters/idle_to_walk/blend_position", local_vel_mag)
	animation_tree.set("parameters/crouch_to_crouchwalk/blend_position", local_vel_mag)

func play_arm_animation(name : String):
	arms_action.set_animation(name)
	animation_tree.set(arms_action_timeseek, 0)
	print("played " + str(arms_action.animation))

func play_arm_animation_from_time(name : String, time : float):
	arms_action.set_animation(name)
	animation_tree.set(arms_action_timeseek, time)

@export var kick_hitbox : Area3D
func _on_kick_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("ragdoll"):
		print("hit")
		var bone_parent = body
		var knockback_dir = (bone_parent.global_position - self.global_position).normalized()
		bone_parent.get_parent().get_parent().hit(body, 10000000)
		bone_parent.linear_velocity = knockback_dir * 5
