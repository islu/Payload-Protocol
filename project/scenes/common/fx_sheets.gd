class_name FxSheets
## Loads the sprite sheets of the effects in res://art/fx (SPEC Sections 4.2 and 21).
## `task fx` makes them: <name>.png has the frames in a grid, and <name>.json has
## {fps, frames, size, columns, pivot, scale}.

const DIR := "res://art/fx/"

## The loaded sheets by name. A sheet is read one time.
static var _cache := {}


## Returns {texture, fps, frames, size: Vector2, columns, pivot: Vector2, scale},
## or {} when the files are missing.
static func sheet(name: String) -> Dictionary:
	if _cache.has(name):
		return _cache[name]
	var png := DIR + name + ".png"
	var text := FileAccess.get_file_as_string(DIR + name + ".json")
	if text == "" or not ResourceLoader.exists(png):
		return {}
	var info: Dictionary = JSON.parse_string(text)
	var s := {
		"texture": load(png),
		"fps": float(info["fps"]),
		"frames": int(info["frames"]),
		"size": Vector2(info["size"][0], info["size"][1]),
		"columns": int(info["columns"]),
		"pivot": Vector2(info["pivot"][0], info["pivot"][1]),
		"scale": float(info["scale"]),
	}
	_cache[name] = s
	return s


## Returns the time of a sheet in seconds.
static func seconds(s: Dictionary) -> float:
	return s["frames"] / s["fps"]


## Returns the region of a frame in the texture.
static func region(s: Dictionary, frame: int) -> Rect2:
	var size: Vector2 = s["size"]
	var columns: int = s["columns"]
	return Rect2(Vector2(frame % columns, frame / columns) * size, size)
