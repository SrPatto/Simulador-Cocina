extends Node
## Autoload singleton. Register it in Project Settings > Globals as "RecipeDatabase".
## Loads every Recipe .tres found in RECIPES_DIR. Keep only recipes in that folder.

const RECIPES_DIR := "res://recipes/data"

var recipes: Array[Recipe] = []


func _ready() -> void:
	for file_name in DirAccess.get_files_at(RECIPES_DIR):
		# Exported projects list resources as "name.tres.remap".
		var clean_name := file_name.trim_suffix(".remap")
		if not clean_name.ends_with(".tres"):
			continue
		var recipe := load(RECIPES_DIR.path_join(clean_name)) as Recipe
		if recipe != null:
			recipes.append(recipe)


func find_recipe(type: Recipe.StationType, items: Array[IngredientData], tool_id: StringName = &"") -> Recipe:
	for recipe in recipes:
		if recipe.matches(type, items, tool_id):
			return recipe
	return null
