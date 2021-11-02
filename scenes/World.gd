extends Node2D

const CHUNK := preload("res://scenes/Chunk.tscn")

export var height := 64
export var width := 128
export var chunk_size := 16
export var square_size := 16
export var level_data = []

onready var camera = $Camera2D
onready var control = $Control

onready var v_chunks: int = ceil(float(height) / float(chunk_size))
onready var h_chunks: int = ceil(float(width) / float(chunk_size))
var radius := 50.0
var color := Color(0.1, 0.1, 0.3, 1)
var chunks := []
var altered_chunks := {}
var world = false
#FIX NOISE- AIR SHOULD ALWAYS BE ZERO, ROCK SHOULD ALWAYS BE 1 INSIDE

export var chunk_vertices := {}

func _ready() -> void:
	# Generate world only when neccesary
	print($Chunks.get_children())
#	if $Chunks.get_child_count() == 0:
#		randomize()
#		generate_world(_generate_empty_world())
#		#generate_world(_get_noise(randi()))

func _input(event):
	if Input.is_action_just_pressed("mouse_wheel_up"):
		level_data = export_level()
	if Input.is_action_just_pressed("mouse_wheel_down"):
		
		if level_data == []:
			randomize()
			print(_get_noise(randi()))
			generate_world(_get_noise(randi()))
		else:
			generate_world( level_data )
		world = true
		print($Chunks.get_children())

func _process(delta_time: float) -> void:
	if !world: return
	_mouse_input()
	update()
	#print(Engine.get_frames_per_second())

func _mouse_input() -> void:
	if(Input.is_action_just_released("mouse_wheel_up")):
		radius += 5
	if(Input.is_action_just_released("mouse_wheel_down")):
		radius -= 5
		radius = max(radius, 10)
	
	if(Input.is_action_just_pressed("debug_mouse3")):
		Global.player.position = get_global_mouse_position()
		Global.player.state_machine.set_state("falling")
		Global.player.velocity = Vector2(0,0)
	
	if(Input.is_action_pressed("debug_mouse")):
		var pos = (get_global_mouse_position() / square_size).round()
		#print(pos)
		explosion(get_global_mouse_position(), radius, -1.0)
		var z = (get_global_mouse_position() / square_size).round()
		set_vertex(z.y, z.x, -0.1, true)
#		for chunk in $Chunks.get_children():
#			chunk.initalize_mesh()
	
	if(Input.is_action_pressed("debug_mouse2")):
		explosion(get_global_mouse_position(), radius, 1.0)

func _draw() -> void:
	draw_circle(get_global_mouse_position(), radius, Color(1.0, 1.0, 0.0, 0.3))
	draw_circle((get_global_mouse_position() / square_size).round() * square_size, 5.0, Color(1.0, 0.0, 0.0, 0.4))
	
	var h_size = h_chunks*chunk_size*square_size
	var v_size = v_chunks*chunk_size*square_size
	var color = Color(1, 1, 1, 0.8)
	draw_line(Vector2(0.0, 0.0), Vector2(h_size, 0.0), color, 2)
	draw_line(Vector2(0.0, v_size), Vector2(h_size, v_size), color, 2)
	draw_line(Vector2(0.0, 0.0), Vector2(0.0, v_size), color, 2)
	draw_line(Vector2(h_size, 0.0), Vector2(h_size, v_size), color, 2)
	
	color = Color(1, 1, 1, 0.1)
	#if !get_tree().debug_collisions_hint: return
	for i in range(0, v_chunks):
		for j in range(0, h_chunks):
			var z = Vector2(j + 1, i + 1) * chunk_size * square_size
			draw_line(Vector2(0.0, z.y), Vector2(h_chunks * chunk_size * square_size, z.y), color)
			draw_line(Vector2(z.x, 0.0), Vector2(z.x, v_chunks * chunk_size * square_size), color)
#	for i in range(0, chunk_size):
#		for j in range(0, chunk_size):
#			var z = Vector2(j + 1, i + 1) * square_size
#			draw_line(Vector2(0.0, z.y), Vector2(h_chunks * chunk_size * square_size, z.y), Color(1.0, 0.0, 0.0, 1.0))
#			draw_line(Vector2(z.x, 0.0), Vector2(z.x, v_chunks * chunk_size * square_size), Color(1.0, 0.0, 0.0, 1.0))


