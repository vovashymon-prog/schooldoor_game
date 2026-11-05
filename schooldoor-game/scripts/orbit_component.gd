class_name OrbitComponent
extends Node2D

@export var rotation_speed := PI / 3
@export var orbiting_distance := 40.0
var is_active := false:
	set(value):
		if is_active == value:
			return
			
		is_active = value
		
		if is_active:
			face_parent()

@onready var orbit : Node2D = $Orbit
@onready var bobber : Node2D = $Orbit/Bobber
var target : Node2D

func _ready() -> void:
	if is_instance_valid(bobber): 
		bobber.position.x = orbiting_distance
	await get_tree().process_frame

func _process(delta: float) -> void:
	if is_active && is_instance_valid(target) && is_instance_valid(orbit):
		orbit.global_position = target.global_position
		orbit.rotation += rotation_speed * delta

func get_target_position() -> Vector2:
	return bobber.global_position

func multiply_spinning_speed(min_v := -1.0, max_v := -1.0):
	rotation_speed *= randf_range(min_v, max_v)

func multiply_orbiting_distance(min_v := 0.8, max_v := 1.25):
	orbiting_distance *= randf_range(min_v, max_v)
	if is_instance_valid(bobber): 
		bobber.position.x = orbiting_distance

func set_rotation_speed(rot):
	rotation_speed = rot

func set_orbiting_distance(dist):
	orbiting_distance = dist
	if is_instance_valid(bobber): 
		bobber.position.x = orbiting_distance

func face_parent():
	if is_instance_valid(orbit):
		orbit.look_at(get_parent().global_position)

func activate():
	if is_active: return
	if is_instance_valid(target) && is_instance_valid(orbit):
		orbit.global_position = target.global_position
	is_active = true

func deactivate():
	is_active = false

func set_target(new_target: Node2D):
	target = new_target
