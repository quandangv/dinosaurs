extends Label


func _ready():
	get_node("/root/game_master").connect("language_changed", self, "update_texts")
func update_texts():
	text = tr("put object prompt")
