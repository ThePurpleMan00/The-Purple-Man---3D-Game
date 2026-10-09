extends SceneTree
## Ship the engine and dependency notices alongside its exported WebAssembly.


func _initialize() -> void:
	var notices := FileAccess.open("res://builds/web/GODOT-LICENSE.txt", FileAccess.WRITE)
	if notices == null:
		push_error("Could not write Godot engine notices")
		quit(1)
		return
	notices.store_string(Engine.get_license_text())
	notices.store_string("\n\nThird-party component copyright notices:\n")
	notices.store_string(JSON.stringify(Engine.get_copyright_info(), "\t"))
	notices.store_string("\n\nThird-party license texts:\n")
	notices.store_string(JSON.stringify(Engine.get_license_info(), "\t") + "\n")
	notices.close()
	print("Godot engine and dependency notices exported")
	quit(0)
