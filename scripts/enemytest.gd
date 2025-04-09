extends CharacterBody2D

const speed = 50

@export var player: Node2D
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var sprite := $Sprite2D  # Ambil sprite buat di-flip
@onready var anim = $AnimationPlayer
@onready var chase_area := $ChaseArea

var player_in_range = false

func _ready() -> void:
	#print("ChaseArea:", chase_area)
	#print("ChaseArea Mask:", chase_area.collision_mask)
	#print("Player Layer:", player.collision_layer)
	
	timer.timeout.connect(_on_timer_timeout)
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	
	var level = get_parent()
	if level.has_signal("player_changed"):
		level.player_changed.connect(_on_player_changed)
	
	call_deferred("actor_setup")

func actor_setup() -> void:
	await get_tree().physics_frame
	makepath(player.position)

func _physics_process(delta: float) -> void:
	if not player_in_range or nav_agent.is_navigation_finished():
		anim.play("Idle")  # AI diam kalau player belum masuk area
		return

	var cur_agent_pos = global_position
	var next_path_pos := nav_agent.get_next_path_position()
	var dir := cur_agent_pos.direction_to(next_path_pos) * speed * delta

	# Flip sprite sesuai arah gerak
	if dir.x != 0:
		update_facing_direction(dir.x)
	
	if dir.length() > 0:
		anim.play("Run")  # Jalan = animasi "Run"
	else:
		anim.play("Idle")  # Diam = animasi "Idle"
	
	velocity = dir * speed
	move_and_slide()

func makepath(target_position) -> void:
	if player_in_range:
		nav_agent.target_position = target_position

func _on_timer_timeout():
	makepath(player.position)

# ✅ Fungsi buat flip sprite AI
func update_facing_direction(direction: float) -> void:
	if direction > 0:
		sprite.scale.x = 1  # Hadap kanan
	elif direction < 0:
		sprite.scale.x = -1  # Hadap kiri

func _on_chase_area_body_entered(body: Node2D) -> void:
	if body == player:
		print("ye")
		player_in_range = true
		makepath(player.position)  # Mulai pathfinding langsung

func _on_chase_area_body_exited(body: Node2D) -> void:
	if body == player:
		print("boooo")
		player_in_range = false
		nav_agent.target_position = global_position  # Biar AI berhenti di tempat

func _on_player_changed(new_player):
	player = new_player
	print("Enemy sekarang ngejar:", player)
