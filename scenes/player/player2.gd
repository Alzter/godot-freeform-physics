extends KinematicBody2D

const MOVE_SPEED = 400
const FRICTION = 0.8
const GRAVITY = 1000

onready var raycast = $Ground
var velocity = Vector2()
var direction = 1
var grounded = false

func _ready():
	print( Vector2(0, -1).angle() / PI )

func _physics_process(delta):
	move_input()
	apply_movement(delta)
	if grounded or raycast.is_colliding(): snap_to_floor(delta)
	if !raycast.is_colliding(): grounded = false
	if !grounded: velocity.y += GRAVITY * delta

func move_input():
	var move_direction = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if move_direction != 0: direction = move_direction
	var move_speed = move_direction * MOVE_SPEED
	
	# ELIMINATE SPEEDCAP: If our velocity is greater than the normal movement speed, retain current velocity
	if move_direction == sign(velocity.x) and abs(velocity.x) > abs(move_speed):
		move_speed = velocity.x
	
	if grounded:
		var floor_angle = get_floor_angle() / PI
		var angle_influence = floor_angle * MOVE_SPEED
		
		if angle_influence * move_direction > 0: angle_influence *= 2
		else: angle_influence *= 1
		
		if move_direction == 0 and abs(floor_angle) < 0.2: angle_influence *= 0
		
		move_speed += angle_influence
	
	velocity.x = lerp(velocity.x, move_speed, 0.05)

func apply_movement(delta):
	var angle = get_floor_angle()
	var angular_velocity = velocity.rotated(angle)
	velocity = move_and_slide(angular_velocity).rotated(-angle)

func get_floor_angle():
	var angle = Vector2(0, -1)
	if raycast.is_colliding(): angle = raycast.get_collision_normal()
	angle = angle.angle()
	angle += PI / 2
	return angle

func snap_to_floor(delta):
	# STEP 1: Get the angle of the floor
	var angle = get_floor_angle()
	
	# STEP 2: Cast the raycast to the floor's angle
	raycast.set_cast_to( Vector2(0, 32).rotated( angle ) )
	raycast.force_raycast_update()
	
	# Stop if we're not on the floor
	if abs(angle/PI) > 1 and abs(velocity.x) < MOVE_SPEED:
		angle = 0
		raycast.set_cast_to( Vector2(0, 32) )
		grounded = false
		return
	
	# STEP 3: Calculate distance between the floor and the player's position
	var distance = raycast.get_collision_point()
	distance -= position
	# STEP 4: Move the player
	var collision = move_and_collide(distance)
	grounded = true
