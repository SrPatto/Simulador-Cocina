class_name Ingredient
extends XRToolsPickable
## A physical ingredient the player can grab. Its look and identity come from IngredientData.
##
## Scene tree (ingredient.tscn):
##   Ingredient (XRToolsPickable, this script)
##   ├─ MeshInstance3D
##   ├─ CollisionShape3D
##   └─ (optional) grab points, e.g. XRToolsGrabPointHand

## Emitted by tools (knife, hammer...) when they hit this ingredient fast enough.
signal tool_hit(ingredient: Ingredient, tool_id: StringName)

@export var data: IngredientData:
	set(value):
		data = value
		work_done = 0.0
		if is_node_ready():
			_apply_data()

## Progress of whatever station is working on this ingredient (cuts made, seconds cooked...).
## Reset automatically whenever the ingredient transforms into something else.
var work_done := 0.0

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


## Creates an ingredient in the world. Stations use this to spawn recipe outputs.
static func spawn(ingredient_data: IngredientData, parent: Node, world_position: Vector3) -> Ingredient:
	var scene := load("res://ingredients/ingredient.tscn") as PackedScene
	var instance := scene.instantiate() as Ingredient
	instance.data = ingredient_data
	parent.add_child(instance)
	instance.global_position = world_position
	return instance


func _ready() -> void:
	super()
	add_to_group(&"ingredients")
	_apply_data()


func transform_to(new_data: IngredientData) -> void:
	data = new_data


func _apply_data() -> void:
	if data == null:
		return
	_mesh_instance.mesh = data.mesh
	var box := BoxShape3D.new()
	box.size = data.collision_size
	_collision_shape.shape = box
