extends Node

signal all_enemies_defeated
var enemy_count = 0
var current_level = 1  # Level dimulai dari 1
var power_slash_unlocked = false  # Status PowerSlash

func register_enemy():
	enemy_count += 1
	print("Enemy registered. Total: ", enemy_count)

func enemy_defeated():
	enemy_count -= 1
	print("Enemy defeated. Remaining: ", enemy_count)
	
	if enemy_count <= 0:
		print("All enemies defeated!")
		emit_signal("all_enemies_defeated")

func unlock_power_slash():
	power_slash_unlocked = true
	print("Power Slash telah diaktifkan!")
	
# Fungsi untuk dipanggil saat pindah ke Level2
func set_level(level_number):
	current_level = level_number
	# Aktifkan PowerSlash di level 2+
	if current_level >= 2 and not power_slash_unlocked:
		unlock_power_slash()
