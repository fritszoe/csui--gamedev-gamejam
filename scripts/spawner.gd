extends Node2D

@export var obstacle : PackedScene  # Scene yang akan di-spawn (misalnya musuh)

var max_enemies = 3  # Batas maksimal jumlah musuh

func _ready():
	repeat()

# Fungsi untuk spawn musuh
func spawn():
	# Cek jumlah musuh yang ada di parent
	var enemy_count = 0
	for child in get_parent().get_children():
		if child is CharacterBody2D:  # Misalnya musuh adalah turunan dari CharacterBody2D
			enemy_count += 1

	# Jika jumlah musuh belum mencapai batas maksimal, spawn musuh baru
	if enemy_count < max_enemies:
		var spawned = obstacle.instantiate()

		# Menggunakan call_deferred untuk menambahkan anak ke parent
		get_parent().call_deferred("add_child", spawned)

		var spawn_pos = global_position
		spawn_pos.x = spawn_pos.x + randf_range(-1000, 1000)

		spawned.global_position = spawn_pos


# Fungsi untuk mengulang spawn setiap detik
func repeat():
	spawn()
	await get_tree().create_timer(1).timeout  # Tunggu 1 detik sebelum spawn lagi
	repeat()
