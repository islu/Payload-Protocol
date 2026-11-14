class_name DataFiles
## Reads the JSON data files for the Catalog. The rules do not read files, so
## the game state and the tools read them here.

const DATA_DIR := "res://data"
const DIRS: PackedStringArray = ["cargo", "contracts", "lines", "events", "mods", "environments"]


## Returns the parsed data for Catalog.from_data(), from a data folder.
static func read(dir: String = DATA_DIR) -> Dictionary:
	var data := {"rules": _read_json(dir + "/rules.json"), "terms": _read_json(dir + "/terms.json")}
	for sub in DIRS:
		var files := {}
		for name in DirAccess.get_files_at(dir + "/" + sub):
			# An export lists the files with ".remap" or ".import" next to them. Use the JSON files only.
			if name.get_extension() == "json":
				files[name.get_basename()] = _read_json(dir + "/" + sub + "/" + name)
		data[sub] = files
	return data


## Reads the catalog from a data folder. Check errors before you use it.
static func catalog(dir: String = DATA_DIR) -> Catalog:
	return Catalog.from_data(read(dir))


static func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("cannot read the data file %s" % path)
	return {}
