# Split-Cloud architectural style guide

The user approved this hall as the visual direction on 22 October 2026. Preserve its successful design. The later environment-continuation request now authorizes controlled conversion stages in the isolated test project. Stages 1–3 (Sect Gate, Training Ground, Scripture Pavilion) are complete and reported separately. The latest user instruction authorized the latter two; review their current results before any new group. No original-project edit, world-layout invention or whole-town conversion is authorized by this style guide.

| Role | sRGB hex | Treatment |
| --- | --- | --- |
| Jade roof | #22594f | Six faceted slope strips; broad swept roof forms |
| Tile seams | #46796b | Raised sparse 0.8 m rhythm, no individual barrel tiles |
| Main timber | #432d2d | Eight-sided columns, deep girders and soffits |
| Cedar brackets | #896048 | Three interlocking bearing courses and diagonal braces |
| Stone | #667e88 | Broad opaque podium and stair masses |
| Coping | #bcc6bd | Pale nosings, pedestals and rail caps |
| Plaster | #e6d9b8 | Warm wall fields framed by real timber |
| Window recess | #284c53 | Opaque shaded backing; geometric screens |
| Bronze | #cda668 | Original mountain/diamond motif; restrained emphasis |
| Interior floor | #85624d | Sparse narrow board joints; blue-grey ceremonial aisle |
| Fabric | #456e73 | Room inserts, cushions and ceremonial screen |
| Lantern | #ffda91 | Mild material emission, existing shadowless light fixtures |

Do not adopt towers, exact silhouettes, crests, layouts or landscape from the reference pictures. Repeat original Split-Cloud mountain strokes in roof crown, entrance tympanum and audience screen. Keep walkable bays clear and structural posts supported by visible shoes. Prioritize eave, doorway and column silhouettes over filigree. No arbitrary whole-building scaling. Current footprint, floor levels, door dimensions and collision define the gameplay contract.

Batch by shared material (12 hall meshes); author logical door sources separately. All meshes are flat shaded, all palette materials opaque, roughness .82 (bronze .56). No external textures, custom shaders, transparency, real-time reflections, added lights, glow or particles. Preserve the current Compatibility renderer. Directional shadow distance is 100 m in the matched test room; both variants use it. Other rendering settings and existing hall lanterns are identical. Baked lighting and occlusion changes were not introduced because this experiment does not establish that they are needed. The distant range uses the same inexpensive mesh, avoiding a visible detail jump; it does not reduce triangles further.

Buildings retain their own proportions and silhouettes; reuse the palette and surface logic rather than duplicating the Hall architecture. Stage-1 Gate mapping and actual geometry/material counts are documented in `LOW_POLY_STAGE_1_REPORT.md` and its metrics sidecar. Test first/third person, inspect real images and use matched conditions. Further work follows the staged scope and review boundary in `HANDOFF.md` and `LOW_POLY_CONVERSION_INVENTORY.md`.

Stages 2–3 retain each existing facility silhouette and use palette extensions Earth #806b50 and CourtStone #81938d for broad Training ground fields. Clear imported custom corner normals before glTF export; polygon flat flags alone may retain the previous smooth normals. Verify exported normal vectors, not just Blender flags. Protected paving node names and archive behavior must remain. Current evidence: `LOW_POLY_STAGES_2_3_REPORT.md`.
