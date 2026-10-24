extends SceneTree
func _initialize() -> void:
 for item: Dictionary in ProjectSettings.get_property_list():
  if "shader_cache" in String(item.name):print(item.name," = ",ProjectSettings.get_setting(item.name))
 for item: Dictionary in RenderingServer.get_method_list():
  if "cache" in String(item.name):print("METHOD ",item.name)
 quit()
