class_name GameText
## Translates text from the view. A text with arguments is {key, args}: this
## class translates the key and each string argument, then fills in the placeholders.

## The name of the pilot (SPEC Section 22). It is not translated.
const PILOT_NAME := "MAGELLAN"


static func format(text: Variant) -> String:
	if text is String:
		return TranslationServer.translate(text)
	if not text is Dictionary or str(text.get("key", "")) == "":
		return ""
	var args := {}
	var raw: Dictionary = text.get("args", {})
	for name: String in raw:
		var v: Variant = raw[name]
		args[name] = str(int(v)) if v is float or v is int else TranslationServer.translate(str(v))
	return TranslationServer.translate(text["key"]).format(args)
