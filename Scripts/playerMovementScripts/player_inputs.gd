extends CharacterBody3D
class_name PlayerInputs
#CODE THAT PARSES USER INPUT
#just organized like this for organization's sake
@export var stats : Resource
@export var view : Camera3D
@export var inventory : Node
@export var interact_ray : RayCast3D
@export var pickup_hold_area : Node3D
@export var pickup_speed = 20
@export var preselected_inventory_slot : int = 1
@export var selected_inventory_slot : int = 1
@export var hud : player_hud
@export var player_body : playermodel

var camera : Node3D
var kick_charge : float = 0.0
var flashlight_toggle = false
var dead = false

func _ready():
	push_warning("You should not be seeing this (player_inputs.gd is being initiated)")
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		InputMouse(event)
		
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event.is_action_pressed("click"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			pass
			
	if event.is_action_pressed("restart"):
		stats.vel = Vector3(0,0,0)
		get_tree().reload_current_scene()

func InputMouse(event):
	stats.xlook += -event.relative.y * stats.ply_xlookspeed 
	stats.ylook += -event.relative.x * stats.ply_ylookspeed
	
	
	stats.xlook = clamp(stats.xlook, stats.ply_maxlookangle_down, stats.ply_maxlookangle_up)
	
func interact_check():
	if interact_ray.is_colliding():
		var object = interact_ray.get_collider().owner
		if object.is_in_group("interactable") or object.is_in_group("pickable"):
			return object
	else:
		return null
		
func ViewAngles(delta):
	camera.rotation_degrees.x = stats.xlook
	camera.rotation_degrees.y = stats.ylook

var movement_local_dir = Vector2.ZERO
func InputKeys():
	if !dead:
		input_tick()

func input_tick():
	if !Input.is_action_pressed("free_lean"):
		player_body.free_lean_cancel()
		stats.sidemove += int(stats.ply_sidespeed) * (int(Input.get_action_strength("move_left") * 50))
		stats.sidemove -= int(stats.ply_sidespeed) * (int(Input.get_action_strength("move_right") * 50))
		
		stats.forwardmove += int(stats.ply_forwardspeed) * (int(Input.get_action_strength("move_forward") * 50))
		stats.forwardmove -= int(stats.ply_backspeed) * (int(Input.get_action_strength("move_back") * 50))
	
	else:
		player_body.free_lean()
	# Clamp that shit so it doesn't go too high
	movement_local_dir = Vector2.ZERO
	if Input.is_action_just_released("move_left") or Input.is_action_just_released("move_right"):
		stats.sidemove = 0
	else:
		stats.sidemove = clamp(stats.sidemove, -4096, 4096)
			
	if Input.is_action_just_released("move_forward") or Input.is_action_just_released("move_back"):
		stats.upmove = 0
	else:
		stats.upmove = clamp(stats.upmove, -4096, 4096)
		
	if Input.is_action_just_released("move_forward") or Input.is_action_just_released("move_back"):
		stats.forwardmove = 0
	else:
		stats.forwardmove = clamp(stats.forwardmove, -4096, 4096)
		
	var local_dir_x = 0
	var local_dir_y = 0
	if stats.sidemove:
		local_dir_x = stats.sidemove / abs(stats.sidemove)
	if stats.forwardmove:
		local_dir_y = stats.forwardmove / abs(stats.forwardmove)
		
	movement_local_dir += Vector2(local_dir_x, local_dir_y)
		
	#auxilary actions
	if Input.is_action_just_pressed("click"):
		if inventory.inventory_array[selected_inventory_slot - 1] != null and preselect_timer.is_stopped():
			if inventory.inventory_array[selected_inventory_slot - 1].object_function(true) == "semi_auto":
				inventory.inventory_array[selected_inventory_slot - 1].object_function(false)
	
	if Input.is_action_pressed("click"):
		if inventory.inventory_array[selected_inventory_slot - 1] != null and preselect_timer.is_stopped():
			if inventory.inventory_array[selected_inventory_slot - 1].object_function(true) == "full_auto":
				inventory.inventory_array[selected_inventory_slot - 1].object_function(false)
	
	#controls the kick
	if Input.is_action_just_pressed("right_click"):
		kick()
		
		
	if Input.is_action_just_pressed("reload"):
		Engine.time_scale = 1
		if inventory.inventory_array[selected_inventory_slot - 1] != null and preselect_timer.is_stopped():
			inventory.inventory_array[selected_inventory_slot - 1].object_reload()
		
	if Input.is_action_just_pressed("interact") and interact_check():
		var object : Object = interact_check()
		if object.is_in_group("interactable"):
			if object.is_class("physics_item"):
				object.object_function(false)
			elif object.is_in_group("npc"):
				var npc : npc_base = object
				var dialogue_controller : dialogue_control = hud.dialogue_controller
				npc.look_at_(self.player_body.head_tracker)
				dialogue_controller.npc = npc
				dialogue_controller.player_dialogue_cam_look_at(npc.head)
				dialogue_controller.store_dialogue_data(npc.dialogue_data_block)
				dialogue_controller.play_dialogue_section(0)
				dialogue_controller.player_to_dialogue_transition()
			else:
				object.get_child(0).object_function(false)
			
			
	elif Input.is_action_just_pressed("interact"):
		print("nothing here...")
		

		
	#inventory actions
	if Input.is_action_just_pressed("pickup") and interact_check():
		var object : Object = interact_check()
		if object.is_in_group("pickable"):
			pickup(object)
		else:
			hold_target = object
	elif !Input.is_action_pressed("pickup"):
		hold_target = null
		
	if Input.is_action_just_pressed("drop"):
		drop(selected_inventory_slot)
		
	if Input.is_action_just_pressed("slot_1"):
		selected_inventory_slot = 1
		preselected_inventory_slot = selected_inventory_slot
	elif Input.is_action_just_pressed("slot_2"):
		selected_inventory_slot = 2
		preselected_inventory_slot = selected_inventory_slot
	elif Input.is_action_just_pressed("slot_3"):
		selected_inventory_slot = 3
		preselected_inventory_slot = selected_inventory_slot
	
	if Input.is_action_just_pressed("scroll_up"):
		preselected_inventory_slot -= 1
		preselect_timer.start()
		hud.show_inventory()
	elif Input.is_action_just_pressed("scroll_down"):
		preselected_inventory_slot += 1
		preselect_timer.start()
		hud.show_inventory()
	inventory.hud.update_inventory_select(preselected_inventory_slot)

	if selected_inventory_slot <= 1:
		selected_inventory_slot = 1
	elif selected_inventory_slot >= 3:
		selected_inventory_slot = 3
		
@export var preselect_timer : Timer
func preselect_check():
	if !preselect_timer.is_stopped() and Input.is_action_just_pressed("click"):
		selected_inventory_slot = preselected_inventory_slot
	
func preselect_timer_end():
	preselected_inventory_slot = selected_inventory_slot
	
var hold_target 
func hold(object):
	pass

func kick_charging():
	pass
	
func kick():
	pass
	
func pickup(object : Object):
	pass

func drop(slot : int):
	hud.show_inventory()
	inventory.drop(selected_inventory_slot)
