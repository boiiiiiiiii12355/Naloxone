extends Node3D
class_name ragdoll
@export var skeleton : Skeleton3D
@export var physics_bone : PhysicalBoneSimulator3D
@export var head_tracker : BoneAttachment3D
@export var body_target : Node3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	
func start_phy():
	visible = true
	skeleton.show_rest_only = false
	physics_bone.physical_bones_start_simulation()

func set_rotate(bone_transform : Transform3D):
	var bone_idx = skeleton.find_bone("root")
	skeleton.set_bone_global_pose(bone_idx, bone_transform)
