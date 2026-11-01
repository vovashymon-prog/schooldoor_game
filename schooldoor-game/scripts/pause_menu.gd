extends Control
func _ready() -> void:
	MusicManager.play_menu()
func _on_resume_pressed() -> void:
	get_tree().paused = false
	queue_free()

func _process(_delta):
	if Input.is_action_just_pressed("pause") && get_tree().paused:
		_on_resume_pressed()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_inMenu_play_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
