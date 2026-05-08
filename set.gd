extends Node
class_name Set
#  no built-in set class
#  this is actually just a dictionary disguised as a set

var values: Dictionary[Variant, bool]

func add(value: Variant):
	values[value] = true

func del(value: Variant):
	values.erase(value)

func has(value: Variant):
	return value in values
