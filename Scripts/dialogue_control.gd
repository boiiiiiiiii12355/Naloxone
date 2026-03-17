extends Control
class_name  dialogue_control

@export var text_label : Label
@export var next_button : Button
@export var dialogue_box_status : bool = false
@export var shop_ui_node : shop_ui
var hud : player_hud
var player : Player
var dialogue_storage : PackedStringArray

func _ready() -> void:
	hud = owner
	player = hud.owner
	
func dialogue_box_show():
	hud.animationplayer.play("dialogue_toggle")
	var model : playermodel = player.player_body
	model.dialogue_start()
	
func dialogue_box_hide():
	hud.animationplayer.play_backwards("dialogue_toggle")
	var model : playermodel = player.player_body
	model.dialogue_end()
	
func dialogue_choices_show():
	hud.animationplayer.play("dialogue_choices_toggle")
	
func dialogue_choices_hide():
	hud.animationplayer.play_backwards("dialogue_choices_toggle")

func store_dialogue_data(data : PackedStringArray):
	dialogue_storage.resize(data.size())
	current_text_idx = 0
	for i in data.size():
		dialogue_storage[i] = data[i]
		
var current_text_idx : int = 0
func _on_next_button_pressed() -> void:
	current_text_idx += 1
	if current_text_idx >= dialogue_storage.size():
		dialogue_to_player_transition()
	else:
		play_dialogue_section(current_text_idx)

@export var npc : npc_base
@export var dialogue_speed : float = 0.05
func play_dialogue_section(idx : int):
	if ! dialogue_storage.is_empty():
		print("has data")
		if dialogue_storage[idx] == "shop.open":
			shop_ui_node.shop_open()
		elif dialogue_storage[idx] == "shop.close":
			shop_ui_node.shop_close()
		else:
			text_label.text = dialogue_storage[idx]
			text_label.visible_characters = 0
			for i  in text_label.text.length():
				
				text_label.visible_characters += 1
				if npc and i % 5:
					print("speak")
					npc.mouth_open()
				await get_tree().create_timer(dialogue_speed).timeout

func player_to_dialogue_transition():
	dialogue_box_show()
	var size_tween : Tween = get_tree().create_tween()
	size_tween.set_ease(Tween.EASE_IN_OUT)
	size_tween.set_trans(Tween.TRANS_CUBIC)
	size_tween.tween_property(hud.player_hud_nodes, "scale", Vector2(1.2, 1.2), 1).set_ease(Tween.EASE_IN_OUT)
	size_tween.tween_property(player.player_cam, "fov", 50, 1)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func dialogue_to_player_transition():
	if !dialogue_storage.is_empty():
		dialogue_storage.clear()
		dialogue_box_hide()
		var size_tween : Tween = get_tree().create_tween()
		size_tween.set_ease(Tween.EASE_IN_OUT)
		size_tween.set_trans(Tween.TRANS_CUBIC)
		size_tween.tween_property(hud.player_hud_nodes, "scale", Vector2(1, 1), 1).set_ease(Tween.EASE_IN_OUT)
		size_tween.tween_property(player.player_cam, "fov", 75, 1)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func player_dialogue_cam_look_at(object : Object):
	player.dialogue_cam_root.look_at(object.global_position)
	pass
	
func initiate_dialogue():
	pass
