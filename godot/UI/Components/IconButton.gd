tool
extends Button
class_name IconButton, "res://Assets/Icons/Editor/icon_button.svg"
# -------------------------------------------------------------------------------------------------
export var normal_icon_name: String setget _set_normal_icon
export var pressed_icon_name: String setget _set_pressed_icon
export var small: bool setget _set_small
var _hovered: bool
var _ic: TextureRect
var _hover_tint: Color
var _normal_tint: Color
var _pressed_tint: Color
var _normal_icon: Texture
var _pressed_icon: Texture
var _size: Vector2
var _icon_size: Vector2
var _small_size: Vector2
var _small_icon_size: Vector2


func _set_normal_icon(value: String):
	normal_icon_name = value
	_normal_icon = get_icon(normal_icon_name, "Icons")
	_update_state()


func _set_pressed_icon(value: String):
	pressed_icon_name = value
	_pressed_icon = get_icon(pressed_icon_name, "Icons")
	_update_state()


func _set_small(value: bool):
	small = value
	_update_state()


func _update_state():
	if toggle_mode && pressed:
		if _pressed_icon:
			_ic.texture = _pressed_icon
			if _hovered:
				modulate = _hover_tint
			else:
				modulate = _normal_tint
		else:
			_ic.texture = _normal_icon
			modulate = _pressed_tint
	else:
		_ic.texture = _normal_icon
		if _hovered:
			modulate = _hover_tint
		else:
			modulate = _normal_tint
	if small:
		rect_min_size = _small_size
		_ic.rect_min_size = _small_icon_size
	else:
		rect_min_size = _size
		_ic.rect_min_size = _icon_size


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE

	var cc := CenterContainer.new()
	cc.anchor_bottom = 1
	cc.anchor_right = 1
	cc.mouse_filter = MOUSE_FILTER_PASS
	add_child(cc)
	_ic = TextureRect.new()
	_ic.expand = true
	_ic.mouse_filter = MOUSE_FILTER_PASS
	cc.add_child(_ic)


# -------------------------------------------------------------------------------------------------
func _ready() -> void:
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	connect("pressed", self, "_on_pressed")


# -------------------------------------------------------------------------------------------------
func _exit_tree() -> void:
	disconnect("mouse_entered", self, "_on_mouse_entered")
	disconnect("mouse_exited", self, "_on_mouse_exited")
	disconnect("pressed", self, "_on_pressed")


# -------------------------------------------------------------------------------------------------
func _on_mouse_entered() -> void:
	_hovered = true
	_update_state()


# -------------------------------------------------------------------------------------------------
func _on_mouse_exited() -> void:
	_hovered = false
	_update_state()


# -------------------------------------------------------------------------------------------------
func toggle() -> void:
	pressed = ! pressed
	_update_state()


# -------------------------------------------------------------------------------------------------
func _on_pressed() -> void:
	_update_state()


# -------------------------------------------------------------------------------------------------
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			_size = Vector2.ONE * get_constant("size", "IconButton")
			_icon_size = Vector2.ONE * get_constant("icon_size", "IconButton")
			_small_size = Vector2.ONE * get_constant("small_size", "IconButton")
			_small_icon_size = Vector2.ONE * get_constant("small_icon_size", "IconButton")
			_hover_tint = get_color("hover_tint", "IconButton")
			_normal_tint = get_color("normal_tint", "IconButton")
			_pressed_tint = get_color("pressed_tint", "IconButton")
			_normal_icon = get_icon(normal_icon_name, "Icons")
			if has_icon(pressed_icon_name, "Icons"):
				_pressed_icon = get_icon(pressed_icon_name, "Icons")
			else:
				_pressed_icon = null
			_update_state()
