class_name Serializer

# TODO: !IMPORTANT! all of this needs validation
# TODO: !IMPORTANT! all of this needs validation
# TODO: !IMPORTANT! all of this needs validation

const BRUSH_STROKE = preload("res://BrushStroke/BrushStroke.tscn")
const COMPRESSION_METHOD = File.COMPRESSION_DEFLATE
const POINT_ELEM_SIZE := 3

const VERSION_NUMBER := 0
const TYPE_BRUSH_STROKE := 0
const TYPE_ERASER_STROKE := 1

static func save_project(project: Project) -> void:
	var start_time := OS.get_ticks_msec()

	# Open file
#	var svg := SvgLib.new()
	var ser: String = str(project)
	print_debug(ser)
	var file := File.new()
	var err = file.open(project.filepath, File.WRITE)
	if err != OK:
		print_debug("Failed to open file for writing: %s" % project.filepath)
		return
	file.store_string(ser)
	# Meta data
#	file.store_32(VERSION_NUMBER)
#	file.store_pascal_string(_dict_to_metadata_str(project.meta_data))
#
#	# Stroke data
#	for stroke in project.strokes:
#		# Type
#		if stroke.eraser:
#			file.store_8(TYPE_ERASER_STROKE)
#		else:
#			file.store_8(TYPE_BRUSH_STROKE)
#
#		# Color
#		file.store_8(stroke.color.r8)
#		file.store_8(stroke.color.g8)
#		file.store_8(stroke.color.b8)
#
#		# Brush size
#		file.store_16(int(stroke.size))
#
#		# Number of points
#		file.store_16(stroke.points.size())
#
#		# Points
#		var p_idx := 0
#		for p in stroke.points:
#			# Add global_position offset which is != 0 when moved by move tool; but mostly it should just add 0
#			file.store_float(p.x + stroke.global_position.x)
#			file.store_float(p.y + stroke.global_position.y)
#			file.store_8(stroke.pressures[p_idx])
#			p_idx += 1

	# Done
	file.close()
	print("Saved %s in %d ms" % [project.filepath, OS.get_ticks_msec() - start_time])

static func load_project(path: String) -> Project:
	var start_time := OS.get_ticks_msec()
	var project := Project.new()
	project.filepath = path

	# Open file
	var file := File.new()
	var err = file.open(project.filepath, File.READ)
	if err != OK:
		print_debug("Failed to load file: %s" % project.filepath)
		return null

	project.load(file.get_as_text())

	# Done
	file.close()
	print("Loaded %s in %d ms" % [project.filepath, OS.get_ticks_msec() - start_time])
	return project

static func _dict_to_metadata_str(d: Dictionary) -> String:
	var meta_str := ""
	for k in d.keys():
		var v = d[k]
		if k is String && v is String:
			meta_str += "%s=%s," % [k, v]
		else:
			print_debug("Metadata should be String key-value pairs only!")
	return meta_str

static func _metadata_str_to_dict(s: String) -> Dictionary:
	var meta_dict := {}
	for kv in s.split(",", false):
		var kv_split: PoolStringArray = kv.split("=", false)
		if kv_split.size() != 2:
			print_debug("Invalid metadata key-value pair: %s" % kv)
		else:
			meta_dict[kv_split[0]] = kv_split[1]
	return meta_dict
