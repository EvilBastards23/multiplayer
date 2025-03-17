extends HBoxContainer

var ip_address:String

@onready var number: Label = $number
@onready var server_name: Label = $server_name
@onready var join_button: Button = $join_button

@onready var queue: Label = $queue

func get_number_label()->Label:
	return number
