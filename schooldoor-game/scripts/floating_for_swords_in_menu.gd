extends Sprite2D

@onready var start_y: float = position.y
var time: float = 0.0

func _process(delta: float) -> void:
	# Додаємо delta, а не системний час — це прибирає будь-які мікро-ринки
	time += delta
	
	# Множник 1.5 робить коливання дуже повільним і заспокійливим
	# 30.0 — це на скільки пікселів в боки він відхиляється
	position.y = start_y + sin(time * 0.5) * 30.0
