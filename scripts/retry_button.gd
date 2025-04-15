extends LinkButton

func _ready() -> void:
	pressed.connect(on_pressed)

func on_pressed() -> void:
	# Kembali ke level terakhir
	GameManager.current_level = 1
	GameManager.power_slash_unlocked = false
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")
