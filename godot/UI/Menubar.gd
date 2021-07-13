extends PanelContainer
class_name Menubar

const PROJECT_TAB = preload("res://UI/Components/ProjectTab.tscn")

signal project_selected(project)
signal project_closed(project)
signal create_new_project

onready var _file_tabs_container: HBoxContainer = $Left/Tabs
export var _main_menu_path: NodePath
var _active_file_tab: ProjectTab
var _tabs_map: Dictionary  # Dictonary<Project, ProjectTab>


func make_tab(project: Project) -> void:
	var tab: ProjectTab = PROJECT_TAB.instance()
	tab.title = project.filepath
	tab.project = project
	tab.connect("close_requested", self, "_on_tab_close_requested")
	tab.connect("selected", self, "_on_tab_selected")
	_file_tabs_container.add_child(tab)
	_tabs_map[project] = tab


# ------------------------------------------------------------------------------------------------
func has_tab(project: Project) -> bool:
	return _tabs_map.has(project)


# ------------------------------------------------------------------------------------------------
func remove_tab(project: Project) -> void:
	if _tabs_map.has(project):
		var tab = _tabs_map[project]
		tab.disconnect("close_requested", self, "_on_tab_close_requested")
		tab.disconnect("selected", self, "_on_tab_selected")
		_file_tabs_container.remove_child(tab)
		_tabs_map.erase(project)
		tab.call_deferred("free")


# ------------------------------------------------------------------------------------------------
func remove_all_tabs() -> void:
	for project in _tabs_map.keys():
		remove_tab(project)
	_tabs_map.clear()
	_active_file_tab = null


# ------------------------------------------------------------------------------------------------
func update_tab_title(project: Project) -> void:
	if _tabs_map.has(project):
		var name = project.filepath
		if project.dirty:
			name += " (*)"
		_tabs_map[project].title = name


# ------------------------------------------------------------------------------------------------
func set_tab_active(project: Project) -> void:
	if _tabs_map.has(project):
		var tab: ProjectTab = _tabs_map[project]
		_active_file_tab = tab
		for c in _file_tabs_container.get_children():
			c.set_active(false)
		tab.set_active(true)
	else:
		print_debug("Project tab not found")


func _on_tab_close_requested(tab: ProjectTab) -> void:
	emit_signal("project_closed", tab.project_id)


func _on_tab_selected(tab: ProjectTab) -> void:
	emit_signal("project_selected", tab.project_id)


func _on_NewFileButton_pressed():
	emit_signal("create_new_project")


func _on_MenuButton_pressed():
	get_node(_main_menu_path).popup()


func get_first_project_id() -> int:
	if _file_tabs_container.get_child_count() == 0:
		return -1
	return _file_tabs_container.get_child(0).project_id


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			var sb = get_stylebox("panel", "Menubar")
			if sb != get_stylebox("panel"):
				add_stylebox_override("panel", sb)
