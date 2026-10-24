"""Regression checks for collapsed ridge corners and invalid-data handling."""
from pathlib import Path
import unittest,json,math
from roof_collision_geometry import collision_polygon_triangles

class RoofCollisionTests(unittest.TestCase):
    def test_ordinary_quad_keeps_fan_and_winding(self):
        p=[[0,0,0],[1,0,0],[1,0,1],[0,0,1]]
        self.assertEqual(collision_polygon_triangles(p),[[p[0],p[1],p[2]],[p[0],p[2],p[3]]])
    def test_collapsed_ridge_both_windings(self):
        p=[[0,0,0],[1,0,0],[.5,1,0],[.5,1,0]]
        self.assertEqual(collision_polygon_triangles(p),[[p[0],p[1],p[2]]])
        self.assertEqual(collision_polygon_triangles(list(reversed(p))),[[p[2],p[1],p[0]]])
    def test_explicit_closing_corner(self):
        p=[[0,0,0],[1,0,0],[0,0,1],[0,0,0]]
        self.assertEqual(collision_polygon_triangles(p),[p[:3]])
    def test_nearby_corners_are_not_merged(self):
        p=[[0,0,0],[1e-10,0,0],[1e-10,0,1],[0,0,1]]
        self.assertEqual(len(collision_polygon_triangles(p)),2)
    def test_unexpected_collinear_input_rejected(self):
        with self.assertRaises(ValueError):collision_polygon_triangles([[0,0,0],[1,0,0],[2,0,0]])
    def test_nonfinite_input_rejected(self):
        with self.assertRaises(ValueError):collision_polygon_triangles([[0,0,0],[1,0,0],[0,math.nan,1]])
    def test_fully_collapsed_input_rejected(self):
        with self.assertRaises(ValueError):collision_polygon_triangles([[0,0,0]]*4)

if __name__=='__main__':
    suite=unittest.defaultTestLoader.loadTestsFromTestCase(RoofCollisionTests)
    result=unittest.TextTestRunner(verbosity=2).run(suite)
    out=Path(__file__).resolve().parents[1]/'reports/roof-collision-fix-2026-10-22/helper-tests.json'
    out.write_text(json.dumps({'run':result.testsRun,'failures':len(result.failures),'errors':len(result.errors),'successful':result.wasSuccessful()},indent=2))
    raise SystemExit(0 if result.wasSuccessful() else 1)
