# Stage 2 verified milestone


Training Ground architecture, court materials and seven equipment types converted. Approved Hall and Gate protected.

Static near: 94,776 -> 88,020 triangles; static LOD: 13,998 -> 12,913. Equipment retains original triangle counts.

86 rendered functional checks and 13 imported bounds/name-contract checks passed. Geometry/flat-normal audit passed. Both camera modes and actual capsule movement exercised.

Training roof collider retains 84 inherited zero-area triangles; JSON byte-identical. No collider repair claimed.


| View | Before ms | After ms | Before draws | After draws |
| --- | ---: | ---: | ---: | ---: |
| overview | 9.59 | 5.52 | 120.0 | 108.0 |
| court | 7.31 | 9.66 | 164.0 | 146.0 |
| shelter | 6.63 | 12.93 | 88.0 | 77.0 |
| 360 sweep | 5.64 | 8.33 | 117.6 | 105.9 |
| first-person | 4.77 | 9.04 | 115.0 | 103.0 |
| third-person | 5.91 | 10.42 | 121.0 | 107.0 |


Short RTX 3050 Laptop observations, not representative low-end or sustained tests. Final report will include repeat measurements.


Exact next action: record Pavilion baseline using unchanged Scripture fixture; convert furniture/leaves first, then structure, and run the three-storey/archive regression before expansion.
