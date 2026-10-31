extends CharacterBody2D

@export var speed = 100
@export var accelration = 20.0
@export var max_hp := 100
var hp := 100
var is_invul := false
var can_dash := true
var is_dashing := false
var dash_dir

@export var sword_item: Item
@onready var sword = $sword
@onready var player_sprite = $Sprite2D
@onready var audio_steps = $Audio_Steps
@onready var audio_hits = $Audio_Hits
@onready var audio_clashes = $Audio_Clashes
var clash_sound = preload("res://audio/Sword/ThoSwordsHit_1.wav")
var hit_sound = preload("res://audio/Sword/Regular hit.wav")
var critical_sound = preload("res://audio/Sword/Critical hit.wav")

var pause_scene = preload("res://scenes/ui/pause_menu.tscn")

var input: Vector2

func _ready():
	hp = max_hp
	if sword_item: sword.get_child(0).texture = sword_item.texture
	update_hp_bar()

func process_invul(time = 0.33):
	is_invul = true
	await get_tree().create_timer(time).timeout
	is_invul = false

func update_hp_bar():
	$HPBar.value = hp

func flash_anim(col = Color(7.759, 7.759, 7.759, 1.0), time = 0.16):
	var tween = get_tree().create_tween()
	tween.tween_property(player_sprite, "modulate", col, time)
	tween.play()
	await tween.finished; tween.kill(); tween = create_tween()
	tween.tween_property(player_sprite, "modulate", Color("ffffffff"), time)
	tween.play()

func die():
	get_tree().change_scene_to_file("res://scenes/ui/death_screen.tscn")

func take_damage(amount):
	if !is_invul:
		hp -= amount
		update_hp_bar()
		flash_anim()
		print(hp)
		process_invul()
		if hp <= 0:
			hp = 0
			update_hp_bar()
			audio_hits.stream = critical_sound
			audio_hits.play()
			die()
		else:
			audio_hits.stream = critical_sound
			audio_hits.play()

func get_input():
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	return input.normalized();

func resume():
	get_tree().paused = false

func pause():
	get_tree().paused = true
	var pause_menu = pause_scene.instantiate()
	pause_menu.scale = Vector2(0.33, 0.33)
	add_child(pause_menu)

func dash():
	is_dashing = true
	dash_dir = global_position.direction_to(get_global_mouse_position())
	process_invul(0.25)
	flash_anim(Color(1.263, 1.166, 0.288, 1.0), 0.12)
	await get_tree().create_timer(0.24).timeout
	is_dashing = false
	await get_tree().create_timer(0.75).timeout
	can_dash = true

func _process(delta):
	var player_input = get_input()
	
	if Input.is_action_just_pressed("pause") && get_tree().paused:
		resume()
	elif Input.is_action_just_pressed("pause"):
		pause()
	# DASHING
	if is_dashing:
		velocity = lerp(velocity, dash_dir * speed * 5, accelration * delta)
		move_and_slide()
	if Input.is_action_just_pressed("dash") && can_dash:
		dash()
		can_dash = false
	# WALKING
	velocity = lerp(velocity, player_input * speed, accelration * delta)
	move_and_slide()
	
	# SWORD
	var direction = global_position.direction_to(get_global_mouse_position())
	var angle = direction.angle()
	if sword_item: sword.rotation = rotate_toward(sword.rotation, angle, sword_item.speed * delta)


func _on_sword_area_entered(area: Area2D) -> void:
	if area.is_in_group("e_weapons"):
		var enemy = area.get_parent().get_parent()
		enemy.inverted_spinning = not enemy.inverted_spinning
		audio_clashes.stream = clash_sound
		audio_clashes.play()


func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(sword_item.power)
