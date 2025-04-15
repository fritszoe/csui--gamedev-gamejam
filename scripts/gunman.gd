extends CharacterBody2D

signal health_changed(new_health)	

@export var speed: float = 150.0
var is_attacking: bool = false
var current_attack_type: String = ""  # Variabel baru untuk melacak jenis serangan

var can_power_slash: bool = true
var power_slash_cooldown: float = 3.0
var current_power_slash_cooldown: float = 0.0

@onready var anim = $AnimationPlayer
@onready var attack_timer = Timer.new()
@onready var sprite = $Sprite2D
@onready var gun_atk = $Sprite2D/GunAtk
@onready var gun_atk_collision = $Sprite2D/GunAtk/GunAtkCollision
@onready var hit_sound = $HitSound
@onready var fire_sound = $FireSound

var max_health = 100
var current_health = 100
var knockback_force = Vector2.ZERO
var knockback_time = 0.0
const KNOCKBACK_DURATION = 0.1
const DAMAGE_FLASH_DURATION = 0.1
const SHOT_DAMAGE = 15

func _ready() -> void:
	#print("Player node type: ", player.get_class())  # Menampilkan kelas node
	#print("Player node name: ", player.name)  # Menampilkan nama node
	#print(player)
	#print(player.name)
	add_to_group("player")

	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _process(delta: float) -> void:
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
	current_attack_type = "fire"
	anim.play("Fire")
	fire_sound.play()
	# Aktifkan collision area serangan Melee
	gun_atk.collision_layer = 1  # Set collision layer ke 1 (atau layer yang diinginkan)
	
	var anim_length = anim.get_animation("Fire").length
	var damage_time = anim_length * 0.4  # Waktu damage di 40% animasi
	
	# Tunggu sampai waktu damage
	await get_tree().create_timer(damage_time).timeout
	
	# Memberikan damage di titik tertentu dalam animasi
	print("Checking for enemies in gun range...")
	var bodies = gun_atk.get_overlapping_bodies()
	for body in bodies:
		if body is CharacterBody2D and not body.is_in_group("player"):
			print("Musuh terkena tembakan di frame animasi!")
			
			# Ambil arah knockback (dari player ke musuh)
			var knockback_dir = (body.global_position - global_position).normalized()
			
			if body.has_method("take_damage"):
				print("Memberikan damage pada musuh:", SHOT_DAMAGE)
				body.take_damage(SHOT_DAMAGE, knockback_dir, false)
	
	# Tunggu sampai animasi selesai
	await get_tree().create_timer(anim_length - damage_time).timeout
	
	# Reset status
	is_attacking = false
	current_attack_type = ""

func _on_attack_timer_timeout() -> void:
	print("Serangan selesai (Timer)")
	
	# Reset status setelah animasi selesai
	is_attacking = false
	current_attack_type = ""
	
	# Nonaktifkan collision area setelah animasi selesai
	gun_atk.collision_layer = 0  # Nonaktifkan collision layer


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


func _on_gun_atk_body_entered(body: Node2D) -> void:
	print('ada yg masuk')
	if is_attacking and current_attack_type == "fire" and body is CharacterBody2D and not body.is_in_group("player"):
		print("Musuh terkena tembakan!")
		
		# Ambil arah knockback (dari player ke musuh)
		var knockback_dir = (body.global_position - global_position).normalized()
		
		# Check jika body memiliki fungsi take_damage
		if body.has_method("take_damage"):
			body.take_damage(SHOT_DAMAGE, knockback_dir, false)
