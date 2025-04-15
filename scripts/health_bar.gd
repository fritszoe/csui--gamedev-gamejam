# HealthBar.gd
extends Node2D

@onready var progress_bar = $ProgressBar
var parent_player = null
var level = null

func _ready():
	# Mendapatkan parent (player) yang memiliki healthbar ini
	parent_player = get_parent()
	level = parent_player.get_parent()
	
	# Atur ukuran dan posisi
	progress_bar.max_value = parent_player.max_health
	progress_bar.value = parent_player.current_health
	
	# Connect health_changed signal jika ada
	if parent_player.has_signal("health_changed"):
		parent_player.health_changed.connect(_on_health_changed)
		
	if level.has_signal("player_health_changed"):
		if level.is_connected("player_health_changed", _on_health_changed):
			level.disconnect("player_health_changed", _on_health_changed)
		level.connect("player_health_changed", _on_health_changed)
	
func _on_health_changed(new_health):
	progress_bar.value = new_health
	
	# Optional: Animasi feedback saat health berubah
	modulate = Color(1.0, 0.3, 0.3)  # Merah
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1.0, 1.0, 1.0)  # Normal
