extends CharacterBody2D

@export var speed = 100
@export var accelration = 20.0

@export var sword_item: Item
@onready var sword = $sword

var input: Vector2

func _ready():
	if sword_item: sword.get_child(0).texture = sword_item.texture

func get_input():
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	return input.normalized();

func _process(delta):
	# WALKING
	var player_input = get_input()
	velocity = lerp(velocity, player_input * speed, accelration * delta)
	move_and_slide()
	
	# SWORD
	var direction = global_position.direction_to(get_global_mouse_position())
	var angle = direction.angle()
	sword.rotation = rotate_toward(sword.rotation, angle, sword_item.speed * delta)
