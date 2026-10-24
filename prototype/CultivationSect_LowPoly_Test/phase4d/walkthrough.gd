extends "res://phase4c/walkthrough.gd"
## Inherit the approved environment, controller, camera and door behavior.
func _ready() -> void:
	super._ready()
	for label: Label in find_children("*","Label",true,false):
		label.text = label.text.replace("PHASE 4C / TERRAIN VISUAL REVIEW","PHASE 4D / DISTRICT INTEGRATION REVIEW")
func _process(delta: float) -> void:
	super._process(delta)
	if location: location.text = location.text.replace("Phase 4C visual review","Phase 4D visual review")
