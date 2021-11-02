extends VBoxContainer

export var variable_to_change = ""
export var label_text = ""
export var minimum_value = 0
export var maximum_value = 1000

func _ready():
	$HSplitContainer/Label.set_text(label_text)
	$HSplitContainer/LineEdit.set_text(str(minimum_value))
	$HSlider.min_value = minimum_value
	$HSlider.max_value = maximum_value
	if Global.player == null: yield(Global, "player_loaded")
	var value = Global.player.get(variable_to_change)
	$HSplitContainer/LineEdit.set_text(str(value))
	$HSlider.set_value(value)

func _on_HSlider_value_changed(value):
	$HSplitContainer/LineEdit.set_text(str(value))
	Global.player.set(variable_to_change, value)

func _on_LineEdit_text_entered(new_text):
	var value = float(new_text)
	$HSlider.set_value(value)
	Global.player.set(variable_to_change, value)
	$HSplitContainer/LineEdit.set_text(str(value))
