extends Panel


@onready var line_edit: LineEdit = $VBoxContainer/LineEdit
@onready var host_button: Button = $"../host_button"


func _ready() -> void:
	pass
	
	
func get_value_from_line_edit()->String:
	return line_edit.text
