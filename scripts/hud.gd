extends CanvasLayer

@onready var player: FirstPersonPlayer = get_parent().get_node("Player")
@onready var capture_prompt: PanelContainer = $CapturePrompt
@onready var crosshair: Label = $Crosshair

var _has_started: bool = false


func _ready() -> void:
	player.controls_changed.connect(_on_controls_changed)
	_on_controls_changed(player.controls_active)


func _on_controls_changed(active: bool) -> void:
	_has_started = _has_started or active
	var prompt := "Click to resume exploring" if _has_started else "Click to start exploring"
	capture_prompt.get_node("Text").text = prompt + "\nWASD to move · Mouse to look"
	capture_prompt.visible = not active
	crosshair.visible = active
