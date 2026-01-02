extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var drag_threshold := 6.0
@export var max_scale := Vector2(4.0, 4.0)
@export var min_scale := Vector2(0.25, 0.25)

var pressed_on_me := false
var dragging := false
var moved_distance := 0.0
var drag_offset_global := Vector2.ZERO
var active_button := -1

func _ready():
	input_pickable = true

func _physics_process(delta: float) -> void:
	if dragging:
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if is_on_floor() and velocity.y > 0:
		velocity.y = 0

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT \
			and event.button_index != MOUSE_BUTTON_RIGHT:
			return
			
		if event.pressed:
			pressed_on_me = true
			dragging = false
			moved_distance = 0.0
			active_button = event.button_index
			drag_offset_global = global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled()
		else:
			if pressed_on_me and not dragging:
				_toggle_scale(active_button)
			pressed_on_me = false
			dragging = false
			get_viewport().set_input_as_handled()
				
func _unhandled_input(event):
	if not pressed_on_me:
		return
		
	if active_button != MOUSE_BUTTON_LEFT:
		return
		
	if event is InputEventMouseMotion:
		moved_distance += event.relative.length()
		
		if not dragging and moved_distance >= drag_threshold:
			dragging = true
		
		if dragging:
			global_position = get_global_mouse_position() + drag_offset_global
			get_viewport().set_input_as_handled()
			
func _toggle_scale(button_index: int):
	if button_index == MOUSE_BUTTON_LEFT:
		scale.x *= 2
		scale.y *= 2
	elif button_index == MOUSE_BUTTON_RIGHT:
		scale.x *= 0.5
		scale.y *= 0.5
		
	scale = scale.clamp(min_scale, max_scale)
