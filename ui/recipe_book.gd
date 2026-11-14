class_name RecipeBook
extends Node3D
## A floating book that shows one recipe per page: ingredient icons, result icon and instructions.
## The 2D UI lives in a SubViewport that is displayed on a quad in the 3D world.
##
## Scene tree (recipe_book.tscn):
##   RecipeBook (Node3D, this script)
##   ├─ BookMesh (MeshInstance3D)
##   ├─ PageQuad (MeshInstance3D)             <- QuadMesh whose material uses the SubViewport as albedo texture
##   ├─ SubViewport (size e.g. 512x512, transparent background)
##   │   └─ Page (Control)
##   │       ├─ Title (Label)
##   │       ├─ Inputs (HBoxContainer)
##   │       ├─ Output (TextureRect)
##   │       └─ Info (Label)
##   ├─ NextButton / PreviousButton           <- e.g. XRToolsInteractableAreaButton -> next_page() / previous_page()

@onready var _title: Label = $SubViewport/Page/Title
@onready var _inputs: HBoxContainer = $SubViewport/Page/Inputs
@onready var _output: TextureRect = $SubViewport/Page/Output
@onready var _info: Label = $SubViewport/Page/Info

var _index := 0


func _ready() -> void:
	show_page(0)


func next_page() -> void:
	show_page(_index + 1)


func previous_page() -> void:
	show_page(_index - 1)


func show_page(index: int) -> void:
	var recipes := RecipeDatabase.recipes
	if recipes.is_empty():
		return
	_index = wrapi(index, 0, recipes.size())
	var recipe := recipes[_index]

	_title.text = recipe.display_name
	_info.text = _describe(recipe)

	for child in _inputs.get_children():
		child.queue_free()
	for ingredient in recipe.inputs:
		var icon := TextureRect.new()
		icon.texture = ingredient.icon
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_inputs.add_child(icon)

	_output.texture = recipe.outputs[0].icon if not recipe.outputs.is_empty() else null


func _describe(recipe: Recipe) -> String:
	match recipe.station_type:
		Recipe.StationType.CUTTING:
			return "Cut %d time(s) with a knife" % int(recipe.work_amount)
		Recipe.StationType.STIRRING:
			return "Drop everything in the pot and stir %.1f turn(s)" % recipe.work_amount
		Recipe.StationType.SKILLET:
			return "Cook on the pan for %d seconds" % int(recipe.work_amount)
		Recipe.StationType.ASSEMBLY:
			return "Stack the ingredients on the cutting board"
	return ""
