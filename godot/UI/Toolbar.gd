extends PanelContainer
class_name Toolbar

signal new_project
signal open_project(filepath)
signal save_project
signal clear_canvas
signal undo_action
signal redo_action
signal brush_color_changed(color)
signal grid_enabled(enabled)
signal brush_size_changed(size)
signal canvas_background_changed(color)
signal tool_changed(t)

# -------------------------------------------------------------------------------------------------
const BUTTON_HOVER_COLOR = Color("50ffd6")
const BUTTON_CLICK_COLOR = Color("50ffd6")
const BUTTON_NORMAL_COLOR = Color.white

# -------------------------------------------------------------------------------------------------
export var file_dialog_path: NodePath
export var brush_color_picker_path: NodePath
export var background_color_picker_path: NodePath

onready var _new_button: IconButton = $HBox/Left/File/NewFileButton
onready var _save_button: IconButton = $HBox/Left/File/SaveFileButton
onready var _open_button: IconButton = $HBox/Left/File/OpenFileButton
onready var _clear_canvas_button: IconButton = $HBox/Left/File/ClearCanvasButton
onready var _undo_button: IconButton = $HBox/Left/UndoButton
onready var _redo_button: IconButton = $HBox/Left/RedoButton
onready var _color_button: Button = $HBox/Left/ColorButton
onready var _brush_size_label: Label = $HBox/Left/BrushSizeLabel
onready var _brush_size_slider: HSlider = $HBox/Left/BrushSizeSlider
onready var _brush_color_picker: ColorPicker = get_node(brush_color_picker_path)
onready var _brush_color_picker_popup: Popup = get_node(brush_color_picker_path).get_parent().get_parent()  # meh...
onready var _background_color_picker: ColorPicker = get_node(background_color_picker_path)
onready var _background_color_picker_popup: Popup = get_node(background_color_picker_path).get_parent().get_parent()  # meh...
onready var _grid_button: IconButton = $HBox/Right/GridButton
onready var _background_color_button: IconButton = $HBox/Right/BackgroundColorButton
onready var _tool_btn_brush: IconButton = $HBox/Left/BrushToolButton
onready var _tool_btn_line: IconButton = $HBox/Left/LineToolButton
onready var _tool_btn_eraser: IconButton = $HBox/Left/EraserToolButton
onready var _tool_btn_colorpicker: IconButton = $HBox/Left/ColorPickerToolButton
onready var _tool_btn_selection: Button = $HBox/Left/SelectionToolButton

var _last_active_tool_button: IconButton
var _size_mode: int = 0
var _last_size: Vector2


# -------------------------------------------------------------------------------------------------
func _ready():
	var brush_size: int = Settings.get_value(
		Settings.GENERAL_DEFAULT_BRUSH_SIZE, Config.DEFAULT_BRUSH_SIZE
	)
	var brush_color: Color = Settings.get_value(
		Settings.GENERAL_DEFAULT_BRUSH_COLOR, Config.DEFAULT_BRUSH_COLOR
	)

	_brush_color_picker.connect("color_changed", self, "_on_brush_color_changed")
	_background_color_picker.connect("color_changed", self, "_on_background_color_changed")
	_brush_size_label.text = str(brush_size)
	_brush_size_slider.value = brush_size
	_last_active_tool_button = _tool_btn_brush
	_on_brush_color_changed(brush_color)

	_brush_color_picker_popup.source = _color_button
	_background_color_picker_popup.source = _background_color_button


# IconButton clicked callbacks
# -------------------------------------------------------------------------------------------------
func _on_NewFileButton_pressed():
	emit_signal("new_project")


func _on_ClearCanvasButton_pressed():
	emit_signal("clear_canvas")


func _on_UndoButton_pressed():
	emit_signal("undo_action")


func _on_RedoButton_pressed():
	emit_signal("redo_action")


# -------------------------------------------------------------------------------------------------
func enable_tool(tool_type: int) -> void:
	var btn: IconButton
	match tool_type:
		Types.Tool.BRUSH:
			btn = _tool_btn_brush
		Types.Tool.LINE:
			btn = _tool_btn_line
		Types.Tool.ERASER:
			btn = _tool_btn_eraser
		Types.Tool.COLOR_PICKER:
			btn = _tool_btn_colorpicker
		Types.Tool.SELECT:
			btn = _tool_btn_selection

	btn.toggle()
	_change_active_tool_button(btn)
	emit_signal("tool_changed", tool_type)


