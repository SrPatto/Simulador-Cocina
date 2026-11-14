class_name StirringPot
extends Node3D
## A pot where ingredients are dropped in and then stirred with a spoon.
## Stirring is measured with math (angle of the spoon tip around the pot axis),
## so it does not depend on physics collisions with the spoon.
##
## Scene tree (stirring_pot.tscn):
##   StirringPot (Node3D, this script)   <- origin at the CENTER of the pot opening
##   ├─ MeshInstance3D
##   ├─ StaticBody3D / CollisionShape3D
##   ├─ IngredientArea (Area3D)          <- volume inside the pot; mask = ingredient layer
##   ├─ OutputMarker (Marker3D)          <- where the result appears (outside IngredientArea!)
##   └─ Spoon (instance of spoon.tscn, XRToolsPickable)
##       └─ Tip (Marker3D)               <- assign this node to [member spoon_tip]

signal contents_changed(contents: Array[IngredientData])
signal progress_changed(progress: float)
signal recipe_completed(recipe: Recipe)

@export var spoon_tip: Node3D
@export var tool_id: StringName = &"spoon"
## The spoon only counts while its tip is inside this ring (local pot space).
@export var stir_min_radius: float = 0.03
@export var stir_max_radius: float = 0.25
@export var stir_min_y: float = -0.2
@export var stir_max_y: float = 0.1

@onready var _ingredient_area: Area3D = $IngredientArea
@onready var _output_marker: Marker3D = $OutputMarker

var _contents: Array[IngredientData] = []
var _recipe: Recipe = null
var _previous_angle := 0.0
var _has_previous_angle := false
## Signed turns: stirring back and forth cancels out, so the player must keep one direction.
var _signed_turns := 0.0


func _ready() -> void:
	_ingredient_area.body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if _recipe == null or spoon_tip == null:
		_has_previous_angle = false
		return

	var local := to_local(spoon_tip.global_position)
	var radial := Vector2(local.x, local.z)
	var inside := radial.length() >= stir_min_radius \
			and radial.length() <= stir_max_radius \
			and local.y >= stir_min_y and local.y <= stir_max_y
	if not inside:
		_has_previous_angle = false
		return

	var angle := atan2(radial.y, radial.x)
	if _has_previous_angle:
		_signed_turns += angle_difference(_previous_angle, angle) / TAU
		var progress := clampf(absf(_signed_turns) / _recipe.work_amount, 0.0, 1.0)
		progress_changed.emit(progress)
		if progress >= 1.0:
			_finish()
			return
	_previous_angle = angle
	_has_previous_angle = true


## Throws away whatever is inside (useful if the player added a wrong ingredient).
func empty_pot() -> void:
	_contents.clear()
	_recipe = null
	_signed_turns = 0.0
	contents_changed.emit(_contents)


func _on_body_entered(body: Node3D) -> void:
	var ingredient := body as Ingredient
	if ingredient == null:
		return
	if ingredient.is_picked_up():
		# Still in the hand: wait until the player lets go inside the pot.
		if not ingredient.dropped.is_connected(_on_ingredient_dropped):
			ingredient.dropped.connect(_on_ingredient_dropped)
	else:
		_absorb.call_deferred(ingredient)


func _on_ingredient_dropped(pickable: XRToolsPickable) -> void:
	if pickable is Ingredient and _ingredient_area.overlaps_body(pickable):
		_absorb.call_deferred(pickable)


func _absorb(ingredient: Ingredient) -> void:
	if not is_instance_valid(ingredient) or ingredient.is_queued_for_deletion():
		return
	_contents.append(ingredient.data)
	ingredient.queue_free()
	_signed_turns = 0.0
	_has_previous_angle = false
	_recipe = RecipeDatabase.find_recipe(Recipe.StationType.STIRRING, _contents, tool_id)
	contents_changed.emit(_contents)


func _finish() -> void:
	var finished := _recipe
	_contents.clear()
	_recipe = null
	_signed_turns = 0.0
	_has_previous_angle = false
	for output in finished.outputs:
		Ingredient.spawn(output, get_parent(), _output_marker.global_position)
	contents_changed.emit(_contents)
	recipe_completed.emit(finished)
