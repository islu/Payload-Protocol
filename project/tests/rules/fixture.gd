class_name Fixture
## The fixture data of the rule tests. It goes through Catalog.from_data(), as
## the real data does. Use the real data only in test_data.gd.

const KIT_POOL := ["foam", "cooler", "battery", "shield", "anchor", "sensor"]


static func catalog() -> Catalog:
	var cat := Catalog.from_data(data())
	assert(cat.errors.is_empty(), "the fixture data is not valid: %s" % ", ".join(cat.errors))
	return cat


static func data() -> Dictionary:
	var one := [[0, 0]]
	var cargo := {}
	var add := func(
		id: String, kind: String, weight: String, traits: Array, shape: Array, price := 0
	) -> void:
		cargo[id] = {
			"id": id,
			"name": id,
			"kind": kind,
			"weight": weight,
			"traits": traits,
			"shape": shape,
			"price": price
		}
	add.call("light", "freight", "light", [], one)
	add.call("box", "freight", "standard", [], one)
	add.call("heavy", "freight", "heavy", [], one)
	add.call("bar", "freight", "standard", [], [[0, 0], [1, 0]])
	add.call("ell", "freight", "standard", [], [[0, 0], [0, 1], [1, 1]])
	add.call("vase", "freight", "light", ["fragile"], one)
	add.call("glass", "freight", "standard", ["fragile"], one)
	add.call("bomb", "freight", "light", ["volatile"], one)
	add.call("bigbomb", "freight", "heavy", ["volatile"], one)
	add.call("tank", "freight", "standard", ["fluid"], one)
	add.call("drum", "freight", "standard", ["fluid", "volatile"], one)
	add.call("chip", "freight", "light", ["electronic"], one)
	add.call("cheese", "freight", "standard", ["perishable"], one)
	add.call("drone", "freight", "light", ["thruster"], one)
	add.call("foam", "kit", "light", ["cushion"], one, 6)
	add.call("cooler", "kit", "standard", ["cooler"], one, 8)
	add.call("battery", "kit", "standard", ["battery", "electronic"], one, 7)
	add.call("shield", "kit", "standard", ["shield"], one, 12)
	add.call("anchor", "kit", "heavy", ["thruster"], one, 9)
	add.call("sensor", "kit", "standard", ["sensor"], one, 14)
	var contracts := {
		"k_boxes":
		{
			"id": "k_boxes",
			"legs": [1, 2, 3],
			"client_name": "A",
			"freight": ["box", "box"],
			"pay": 5
		},
		"k_vases":
		{
			"id": "k_vases",
			"legs": [1, 2, 3],
			"client_name": "B",
			"freight": ["vase", "vase"],
			"pay": 8,
			"bonus": {"type": "all_intact", "pay": 6},
		},
		"k_bars":
		{
			"id": "k_bars",
			"legs": [1, 2, 3],
			"client_name": "C",
			"freight": ["bar"],
			"pay": 7,
			"bonus": {"type": "zone", "pay": 4, "zone": {"side": "left", "size": 2}},
		},
		"k_chips":
		{
			"id": "k_chips",
			"legs": [1, 2, 3],
			"client_name": "D",
			"freight": ["chip", "chip"],
			"pay": 5,
			"bonus": {"type": "not_next_to", "pay": 4, "trait": "fluid"},
		},
	}
	var lines := {}
	for e in Defs.LINE_EVENTS:
		lines[e] = {
			"id": e,
			"lines":
			[{"text": e + " 1"}, {"text": e + " 2"}, {"text": e + " 3"}, {"text": e + " 4"}]
		}
	var terms := {
		"traits": {}, "kinds": {}, "weights": {}, "directions": {}, "sides": {}, "bonuses": {}
	}
	for t in Defs.TRAITS:
		terms["traits"][t] = {"name": t.capitalize(), "text": "rule of %s at {limit}" % t}
	for group: String in ["kinds", "weights", "directions", "sides"]:
		var ids: PackedStringArray = {
			"kinds": Defs.KINDS,
			"weights": Defs.WEIGHTS,
			"directions": Defs.DIRECTIONS,
			"sides": Defs.SIDES
		}[group]
		for id in ids:
			terms[group][id] = {"name": id}
	for b in Defs.BONUSES:
		terms["bonuses"][b] = {"name": b, "text": "bonus %s" % b}
	return {
		"rules":
		{
			"start": {"credits": 40, "clamps": 1, "hold": {"columns": 6, "rows": 6}},
			"hold_max": {"columns": 8, "rows": 8},
			"weights": {"light": 1, "standard": 2, "heavy": 3},
			"break_limits": {"fragile": 2, "volatile": 3, "fluid": 2},
			"offers": {"contracts": 3, "kit": 3},
			"prices":
			{
				"reroll_first": 2,
				"reroll_step": 2,
				"clamp": 8,
				"clamp_max": 4,
				"upgrade_first": 15,
				"upgrade_step": 10,
				"scrap_cell": 2,
				"breach_fee": 5,
				"sell_divisor": 2,
				"reinforce_first": 12,
				"reinforce_step": 8,
			},
			"mass":
			{"limit": 40, "over_percent": 25, "fuel_fee": 2, "reinforce": 8, "offer_percent": 130},
			"legs":
			[
				{"payment": 60, "hazard_steps": [[1, 1], [2, 2], [2, 2]], "kit_pool": KIT_POOL},
				{
					"payment": 140,
					"hazard_steps": [[2, 2], [2, 2], [2, 2]],
					"kit_pool": KIT_POOL,
					"fork": true
				},
				{
					"payment": 260,
					"hazard_steps": [[2, 3], [2, 3], [2, 3]],
					"kit_pool": KIT_POOL,
					"fork": true
				},
			],
		},
		"terms": terms,
		"cargo": cargo,
		"contracts": contracts,
		"lines": lines,
	}
