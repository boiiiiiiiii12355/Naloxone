extends Control

var player_inventory : Array
	
@export var slot_1 : RichTextLabel
@export var slot_2 : RichTextLabel
@export var slot_3 : RichTextLabel
@export var selector : ColorRect
@export var player_camera : Camera3D
var ui_hp : float
var req_selector_position : Vector2 = Vector2.ZERO

@export var hp_bar : ProgressBar
func  _ready() -> void:
	var blood_vignette_shader : ShaderMaterial = blood_vignette_rect.material
	blood_vignette_shader.set_shader_parameter("outerRadius", 0)
	
func _physics_process(delta: float) -> void:
	screen_effects()
	selector.global_position = lerp(selector.global_position, req_selector_position, 0.3)
	hp_bar.value = lerp(hp_bar.value, ui_hp, 0.1)
	
func update_inventory_display():
	player_inventory = get_parent().inventory.inventory_array
	if player_inventory[0]:
		slot_1.text = "1 :" + player_inventory[0].item_name
	else:
		slot_1.text = "1 :empty"
	if player_inventory[1]:
		slot_2.text = "2 :" + player_inventory[1].item_name
	else:
		slot_2.text = "2 :empty"
	if player_inventory[2]:
		slot_3.text = "3 :" + player_inventory[2].item_name
	else:
		slot_3.text = "3 :empty"
		
		
func update_inventory_select(slot : int):
	if slot == 1:
		req_selector_position = slot_1.global_position
	elif slot == 2:
		req_selector_position = slot_2.global_position
	elif slot == 3:
		req_selector_position = slot_3.global_position
	
func update_hp_bar(hp, update_type : int):
	ui_hp = clamp(hp, 0, 100)
	
	if update_type == 1 : #damaged
		pass
		
	elif update_type == 2 : #healed
		pass
		
@export var blood_vignette_rect : ColorRect
var blood_vignette_default = 1.0
var blood_vignette_wish : float = 1.0
func screen_effects():
	if ui_hp > 0:
		blood_vignette_wish = (ui_hp / 100) + 0.1 + randf_range(-0.5, 0.5)
		blood_vignette_wish = clamp(blood_vignette_wish, .3, 1)
	else:
		blood_vignette_wish = 0.0 + randf_range(-0.7, 0.7)
		
	var blood_vignette_shader : ShaderMaterial = blood_vignette_rect.material
	var blood_vignette_curr = blood_vignette_shader.get_shader_parameter("radius")
	var blood_vignette_set = lerp(float(blood_vignette_curr), blood_vignette_wish, 0.03)
	blood_vignette_shader.set_shader_parameter("radius", blood_vignette_set)
	
