class_name IngredientData
extends Resource
## Describes one kind of ingredient (raw tomato, cabbage leaf, cooked bacon...).
## Create one .tres per ingredient state: "chicken_raw" and "chicken_pieces" are two different resources.

@export var id: StringName
@export var display_name: String = ""
@export var icon: Texture2D
@export var mesh: Mesh
## Size of the box collider generated for the physical ingredient.
@export var collision_size: Vector3 = Vector3(0.1, 0.1, 0.1)
## Thickness used when this ingredient is stacked on the cutting board.
@export var layer_height: float = 0.02
