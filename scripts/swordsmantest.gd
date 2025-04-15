extends CharacterBody2D

signal health_changed(new_health)	

@export var speed: float = 170.0
var is_attacking: bool = false
var current_attack_type: String = ""  # Variabel baru untuk melacak jenis serangan

var can_power_slash: bool = true
var power_slash_cooldown: float = 3.0
var current_power_slash_cooldown: float = 0.0

@onready var anim = $AnimationPlayer
@onready var attack_timer = Timer.new()
@onready var sprite = $Sprite2D
@onready var melee_atk = $Sprite2D/MeleeAtk
@onready var melee_atk_collision = $Sprite2D/MeleeAtk/MeleeAtkCollision
@onready var pow_slash_area = $Sprite2D/PowSlashArea
@onready var pow_slash_collision = $Sprite2D/PowSlashArea/CollisionShape2D
@onready var player = get_node("../Swordsmantest")
@onready var melee_sound = $MeleeSound
@onready var pow_slash_sound = $PowSlashSound
@onready var hit_sound = $HitSound

var max_health = 100
var current_health = 100
var knockback_force = Vector2.ZERO
var knockback_time = 0.0
const KNOCKBACK_DURATION = 0.1
const DAMAGE_FLASH_DURATION = 0.1
const MELEE_DAMAGE = 30
const POWER_SLASH_DAMAGE = 70

func _ready() -> void:
	#print("Player node type: ", player.get_class())  # Menampilkan kelas node
	#print("Player node name: ", player.name)  # Menampilkan nama node
	#print(player)
	#print(player.name)
	add_to_group("player")

	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	# Connect the signals for body entered in the area
	melee_atk.body_entered.connect(_on_melee_attack_body_entered)
	check_power_slash_availability()

func check_power_slash_availability():
	# PowerSlash hanya tersedia di level 2+
	if Engine.has_singleton("GameManager"):
		can_power_slash = GameManager.power_slash_unlocked
		
		if not can_power_slash:
			print("PowerSlash belum tersedia di level ini!")
			# Optional: Sembunyikan UI PowerSlash
			if has_node("PowerSlashIcon"):
				$PowerSlashIcon.visible = false
		else:
			print("PowerSlash tersedia! Tekan tombol PowerSlash untuk menggunakan.")
			# Optional: Tampilkan UI PowerSlash
			if has_node("PowerSlashIcon"):
				$PowerSlashIcon.visible = true

# Deteksi musuh yang terkena melee attack
func _on_melee_attack_body_entered(body: Node2D) -> void:
	if is_attacking and current_attack_type == "melee" and body is CharacterBody2D and not body.is_in_group("player"):
		print("Musuh terkena serangan melee!")
		
		# Ambil arah knockback (dari player ke musuh)
		var knockback_dir = (body.global_position - global_position).normalized()
		
		# Check jika body memiliki fungsi take_damage
		if body.has_method("take_damage"):
			body.take_damage(MELEE_DAMAGE, knockback_dir, false)

func _process(delta: float) -> void:
	if GameManager.power_slash_unlocked:
		if not can_power_slash:
			current_power_slash_cooldown -= delta
			if current_power_slash_cooldown <= 0:
				can_power_slash = true
				print("Power Slash ready!")

	if knockback_time > 0:
		knockback_time -= delta
		velocity = knockback_force
		move_and_slide()
		return

	var direction := Vector2.ZERO

	if Input.is_action_pressed("left"):
		direction.x = -1
	elif Input.is_action_pressed("right"):
		direction.x = 1
	if Input.is_action_pressed("up"):
		direction.y = -1
	elif Input.is_action_pressed("down"):
		direction.y = 1
	if direction.x != 0:
		update_facing_direction(direction.x)
	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
	
	if Input.is_action_just_pressed("powslash") and not is_attacking:
		if GameManager.power_slash_unlocked:
			if can_power_slash:
				attack_power()
			else:
				# Feedback cooldown
				print("Power Slash on cooldown! Remaining: " + str(current_power_slash_cooldown) + " seconds")
				modulate = Color(0.5, 0.5, 1.0, 1.0)  # Warna biru
				await get_tree().create_timer(0.1).timeout
				modulate = Color(1, 1, 1, 1.0)  # Normal
		else:
			# PowerSlash belum terbuka, tampilkan pesan
			print("PowerSlash belum tersedia di level ini!")
			modulate = Color(0.7, 0.7, 0.7, 1.0)  # Warna abu-abu
			await get_tree().create_timer(0.2).timeout
			modulate = Color(1, 1, 1, 1.0)  # Normal
		
	if not is_attacking:
		if direction != Vector2.ZERO:
			anim.play("Walk")
		else:
			anim.play("Idle")

	velocity = direction * speed
	move_and_slide()

