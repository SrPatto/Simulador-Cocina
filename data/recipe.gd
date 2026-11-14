class_name Recipe
extends Resource
## A single transformation: inputs -> outputs, performed by one type of station.

enum StationType { CUTTING, STIRRING, SKILLET, ASSEMBLY }

@export var id: StringName
@export var display_name: String = ""
@export var station_type: StationType = StationType.CUTTING
@export var inputs: Array[IngredientData] = []
@export var outputs: Array[IngredientData] = []
## Tool needed to perform the recipe (&"knife", &"spoon"...). Empty means no tool is required.
@export var required_tool: StringName = &""
## Meaning depends on the station:
## CUTTING = number of cuts, STIRRING = number of full turns, SKILLET = seconds of cooking.
@export var work_amount: float = 1.0
## SKILLET only: minimum heat (0..1) needed for the food to cook.
@export_range(0.0, 1.0) var min_heat: float = 0.0


## Returns true if this recipe can be made at [param type] with exactly these ingredients.
## Order is ignored.
func matches(type: StationType, available: Array[IngredientData], tool_id: StringName = &"") -> bool:
	if type != station_type:
		return false
	if required_tool != &"" and required_tool != tool_id:
		return false
	if available.size() != inputs.size():
		return false
	var remaining: Array[IngredientData] = available.duplicate()
	for needed in inputs:
		var index := remaining.find(needed)
		if index == -1:
			return false
		remaining.remove_at(index)
	return true
