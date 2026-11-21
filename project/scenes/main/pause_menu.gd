class_name PauseMenu
extends Overlay
## The pause menu: Esc at the station and during the warp (SPEC Section 20.7).

const PAUSED_TEXT := "Paused"
const RESUME_TEXT := "Resume"
const HOW_TO_PLAY_TEXT := "How to Play"
const SETTINGS_TEXT := "Settings"
const ABANDON_TEXT := "Abandon Run"
const ABANDON_CONFIRM_TEXT := "Abandon this run? Its progress is lost."

var _confirm: ConfirmationDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	closed.connect(func() -> void: get_tree().paused = false)
	_confirm = ConfirmationDialog.new()
	TextSize.apply_to_dialog(_confirm)
	_confirm.confirmed.connect(_abandon)
	add_child(_confirm)
	super()


func _build() -> void:
	heading(PAUSED_TEXT)
	button(RESUME_TEXT, close).grab_focus()
	button(HOW_TO_PLAY_TEXT, func() -> void: add_child(HowToPlay.new()))
	button(SETTINGS_TEXT, func() -> void: add_child(SettingsPanel.new()))
	button(ABANDON_TEXT, func() -> void: _confirm.popup_centered())
	_confirm.dialog_text = tr(ABANDON_CONFIRM_TEXT)


func _abandon() -> void:
	close()
	GameState.abandon_run()
