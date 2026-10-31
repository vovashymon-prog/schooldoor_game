extends Sprite2D

@export var frame_1: Texture2D 
@export var frame_2: Texture2D 
@onready var start_y: float = position.y
var time: float = 0.0
var timer: float = 0.0
var next_switch_time: float = 0.2

func _process(delta: float) -> void:
	timer += delta
	
	
	if timer >= next_switch_time:
		timer = 0.0
		
		
		if texture == frame_1:
			texture = frame_2
			next_switch_time = randf_range(0.05, 0.15) 
		else:
			texture = frame_1
			next_switch_time = randf_range(0.5, 2.0)  



	# Додаємо delta, а не системний час — це прибирає будь-які мікро-ринки
	time += delta
	
	# Множник 1.5 робить коливання дуже повільним і заспокійливим
	# 30.0 — це на скільки пікселів в боки він відхиляється
	position.y = start_y + sin(time * 0.5) * 30.0
