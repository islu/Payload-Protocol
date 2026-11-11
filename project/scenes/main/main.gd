extends Control
## The main scene. Day 4 replaces this placeholder with the screens of SPEC Section 20.

@onready var _label: Label = $Label


func _ready() -> void:
	_label.text = "Payload Protocol %s" % GameState.VERSION
