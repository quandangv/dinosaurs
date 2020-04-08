extends Button

export var available = ["en"]

var current = 0
func _ready():
	update_locale()
	yield(get_tree(), "idle_frame")
	get_node("/root/game_master").emit_signal("language_changed")
func _pressed():
	current = (current+1)%available.size()
	update_locale()
	get_node("/root/game_master").emit_signal("language_changed")

func update_locale():
	TranslationServer.set_locale(available[current])
	text = TranslationServer.get_locale_name(available[current])
	
