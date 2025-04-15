# HUD.gd
extends CanvasLayer

@onready var health_bar = $Control/ProgressBar
@onready var player = get_node("/root/Level1/Swordsmantest")  # Sesuaikan path

func _ready():
	# Set max value ke max health player
	health_bar.max_value = player.max_health
	health_bar.value = player.current_health
	
	# Connect signal
	player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(new_health):
	health_bar.value = new_health
