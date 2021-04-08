extends EditorPlugin
tool

var editor_interface: EditorInterface = null


func _init():
	print("Initialising DebugManager plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying DebugManager plugin")


func get_name() -> String:
	return "DebugManager"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	add_autoload_singleton(
		"DebugManager", "res://addons/sar1_debug_manager/debug_manager.gd"
	)


func _exit_tree() -> void:
	remove_autoload_singleton("DebugManager")
