extends CharacterBody2D

const speed = 70

@export var player: Node2D
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var sprite := $Sprite2D  # Ambil sprite buat di-flip
@onready var anim = $AnimationPlayer
@onready var chase_area := $ChaseArea
@onready var attack_area = $AttackArea
@onready var hit_sound = $HitSound
@onready var attack_sound = $AtkSound

var can_attack = true
var attack_cooldown = 1.0  # Cooldown serangan dalam detik
var attack_damage = 10     # Damage yang diberikan enemy
var player_in_range = false
var max_health = 100
var current_health = 100
var knockback_force = Vector2.ZERO
var knockback_time = 0.0
var is_attacking = false
const KNOCKBACK_DURATION = 0.2
const DAMAGE_FLASH_DURATION = 0.1
var current_attack_target = null

func check_player_group():
	var players = get_tree().get_nodes_in_group("player")
	#print("Jumlah node dalam group player: ", players.size())
	
	# Cetak detail setiap node
	for i in range(players.size()):
		var player_node = players[i]
		#print("Player ", i, ":")
		#print("   - Name: ", player_node.name)
		#print("   - Path: ", player_node.get_path())
		#print("   - Type: ", player_node.get_class())

func _ready() -> void:
	add_to_group("enemy")
	timer.timeout.connect(_on_timer_timeout)
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	check_player_group()
	var level = get_parent()
	if level.has_signal("player_changed"):
		level.player_changed.connect(_on_player_changed)
		
	call_deferred("actor_setup")

func _on_attack_area_body_entered(body: Node2D) -> void:
	#print("Body entered: ", body.name)
	#print("Is in group player?: ", body.is_in_group("player"))
	if body is CharacterBody2D and body.is_in_group("player"):
		#print("OKAY - Player terdeteksi!")
		current_attack_target = body
		attack_player(body)
		
func _on_attack_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player") and body == current_attack_target:
		#print("Player keluar attack area!")
		current_attack_target = null  # Hapus referensi target

# Fungsi untuk serangan enemy ke player
func attack_player(target_player) -> void:
	if not can_attack or not is_instance_valid(target_player):
		return
	
	#print(name + " attacks player!")
	can_attack = false
	is_attacking = true
	
	# Play animasi attack dahulu
	if anim.has_animation("Attack_1"):
		anim.play("Attack_1")
		var anim_length = anim.get_animation("Attack_1").length
		var damage_time = anim_length * 0.5  # Sesuaikan angka ini (0.4 = 40% dari durasi animasi)
		# Tunggu sampai animasi selesai, kemudian berikan damage
		if attack_sound:
			attack_sound.play()
		await get_tree().create_timer(damage_time).timeout
		
		# Berikan damage di tengah animasi
		if is_instance_valid(target_player) and target_player == current_attack_target and target_player.has_method("take_damage"):
			var attack_dir = (target_player.global_position - global_position).normalized()
			#print("Memberikan damage pada player di tengah animasi")
			target_player.take_damage(attack_damage, attack_dir)
		#else:
			#print("Player keluar area, damage tidak diberikan!")
		
		# Tunggu sisa animasi selesai
		await get_tree().create_timer(anim_length - damage_time).timeout
	else:
		# Jika tidak ada animasi, tunggu sebentar sebelum damage
		if attack_sound:
			attack_sound.play()
		await get_tree().create_timer(0.25).timeout
		
		if is_instance_valid(target_player) and target_player.has_method("take_damage"):
			var attack_dir = (target_player.global_position - global_position).normalized()
			target_player.take_damage(attack_damage, attack_dir)
		
		await get_tree().create_timer(0.25).timeout
	
	# Reset flag attacking
	is_attacking = false
	
	# Set cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func actor_setup() -> void:
	await get_tree().physics_frame
	makepath(player.position)
	
func _physics_process(delta: float) -> void:
	if knockback_time > 0:
		knockback_time -= delta
		velocity = knockback_force
		move_and_slide()
		return
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
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
		transform.x.x = 1  # Hadap kanan
	elif direction < 0:
		transform.x.x = -1  # Hadap kiri

func _on_chase_area_body_entered(body: Node2D) -> void:
	# Ubah dari body == player menjadi is_in_group
	if body is CharacterBody2D and body.is_in_group("player"):
		print("Player terdeteksi di chase area!")
		player = body  # Update referensi player
		player_in_range = true
		makepath(player.position)  # Mulai pathfinding langsung

func _on_chase_area_body_exited(body: Node2D) -> void:
	# Ubah dari body == player menjadi is_in_group
	if body is CharacterBody2D and body.is_in_group("player"):
		print("Player keluar chase area")
		player_in_range = false
		nav_agent.target_position = global_position  # Biar AI berhenti di tempat

func _on_player_changed(new_player):
	player = new_player
	print("Enemy sekarang ngejar:", player)

func take_damage(amount: int, knockback_direction: Vector2, is_power_attack: bool = false) -> void:
	current_health -= amount
	#print(name + " took " + str(amount) + " damage, health: " + str(current_health))
	
	# Aplikasikan knockback
	var kb_force = 400 if is_power_attack else 200
	knockback_force = knockback_direction.normalized() * kb_force
	knockback_time = KNOCKBACK_DURATION
	
	# Flash effect saat terkena damage
	modulate = Color(7.0, 7.0, 7.0	, 7.0)  # Putih
	if hit_sound:
		hit_sound.play()
	await get_tree().create_timer(DAMAGE_FLASH_DURATION).timeout
	modulate = Color(1, 1, 1, 1.0)  # Normal
	
	# Cek apakah musuh mati
	if current_health <= 0:
		die()

# Fungsi untuk efek kematian
func die() -> void:
	# Tambahkan animasi atau efek kematian jika ada
	print(name + " has died!")
	GameManager.enemy_defeated()
	queue_free()  # Hapus enemy dari scene
