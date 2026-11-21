class_name CargoDef
extends RefCounted
## The definition of a freight or a kit (SPEC Section 6.1). The data is in
## data/cargo/<id>.json.

var id: String
var name: String
var kind: String
var weight: String
var traits: PackedStringArray = []
var shape: Array[Vector2i] = []
## The shop price of a kit.
var price: int = 0


static func from_dict(d: Dictionary) -> CargoDef:
	var c := CargoDef.new()
	c.id = str(d.get("id", ""))
	c.name = str(d.get("name", c.id))
	c.kind = str(d.get("kind", ""))
	c.weight = str(d.get("weight", ""))
	for t in d.get("traits", []):
		c.traits.append(str(t))
	c.shape = Shapes.from_json(d.get("shape", []))
	c.price = int(d.get("price", 0))
	return c
