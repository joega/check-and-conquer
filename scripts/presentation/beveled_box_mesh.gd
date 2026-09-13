class_name BeveledBoxMesh
extends RefCounted

## Small flat-shaded chamfers for presentation geometry. Dimensions remain the
## requested outer bounds, so board mapping and authored placement stay exact.

static func create(size: Vector3, bevel: float) -> ArrayMesh:
	var half := size * 0.5
	var edge := minf(bevel, minf(half.x, minf(half.y, half.z)) * 0.49)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Six inset faces.
	for axis in 3:
		for sign_value in [-1.0, 1.0]:
			var normal := Vector3.ZERO
			normal[axis] = sign_value
			var other: Array[int] = []
			for candidate in 3:
				if candidate != axis:
					other.append(candidate)
			var points: Array[Vector3] = []
			for uv in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var point := Vector3.ZERO
				point[axis] = sign_value * half[axis]
				point[other[0]] = uv.x * (half[other[0]] - edge)
				point[other[1]] = uv.y * (half[other[1]] - edge)
				points.append(point)
			_add_polygon(surface, points, normal)
	# Twelve edge strips.
	for fixed_a in 3:
		for fixed_b in range(fixed_a + 1, 3):
			var free_axis := 3 - fixed_a - fixed_b
			for sign_a in [-1.0, 1.0]:
				for sign_b in [-1.0, 1.0]:
					var points: Array[Vector3] = []
					for free_sign in [-1.0, 1.0]:
						var p1 := Vector3.ZERO
						p1[fixed_a] = sign_a * half[fixed_a]
						p1[fixed_b] = sign_b * (half[fixed_b] - edge)
						p1[free_axis] = free_sign * (half[free_axis] - edge)
						var p2 := p1
						p2[fixed_a] = sign_a * (half[fixed_a] - edge)
						p2[fixed_b] = sign_b * half[fixed_b]
						points.append(p1)
						points.append(p2)
					_add_polygon(surface, points, _axis_normal(fixed_a, sign_a) + _axis_normal(fixed_b, sign_b))
	# Eight triangular corner facets.
	for sign_x in [-1.0, 1.0]:
		for sign_y in [-1.0, 1.0]:
			for sign_z in [-1.0, 1.0]:
				var points: Array[Vector3] = [
					Vector3(sign_x * half.x, sign_y * (half.y - edge), sign_z * (half.z - edge)),
					Vector3(sign_x * (half.x - edge), sign_y * half.y, sign_z * (half.z - edge)),
					Vector3(sign_x * (half.x - edge), sign_y * (half.y - edge), sign_z * half.z),
				]
				_add_polygon(surface, points, Vector3(sign_x, sign_y, sign_z))
	surface.generate_normals()
	return surface.commit()


static func _axis_normal(axis: int, sign_value: float) -> Vector3:
	var normal := Vector3.ZERO
	normal[axis] = sign_value
	return normal


static func _add_polygon(surface: SurfaceTool, source: Array[Vector3], desired_normal: Vector3) -> void:
	var points := source.duplicate()
	if points.size() >= 3 and (points[1] - points[0]).cross(points[2] - points[0]).dot(desired_normal) < 0.0:
		points.reverse()
	for index in range(1, points.size() - 1):
		surface.set_smooth_group(-1)
		surface.add_vertex(points[0])
		surface.add_vertex(points[index])
		surface.add_vertex(points[index + 1])
