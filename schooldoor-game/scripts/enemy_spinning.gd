extends CharacterBody2D

@export var speed = 100
@export var accelration = 20.0
@export var max_hp := 100
var hp := 100
var inverted_spinning := false
var is_invul := false

@export var sword_item: Item
@onready var sword = $sword
@onready var audio = $Audio
@onready var player = get_tree().get_first_node_in_group("player")
var clash_sound = preload("res://audio/Sword/ThoSwordsHit_1.wav")
var hit_sound = preload("res://audio/Sword/Regular hit.wav")
var critical_sound = preload("res://audio/Sword/Critical hit.wav")

var input: Vector2

func process_invul():
	is_invul = true
	await get_tree().create_timer(0.33).timeout
	is_invul = false

func take_damage(amount):
	if !is_invul:
		hp -= amount
		print(hp)
		process_invul()
		if hp <= 0:
			hp = 0
			if player != null: 
				player.audio_hits.stream = critical_sound
				player.audio_hits.play()
			queue_free()
		else:
			if player != null: 
				player.audio_hits.stream = critical_sound
				player.audio_hits.play()
		modulate = Color(7.759, 7.759, 7.759, 1.0)
		await get_tree().create_timer(0.33).timeout
		modulate = Color(1.0, 1.0, 1.0)

func _ready():
	if sword_item: sword.get_child(0).texture = sword_item.texture

func _process(delta):
	# WALKING
	
	# SWORD
	#var direction = global_position.direction_to(get_global_mouse_position())
	#var angle = direction.angle()
	if sword_item && !inverted_spinning: sword.rotation += -sword_item.speed * delta
	elif sword_item && inverted_spinning: sword.rotation += sword_item.speed * delta


func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(sword_item.power)
