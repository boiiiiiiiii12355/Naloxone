extends gun_item_base
class_name  p7_quiver

func play_equip_animation():
	get_tree().call_group("player_animations", "play_arm_animation", "p7_quiver_equip")
	
func  play_store_animation():
	#get_tree().call_group("player_animations", "play_arm_animation", "p2000_store")
	pass
	
func play_reload_animation():
	get_tree().call_group("player_animations", "play_arm_animation", "p7_quiver_reload")
	animation_player.play("p7_quiver_reload_gun_baked")
	animation_player.seek(0)
	
	
func  play_fire_animation():
	gun_shot_sound.play(0)
	get_tree().call_group("player_animations", "play_arm_animation_from_time", "p7_quiver_shoot", 0.045)
	animation_player.play("p7_quiver_fire")
	animation_player.seek(0)
	
func fire_type():
	return "full_auto"
