extends physics_item
class_name gun_item_base

@export var gun_shot_sound : AudioStreamPlayer3D
@export var weapon_model : Node3D
@export var muzzle_flash : OmniLight3D
@export var gun_ray : RayCast3D
@export var fire_rate_timer : Timer
@export var mag_size : int
@export var base_damage : int
@export var animation_player : AnimationPlayer
@export var chest_twist_offset : Vector3 
var ammunition = mag_size


func _ready() -> void:
	ammunition = mag_size
	fire_rate_timer.connect("timeout", fire_rate_timer_end)
	
func play_equip_animation():
	animation_player.play("p2000_gun_equip")
	get_tree().call_group("player_animations", "play_arm_animation", "player_animation/p2000_equip")
	
func  play_store_animation():
	#get_tree().call_group("player_animations", "play_arm_animation", "p2000_store")
	pass
	
func play_reload_animation():
	get_tree().call_group("player_animations", "play_arm_animation", "player_animation/p2000_reload")
	animation_player.play("p2000_reload_baked")
	animation_player.seek(0)
	
func play_fire_animation():
	gun_shot_sound.play(0)
	animation_player.play("fire")
	get_tree().call_group("player_animations", "play_arm_animation_from_time", "player_animation/p2000_shoot", 0)
	
	
func object_function(check : bool):
	if !check and equip_timer.is_stopped() and ammunition and fire_rate_timer.is_stopped():
		play_fire_animation()
		ammunition -= 1
		animation_player.seek(0)
		check_hit()
		effects()
		fire_rate_timer.start()
		muzzle_flash.omni_range = 1000
		get_tree().call_group("player_animations", "apply_recoil", Vector3(0.2,0.2,0)) 
		
	elif check:
		return fire_type()

func item_point(look_atv : Vector3):
	gun_ray.look_at(look_atv)
	
func fire_type():
	return "semi_auto"
	
func object_reload():
	play_reload_animation()
	await animation_player.animation_finished
	ammunition = mag_size

var hit_particle = preload("res://particle_effects/hit_particles.tscn")
func check_hit():
	if gun_ray.get_collider():
		print(gun_ray.get_collider())
		var hit_particle_clone = hit_particle.instantiate()
		root_node.particles.add_child(hit_particle_clone)
		DrawLine3d.DrawLine(gun_ray.global_position, gun_ray.get_collision_point(), Color.YELLOW, 0.01)
		hit_particle_clone.global_position = gun_ray.get_collision_point()
		hit_particle_clone.rotation = gun_ray.get_collision_normal()
		hit_particle_clone.restart()
		
		if gun_ray.get_collider().is_in_group("ragdoll"):
			var bone_parent = gun_ray.get_collider()
			var knockback_dir = (bone_parent.global_position - gun_ray.global_position).normalized()
			bone_parent.get_parent().get_parent().hit(bone_parent, base_damage)
			bone_parent.linear_velocity = knockback_dir * 20
			
			
	else:
		return false

func fire_rate_timer_end():
	muzzle_flash.omni_range = 0
	
var random_number = RandomNumberGenerator.new()
@export var ejection_area : Node3D
@onready var ejection_dir_node : Node3D = ejection_area.get_child(0)
var bullet_casing = preload("res://particle_effects/bullet_casings.tscn")
func effects():
	var bullet_casing_clone : RigidBody3D = bullet_casing.instantiate()
	add_child(bullet_casing_clone)
	bullet_casing_clone.global_position = ejection_area.global_position
	bullet_casing_clone.linear_velocity = ((ejection_dir_node.global_position - bullet_casing_clone.global_position).normalized() + Vector3(0, random_number.randf_range(-1, 1), 0)) * random_number.randf_range(2.0, 4.0)
	bullet_casing_clone.angular_velocity = Vector3(0, random_number.randf_range(10, 100), 0)
	bullet_casing_clone.reparent(root_node.particles)
