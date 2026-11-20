class_name GameText
## Translates text from the view. A text with arguments is {key, args}: this
## class translates the key and each string argument, then fills in the placeholders.
## An argument can be a text too.

## The name of the pilot (SPEC Section 22). It is translated: use pilot_name().
const PILOT_NAME_TEXT := "MAGELLAN"


## Returns the name of the pilot in the language now (SPEC Section 22).
static func pilot_name() -> String:
	return TranslationServer.translate(PILOT_NAME_TEXT)


static func format(text: Variant) -> String:
	if text is String:
		return TranslationServer.translate(text)
	if not text is Dictionary or str(text.get("key", "")) == "":
		return ""
	var args := {}
	var raw: Dictionary = text.get("args", {})
	for name: String in raw:
		var v: Variant = raw[name]
		if v is Dictionary:
			args[name] = format(v)
		elif v is float or v is int:
			args[name] = str(int(v))
		else:
			args[name] = TranslationServer.translate(str(v))
	return TranslationServer.translate(text["key"]).format(args)


## Returns the line of a trait: "Name: rule" from the terms of the view, or "" for a
## trait that is not in terms (SPEC Section 8.4). With colored, the name has the color
## of the trait in BBCode, for a RichTextLabel.
static func trait_line(terms: Array, trait_id: String, colored := false) -> String:
	for term: Dictionary in terms:
		if term["id"] != trait_id:
			continue
		var name := TranslationServer.translate(term["name"])
		if colored:
			var color: Color = Palette.trait_color(trait_id)
			name = "[color=#%s]%s[/color]" % [color.to_html(false), name]
		return "%s: %s" % [name, format(term["rule"])]
	return ""
