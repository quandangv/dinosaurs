extends VBoxContainer

func _ready():
	get_node("/root/game_master").connect("language_changed", self, "update_texts")

func update_texts():
	$Land/texts/header/title.text = tr("Land")
	$Land/texts/content.text = tr("Land text")
	$Land/texts/stat.text = tr("Land stat")
	$Sand/texts/header/title.text = tr("Sand")
	$Sand/texts/content.text = tr("Sand text")
	$Sand/texts/stat.text = tr("Sand stat")

func set_cancel_button_visible(value):
	$Land/texts/header/cancel.visible = value
	$Sand/texts/header/cancel.visible = value
