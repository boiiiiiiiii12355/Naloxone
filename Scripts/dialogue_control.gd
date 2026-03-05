extends Control
class_name  dialogue_control

@export var text_label : Label
var hud : player_hud
var player : Player
var dialogue_cam : Camera3D
var dialogue_gimbal : Node3D
var dialogue_root : Node3D
var dialogue_storage : PackedStringArray

func _ready() -> void:
	hud = owner
	player = hud.owner
	#dialogue_root = hud.dialogue_cam_root
	#dialogue_cam = hud.dialogue_gimbal.get_child(0)
	#dialogue_gimbal = hud.dialogue_gimbal
	
func dialogue_box_show():
	hud.animationplayer.play("dialogue_toggle")
	
func dialogue_box_hide():
	hud.animationplayer.play_backwards("dialogue_toggle")
	
	
func store_dialogue_data(data : PackedStringArray):
	dialogue_storage.resize(10)
	for i in data.size():
		dialogue_storage[i] = data[i]
	
func play_dialogue_section(idx : int):
	player_to_dialogue_transition()
	if ! dialogue_storage.is_empty():
		text_label.text = dialogue_storage[idx]
		text_label.visible_characters = 0
		for i  in text_label.text.length():
			text_label.visible_characters += 1
	
func player_to_dialogue_transition():
	dialogue_cam.current = true

func initiate_dialogue():
	pass
