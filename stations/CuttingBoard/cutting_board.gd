class_name CuttingBoard
extends Node3D
## Handles two kinds of recipes:
##   CUTTING  - one ingredient on the board is hit by a knife (cabbage -> cabbage leaf).
##   ASSEMBLY - several ingredients stacked on the board become one item (bread + bacon + tomato -> sandwich).
##
## Scene tree (cutting_board.tscn):
##   CuttingBoard (Node3D, this script)
##   ├─ MeshInstance3D
##   ├─ StaticBody3D / CollisionShape3D      <- the solid board
##   ├─ PlacementArea (Area3D)               <- volume just above the board; mask = ingredient layer
##   │   └─ CollisionShape3D
##   └─ SlotOrigin (Marker3D)                <- center of the board surface, +Y pointing up

signal recipe_completed(recipe: Recipe)

@onready var _placement_area: Area3D = $PlacementArea
@onready var _slot_origin: Marker3D = $SlotOrigin

## Ingredients currently resting on the board, bottom to top.
var _items: Array[Ingredient] = []


func _ready() -> void:
	_placement_area.body_entered.connect(_on_body_entered)
	_placement_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	var ingredient := body as Ingredient
	if ingredient == null:
		return
	_connect_ingredient(ingredient)
	if not ingredient.is_picked_up():
		_place.call_deferred(ingredient)


func _on_body_exited(body: Node3D) -> void:
	var ingredient := body as Ingredient
	if ingredient == null:
		return
	_disconnect_ingredient(ingredient)
	_remove(ingredient)


func _on_ingredient_dropped(pickable: XRToolsPickable) -> void:
	# Deferred so the pickable finishes its own drop logic before we freeze it.
	if pickable is Ingredient and _placement_area.overlaps_body(pickable):
		_place.call_deferred(pickable)


func _on_ingredient_picked_up(pickable: XRToolsPickable) -> void:
	_remove(pickable as Ingredient)


func _on_tool_hit(ingredient: Ingredient, tool_id: StringName) -> void:
	if not _items.has(ingredient):
		return
	var inputs: Array[IngredientData] = [ingredient.data]
	var recipe := RecipeDatabase.find_recipe(Recipe.StationType.CUTTING, inputs, tool_id)
	if recipe == null:
		return
	ingredient.work_done += 1.0
	if ingredient.work_done >= recipe.work_amount:
		var consumed: Array[Ingredient] = [ingredient]
		_replace_items(consumed, recipe.outputs)
		recipe_completed.emit(recipe)


func _place(ingredient: Ingredient) -> void:
	if not is_instance_valid(ingredient) or ingredient.is_queued_for_deletion():
		return
	if _items.has(ingredient) or ingredient.is_picked_up():
		return
	ingredient.freeze = true
	_items.append(ingredient)
	_restack()
	_try_assembly()


func _remove(ingredient: Ingredient) -> void:
	if ingredient == null or not _items.has(ingredient):
		return
	_items.erase(ingredient)
	_restack()


func _try_assembly() -> void:
	if _items.size() < 2:
		return
	var inputs: Array[IngredientData] = []
	for item in _items:
		inputs.append(item.data)
	var recipe := RecipeDatabase.find_recipe(Recipe.StationType.ASSEMBLY, inputs)
	if recipe == null:
		return
	_replace_items(_items.duplicate(), recipe.outputs)
	recipe_completed.emit(recipe)


func _replace_items(consumed: Array[Ingredient], outputs: Array[IngredientData]) -> void:
	for item in consumed:
		_items.erase(item)
		item.queue_free()
	for output in outputs:
		var piece := Ingredient.spawn(output, get_parent(), _slot_origin.global_position)
		piece.freeze = true
		_items.append(piece)
	_restack()


## Lays the ingredients one on top of the other, centered on the board.
func _restack() -> void:
	var basis := _slot_origin.global_basis.orthonormalized()
	var height := 0.0
	for item in _items:
		var offset := basis.y * (height + item.data.layer_height * 0.5)
		item.global_transform = Transform3D(basis, _slot_origin.global_position + offset)
		height += item.data.layer_height


func _connect_ingredient(ingredient: Ingredient) -> void:
	if not ingredient.dropped.is_connected(_on_ingredient_dropped):
		ingredient.dropped.connect(_on_ingredient_dropped)
	if not ingredient.picked_up.is_connected(_on_ingredient_picked_up):
		ingredient.picked_up.connect(_on_ingredient_picked_up)
	if not ingredient.tool_hit.is_connected(_on_tool_hit):
		ingredient.tool_hit.connect(_on_tool_hit)


func _disconnect_ingredient(ingredient: Ingredient) -> void:
	if ingredient.dropped.is_connected(_on_ingredient_dropped):
		ingredient.dropped.disconnect(_on_ingredient_dropped)
	if ingredient.picked_up.is_connected(_on_ingredient_picked_up):
		ingredient.picked_up.disconnect(_on_ingredient_picked_up)
	if ingredient.tool_hit.is_connected(_on_tool_hit):
		ingredient.tool_hit.disconnect(_on_tool_hit)
