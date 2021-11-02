extends KinematicBody2D

const SPEED = 300
const RAYCAST = 32

var move_direction = 0
var grounded = false
var direction = 1
var velocity = Vector2()
var angle = Vector2()
onready var raycast = $Ground

func _ready():
	print( Vector2(0, -1).angle() / PI )

func _physics_process(delta):
	move_input()
	debug()
	
	var angular_velocity = velocity.rotated(angle.angle())
	move_and_slide(angular_velocity, angle)
	get_floor_angle()
	grounded = is_on_floor()
	
	if raycast.is_colliding(): snap_to_floor(delta)

func move_input():
	move_direction = int(Input.is_action_pressed("move_up")) - int(Input.is_action_pressed("move_down"))
	velocity.x = move_direction * SPEED
	move_direction = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if move_direction != 0: direction = move_direction
	velocity.y = move_direction * SPEED

func get_floor_angle():
	if raycast.is_colliding():
		var floor_vector = raycast.get_collision_normal()
		angle = floor_vector.angle() / PI
		#print(angle)
	else:
		angle = Vector2(0, -1)
	
	var degrees = angle.angle()
	degrees = rad2deg(degrees) + 90
	var raycast_angle = Vector2(0, RAYCAST)
	#print(degrees)
	if degrees > 45:
		raycast_angle = raycast_angle.rotated(-PI)
	raycast.cast_to = raycast_angle

func snap_to_floor(delta):
	var distance = raycast.get_collision_point() - position
	get_floor_angle()
	var floor_angle = angle + Vector2(1,0)
	floor_angle = floor_angle.angle()
	distance = distance.rotated(floor_angle)
	#print(distance)
	#move_and_slide(distance / delta)

func set_floor_mode():
	pass

func debug():
	var point_pos = Vector2(100, 0).rotated(angle.angle())
	$Line2D.set_point_position(1, point_pos)
