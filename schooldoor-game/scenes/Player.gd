extends CharacterBody2D

@export var speed = 100
@export var accelration = 20.0

var input: Vector2

func get_input():
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	return input.normalized();

func _process(delta):
	var player_input = get_input()
	
	velocity = lerp(velocity, player_input * speed, accelration * delta)
	
	move_and_slide()
