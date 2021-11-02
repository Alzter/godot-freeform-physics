extends Node2D

export var destination_level = ""

func _on_Area2D_body_entered(body):
	print("A")
	var level = "res://scenes/levels/" + destination_level + ".tscn"
	print(level)
	Global.goto_scene(level)
