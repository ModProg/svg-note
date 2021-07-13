extends CanvasTool
class_name EraserTool


func process_stroke(p: Vector2, w: float):
	print_debug(p, w)
	get_project().erase_line(p, w)
