# The pages are paragraphs of text for the player, so their lines are long.
# gdlint: disable=max-line-length
class_name HowToPlay
extends Overlay
## How to Play: 4 pages, each with a picture (SPEC Section 23.2).

const TITLE_TEXT := "How to Play"
const PAGE_TEXT := "{n} / {total}"
const NEXT_TEXT := "Next"
const BACK_TEXT := "Back"
const CLOSE_TEXT := "Close"
const PAGE_1_TEXT := """[b]Contracts and the hold[/b]

• Accept contracts. Their freight goes to the dock.
• Drag a cargo into the hold, or click it and then click a cell.
• Right click or R rotates it. Green fits, red does not."""
const PAGE_2_TEXT := """[b]The warp[/b]

• Each shift step slides all cargo to a wall or a stopped cargo.
• Force = weight × cells slid. Light {light}, standard {standard}, heavy {heavy}.
• Cargo at the front wall takes a jolt. Cargo that does not slide presses on the cargo in front of it. From leg 2, the last step is a fork."""
const PAGE_3_TEXT := """[b]Traits and reactions[/b]

• Fragile breaks at force {fragile}. Broken cargo becomes scrap and stays.
• Volatile explodes at force {volatile} and breaks the cargo around it.
• Fluid leaks at force {fluid} and shorts the Electronic cargo next to it."""
const PAGE_4_TEXT := """[b]Links, the shop, and payments[/b]

• Perishable needs a Cooler next to it. A Shield next to a Battery stops one reaction.
• Clamps stop a slide. Over the mass limit, the warp costs a fuel fee.
• Make the payment at the end of each leg, or the run ends."""
const PAGES: Array[String] = [PAGE_1_TEXT, PAGE_2_TEXT, PAGE_3_TEXT, PAGE_4_TEXT]

var _page := 0
var _picture: TutorialPicture
var _text: RichTextLabel
var _count: Label
var _next: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	box.custom_minimum_size.x = 820
	super()


func _build() -> void:
	heading(TITLE_TEXT)
	_picture = TutorialPicture.new()
	_picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_picture)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size.y = 200
	_text.add_theme_font_size_override("normal_font_size", 22)
	_text.add_theme_font_size_override("bold_font_size", 26)
	box.add_child(_text)
	_count = Label.new()
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_count)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var back := Button.new()
	back.text = tr(BACK_TEXT)
	back.custom_minimum_size = Vector2(200, 56)
	back.pressed.connect(func() -> void: _show(_page - 1))
	row.add_child(back)
	_next = Button.new()
	_next.custom_minimum_size = Vector2(200, 56)
	_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next.pressed.connect(_on_next)
	row.add_child(_next)
	# A new language keeps the page (SPEC Section 23.1).
	_show(_page)
	_next.grab_focus()


func _on_next() -> void:
	if _page == PAGES.size() - 1:
		close()
	else:
		_show(_page + 1)


func _show(page: int) -> void:
	_page = clampi(page, 0, PAGES.size() - 1)
	# The numbers come from the data (SPEC Sections 6.1 and 7).
	var names: Dictionary = GameState.view()["names"]
	var values: Dictionary = names.get("weight_values", {}).merged(names.get("limits", {}))
	_text.text = tr(PAGES[_page]).format(values)
	_picture.show_page(_page, names)
	_count.text = tr(PAGE_TEXT).format({"n": _page + 1, "total": PAGES.size()})
	_next.text = tr(CLOSE_TEXT if _page == PAGES.size() - 1 else NEXT_TEXT)
