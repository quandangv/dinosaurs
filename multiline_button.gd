extends Button

export var label:String
export var color:Color

func _ready():
	$Label.text = label
	modulate = color
