extends Node2D

@export var target_path: NodePath
@onready var target = get_node(target_path)
@onready var progress_bar = $ProgressBar

func _ready():
	progress_bar.max_value = target.max_health
	progress_bar.value = target.current_health

	if target.has_signal("health_changed"):
		target.health_changed.connect(_on_health_changed)


func set_target(new_target: Node2D):
	target = new_target
	print(new_target)
	
	print(target.max_health)
	print(target.current_health)
	progress_bar.max_value = target.max_health
	progress_bar.value = target.current_health

	if target.has_signal("health_changed"):
		# Disconnect dulu biar aman kalau sudah connect sebelumnya
		if target.is_connected("health_changed", _on_health_changed):
			target.disconnect("health_changed", _on_health_changed)
		target.connect("health_changed", _on_health_changed)

func _process(delta):
	if target:
		global_position = target.global_position + Vector2(-50, -50)  # posisi di atas kepala
		rotation = 0
		scale = Vector2(1, 1)  # pastikan tidak ikut flip

func _on_health_changed(new_health):
	progress_bar.value = new_health
