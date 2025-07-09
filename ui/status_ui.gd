extends Control


@onready var player = get_node("/root/world/player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$Label.text = "Status: "

	match player.state:
		VBConst.player_state.IDLE:
			$Label.text += "Idle"
		VBConst.player_state.RUNNING:
			$Label.text += "Running"
		VBConst.player_state.JUMPING:
			$Label.text += "Jumping"
		VBConst.player_state.SPIKING:
			$Label.text += "Spiking"
		VBConst.player_state.RECEIVING:
			$Label.text += "Receiving"
		VBConst.player_state.FRONT_SETTING:
			$Label.text += "Front setting"
		VBConst.player_state.DIVING:
			$Label.text += "Diving"
		VBConst.player_state.BLOCKING:
			$Label.text += "Blocking"
