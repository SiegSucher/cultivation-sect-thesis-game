"""Triangulate the authored convex roof strips, including collapsed hip tips."""
import math

def collision_polygon_triangles(points):
    """Return a fan after removing only exactly coincident adjacent corners.

    At a closed hip ridge a four-corner strip has just three distinct corners.
    Treat that strip as its actual triangle. Exact comparison is deliberate:
    no distance tolerance may shrink a thin but valid architectural feature.
    Unexpected collinearity/non-finite input raises instead of silently erasing
    a collider surface. Coordinates and winding of valid triangles are retained.
    """
    corners=[]
    for point in points:
        p=tuple(float(v) for v in point)
        if len(p)!=3 or not all(math.isfinite(v) for v in p):
            raise ValueError('Roof collision requires finite 3D corners')
        if not corners or p!=corners[-1]:corners.append(p)
    if len(corners)>1 and corners[0]==corners[-1]:corners.pop()
    if len(corners)<3:
        raise ValueError('Roof polygon has fewer than three distinct corners')
    triangles=[]
    for i in range(1,len(corners)-1):
        a,b,c=corners[0],corners[i],corners[i+1]
        u=[b[j]-a[j] for j in range(3)]
        v=[c[j]-a[j] for j in range(3)]
        cross=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
        if not all(math.isfinite(q) for q in cross) or not any(q!=0 for q in cross):
            raise ValueError('Unexpected degenerate roof polygon; inspect its source')
        triangles.append([list(a),list(b),list(c)])
    return triangles
