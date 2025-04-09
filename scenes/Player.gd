extends CharacterBody2D

@export var speed: int = 400
@export var gravity: int = 1200
@export var jump_speed: int = -400
@export var max_jumps: int = 2  # Allows double jump

var jump_count: int = 0  # Tracks jumps

@onready var anim = $Animator
@onready var sprite = $Sprite2D

func get_input():
	velocity = Vector2.ZERO  # Reset velocity biar tidak ada sisa gerakan sebelumnya

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_speed
			jump_count = 1  # First jump
		elif jump_count < max_jumps:
			velocity.y = jump_speed
			jump_count += 1  # Second jump

	if Input.is_action_pressed("right"):
		velocity.x += speed
	elif Input.is_action_pressed("left"):
		velocity.x -= speed

	# ✅ Tambahkan gerakan vertikal seperti Swordsman
	if Input.is_action_pressed("up"):
		velocity.y -= speed
	elif Input.is_action_pressed("down"):
		velocity.y += speed

func _physics_process(delta):
	get_input()
	move_and_slide()

	if is_on_floor():
		jump_count = 0

func _process(_delta):
	if not is_on_floor():
		anim.play("Jump")
	elif velocity.length() > 0:  # Jika ada pergerakan, mainkan animasi berjalan
		anim.play("Walk")
	else:
		anim.play("Idle")

	# ✅ Flip sprite saat bergerak ke kiri atau kanan
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
