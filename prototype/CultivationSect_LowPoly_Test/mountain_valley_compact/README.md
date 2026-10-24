# Compact mountain-valley proposal layout — Phase 4B

**Unapproved visual-review revision.** Double-click **Launch Compact Valley.cmd** in this folder, or open `res://mountain_valley_compact/compact_valley.tscn` in the test project and press **F6**. The large scene and its launchers remain intact.

WASD/mouse move/look; Tab first/third person; M map/resume; V valley overview; R forest start; Esc gallery. Existing keys 2–8 are optional review shortcuts. The demonstration route is continuously walkable without those shortcuts, sprinting or speed changes.

See [the review report](review/REVIEW.md), [labeled layout](review/layout-plan.png), and [valley overview](review/07-valley-overview.png). The source of positions, dimensions and routes is this folder's independent `layout.json`; generated resources are in `resources/`.

The old map has an additional recovery archive at `review/large-map-recovery.zip`, with a before-file manifest and final preservation check alongside it. Recovery does not depend on Git.

Build support: `prepare_sources.py` copies reusable map logic into this folder, `prepare_layout.py` writes the compact data, `build_map.gd` saves only compact scene/resources, and `render_plan.py` draws the labeled plan. Run the builder with a rendered Godot process so existing pine batch transforms survive serialization. Building and environmental assets must not be regenerated.

Stop at Phase 4B review; detailed decoration and Phase 4C remain outside scope.
