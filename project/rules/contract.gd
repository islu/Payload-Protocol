class_name Contract
extends RefCounted
## A contract that a station offers (SPEC Section 15).

var id: int
var template: ContractTemplate
var accepted := false
## The IDs of the freight of an accepted contract.
var cargo: Array[int] = []
## The freight that stayed on the dock at the warp (SPEC Section 15.4).
var breached: Array[int] = []
## The arrivals before the delivery of a long contract (SPEC Section 30.2).
var jumps_left: int = 1


func _init(contract_id: int, t: ContractTemplate) -> void:
	id = contract_id
	template = t
	jumps_left = t.jumps


## Reports whether the freight of a long contract is on its way: an arrival is past
## (SPEC Section 30.2).
func carried() -> bool:
	return jumps_left < template.jumps
