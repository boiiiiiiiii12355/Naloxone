extends Node3D
class_name npc_base
#absolute basics like dialogue are included here

@export var animationplayer : AnimationPlayer
@export var head : Node3D
@export var npc_mesh : MeshInstance3D
var dialogue_data_block : PackedStringArray = [
"oi mate",
"what are ya buyin?",
"shop.open",
"shop.close",
"why your hair so short? later no one want you"
]
func _ready() -> void:
	animationplayer.play("idle")
	
	
func blink():
	var blink_tween : Tween = get_tree().create_tween()
	blink_tween.set_ease(Tween.EASE_OUT)
	blink_tween.set_trans(Tween.TRANS_CUBIC)
	blink_tween.tween_method(blink_value_set, 0.0, 1.0, 0.2)
	blink_tween.tween_method(blink_value_set, 1.0, 0.0, 0.2)
	
func blink_value_set(value : float):
	npc_mesh.set_blend_shape_value(0, value)
	
func mouth_open():
	var mouth_tween : Tween = get_tree().create_tween()
	mouth_tween.set_ease(Tween.EASE_IN_OUT)
	mouth_tween.set_trans(Tween.TRANS_CUBIC)
	mouth_tween.tween_method(mouth_value_set, 0.0, 1, 0.2)
	mouth_tween.tween_method(mouth_value_set, 1.0, 0, 0.2)

func mouth_value_set(value : float):
	npc_mesh.set_blend_shape_value(1, value)
	
@export var head_look_at : Node3D
@export var legs_look_at : Node3D
func look_at_(object : Object):
	var look_tween : Tween = get_tree().create_tween()
	look_tween.set_ease(Tween.EASE_IN_OUT)
	look_tween.set_trans(Tween.TRANS_QUAD)
	look_tween.tween_property(head_look_at, "global_position", object.global_position, 1)
	look_tween.tween_property(legs_look_at, "global_position", object.global_position, 1.5)

@export var blink_timer : Timer
func _on_blink_timer_timeout() -> void:
	blink()
	blink_timer.start(randf_range(2, 5))
