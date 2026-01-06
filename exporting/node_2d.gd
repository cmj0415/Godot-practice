extends Node2D


@export_category("Body")
@export var height := 10.0
@export var weight := 50.0

@export_category("Combat")
@export_group("Health")
@export var hp := 100

@export_group("Attack")
@export_range(5, 10) var atk := 5

@export_category("Movement")
@export_group("Horizontal")
@export var walk_speed := 10.0
@export var sprint_speed := 15.0

@export_group("Vertical")
@export var jmp_height := 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
