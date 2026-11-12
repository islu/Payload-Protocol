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


## Saves a setting, keeps the other settings, and applies it.
static func set_value(key: String, value: Variant) -> void:
	_load().set_value(SECTION, key, value)
	_config.save(PATH)
	apply()


## Applies all settings: the volumes, the window, and the language.
static func apply() -> void:
	_set_bus("Music", get_value("music_volume"))
	_set_bus("SFX", get_value("sound_volume"))
	TranslationServer.set_locale(get_value("locale"))
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
