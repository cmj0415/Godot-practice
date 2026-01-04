extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var images: Array = [$Sprite2D, $Sprite2D2]

@export var drag_threshold := 6.0
@export var max_scale := Vector2(4.0, 4.0)
@export var min_scale := Vector2(0.25, 0.25)
@export var double_click_time := 250
@export var double_click_dist := 8

var current_image = 0
var current_multi := 2.0
var pressed_on_me := false
var dragging := false
var moved_distance := 0.0
var drag_offset_global := Vector2.ZERO
var waiting_for_second := false
var last_click_time := 0.0
var last_click_pos := Vector2.ZERO

func _ready():
	images[current_image].visible = true
	images[1 - current_image].visible = false
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
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
			
		if event.pressed:
			pressed_on_me = true
			dragging = false
			moved_distance = 0.0
			
			drag_offset_global = global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled()
		else:
			# avoid execution of _toggle_scale() upon release of drag
			if dragging:
				waiting_for_second = false
				pressed_on_me = false
				dragging = false
				get_viewport().set_input_as_handled()
				return
			var now := Time.get_ticks_msec()
			if waiting_for_second:
				if now - last_click_time <= double_click_time \
					and event.position.distance_to(last_click_pos) <= double_click_dist:
					waiting_for_second = false
					_transform()
					pressed_on_me = false
					dragging = false
					get_viewport().set_input_as_handled()
					return
				else:
					last_click_time = now
					last_click_pos = event.position
					waiting_for_second = true
			else:
				last_click_time = now
				last_click_pos = event.position
				waiting_for_second = true
					
			pressed_on_me = false
			dragging = false
			get_viewport().set_input_as_handled()
		
func _process(delta):	
	if not waiting_for_second:
		return
		
	var now := Time.get_ticks_msec()
	if now - last_click_time > double_click_time:
		_toggle_scale()
		waiting_for_second = false
				
func _unhandled_input(event):
	if not pressed_on_me:
		return
		
	if event is InputEventMouseMotion:
		moved_distance += event.relative.length()
		
		if not dragging and moved_distance >= drag_threshold:
			dragging = true
		
		if dragging:
			global_position = get_global_mouse_position() + drag_offset_global
			get_viewport().set_input_as_handled()
			
func _toggle_scale():
	scale.x *= current_multi
	scale.y *= current_multi
	
	scale = scale.clamp(min_scale, max_scale)
	
	if scale.x == 4.0:
		current_multi = 0.5
	
	if scale.x == 0.25:
		current_multi = 2.0
		
func _transform():
	current_image = 1 - current_image
	images[current_image].visible = true
	images[1 - current_image].visible = false
