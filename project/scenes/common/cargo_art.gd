class_name CargoArt
## The pixel art images of the cargo in res://art/cargo (task art, SPEC Section 4.2).
## Each cargo ID has <id>.png (100 pixels for each cell of the box of its shape),
## <id>_scrap.png (the image in gray), and <id>.json ({"shape": the cells at rotation 0}).

const DIR := "res://art/cargo/"

## The cache: {id: {texture, scrap, shape}}, or {} for a cargo with no image.
static var _cache: Dictionary = {}


## Returns the image of a cargo, or its scrap image, or null.
static func texture(def_id: String, scrap := false) -> Texture2D:
	var a := _art(def_id)
	if a.is_empty():
		return null
	return a["scrap"] if scrap else a["texture"]


## Returns the quarter turns (0 to 3, clockwise) of the image of a cargo for a
## shape in the view. The image stays upright when the cells allow it: the
## smallest turn that gives the same cells (SPEC Section 4.2). -1: no image.
static func turns(def_id: String, shape: Array) -> int:
	var a := _art(def_id)
	if a.is_empty():
		return -1
	var want := _cells(shape)
	for q in 4:
		if _cells(Shapes.to_view(Shapes.rotate(a["shape"], q))) == want:
			return q
	return 0


## Draws the image of a cargo over the box of its shape. origin is the upper left
## of the box. It returns false when the cargo has no image.
static func draw(
	canvas: CanvasItem,
	def_id: String,
	shape: Array,
	origin: Vector2,
	cell: float,
	scrap: bool,
	modulate: Color
) -> bool:
	var tex := texture(def_id, scrap)
	var q := turns(def_id, shape)
	if tex == null or q < 0:
		return false
	var k := cell / 100.0
	var s := tex.get_size() * k
	# The image turns about its upper left. Move it back into the box.
	var offsets: Array[Vector2] = [Vector2.ZERO, Vector2(s.y, 0), s, Vector2(0, s.x)]
	canvas.draw_set_transform(origin + offsets[q], q * PI / 2.0)
	canvas.draw_texture_rect(tex, Rect2(Vector2.ZERO, s), false, modulate)
	canvas.draw_set_transform(Vector2.ZERO)
	return true


static func _art(def_id: String) -> Dictionary:
	if _cache.has(def_id):
		return _cache[def_id]
	var a := {}
	var path := DIR + def_id
	if ResourceLoader.exists(path + ".png") and FileAccess.file_exists(path + ".json"):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path + ".json"))
		if data is Dictionary:
			var shape: Array[Vector2i] = []
			for c: Array in data["shape"]:
				shape.append(Vector2i(int(c[0]), int(c[1])))
			a = {
				"texture": load(path + ".png"),
				"scrap": load(path + "_scrap.png"),
				"shape": shape,
			}
	_cache[def_id] = a
	return a


static func _cells(shape: Array) -> Array:
	var out := []
	for c: Dictionary in shape:
		out.append(Vector2i(int(c["x"]), int(c["y"])))
	out.sort()
	return out
