extends gun_item_base
class_name  fs_12

@export var gun_ray_collection : Node3D

func play_equip_animation():
	get_tree().call_group("player_animations", "play_arm_animation", "player_animation/FS_12_equip")
	animation_player.play("fs_12_equip_gun")
func  play_store_animation():
	#get_tree().call_group("player_animations", "play_arm_animation", "p2000_store")
	pass
	
func play_reload_animation():
	get_tree().call_group("player_animations", "play_arm_animation", "player_animation/p7_quiver_reload")
	animation_player.play("p2000_reload_anim")
	animation_player.seek(0)
	
	
func  play_fire_animation():
	gun_shot_sound.play(0)
	get_tree().call_group("player_animations", "play_arm_animation_from_time", "player_animation/FS_12_shoot", 0.045)
	animation_player.play("fs_12_shoot_gun")
	animation_player.seek(0)
	
func fire_type():
	return "semi_auto"

var pellets = 9
func object_function(check : bool):
	Engine.time_scale = 0.1
	if !check and equip_timer.is_stopped() and ammunition and fire_rate_timer.is_stopped():
		play_fire_animation()
		check_hit_shotgun()
		animation_player.seek(0)
		effects()
		fire_rate_timer.start()
		get_tree().call_group("player_animations", "apply_recoil", Vector3(0.0,0.0,0)) 
		ammunition -= 1
		muzzle_flash.omni_range = 1000
		await get_tree().create_timer(0.1).timeout
		muzzle_flash.omni_range = 0
	elif check:
		return fire_type()
		
func item_point(look_atv : Vector3):
	gun_ray_collection.look_at(look_atv)
	
func check_hit_shotgun():
	for i : RayCast3D in gun_ray_collection.get_children():
		i.rotation_degrees.x = randf_range(-5, 5)
		i.rotation_degrees.y = randf_range(-5, 5)
		
		if i.get_collider():
			print(i.get_collider())
			var hit_particle_clone = hit_particle.instantiate()
			root_node.particles.add_child(hit_particle_clone)
			DrawLine3d.DrawLine(i.global_position, i.get_collision_point(), Color.YELLOW, 0.1)
			hit_particle_clone.global_position = i.get_collision_point()
			hit_particle_clone.rotation = i.get_collision_normal()
			hit_particle_clone.restart()
			
			if i.get_collider().is_in_group("ragdoll"):
				var bone_parent = i.get_collider()
				var knockback_dir = (bone_parent.global_position - i.global_position).normalized()
				bone_parent.get_parent().get_parent().hit(bone_parent, base_damage)
				bone_parent.linear_velocity = knockback_dir * 20
				
				
		else:
			return false

func fire_rate_timer_end():
	pass
