class_name ContractTemplate
extends RefCounted
## A contract that a station can offer (SPEC Section 15). The data is in
## data/contracts/<id>.json.

var id: String
var legs: Array[int] = []
var client_name: String
var freight: PackedStringArray = []
var pay: int = 0
## The bonus (SPEC Section 15.2): {type, pay, zone: {side, size}, trait}, or empty.
var bonus: Dictionary = {}
## The penalty of a VIP contract, or 0 (SPEC Section 30.1).
var penalty: int = 0
## The jumps of the freight: 2 for a long contract (SPEC Section 30.2).
var jumps: int = 1
## The tags of the look: Defs.CONTRACT_TAGS (SPEC Section 30.4).
var tags: PackedStringArray = []


static func from_dict(d: Dictionary) -> ContractTemplate:
	var t := ContractTemplate.new()
	t.id = str(d.get("id", ""))
	for s in d.get("legs", []):
		t.legs.append(int(s))
	t.client_name = str(d.get("client_name", ""))
	for f in d.get("freight", []):
		t.freight.append(str(f))
	t.pay = int(d.get("pay", 0))
	t.penalty = int(d.get("penalty", 0))
	t.jumps = int(d.get("jumps", 1))
	var b: Dictionary = d.get("bonus", {})
	if not b.is_empty():
		t.bonus = {
			"type": str(b.get("type", "")),
			"pay": int(b.get("pay", 0)),
			"trait": str(b.get("trait", "")),
			"side": str(b.get("zone", {}).get("side", "")),
			"size": int(b.get("zone", {}).get("size", 0)),
		}
	for tag in d.get("tags", []):
		t.tags.append(str(tag))
	return t


func has_bonus() -> bool:
	return not bonus.is_empty()


## Reports whether a cell is in the zone of a zone bonus (SPEC Section 15.3).
func in_zone(c: Vector2i, columns: int, rows: int) -> bool:
	var n: int = bonus.get("size", 0)
	match bonus.get("side", ""):
		Defs.SIDE_LEFT:
			return c.x < n
		Defs.SIDE_RIGHT:
			return c.x >= columns - n
		Defs.SIDE_TOP:
			return c.y < n
		Defs.SIDE_BOTTOM:
			return c.y >= rows - n
	return false
