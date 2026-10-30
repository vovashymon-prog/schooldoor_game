extends CharacterBody2D

@export var speed = 100
@export var accelration = 20.0
@export var max_hp := 100
var hp := 100
var is_invul := false

@export var sword_item: Item
@onready var sword = $sword
@onready var audio = $Audio
var clash_sound = preload("res://audio/Sword/ThoSwordsHit_1.wav")
#var critical_sound = preload()

var input: Vector2

func _ready():
	if sword_item: sword.get_child(0).texture = sword_item.texture

func process_invul():
	is_invul = true
	await get_tree().create_timer(0.33).timeout
	is_invul = false

func take_damage(amount):
	if !is_invul:
		hp -= amount
		process_invul()
		if hp <= 0:
			pass
		else:
			pass

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
	if sword_item: sword.rotation = rotate_toward(sword.rotation, angle, sword_item.speed * delta)


func _on_sword_area_entered(area: Area2D) -> void:
	if area.is_in_group("e_weapons"):
		var enemy = area.get_parent()
		enemy.inverted_spinning = not enemy.inverted_spinning
		audio.stream = clash_sound
		audio.play()


func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(sword_item.power)
