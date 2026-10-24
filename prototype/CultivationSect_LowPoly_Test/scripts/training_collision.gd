extends RefCounted
## Shared simple solids for the facility and its reusable equipment scenes.

static func vector(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])

static func add_shapes(parent: Node3D, records: Array, local := Transform3D.IDENTITY) -> void:
	for record: Dictionary in records:
		var shape := CollisionShape3D.new()
		shape.name = String(record.name).validate_node_name()
		var pose := Transform3D.IDENTITY
		match String(record.type):
			"box":
				var box := BoxShape3D.new()
				box.size = vector(record.size)
				shape.shape = box
				pose.origin = vector(record.position)
			"cylinder":
				var cylinder := CylinderShape3D.new()
				cylinder.radius = record.radius
				cylinder.height = record.height
				shape.shape = cylinder
				pose.origin = vector(record.position)
			"convex":
				var convex := ConvexPolygonShape3D.new()
				var points := PackedVector3Array()
				for point: Array in record.points: points.append(vector(point))
				convex.points = points
				shape.shape = convex
		shape.transform = local * pose
		parent.add_child(shape)
