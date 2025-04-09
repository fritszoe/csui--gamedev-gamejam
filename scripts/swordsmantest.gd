extends CharacterBody2D

@export var speed: float = 120.0
var is_attacking: bool = false

@onready var anim = $AnimationPlayer
@onready var attack_timer = Timer.new()
@onready var sprite = $Sprite2D
@onready var melee_atk = $Sprite2D/MeleeAtk
@onready var melee_atk_collision = $Sprite2D/MeleeAtk/MeleeAtkCollision
@onready var pow_slash_area = $Sprite2D/PowSlashArea
@onready var pow_slash_collision = $Sprite2D/PowSlashArea/CollisionShape2D
@onready var player = get_node("../Swordsmantest")

func _ready() -> void:
	print("Player node type: ", player.get_class())  # Menampilkan kelas node
	print("Player node name: ", player.name)  # Menampilkan nama node
	print(player)
	print(player.name)

	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	# Connect the signals for body entered in the area
	melee_atk.body_entered.connect(_on_melee_attack_body_entered)
	pow_slash_area.body_entered.connect(_on_pow_slash_body_entered)

# Deteksi musuh yang terkena melee attack
func _on_melee_attack_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name != player.name:  # Jika objek adalah musuh
		if is_attacking == true:
			print("Musuh terkena serangan melee!")
			body.queue_free()  # Menghapus musuh dari scene

 #Deteksi musuh yang terkena power slash
func _on_pow_slash_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name != player.name:  # Jika objek adalah musuh
		if is_attacking == true:
			print("Musuh terkena serangan PowerSlash!")
			body.queue_free()  # Menghapus musuh dari scene

func _process(delta: float) -> void:
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
		attack_power()
		
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
	anim.play("Melee")

	# Aktifkan collision area serangan Melee
	melee_atk.collision_layer = 1  # Set collision layer ke 1 (atau layer yang diinginkan)

	# Set Timer untuk reset is_attacking setelah durasi animasi
	attack_timer.start(anim.get_animation("Melee").length)

func attack_power() -> void:
	print('powerslash')
	is_attacking = true
	await get_tree().process_frame # Tunggu satu frame untuk memastikan is_attacking diatur
	print(is_attacking)
	anim.play("PowerSlash")
	pow_slash_area.collision_layer = 1
	attack_timer.start(anim.get_animation("PowerSlash").length)
	
func _on_attack_timer_timeout() -> void:
	print(is_attacking)
	print("Melee selesai (Timer), kembali ke idle/walk")
	is_attacking = false
	print(is_attacking)
	# Nonaktifkan collision area setelah animasi selesai
	melee_atk.collision_layer = 0  # Nonaktifkan collision layer
	pow_slash_area.collision_layer = 0  # Nonaktifkan collision layer
	
	# Tambahkan logika body.queue_free() di sini
	if anim.current_animation == "PowerSlash": # Periksa apakah animasi PowerSlash selesai
		var bodies = pow_slash_area.get_overlapping_bodies()
		for body in bodies:
			if body is CharacterBody2D and body.name != player.name:
				print("Musuh terkena serangan PowerSlash!")
				body.queue_free()

func update_facing_direction(direction: int) -> void:
	transform.x.x = direction
