extends KinematicBody2D

var MOVE_SPEED = 600
var ACCELERATION = 0.05
var BOOST_ACCELERATION = 0.02
var CEILING_SPEED = 400 # Minimum speed needed to keep traction on ceilings
var MAX_ANGLE = 0.25 # The largest change in floor angle (in radians / pi) the player can face without being forced into an airborne state
var BOOST_SPEED = 600
var BOOST_ADDITIONAL_SPEED = 500
var STOMP_SPEED = 2500
var MIN_JUMP_HEIGHT = 500
var JUMP_HEIGHT = 900
var SLOPE_ACCELERATION = MOVE_SPEED * 3.5
var SLOPE_DECELERATION = MOVE_SPEED * 1
var GRAVITY = 2500

onready var raycast = $Ground
onready var camera = $Camera2D
onready var state_machine = $StateMachine

var floor_angle = 0
var velocity = Vector2()
var direction = 1

func apply_gravity(delta):
	velocity.y += GRAVITY * delta

func special_moves():
	var boost_direction = Vector2(0,0)
	if Input.is_action_pressed("move_up"): boost_direction.y = -1
	if Input.is_action_pressed("move_down"): boost_direction.y = 1
	if Input.is_action_pressed("move_left"): boost_direction.x = -1
	if Input.is_action_pressed("move_right"): boost_direction.x = 1
	if boost_direction == Vector2(0,0):
		boost_direction.x = 1 * direction
	var boost_velocity = Vector2(BOOST_SPEED, 0).rotated(boost_direction.angle())
	if Input.is_action_just_pressed("boost") and !state_machine.state in state_machine.grounded_states:
#		if boost_direction.x != 0: velocity.x = 0
#		if boost_direction.y != 0: velocity.y = 0
		velocity += boost_velocity
	
	#if Input.is_action_just_pressed("stomp") or Input.is_action_just_pressed("diag_boost"):
	#	velocity.y = STOMP_SPEED

func move_input(floor_angle, angled = false, acceleration = ACCELERATION):
	var move_direction = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if move_direction != 0: direction = move_direction
	var move_speed = move_direction * MOVE_SPEED
	
	# ELIMINATE SPEEDCAP: If our velocity is greater than the normal movement speed, retain current velocity
	if move_direction == sign(velocity.x) and abs(velocity.x) > abs(move_speed):
		move_speed = velocity.x
	
	if angled:
		var angle_to_rotate = floor_angle / PI
		if angle_to_rotate > 0.5: angle_to_rotate = 1 - angle_to_rotate
		var angle_influence = fmod(angle_to_rotate, 180)
		
		var slope_downward = angle_influence * move_direction > 0
		angle_influence *= SLOPE_ACCELERATION if slope_downward else SLOPE_DECELERATION
		
		#if move_direction == 0 and abs(angle_to_rotate) < 0.6: angle_influence *= 0
		
		move_speed += angle_influence
	
	velocity.x = lerp(velocity.x, move_speed, acceleration)

func apply_movement(angle, delta):
	var angle_up = angle - PI / 2
	var up_direction = Vector2( cos(angle_up), sin(angle_up) )
	var angular_velocity = velocity.rotated(angle)
	
	var velocity_product = move_and_slide(angular_velocity, up_direction, false, 4, 2*PI, true)
	velocity = velocity_product.rotated(-angle)

func get_floor_angle():
	if raycast.is_colliding():
		var angle = Vector2(0, -1)
		angle = raycast.get_collision_normal()
		angle = angle.angle()
		angle += PI / 2
		return angle
	else: return null

func snap_to_floor(angle):
	# STEP 1: Cast the raycast to the floor's angle
	raycast.set_cast_to( Vector2(0, 42).rotated( angle ) )
	raycast.force_raycast_update()
	
	# STEP 2: Calculate distance between the floor and the player's position
	var distance = raycast.get_collision_point()
	distance -= position
	
	# STEP 3: Move the player
	var collision = move_and_collide(distance)
	raycast.force_raycast_update() # THIS IS NEEDED to prevent player slipping off changes in inclination

func can_touch_ground(grounded = true):
	var old_cast_to = raycast.get_cast_to()
	if (is_on_floor() or is_on_wall()) and (velocity.y > 0 or !grounded):
		raycast.set_cast_to( Vector2(0, 64) )
		raycast.force_raycast_update()
		
		if raycast.is_colliding(): 
			var angle = get_floor_angle()
			raycast.set_cast_to(old_cast_to)
			raycast.force_raycast_update()
			if grounded: return true
			return int(abs(angle) < 1)
	return false

func enter_grounded_state(angle):
	#print("===FLOOR===")
	#print(angle/PI)
	#var velocity_add = velocity.rotated(angle)
	#if angle < 0: velocity_add *= -1
	#print(velocity_add)
	#velocity.x += velocity_add
	#velocity.x += velocity.rotated(angle).y
	velocity = velocity.rotated(-angle)
	snap_to_floor(angle)

func exit_grounded_state(angle, is_jumping = false):
#	print("===AIR===")
#	print("Angle: ", angle/PI)
#	print( Vector2(JUMP_HEIGHT, 0).rotated(angle) )
#	print(velocity)
	
	if !is_jumping: velocity.y = 0
	velocity = velocity.rotated(angle)
#	print(velocity)
	raycast.set_cast_to( Vector2(0, 42) )

func jump_input():
	if Input.is_action_just_pressed("jump"):
		velocity.y = -JUMP_HEIGHT
		state_machine.set_state("jumping")

func jump_cancelling():
	if velocity.y > -JUMP_HEIGHT and velocity.y < -MIN_JUMP_HEIGHT and !Input.is_action_pressed("jump"):
		velocity.y = -MIN_JUMP_HEIGHT

func update_sprite(angle, state):
	var angle_degrees = rad2deg(angle)
	$Control.rect_rotation = angle_degrees
	$Control/AnimatedSprite.flip_h = int(sign(velocity.x) == -1)
	
	$Control/AnimatedSprite.play(state)
	if state != "idle":
		var vel_to_rotate = Vector2( velocity.x, min(-300, velocity.y) )
		$Control.rect_rotation = rad2deg( vel_to_rotate.angle() + PI / 2 )
	
	var zoom = (abs(velocity.x) + abs(velocity.y)) * 0.00015
	zoom = Vector2(zoom, zoom)
	zoom += Vector2(1, 1)
	$Camera2D.zoom += (zoom - $Camera2D.zoom) / 20
