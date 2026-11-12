# The pages are paragraphs of text for the player, so their lines are long.
# gdlint: disable=max-line-length
class_name HowToPlay
extends Overlay
## How to Play: 4 pages (SPEC Section 23.2). Day 7 adds a picture to each page.

const TITLE_TEXT := "How to Play"
const PAGE_TEXT := "{n} / {total}"
const NEXT_TEXT := "Next"
const BACK_TEXT := "Back"
const CLOSE_TEXT := "Close"
const PAGE_1_TEXT := """[b]Contracts and the hold[/b]

Accept contracts at the station. Their freight goes to the dock.
Drag each cargo into the hold. A green preview fits, a red one does not.
Right click or press R to rotate a cargo."""
const PAGE_2_TEXT := """[b]The warp[/b]

The hazard panel shows each shift step of the next jump, in order.
In each step, all cargo slides in that direction until a wall or a stopped cargo blocks it.
Force = weight × cells that it slid. Light {light}, standard {standard}, heavy {heavy}.
A cargo that does not slide makes no hit."""
const PAGE_3_TEXT := """[b]Traits and reactions[/b]

Fragile breaks at force {fragile}. Volatile explodes at force {volatile} and breaks the cargo around it.
Fluid leaks at force {fluid} and shorts each Electronic cargo next to it.
Broken cargo becomes scrap. Scrap stays in the hold and takes space."""
const PAGE_4_TEXT := """[b]Links, clamps, the shop, and tolls[/b]

Perishable cargo needs a Cooler next to it at the arrival.
A Shield next to a Battery protects the cargo next to it from one reaction.
A clamp stops a cargo from sliding. Buy kit, clamps, and a bigger hold in the shop.
Pay the toll at the end of each sector, or the run ends."""
const PAGES: Array[String] = [PAGE_1_TEXT, PAGE_2_TEXT, PAGE_3_TEXT, PAGE_4_TEXT]

var _page := 0
var _text: RichTextLabel
var _count: Label
var _next: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	box.custom_minimum_size.x = 820
	heading(TITLE_TEXT)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size.y = 260
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
	_show(0)
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
	_count.text = tr(PAGE_TEXT).format({"n": _page + 1, "total": PAGES.size()})
	_next.text = tr(CLOSE_TEXT if _page == PAGES.size() - 1 else NEXT_TEXT)
