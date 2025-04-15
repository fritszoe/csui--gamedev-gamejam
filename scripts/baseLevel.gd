extends Node2D

signal player_changed(new_player)  # Signal untuk memberi tahu perubahan player
signal player_health_changed(new_health)

@onready var swordsman = $Swordsmantest  
@export var new_character_scene: PackedScene  
@export var swordsman_scene: PackedScene  
@export var next_level_scene: String = "res://scenes/Level2.tscn" # Atur di Inspector

var current_character: Node2D = null  
var last_position: Vector2 = Vector2.ZERO

var player_max_health = 100
var player_current_health = 100

func _ready() -> void:
	current_character = swordsman  
	emit_signal("player_changed", current_character)
	
	_sync_character_health()
	# Tunggu sebentar untuk memastikan semua node sudah siap
	await get_tree().create_timer(0.2).timeout
	
	# Reset enemy counter dan register musuh
	print("Resetting enemy count from Level script")
	register_all_enemies()
	GameManager.all_enemies_defeated.connect(_on_all_enemies_defeated)

func _sync_character_health():
	if current_character.has_signal("health_changed"):
		# Connect signal dari karakter ke level
		if current_character.is_connected("health_changed", _on_character_health_changed):
			current_character.disconnect("health_changed", _on_character_health_changed)
		current_character.connect("health_changed", _on_character_health_changed)
	
	# Set health karakter sesuai health yang disimpan di level
	current_character.current_health = player_current_health
	current_character.max_health = player_max_health
	
	# Pancarkan signal agar UI diperbarui
	emit_signal("player_health_changed", player_current_health)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_char_2"):  
		swap_character(new_character_scene)  
	elif Input.is_action_just_pressed("switch_char_1"):  
		swap_character(swordsman_scene)  

func _on_character_health_changed(new_health):
	# Simpan health dari karakter ke level
	player_current_health = new_health
	
	# Forward signal ke UI
	emit_signal("player_health_changed", new_health)

func swap_character(new_scene: PackedScene) -> void:
	if current_character:
		last_position = current_character.global_position
		current_character.queue_free()  

	await get_tree().process_frame  

	current_character = new_scene.instantiate()  
	if not current_character.is_in_group("player"):
		current_character.add_to_group("player")

	add_child(current_character)
	current_character.global_position = last_position  
	
	_sync_character_health()
	
	emit_signal("player_changed", current_character)  # ✅ Kasih tahu AI player baru

func register_all_enemies():
	# Temukan semua enemy di level
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	# Reset counter
	GameManager.enemy_count = 0
		
		# Registrasi setiap enemy
	for enemy in enemies:
		GameManager.register_enemy()
	
	print("Total enemies in level: ", enemies.size())

func _on_all_enemies_defeated():	
	print("Level complete! Moving to next level...")
	
	# Tampilkan UI "Level Complete" jika ada
	if has_node("UI/LevelCompletePanel"):
		print ("ada ui lvlcomplete")
		$UI/LevelCompletePanel.visible = true
		# Tunggu beberapa detik sebelum ganti scene
		await get_tree().create_timer(3.0).timeout
		$UI/LevelCompletePanel.visible = false
		await get_tree().create_timer(8.0).timeout
	if next_level_scene.contains("Level2"):
		GameManager.set_level(2)
	elif next_level_scene.contains("Level3"):
		GameManager.set_level(3)
	elif next_level_scene.contains("Level4"):
		GameManager.set_level(4)
	# Ganti ke scene berikutnya
	get_tree().change_scene_to_file(next_level_scene)
