extends Control


@onready var player = get_node("/root/world/player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Label.text = "Status: "

	match player.state:
		player.player_state.IDLE:
			$Label.text += "Idle"
		player.player_state.RUNNING:
			$Label.text += "Running"
		player.player_state.JUMPING:
			$Label.text += "Jumping"
		player.player_state.SPIKING:
			$Label.text += "Spiking"
		player.player_state.RECEIVING:
			$Label.text += "Receiving"
		player.player_state.FRONT_SETTING:
			$Label.text += "Front setting"
		player.player_state.DIVING:
			$Label.text += "Diving"
