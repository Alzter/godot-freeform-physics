extends StateMachine

var floor_angle = 0
var grounded_states = []

func _ready():
	Global.player = host
	add_state("idle")
	add_state("jumping")
	add_state("falling")
	add_state("boosting")
	grounded_states = ["idle"]
	previous_state = "idle"
	call_deferred("set_state", "falling")

# VERY IMPORTANT SCRIPT!!
# The player's floor angle is calculated by the normal of the ground they're on.
# It influences their movement by rotating their velocity, which lets them move across walls or even ceilings.
# Our movement velocity always points left or right, but if we're on a wall, it's rotated to be up or down, and so on.
# In the air it's set to nothing, because if we were to rotate the player's velocity in the air it'd screw with gravity itself.
func set_floor_angle(force = false):
	var old_floor_angle = floor_angle
	# If we're in the air, set floor angle to 0 (upright)
	if !force and !state in grounded_states: floor_angle = 0
	else:
		# OTHERWISE, ONLY set the floor angle under certain conditions.
		# ONE, the player's floor raycast must be colliding. If not, just keep the old floor angle.
		# TWO, the change in floor angle must be under a certain amount (45 degrees) so if the player goes over a corner,
		# they don't stay attatched to the ground, but rather get booted off into a falling state.
		
		var angle_to_set = host.get_floor_angle()
		if angle_to_set != null:
			
			# This here is important!!
			# When we move around a circle, at some point the floor normal in radians wraps over from 1.5 pi to -0.5pi.
			# This can create false positives when calculating the difference in floor angles, so to account for this
			# we change the old floor angle's value in this hyper-specific condition to wrap around with the new value.
			if angle_to_set / PI > 1 and old_floor_angle / PI < 0 or angle_to_set / PI < 0 and old_floor_angle / PI > 1:
				old_floor_angle = PI - old_floor_angle
			var angle_difference = abs(angle_to_set - old_floor_angle) / PI
			floor_angle = angle_to_set
			if !force and angle_difference > host.MAX_ANGLE:
				set_state("falling")

func _state_logic(delta):
	set_floor_angle()
	
	host.move_input(floor_angle, state == "idle", host.ACCELERATION if state != "boosting" else host.BOOST_ACCELERATION)
	#host.special_moves()
	host.apply_movement(floor_angle, delta)
	
	if state in grounded_states:
		host.snap_to_floor(floor_angle)
		host.jump_input()
	else:
		host.apply_gravity(delta)
		if state == "jumping": host.jump_cancelling()
	host.update_sprite(floor_angle, state)

func _get_transition(delta):
	set_floor_angle()
	var angle = floor_angle / PI
	var is_on_ceiling = int(angle > 0.5 and angle < 1.5)
	
	if state in grounded_states:
		if host.can_touch_ground(true):
			return null
		if !host.raycast.is_colliding():
			return "falling"
		if abs(host.velocity.x) <= abs(host.CEILING_SPEED):
			if is_on_ceiling:
				return "falling"
	
	elif state != "jumping" and host.can_touch_ground(false):
		return "idle"
	
	match state:
		"jumping":
			if host.velocity.y >= 0: return "falling"
	
	return null

func _enter_state(new_state, old_state):
	set_floor_angle(true)
	if new_state in grounded_states and !old_state in grounded_states:
		host.enter_grounded_state(floor_angle)
	if !new_state in grounded_states and old_state in grounded_states:
		host.exit_grounded_state(floor_angle, new_state == "jumping")

func _exit_state(old_state, new_state):
	pass
