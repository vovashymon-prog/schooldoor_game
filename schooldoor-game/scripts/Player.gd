extends CharacterBody2D

@export var speed = 100
@export var accelration = 20.0
@export var max_hp := 100
var hp := 100
var is_invul := false

@export var sword_item: Item
@onready var sword = $sword
@onready var audio_steps = $Audio_Steps
@onready var audio_hits = $Audio_Hits
@onready var audio_clashes = $Audio_Clashes
var clash_sound = preload("res://audio/Sword/ThoSwordsHit_1.wav")
var hit_sound = preload("res://audio/Sword/Regular hit.wav")
var critical_sound = preload("res://audio/Sword/Critical hit.wav")

var input: Vector2

func _ready():
	if sword_item: sword.get_child(0).texture = sword_item.texture
	update_hp_bar()

func process_invul():
	is_invul = true
	await get_tree().create_timer(0.33).timeout
	is_invul = false

func update_hp_bar():
	$HPBar.value = hp

func take_damage(amount):
	if !is_invul:
		hp -= amount
		update_hp_bar()
		print(hp)
		process_invul()
		if hp <= 0:
			hp = 0
			update_hp_bar()
			audio_hits.stream = critical_sound
			audio_hits.play()
			queue_free()
		else:
			audio_hits.stream = critical_sound
			audio_hits.play()
		modulate = Color(7.759, 7.759, 7.759, 1.0)
		await get_tree().create_timer(0.33).timeout
		modulate = Color(1.0, 1.0, 1.0)

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
		audio_clashes.stream = clash_sound
		audio_clashes.play()


func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(sword_item.power)
