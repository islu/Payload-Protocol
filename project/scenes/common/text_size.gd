class_name TextSize
## The four sizes of the text, in pixels (SPEC Section 4.2). Display text, such as
## the title of the game and the Warp button, has its own size.

const HEADING := 24
const BODY := 18
const SMALL := 15
const BUTTON := 20


## Sets the sizes of the text and the buttons of a dialog.
static func apply_to_dialog(dialog: AcceptDialog) -> void:
	dialog.get_label().add_theme_font_size_override("font_size", BODY)
	dialog.get_ok_button().add_theme_font_size_override("font_size", BUTTON)
	if dialog is ConfirmationDialog:
		dialog.get_cancel_button().add_theme_font_size_override("font_size", BUTTON)
