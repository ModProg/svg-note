class_name CanvasTool, "res://Assets/Icons/Editor/tools.png"
extends Node

export var cursor_path: NodePath
export var pressure_curve: Curve = Curve.new()
var _cursor: Sprite  # This is a BaseCursor. Can't type it.
var _canvas: Node  # This is an InfinteCanvas. Can't type it though because of cyclic dependency bugs...
var enabled := false setget set_enabled, get_enabled
var performing_stroke := false
var touch := false
var stylus := true
var _last_mouse_motion: InputEventMouseMotion
var project: Project setget , get_project
# Child Events


func start_stroke():
	pass


func end_stroke():
	pass


func process_stroke(brush_position: Vector2, pressure: float):
	pass


func get_project():
	return _canvas.project


func _input(event: InputEvent) -> void:
	_cursor.set_pressure(1.0)
	if touch:
		if stylus:
			if event is InputEventMouseMotion:
				if event.pressure > 0:
					_last_mouse_motion = event
					if ! performing_stroke:
						performing_stroke = true
						start_stroke()
				elif performing_stroke:
					performing_stroke = false
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
					performing_stroke = true
					start_stroke()
				elif ! event.pressed:
					performing_stroke = false
					end_stroke()


func _process(delta: float) -> void:
	if performing_stroke && _last_mouse_motion != null:
		var brush_position: Vector2 = xform_vector2(_last_mouse_motion.global_position)
		var pressure = _last_mouse_motion.pressure
		print(pressure)
		pressure = pressure_curve.interpolate(pressure)
		print(pressure)
		process_stroke(brush_position, pressure * 20)
		_last_mouse_motion = null


func _ready():
	_cursor = get_node(cursor_path)
	_canvas = get_parent()
	set_enabled(false)


func _on_brush_size_changed(size: int) -> void:
	_cursor.change_size(size)


func set_enabled(e: bool) -> void:
	enabled = e
	set_process(enabled)
	set_process_input(enabled)
	_cursor.set_visible(enabled)
	if enabled && _canvas:
		_cursor.global_position = xform_vector2(get_viewport().get_mouse_position())


func get_enabled() -> bool:
	return enabled


func xform_vector2(v: Vector2) -> Vector2:
	return _canvas.get_camera().xform(v)


# Returns the input Vector translated by the camera offset and zoom, giving always the absolute position


func xform_vector2_relative(v: Vector2) -> Vector2:
	return (
		(_canvas.get_camera().xform(v) - _canvas.get_camera_offset())
		/ _canvas.get_camera().get_zoom()
	)
