class_name EventDef
extends RefCounted
## An event that a station can show (SPEC Section 26). The data is in
## data/events/<id>.json.

var id: String
var name: String
var text: String
## The ID of the speaker: the character who speaks in the event (SPEC Section 20.8).
var speaker: String
## Each choice: {text: String, cost: int, reply: String, effects: Array of {type, amount,
## cargo, contract}}. The reply is the line of the speaker after the choice (SPEC Section 26.2).
var choices: Array[Dictionary] = []


static func from_dict(d: Dictionary) -> EventDef:
	var e := EventDef.new()
	e.id = str(d.get("id", ""))
	e.name = str(d.get("name", ""))
	e.text = str(d.get("text", ""))
	e.speaker = str(d.get("speaker", ""))
	for c: Dictionary in d.get("choices", []):
		var effects: Array[Dictionary] = []
		for f: Dictionary in c.get("effects", []):
			(
				effects
				. append(
					{
						"type": str(f.get("type", "")),
						"amount": int(f.get("amount", 0)),
						"cargo": str(f.get("cargo", "")),
						"contract": str(f.get("contract", "")),
					}
				)
			)
		(
			e
			. choices
			. append(
				{
					"text": str(c.get("text", "")),
					"cost": int(c.get("cost", 0)),
					"reply": str(c.get("reply", {}).get("text", "")),
					"effects": effects,
				}
			)
		)
	return e
