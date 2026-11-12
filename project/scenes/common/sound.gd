class_name Sound
## Plays a sound effect by name from res://audio/sfx/<name>.wav or .ogg
## (SPEC Section 4.3). A missing file plays nothing, so each scene works with no sounds.

## The name of each sound that the scenes play (SPEC Section 21). The UI check
## fails when a name has no file. tools/sfx/make_sfx.py makes the placeholders.
const NAMES: PackedStringArray = [
	"alarm",
	"buzz",
	"clack",
	"coin",
	"deny",
	"explosion",
	"glass_break",
	"metal_hit",
	"rumble",
	"shield",
	"soft_hit",
	"splash",
	"squelch",
]


## Returns whether a sound name has a file.
static func exists(sound: String) -> bool:
	return _stream(sound) != null


static func play(node: Node, sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	# Headless runs (the tests) have no audio device, so a sound never ends there.
	if DisplayServer.get_name() == "headless":
		return
	var stream := _stream(sound)
	if stream == null or not node.is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = volume_db
	player.pitch_scale = pitch
	node.get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## Returns the stream of a sound, or null. load() keeps each stream in the cache
## of Godot, so a static cache here is not necessary. A static cache would also keep
## the streams after the exit.
static func _stream(sound: String) -> AudioStream:
	for ext in ["wav", "ogg"]:
		var path := "res://audio/sfx/%s.%s" % [sound, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null
