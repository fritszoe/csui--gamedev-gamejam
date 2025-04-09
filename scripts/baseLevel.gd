extends Node2D

signal player_changed(new_player)  # Signal untuk memberi tahu perubahan player

@onready var swordsman = $Swordsmantest  
@export var new_character_scene: PackedScene  
@export var swordsman_scene: PackedScene  

var current_character: Node2D = null  
var last_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_character = swordsman  
	emit_signal("player_changed", current_character)  # ✅ Beri tahu semua AI siapa player awal

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_char_2"):  
		swap_character(new_character_scene)  
	elif Input.is_action_just_pressed("switch_char_1"):  
		swap_character(swordsman_scene)  

func swap_character(new_scene: PackedScene) -> void:
	if current_character:
		last_position = current_character.global_position
		current_character.queue_free()  

	await get_tree().process_frame  

	current_character = new_scene.instantiate()  
	add_child(current_character)
	current_character.global_position = last_position  

	emit_signal("player_changed", current_character)  # ✅ Kasih tahu AI player baru
