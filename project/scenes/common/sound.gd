class_name Sound
## Plays a sound effect by name from res://audio/sfx/<name>.wav or .ogg
## (SPEC Section 4.3). A missing file plays nothing, so each scene works with no sounds.

static var _cache: Dictionary = {}


static func play(node: Node, sound: String, volume_db := 0.0, pitch := 1.0) -> void:
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


static func _stream(sound: String) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	var stream: AudioStream = null
	for ext in ["wav", "ogg"]:
		var path := "res://audio/sfx/%s.%s" % [sound, ext]
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	_cache[sound] = stream
	return stream
