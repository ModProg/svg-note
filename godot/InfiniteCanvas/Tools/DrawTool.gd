class_name DrawTool
extends CanvasTool


func _on_brush_color_changed(color: Color) -> void:
	pass


func start_stroke(eraser: bool = false) -> void:
	_canvas.start_stroke(eraser)
	performing_stroke = true


func add_stroke_point(point: Vector2, pressure: float = 1.0) -> void:
	_canvas.add_stroke_point(point, pressure)


func remove_last_stroke_point() -> void:
	_canvas.remove_last_stroke_point()


func end_stroke() -> void:
	_canvas.end_stroke()
	performing_stroke = false


func xform_vector2(v: Vector2) -> Vector2:
	return _canvas.get_camera().xform(v)


# Returns the input Vector translated by the camera offset and zoom, giving always the absolute position


func xform_vector2_relative(v: Vector2) -> Vector2:
	return (
		(_canvas.get_camera().xform(v) - _canvas.get_camera_offset())
		/ _canvas.get_camera().get_zoom()
	)