# -------------------------------------------------------------------------------------------------
func _on_OpenFileButton_pressed():
	var file_dialog: FileDialog = get_node(file_dialog_path)
	file_dialog.mode = FileDialog.MODE_OPEN_FILE
	file_dialog.connect("file_selected", self, "_on_project_selected_to_open")
	file_dialog.connect("popup_hide", self, "_on_file_dialog_closed")
	file_dialog.invalidate()
	file_dialog.popup_centered()


# -------------------------------------------------------------------------------------------------
func _on_project_selected_to_open(filepath: String) -> void:
	emit_signal("open_project", filepath)


# -------------------------------------------------------------------------------------------------
func _on_SaveFileButton_pressed():
	emit_signal("save_project")


# -------------------------------------------------------------------------------------------------
func _on_file_dialog_closed() -> void:
	var file_dialog: FileDialog = get_node(file_dialog_path)
	Utils.remove_signal_connections(file_dialog, "file_selected")
	Utils.remove_signal_connections(file_dialog, "popup_hide")


# -------------------------------------------------------------------------------------------------
func _on_ColorButton_pressed():
	_brush_color_picker_popup.popup()


# -------------------------------------------------------------------------------------------------
func _on_brush_color_changed(color: Color) -> void:
	_color_button.get("custom_styles/normal").bg_color = color
	var text_color := color.inverted()
	_color_button.set("custom_colors/font_color", text_color)
	_color_button.set("custom_colors/font_color_hover", text_color)
	_color_button.set("custom_colors/font_color_pressed", text_color)
	_color_button.text = "#" + color.to_html(false)
	emit_signal("brush_color_changed", color)


# -------------------------------------------------------------------------------------------------
func _on_background_color_changed(color: Color) -> void:
	emit_signal("canvas_background_changed", color)


# -------------------------------------------------------------------------------------------------
func _on_BrushSizeSlider_value_changed(value: float):
	var new_size := int(value)
	_brush_size_label.text = "%d" % new_size
	emit_signal("brush_size_changed", new_size)


# -------------------------------------------------------------------------------------------------
func _on_BrushToolButton_pressed():
	_change_active_tool_button(_tool_btn_brush)
	emit_signal("tool_changed", Types.Tool.BRUSH)


# -------------------------------------------------------------------------------------------------
func _on_LineToolButton_pressed():
	_change_active_tool_button(_tool_btn_line)
	emit_signal("tool_changed", Types.Tool.LINE)


# -------------------------------------------------------------------------------------------------
func _on_EraserToolButton_pressed():
	_change_active_tool_button(_tool_btn_eraser)
	emit_signal("tool_changed", Types.Tool.ERASER)


# -------------------------------------------------------------------------------------------------
func _on_ColorPickerToolButton_pressed():
	_change_active_tool_button(_tool_btn_colorpicker)
	emit_signal("tool_changed", Types.Tool.COLOR_PICKER)


# -------------------------------------------------------------------------------------------------
func _on_SelectToolButton_pressed():
	_change_active_tool_button(_tool_btn_selection)
	emit_signal("tool_changed", Types.Tool.SELECT)


# -------------------------------------------------------------------------------------------------
func _on_BackgroundColorButton_pressed():
	_background_color_picker_popup.popup()


# -------------------------------------------------------------------------------------------------
func _on_GridButton_toggled(toggled: bool):
	emit_signal("grid_enabled", toggled)


# -------------------------------------------------------------------------------------------------
func _change_active_tool_button(btn: IconButton) -> void:
	if _last_active_tool_button != null:
		_last_active_tool_button.toggle()
	_last_active_tool_button = btn


func _on_Toolbar_resized() -> void:
	if get_minimum_size().x >= rect_size.x:
		print(name + " at size " + str(_size_mode) + " is too big, increasing compactness")
		_last_size = get_parent_area_size()
		_size_mode += 1
	elif _size_mode > 0 && get_parent_area_size().x > _last_size.x:
		_last_size = get_parent_area_size()
		_size_mode -= 1


# -------------------------------------------------------------------------------------------------
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			var sb = get_stylebox("panel", "Toolbar")
			if sb != get_stylebox("panel"):
				add_stylebox_override("panel", sb)
