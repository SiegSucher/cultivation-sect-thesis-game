# Mountain valley review blockout

Run `res://mountain_valley/mountain_valley.tscn` with **F6**, or use **View Mountain Valley Blockout.cmd** at the workspace root.

WASD/mouse move/look; Tab first/third person; M map/resume; V valley overview; R forest start; Esc gallery. Review jumps 2–8 visit the main districts. The connected walking routes remain available from the forest start.

See [the report](../reports/MOUNTAIN_VALLEY_BLOCKOUT.md) and [the labeled plan](../reports/mountain-valley/layout-plan.png). `layout.json` is the single layout source, in metres. This map does not replace the existing project startup, Phase 4A or the old 2D town.

If rebuilding is explicitly authorized later:

1. Run `prepare_layout.py` with the bundled Python to write layout data and SVG. `render_plan.py` writes the PNG using Pillow.
2. Run Godot **without `--headless`**, with `--path` pointing at the test project and `--script res://mountain_valley/build_map.gd`. This writes only this map's scene/resources and its build summary. A real renderer is required to save the existing pine mesh batch transforms correctly.

Do not regenerate any building or environmental asset. Detailed decoration and final town polish remain approval-gated.


## Video-review follow-up — 24 October 2026
The stair endpoint overlap has been removed and a first environment polish pass added. Existing map launchers load the updated scene. See reports/mountain-valley-polish/REVIEW.md for diagnosis, before/after evidence, tests, limits and recovery. The earlier blockout report is historical; this does not imply final terrain or gameplay acceptance.

