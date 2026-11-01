extends Sprite2D

@onready var start_y: float = position.y
var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	position.y = start_y + sin(time * 0.5) * 30.0
