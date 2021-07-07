extends Popup

var source: Control


func _process(delta: float) -> void:
	if visible:
		rect_min_size = get_child(0).rect_size
		if source:
			rect_global_position = (
				source.rect_global_position
				+ Vector2(-rect_min_size.x / 2.0 + source.rect_size.x / 2.0, source.rect_size.y)
			)
			rect_global_position.x = min(
				rect_global_position.x, get_viewport_rect().size.x - rect_size.x
			)
