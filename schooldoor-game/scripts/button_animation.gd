extends Button

# Запам'ятовуємо початковий розмір кнопки
@onready var original_scale: Vector2 = scale

func _ready() -> void:
	# Додаємо вузол у режим центрування трансформації, 
	# щоб кнопка росла з центру, а не з кута (дуже важливо!)
	pivot_offset = size / 2

# Коли миша наводиться на кнопку
func _on_mouse_entered() -> void:
	var tween = create_tween().set_parallel(true)
	# Плавно збільшуємо на 10% (scale 1.1) за 0.15 секунди
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)
	# Можнцца паралельно змінити колір ( modulate ) на трохи світліший або червонуватий
	tween.tween_property(self, "modulate", Color(1.3, 1.0, 1.0), 0.15)

# Коли миша злітає з кнопки
func _on_mouse_exited() -> void:
	var tween = create_tween().set_parallel(true)
	# Повертаємо назад у звичайний стан
	tween.tween_property(self, "scale", original_scale, 0.15)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.15)
