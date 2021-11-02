extends CanvasLayer

enum mode {SAVE, LOAD}
onready var mode_set = mode.SAVE

func _on_Save_pressed():
	mode_set = mode.SAVE
	$FileDialog.current_file = ".tscn"
	$FileDialog.set_mode(FileDialog.MODE_SAVE_FILE)
	$FileDialog.popup()

func _on_Load_pressed():
	mode_set = mode.LOAD
	$FileDialog.current_file = ""
	$FileDialog.set_mode(FileDialog.MODE_OPEN_FILE)
	$FileDialog.popup()

func _on_FileDialog_file_selected(path):
	print("SAVE" if mode_set == mode.SAVE else "LOAD")
	
	# Saving a level
	if mode_set == mode.SAVE:
		var packed_scene = PackedScene.new()
		var result = packed_scene.pack(get_tree().get_current_scene())
		if result == OK:
			ResourceSaver.save(path, packed_scene)
		
	# Loading a level
	else: Global.goto_scene(path)
