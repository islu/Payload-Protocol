class_name Settings
## The settings of the player in user://settings.cfg (SPEC Section 23.1). They are
## presentation only, not game state.

const PATH := "user://settings.cfg"
const SECTION := "settings"
const DEFAULTS := {
	"music_volume": 70,
	"sound_volume": 80,
	"crt": true,
	"shake": true,
	"warp_speed": 1,
	"fullscreen": false,
	"locale": "en",
	"hints": true,
	# Pick up the next cargo of the dock after a placement (SPEC Sections 8.2 and 23.1).
	"pick_next": true,
	# The progress of the hints (SPEC Section 23.3).
	"hints_seen": [],
	"runs_started": 0,
}
const LOCALES: PackedStringArray = ["en", "zh_TW"]

## The settings in memory. The file is read one time.
static var _config: ConfigFile = null


## Returns a setting, or its default when the file or the key is missing.
static func get_value(key: String) -> Variant:
	return _load().get_value(SECTION, key, DEFAULTS.get(key))


static func _load() -> ConfigFile:
	if _config == null:
		_config = ConfigFile.new()
		_config.load(PATH)  # A missing file is not an error.
	return _config


## Sets a setting, keeps the other settings, and applies it. With save false, it
## does not write the file: a slider saves at the end of its drag (save()).
static func set_value(key: String, value: Variant, save_now := true) -> void:
	_load().set_value(SECTION, key, value)
	if save_now:
		save()
	_apply_key(key)


## Writes the settings to the file.
static func save() -> void:
	_load().save(PATH)


## Applies all settings: the volumes, the window, and the language.
static func apply() -> void:
	for key: String in ["music_volume", "sound_volume", "locale", "fullscreen"]:
		_apply_key(key)


## Applies one setting. The other settings have no effect until a screen reads them.
static func _apply_key(key: String) -> void:
	match key:
		"music_volume":
			_set_bus("Music", get_value(key))
		"sound_volume":
			_set_bus("SFX", get_value(key))
		"locale":
			TranslationServer.set_locale(get_value(key))
		"fullscreen":
			_set_window()


static func _set_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var full: bool = get_value("fullscreen")
	var mode := DisplayServer.window_get_mode()
	var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	if full != is_full:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_MAXIMIZED
		)


static func _set_bus(bus: String, percent: int) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, percent <= 0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(percent, 1) / 100.0))
