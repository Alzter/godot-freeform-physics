extends StateMachine

export var camera_move_speed = 20

var camera = null

func _ready():
	add_state("editing")
	add_state("playing")
	call_deferred("set_state", "editing")

func _state_logic(delta):
	if state == "editing":
		_camera_input(camera, camera_move_speed)
	
	if Input.is_action_just_pressed("debug_toggle_editmode"):
		var state_to_set = "playing" if state == "editing" else "editing"
		set_state(state_to_set)

func _get_transition(delta):
	return null

func _enter_state(new_state, old_state):
	var old_camera = camera
	#get_tree().debug_collisions_hint = true#int(state == "editing")
#	host.update_chunks(true)
	
	match new_state:
		"editing":
			camera = host.camera
			if old_camera != null: camera.position = old_camera.global_position
		"playing":
			camera = Global.player.camera
	camera.current = true

func _exit_state(old_state, new_state):
	pass

func _camera_input(camera, move_speed):
	var move_direction = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	camera.position.x += move_direction * move_speed
	move_direction = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	camera.position.y += move_direction * move_speed
