extends CanvasLayer

@onready var player: FirstPersonPlayer = get_parent().get_node("Player")
@onready var capture_prompt: PanelContainer = $CapturePrompt
@onready var crosshair: Label = $Crosshair


func _ready() -> void:
	player.controls_changed.connect(_on_controls_changed)
	_on_controls_changed(player.controls_active)


func _on_controls_changed(active: bool) -> void:
	capture_prompt.visible = not active
	crosshair.visible = active
