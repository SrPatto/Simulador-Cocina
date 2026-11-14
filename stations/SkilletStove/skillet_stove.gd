class_name SkilletStove
extends Node3D
## A pan over a fire. The heat rises and falls smoothly toward a target value
## (like the red gauge in the video). Food on the pan cooks while heat >= recipe.min_heat.
## SKILLET recipes must have exactly one input and one output.
##
## Scene tree (skillet_stove.tscn):
##   SkilletStove (Node3D, this script)
##   ├─ StoveMesh (MeshInstance3D)
##   ├─ StaticBody3D / CollisionShape3D      <- stove + pan surface
##   ├─ CookingArea (Area3D)                 <- volume on the pan; mask = ingredient layer
##   ├─ Flames (GPUParticles3D)
##   ├─ FireLight (OmniLight3D)
##   ├─ HeatGauge (MeshInstance3D)           <- thin bar, scaled on Y to show the heat
##   └─ HeatControl                          <- a lever/knob (e.g. XRToolsInteractableHinge)
##                                              that calls set_target_heat()

signal heat_changed(heat: float)
signal recipe_completed(recipe: Recipe, ingredient: Ingredient)

## How fast the heat moves toward the target, in heat units per second (0..1 range).
@export var heat_rate: float = 0.25
@export_range(0.0, 1.0) var target_heat: float = 0.0:
	set(value):
		target_heat = clampf(value, 0.0, 1.0)

var heat := 0.0

@onready var _cooking_area: Area3D = $CookingArea
@onready var _flames: GPUParticles3D = $Flames
@onready var _fire_light: OmniLight3D = $FireLight
@onready var _heat_gauge: MeshInstance3D = $HeatGauge


func _physics_process(delta: float) -> void:
	var previous := heat
	heat = move_toward(heat, target_heat, heat_rate * delta)
	if not is_equal_approx(previous, heat):
		_update_visuals()
		heat_changed.emit(heat)

	for body in _cooking_area.get_overlapping_bodies():
		var ingredient := body as Ingredient
		if ingredient != null and not ingredient.is_picked_up():
			_cook(ingredient, delta)


## Connect your lever/knob to this (value from 0 to 1).
func set_target_heat(value: float) -> void:
	target_heat = value


func _cook(ingredient: Ingredient, delta: float) -> void:
	var inputs: Array[IngredientData] = [ingredient.data]
	var recipe := RecipeDatabase.find_recipe(Recipe.StationType.SKILLET, inputs)
	if recipe == null or heat < recipe.min_heat or recipe.outputs.is_empty():
		return
	ingredient.work_done += delta
	if ingredient.work_done >= recipe.work_amount:
		ingredient.transform_to(recipe.outputs[0])
		recipe_completed.emit(recipe, ingredient)


func _update_visuals() -> void:
	_flames.emitting = heat > 0.05
	_fire_light.light_energy = heat * 2.0
	_heat_gauge.scale.y = maxf(heat, 0.01)
