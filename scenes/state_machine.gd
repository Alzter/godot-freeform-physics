extends Node
class_name StateMachine

var state = null setget set_state
var previous_state = null
var states = []

onready var host = get_parent()

func _physics_process(delta):
	if host.has_node("VisibilityEnabler2D"): # Disable node functioning if it has VisibilityEnabler2D
		if !host.get_node("VisibilityEnabler2D").is_on_screen(): return
	
	if state != null:
		_state_logic(delta)
		var transition = _get_transition(delta)
		if transition != null:
			set_state(transition)

func _state_logic(delta):
	pass

func _get_transition(delta):
	return null

func _enter_state(new_state, old_state):
	pass

func _exit_state(old_state, new_state):
	pass

func set_state(new_state):
	previous_state = state
	state = new_state
	
	if previous_state != null:
		_exit_state(previous_state, state)
	if new_state != null:
		_enter_state(state, previous_state)

func add_state(state_name):
	states.append(state_name)
