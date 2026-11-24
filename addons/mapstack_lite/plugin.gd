@tool
extends EditorPlugin
## MapStack Lite: one dock that installs MapStack Free and links to MapStack Pro.

const LiteDock := preload("res://addons/mapstack_lite/lite_dock.gd")

var _dock: Control

func _enter_tree() -> void:
	_dock = LiteDock.new()
	_dock.name = "MapStack Lite"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)

func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
