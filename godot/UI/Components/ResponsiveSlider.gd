extends HSlider

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			rect_min_size.x = get_constant("length", "Slider")
