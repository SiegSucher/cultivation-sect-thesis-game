extends "res://mountain_valley_compact/valley_walkthrough.gd"
## Reuse the approved camera/controller and all review controls unchanged.
func _ready() -> void:
	super._ready()
	for label: Label in find_children("*","Label",true,false):
		label.text = label.text.replace("COMPACT PHASE 4B / UNAPPROVED","PHASE 4C / TERRAIN VISUAL REVIEW")
func _process(delta: float) -> void:
	super._process(delta)
	if location: location.text = location.text.replace("compact layout review","Phase 4C visual review")
