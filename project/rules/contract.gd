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


func _init(contract_id: int, t: ContractTemplate) -> void:
	id = contract_id
	template = t
