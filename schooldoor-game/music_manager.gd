extends AudioStreamPlayer2D

const MENU_MUSIC = preload("res://menu.wav")
const ROOM_MUSIC = preload("res://music.wav")
const BOSS_MUSIC = preload("res://music.wav")

func _ready() -> void:
	# Підключаємо сигнал завершення треку, щоб він грав по колу
	finished.connect(_on_finished)

func play_menu():
	if stream != MENU_MUSIC:
		stream = MENU_MUSIC
		volume_db = 8.0
		play()

func play_room():
	if stream != ROOM_MUSIC:
		stream = ROOM_MUSIC
		volume_db = 0.0
		play()

func play_boss():
	if stream != BOSS_MUSIC:
		stream = BOSS_MUSIC
		volume_db = 5.0
		play()

func _on_finished():
	# Коли музика закінчується, запускаємо її знову
	play()
