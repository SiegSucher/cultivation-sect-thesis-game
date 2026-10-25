const fs=require('fs'),path=require('path');
const read=name=>JSON.parse(fs.readFileSync(path.join(__dirname,name),'utf8'));
const summary=read('verification-summary.json');
const preservation=read('preservation.json');
const perf=read('Performance1080.json');
const rehearsal=read('rehearsal/rehearsal-python.json');
const labels={Runner:'Restricted interpreter: Python, C, Java; supported syntax, limits and authored answers',Quest:'Complete quest in all three languages, drafts, hints, solutions, recognition and reset',Life720:'Rendered lantern activity, journal, Mei, original Python quest and reset at 1280 × 720',Life1080:'Same rendered activity/quest checks at native 1920 × 1080',Layout720:'Terminal dragging/resizing, reference panes, text/UI scale and camera restore at 720p',Layout1080:'Same terminal checks at native 1080p',Routes:'Physical Gate passage and eight principal district routes',LivingRendered:'Rendered residents, wall solidity/support, feet, water response, dialogue, camera and reset',Extras:'Walker yielding, planted-foot motion and listening-bench state/camera/reset'};
const table=summary.suites.map(s=>`| ${labels[s.suite]} | **${s.checks} passed / ${s.failures} failed** | [${s.suite}.json](${s.suite}.json) |`).join('\n');
const perfRows=perf.samples.map(s=>`| ${s.view} | ${s.avg_fps} | ${s.avg_ms} | ${s.p95_ms} | ${s.worst_ms} |`).join('\n');
const report=`# Living Sect — delivery review

The integrated playable version is in **proposal_demo_living_sect/**, with **[its own launcher](../Launch%20Living%20Sect.cmd)**. Sect Life supplies the complete gameplay; Creative supplies selected atmosphere, wind, lantern lighting, conversation framing and the listening bench. The three earlier versions remain available.

## Architectural decisions

- Kept the Gate and every building model and placement intact. Rebuilt **22 entrance wall sections and 15 supporting piers/abutments** on the original west/east footprints. The former low garden-wall appearance is replaced by roughly **5.5 m masonry bodies plus separately proportioned caps**, with **1.04 m plaster cores, 1.22 m plinths and 1.48–1.64 m piers**. These dimensions were authored separately; the existing modules were not uniformly stretched.
- Sampled ground across the wider footprints. Foundations extend at least 0.22 m beneath the lowest sampled terrain; plinths rise above the highest ground. Level caps step at supported joints. Gate-end piers overlap the original connectors, corner piers support the turns, and retained rock outcrops anchor the endpoints. The quieter garden/training boundary walls remain the existing lighter enclosure.
- Kept the central courtyard open for arrival, teaching and circulation. Activity pockets use flush paving, edged planting, a bamboo reading shade, benches, a tea table, practice equipment, laundry, tools and supplies. The new paving follows sampled ground. Shared architecture and terrain were not edited.
- Physical route testing led to a clear shared street: the lantern rack moved 1.7 m north, Mei moved 2.2 m south, and the tea pocket sits beside the dining approach. Lin's position, exercises, journal and optional progress remain intact. The principal elevations and building positions are unchanged.

## Population and character decisions

**18 new residents, 22 NPCs in total, plus the player.** The nearby court has apprentices practising forms, two readers, a seated resident and tea companion, a sweeper, gardener, courier and water carrier. Guards mark the entrance; teachers, trainees, a scholar, herbalist and attendant occupy the farther districts. Resident collision remains small, routes avoid the quest triangle, walkers yield near the player, and core quest/Lin/Mei interactions take priority over incidental conversations.

The two walkers use short authored routes with gravity, collision and destination pauses. This is a contained population suitable for this demonstration, not a general navigation or daily-schedule simulation. Restoring the basin changes Lian's route so she visits the public water; dialogue acknowledges that actual state. Reset restores all residents, visits and presentation state.

All characters use a new original articulated low-poly figure, including the player, Guide, Mentor, Lin and Mei. New proportions, tapered clothing, crossed lapels, split hems, sashes, role-specific apron/armour, facial features, ears, hair variants, hands/fingers and boots replace the old capsule-and-cone silhouette. The red apprentice, blue Lin, brown Mei, travelling Guide and long-robed Mentor retain their visual identities. Teachers have greying hair and longer hems; guards wear protective chest panels; workers have aprons and practical poses.

Idle, bowing, talking, turning, walking, reading, sweeping, tending, training, tea and seated poses use articulated pivots. Walking follows actual displacement, with a two-segment leg solve and ankle correction. A fresh physical walk sampled **144 planted-foot poses**: the measured stance drift was about **3.1 cm while the body advanced 2.52 m** (1.2%). Seated hems fold across the thighs instead of passing vertically through the bench. Static pieces are merged per joint using vertex colours, so facial/clothing details do not each require a separate draw call.

## Additions made through independent judgment

1. Added the open reading shade, tea setting, laundry movement and maintenance supplies to make everyday work legible without changing the buildings.
2. Adapted Creative's lighting to a brighter late-afternoon palette, kept wind in nearby foliage, softened terrain colour, and retained restrained local motes, lantern pools and the basin's jade-light/chime response.
3. Integrated the listening bench with contextual dry/flowing-water text and safe camera restoration; added incidental resident conversations and journal notes for people met and the bench discovery.
4. Corrected the shared-street obstructions found during testing and made residents yield to the player.
5. Added a slider-based comparison page and a captured walking-animation viewer for inspection, plus source preservation and recovery records.

## Fresh verification

**${summary.total_assertions} automated assertions passed; ${summary.failed_assertions} failed.** The total includes repeated checks at both resolutions. Heavy checks ran sequentially with one Godot game instance; the console executable is only its launcher wrapper. Final listed suites have no script/parse/resource-loading failures.

| Check | Result | Evidence |
| --- | --- | --- |
${table}

The rendered rehearsal physically walked from the forest through the Gate to the Mentor, sent typing events into the editor, tried mistakes and corrections, awakened Qi, channelled the basin, received recognition once, switched cameras and reset. It completed in **${rehearsal.spawn_to_completion_seconds} seconds**, or **${rehearsal.total_with_reset_seconds} seconds including reset**. See [rehearsal record](rehearsal/rehearsal-python.json) and [recognition capture](rehearsal/21-recognition.png).

The new-environment suite includes **1,188 wall collision rays**, sampled terrain support, all resident resets, actual walking arrivals, the basin-triggered water round, and **72 third-person camera-orbit samples** beside the new walls with no collision contacts. Wall-only ray tests exclude terrain that can occlude an uphill ray; separate foundation checks compare the wall base against terrain. The route suite physically traverses the central demonstration route and district links. These checks are bounded, not an exhaustive audit of every inherited roof, stair or corner.

The interpreter, lesson content and terminal-window implementation are byte-identical to Sect Life after normalising only the local resource path. The original three demos and shared files were checked against **${preservation.protected_files.toLocaleString()} task-start SHA-256 hashes**: **${preservation.changed.length} changed, ${preservation.missing.length} missing, ${preservation.added_outside_edition.length} added outside this edition**. See [preservation.json](preservation.json).

## Performance

Fresh local measurement: **${perf.cpu}**, **${perf.gpu}**, approximately **15.63 GiB usable RAM**, Godot **${perf.godot.string}**, Compatibility renderer, actual **1920 × 1080**, VSync disabled. All 23 characters are present. Each view settles for 30 frames and samples eight real-time seconds. The flowing-court conditions include water, Qi aura, animation and audio playback; these are short measurements on this machine, not a low-end or long-duration benchmark.

| View | Average FPS | Mean ms | P95 ms | Worst ms |
| --- | ---: | ---: | ---: | ---: |
${perfRows}

[Full performance data](Performance1080.json). Godot's reported static allocation was ${perf.godot_static_memory_mib} MiB; this is not total process/GPU memory. System power profile, clocks and unrelated background load were not controlled.

## Rendered evidence

- **[Before/after sliders and walking animation](COMPARE.html)** — 12 matched pairs at 1280 × 720, using identical positions, aim and field of view.
- [Gate after](views/after/01-gate-distance.png), [Gate join](views/after/03-wall-join.png), [courtyard](views/after/04-courtyard.png), [player](views/after/12-player.png).
- [Reading pose](living-captures/01-reading.png), [sweeping](living-captures/02-sweeping.png), [seated clothing](living-captures/03-seated-tea.png), [training](living-captures/04-training.png).
- [Native 1080p journal](screenshots-1920x1080/06-journal.png), [Mei after restoration](screenshots-1920x1080/07-court-keeper-after-quest.png), [1080p worked-solution layout](layout-captures/reference-solution-1920x1080.png).

## Limits and recovery

- **No human playtest or audible listening assessment.** Verification used automated input, real rendered gameplay, numerical checks and agent inspection of saved images. Desktop automation did not expose the Godot window in its window inventory; physical desktop focus/double-click behaviour is not certified.
- The figures are procedural articulated low-poly models, not imported skinned characters. No lip-sync, combat AI, full schedule simulation, dynamic pathfinding or persistent save system is claimed. Remaining style/animation acceptance belongs to visual review.
- Existing project geometry/camera limitations outside the tested routes remain. This is a local source build plus launcher, not an exported standalone executable or a cross-device performance certification.
- Godot logs this host's certificate-store and shader-cache write diagnostics, plus small renderer/ObjectDB cleanup diagnostics at exit. No system permissions or engine installation were changed. Earlier failed development checks are superseded by the final JSON results listed above.
- **Reset:** Esc → Reset Demo. **Return to a preserved edition:** close this game and use that edition's own launcher. **Recover this edition:** close Godot and extract [living-sect-source.zip](living-sect-source.zip) at the project root. It restores this edition only and still depends on the preserved shared project. No shared-file rollback is needed.

The included review scripts are for reproducible local checks. **final_checks.ps1** runs assertions sequentially; **final_visuals.ps1** captures comparisons, motion and performance. Do not run them beside another Godot game/editor.
`;
fs.writeFileSync(path.join(__dirname,'REVIEW.md'),report);
console.log('Delivery report generated from final JSON evidence.');