func _get_noise(noise_seed: int) -> Array:  #priv mark?
	var noise := OpenSimplexNoise.new()
	noise.seed = noise_seed
	noise.octaves = 2
	noise.persistence = 0.9
	noise.period = 17.0
	var n_max := 0.0
	var n_avg := 0.0
	for i in range(height):
		for j in range(width):
			var n = abs(noise.get_noise_2d(j,i))
			n_avg += n
			if n > n_max:
				n_max = n
	n_avg /= height * width
	
	var data = []
	for i in range(v_chunks * chunk_size + 1): #debug
		data.append([])
		for j in range(h_chunks * chunk_size + 1):
			data[i].append(clamp(noise.get_noise_2d(j, i) / n_avg + 1.0, 0.0, 2.0) / 2.0)
	
	return data

func _generate_empty_world() -> Array:
	var data = []
	for i in range(v_chunks * chunk_size + 1): #debug
		data.append([])
		for j in range(h_chunks * chunk_size + 1):
			data[i].append(0)
	return data

func generate_world(terrain_data: Array) -> void:
	chunks.resize(v_chunks)
	for i in range(v_chunks):
		chunks[i] = []
		chunks[i].resize(h_chunks)
		for j in range(h_chunks):
			chunks[i][j] = CHUNK.instance()
			chunks[i][j].set_size(chunk_size, square_size)
			chunks[i][j].position = Vector2(j, i) * chunk_size * square_size
			for k in range(chunk_size + 1):
				for l in range(chunk_size + 1):
					chunks[i][j].vertices[k][l] = terrain_data[i * chunk_size + k][j * chunk_size + l]
			$Chunks.add_child(chunks[i][j])
			
	for chunk in $Chunks.get_children():
		chunk.initalize_mesh()

func set_vertex(row: int, col: int, value: float, add: bool = false) -> void:
	if row < 0 or col < 0 or row > height or col > width:
		return
	
	var chunk_row: int = (row - 1) / (chunk_size)
	var chunk_col: int = (col - 1) / (chunk_size)
	var vertex_row := (row - chunk_row * chunk_size) % (chunk_size + 1)
	var vertex_col := (col - chunk_col * chunk_size) % (chunk_size + 1)
	
	if add:
		value += chunks[chunk_row][chunk_col].vertices[vertex_row][vertex_col]
	
	value = clamp(value, 0.0, 1.0)
	
	var chunk = chunks[chunk_row][chunk_col]
	chunk.vertices[vertex_row][vertex_col] = value
	altered_chunks[chunk] = true
	
	var v_edge := vertex_row == chunk_size
	var v_bound := chunk_row < v_chunks - 1
	var h_edge := vertex_col == chunk_size
	var h_bound := chunk_col < h_chunks - 1
	if v_bound and v_edge:
		chunk = chunks[chunk_row + 1][chunk_col] 
		chunk.vertices[0][vertex_col] = value
		altered_chunks[chunk] = true
	if h_bound and h_edge:
		chunk = chunks[chunk_row][chunk_col + 1] 
		chunk.vertices[vertex_row][0] = value
		altered_chunks[chunk] = true
	if v_bound and v_edge and h_bound and h_edge:
		chunk = chunks[chunk_row + 1][chunk_col + 1]
		chunk.vertices[0][0] = value
		altered_chunks[chunk] = true

func update_chunks(every_chunk = false): #unoptimized debug function
	if every_chunk:
		for chunk in $Chunks.get_children():
			chunk.initalize_mesh()
	else:
		for chunk in altered_chunks.keys():
			chunk.initalize_mesh()
		altered_chunks.clear()
	

func explosion(location: Vector2, radius: float, intensity: float) -> void:
	radius /= square_size
	location /= square_size
	var cell_radius := ceil(radius) + 1
	var current := location.round() - Vector2(cell_radius, cell_radius)
	for i in range(cell_radius * 2):
		for j in range(cell_radius * 2):
			set_vertex(current.y + i, current.x + j, max(0.0, 1.0 - min(1.0, Vector2(current.x + j, current.y + i).distance_to(location) / radius)) * -intensity, true) #make this prettier
	update_chunks()

func export_level():
	
	var data = []
	for i in range(v_chunks * chunk_size + 1): #debug
		data.append([])
		for j in range(h_chunks * chunk_size + 1):
			data.append_array(chunks[i][j].vertices)
			pass#data[i].append(  )
	
	return data
	
#	var export_string = []
#	for i in range(v_chunks):
#		for j in range(h_chunks):
#			print(chunks[i][j].vertices)
#			export_string.append_array(chunks[i][j].vertices)
#	return export_string
