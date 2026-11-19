class_name TextSize
## The four sizes of the text, in pixels (SPEC Section 4.2). Text with no other size
## has the body size: the theme has it as its default. Display text, such as the
## title of the game and the Warp button, has its own size: set it with display().

const HEADING := 28
const BODY := 22
const SMALL := 18
const BUTTON := 24
## The meta of display text. The UI check does not check its size.
const DISPLAY_META := "display_text"


## Sets the size of a display text (SPEC Section 4.2). For a container, the text in
## it is display text too.
static func display(control: Control, font_size := 0) -> void:
	control.set_meta(DISPLAY_META, true)
	if font_size > 0:
		control.add_theme_font_size_override("font_size", font_size)


## Sets the sizes of the text and the buttons of a dialog.
static func apply_to_dialog(dialog: AcceptDialog) -> void:
	dialog.get_label().add_theme_font_size_override("font_size", BODY)
	dialog.get_ok_button().add_theme_font_size_override("font_size", BUTTON)
	if dialog is ConfirmationDialog:
		dialog.get_cancel_button().add_theme_font_size_override("font_size", BUTTON)
