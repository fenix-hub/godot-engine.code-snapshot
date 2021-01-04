tool
extends EditorPlugin

var script_editor : ScriptEditor = get_editor_interface().get_script_editor()
var code_snapshot_instance : CodeSnapshotInstance 

func _enter_tree():
	code_snapshot_instance = preload("res://addons/code-snapshot/Instance/instance.tscn").instance()
	code_snapshot_instance.set_script_editor(script_editor)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, code_snapshot_instance)

func _exit_tree():
	code_snapshot_instance.free()
