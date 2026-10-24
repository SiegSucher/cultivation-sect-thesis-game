# Phase 4C arrival-stair railing integration

Ready for final Phase 4C visual review. **Phase 4C remains unapproved. No Phase 4D work was started.**

## Launch and captures

Double-click [Launch Phase 4C.cmd](../../Launch%20Phase%204C.cmd), or run `res://phase4c/phase4c_valley.tscn` with F6 in the working test project. WASD moves, mouse looks, Tab switches first/third person. The forest start leads directly to the arrival flight; R returns there.

- [Complete arrival approach, third-person gameplay](complete-arrival-approach.png)
- [Side view showing the entire flight and supporting strips](arrival-side.png)
- [Upper landing connection](upper-landing-connection.png)

All three captures were visually inspected by the agent. The two closer views use the existing review camera only within the capture fixture; no saved player/camera settings changed.

## Integration

Installed **five 2 m sections followed by one 1 m section on each side**, at the exact **4/11 pitch**, spanning 11 m horizontally and 4 m vertically. All twelve new instances retain unit scale, vertical posts and yaw-only placement. Their origins are at x ±6.35 m, run 0/2/4/6/8/10 m, with the established **+0.06 m pitch offset**. The top rail is approximately **1.16 m above the walking pitch**.

The existing level landing rails supply the terminal leading posts at `(±6.35, 4.06, 94)`. No new terminal posts, supporting strips or landing rails were added. The staged GLBs were imported into phase-local model resources; each adapter changes only its model resource path, preserving staged geometry, materials and collision.

The targeted integrator appended twelve instances to the existing support scene. It never called the terrain or world builders. The latest mountain mesh/collision, pine batches, all other stairs/guards, buildings, layout, terrace heights, walking ramps and player/camera sources/settings remain unchanged. The compact baseline, large map, Phase 4A and staging assets are preserved.

## Checks actually performed

- **31 focused automated checks passed:** launch; six sections per side at the expected transforms; one existing terminal landing post per side; support under flight/landing samples; visible plinth/top-rail join probes; approximately 1.16 m rail height; twelve uphill/downhill walks across centre and both edges in first/third person; eight sideways movement probes at a 2 m section, post joint, 1 m section and upper landing on both sides. Waist-height rays separately hit actual rail collision.
- Edge walks reached x **±5.93 m** on the flight, 0.30 m from the rail collision face, and joined the narrower forest/landing approaches through the centre. Each walk was continuous between its starting and ending approaches.
- **6 rendered checks passed:** launch, actual Tab switching in both directions and the three captures. No full-map, building gallery or asset verification suite was repeated.
- [Preservation comparison](preservation.json): hashes of **6,241 pre-existing project files**, no unexpected changes or missing files. Existing support-scene content is retained verbatim; only the two resource declarations and twelve arrival instances were appended. Both adapters match staging except the model path. [Walking evidence](walking-results.json), [rendered evidence](rendered-results.json), [import record](kit-imports.json).

## Remaining limits and diagnostic findings

Initial straight-line probes outside the narrower approaches found existing terrain snags: uphill at the right foot margin, x +5.93 m near z 105.23; downhill from the upper shoulder at x ±5.65 m near z 93.72. All three reproduce with the **pre-integration support scene and no new sloped rails**; contacts identify `ValleyGroundCollision`. See [baseline diagnosis](preexisting-edge-diagnosis.json). These are unchanged outer transition limits, not newly blocked centre routes. Terrain was preserved as requested.

An initial landing sideways probe contacted the low support/shoulder before reaching the rail. The final probe starts on the existing supporting strip and confirms actual landing-rail blocking. Initial results/logs are retained alongside the final results.

Automated walking and agent screenshot inspection are **not human playtesting or visual approval**. Existing selective guard coverage elsewhere remains unchanged. The host certificate-store warning appears in headless Godot logs but did not prevent the checks.

## Changed files and recovery

Updated `phase4c/import_kit.gd`, `safety_assembly.gd` and `resources/safety_assembly.tscn`; added `integrate_arrival_rails.gd`, two `resources/kit/railings/rail_stair_4in11_*.tscn` adapters and their two `*_model.scn` resources. README/original review link here; this review folder contains the snapshot, targeted fixtures, captures and evidence.

[phase4c-before-arrival-rails.zip](phase4c-before-arrival-rails.zip) preserves the prior Phase 4C sources, scene and generated resources, including the latest revised mountains. Close Godot and extract the required project-relative `phase4c/` files into the working project root to recover them. [before-hashes.json](before-hashes.json) records the pre-edit project. Recovery does not depend on Git.