func attack() -> void:
	print("attacking")
	is_attacking = true
	current_attack_type = "melee"
	anim.play("Melee")
	
	if melee_sound:
		melee_sound.play()
	# Aktifkan collision area serangan Melee
	melee_atk.collision_layer = 1  # Set collision layer ke 1 (atau layer yang diinginkan)

	# Set Timer untuk reset is_attacking setelah durasi animasi
	attack_timer.start(anim.get_animation("Melee").length)

func attack_power() -> void:
	print('powerslash')
	is_attacking = true
	current_attack_type = "power"
	print(is_attacking)
	anim.play("PowerSlash")
	if pow_slash_sound:
		pow_slash_sound.play()
		
	pow_slash_area.collision_layer = 1
	
	var anim_length = anim.get_animation("PowerSlash").length
	var damage_time = anim_length * 0.5  # 50% dari durasi animasi
	await get_tree().create_timer(damage_time).timeout
	var bodies = pow_slash_area.get_overlapping_bodies()
	for body in bodies:
		if body is CharacterBody2D and not body.is_in_group("player"):
			print("Musuh terkena serangan PowerSlash!")
			
			# Knockback lebih kuat untuk power slash
			var knockback_dir = (body.global_position - global_position).normalized()
			
			if body.has_method("take_damage"):
				body.take_damage(POWER_SLASH_DAMAGE, knockback_dir, true)
	
	# Tunggu sampai animasi selesai
	await get_tree().create_timer(anim_length - damage_time).timeout
	
	# Reset status setelah animasi selesai
	is_attacking = false
	current_attack_type = ""
	
	# Nonaktifkan collision area
	pow_slash_area.collision_layer = 0
	
	# Set cooldown
	can_power_slash = false
	current_power_slash_cooldown = power_slash_cooldown
	print("Power Slash on cooldown for " + str(power_slash_cooldown) + " seconds")
	
func _on_attack_timer_timeout() -> void:
	print("Serangan selesai (Timer)")
	
	# Reset status setelah animasi selesai
	is_attacking = false
	current_attack_type = ""
	
	# Nonaktifkan collision area setelah animasi selesai
	melee_atk.collision_layer = 0  # Nonaktifkan collision layer
	pow_slash_area.collision_layer = 0  # Nonaktifkan collision layer


func update_facing_direction(direction: int) -> void:
	transform.x.x = direction

func take_damage(amount: int, knockback_direction: Vector2, _is_strong: bool = false) -> void:
	current_health -= amount
	print("Player took " + str(amount) + " damage, health: " + str(current_health))
	
	emit_signal("health_changed", current_health)
	# Aplikasikan knockback
	knockback_force = knockback_direction.normalized() * 300
	knockback_time = KNOCKBACK_DURATION
	
	# Flash effect saat terkena damage
	modulate = Color(1, 0.3, 0.3, 1.0)  # Merah
	if hit_sound:
		hit_sound.play()
	await get_tree().create_timer(DAMAGE_FLASH_DURATION).timeout
	modulate = Color(1, 1, 1, 1.0)  # Normal
	
	# Cek apakah player mati
	if current_health <= 0:
		die()

func die() -> void:
	print("Player has died! Game Over")
	# Implementasi game over screen
	# Contoh sederhana:
	set_process_input(false)
	set_physics_process(false)
	anim.play("Die")  # Jika ada animasi mati
	
	# Tampilkan UI game over (implementasi terpisah)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")  # Reload scene atau tampilkan menu game over
