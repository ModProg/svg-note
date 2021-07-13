class_name BrushTool
extends DrawTool

enum Mode { DRAW, ERASE }

var mode: int = Mode.DRAW


func _input(event: InputEvent) -> void:
	_cursor.set_pressure(1.0)
	if touch:
		if stylus:
			if event is InputEventMouseMotion:
				if event.pressure > 0:
					_last_mouse_motion = event
					if ! performing_stroke:
						start_stroke(mode == Mode.ERASE)
				elif performing_stroke:
					end_stroke()

		else:
			pass
	else:
		if event is InputEventMouseMotion:
			_last_mouse_motion = event
			_cursor.global_position = xform_vector2(event.global_position)
			if performing_stroke:
				_cursor.set_pressure(event.pressure)

		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if event.pressed && _last_mouse_motion != null:
					_last_mouse_motion.global_position = event.global_position
					_last_mouse_motion.position = event.position
					start_stroke(mode == Mode.ERASE)
				elif ! event.pressed:
					end_stroke()


func _process(delta: float) -> void:
	if performing_stroke && _last_mouse_motion != null:
		var brush_position: Vector2 = xform_vector2(_last_mouse_motion.global_position)
		var pressure = _last_mouse_motion.pressure
		pressure = pressure_curve.interpolate(pressure)
		add_stroke_point(brush_position, pressure)
		_last_mouse_motion = null

		# If the brush stroke gets too long, we make a new one. This is necessary because Godot limits the number
		# of indices in a Line2D/Polygon
#		if get_current_brush_stroke().points.size() >= BrushStroke.MAX_POINTS:
#			end_stroke()
#			start_stroke(mode == Mode.ERASE)
#			add_stroke_point(brush_position, pressure)
