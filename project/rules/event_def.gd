class_name EventDef
extends RefCounted
## An event that a station can show (SPEC Section 26). The data is in
## data/events/<id>.json.

var id: String
var name: String
var text: String
## Each choice: {text: String, cost: int, effects: Array of {type, amount, cargo, contract}}.
var choices: Array[Dictionary] = []


static func from_dict(d: Dictionary) -> EventDef:
	var e := EventDef.new()
	e.id = str(d.get("id", ""))
	e.name = str(d.get("name", ""))
	e.text = str(d.get("text", ""))
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
		e.choices.append(
			{"text": str(c.get("text", "")), "cost": int(c.get("cost", 0)), "effects": effects}
		)
	return e
