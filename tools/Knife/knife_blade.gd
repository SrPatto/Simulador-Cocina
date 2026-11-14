class_name KnifeBlade
extends Area3D
## Put this on an Area3D child of the knife scene (the knife root is an XRToolsPickable).
## It measures its own speed, so it works while the knife is held by a hand.
##
## Scene tree (knife.tscn):
##   Knife (XRToolsPickable)
##   ├─ MeshInstance3D
##   ├─ CollisionShape3D
##   └─ Blade (Area3D, this script)
##       └─ CollisionShape3D   <- thin box along the cutting edge

@export var tool_id: StringName = &"knife"
## Minimum blade speed in m/s for a hit to count as a cut.
@export var min_speed: float = 0.8
## Seconds before the blade can cut again, so one stroke is one cut.
@export var cooldown: float = 0.3

var _last_position := Vector3.ZERO
var _speed := 0.0
var _cooldown_left := 0.0


func _ready() -> void:
	_last_position = global_position
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_speed = global_position.distance_to(_last_position) / delta
	_last_position = global_position
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func _on_body_entered(body: Node3D) -> void:
	if _cooldown_left > 0.0 or _speed < min_speed:
		return
	var ingredient := body as Ingredient
	if ingredient == null:
		return
	_cooldown_left = cooldown
	ingredient.tool_hit.emit(ingredient, tool_id)
