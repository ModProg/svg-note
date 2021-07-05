extends Node

# -------------------------------------------------------------------------------------------------
var _open_projects: Array  # Array<Project>
var _active_project: Project
var _max_id:=0

var active_project: Project setget _make_project_active,_get_active_project


# -------------------------------------------------------------------------------------------------
func read_project_list() -> void:
	pass


# -------------------------------------------------------------------------------------------------
func _make_project_active(project: Project) -> void:
	_active_project = project
#	if ! project.loaded:
#		_load_project(project)
#	_active_project = project


# -------------------------------------------------------------------------------------------------
func _get_active_project() -> Project:
	return _active_project


# -------------------------------------------------------------------------------------------------
func remove_project(project: Project) -> void:
	_open_projects.erase(project)

	if project == _active_project:
		_active_project = null

#	project.clear()


# -------------------------------------------------------------------------------------------------
func remove_all_projects() -> void:
	for project in _open_projects:
		remove_project(project)
	_open_projects.clear()
	_active_project = null


# -------------------------------------------------------------------------------------------------
func add_project(filepath: String = "") -> Project:
	# Check if already open
	if ! filepath.empty():
		var p := get_open_project_by_filepath(filepath)
		if p != null:
			print_debug("Project already in open project list")
			return p
	var project: Project
	if filepath.empty():
		project = Project.new()
		project.empty()
	else:
		project = Serializer.load_project(filepath)
	_open_projects.append( project)
	return project


# -------------------------------------------------------------------------------------------------
func save_project(project: Project) -> void:
	Serializer.save_project(project)
	project.dirty = false


# -------------------------------------------------------------------------------------------------
func save_all_projects() -> void:
	for p in _open_projects:
		if ! p.filepath.empty() && p.loaded && p.dirty:
			save_project(p)


# -------------------------------------------------------------------------------------------------
func _load_project(project: Project) -> void:
	if ! project.loaded:
		Serializer.load_project(project.file_name)
		project.loaded = true
	else:
		print_debug("Trying to load already loaded project")


# -------------------------------------------------------------------------------------------------
func get_open_project_by_filepath(filepath: String) -> Project:
	for project in _open_projects:
		if project.filepath == filepath:
			return project
	return null


# -------------------------------------------------------------------------------------------------
func get_project_by_id(id: int) -> Project:
	for p in _open_projects:
		if p.id == id:
			return p
	return null


# -------------------------------------------------------------------------------------------------
func has_unsaved_changes() -> bool:
	for p in _open_projects:
		if p.dirty:
			return true
	return false


# -------------------------------------------------------------------------------------------------
func has_unsaved_projects() -> bool:
	for p in _open_projects:
		if p.dirty && p.filepath.empty():
			return true
	return false


# -------------------------------------------------------------------------------------------------
func get_project_count() -> int:
	return _open_projects.size()


# -------------------------------------------------------------------------------------------------
func is_active_project(project: Project) -> bool:
	return _active_project == project
