extends Node

var debug_material: StandardMaterial3D = null
var layers: Dictionary = {}

var cached_spheres: Dictionary = {}

const debug_manager_const = preload("res://addons/sar1_debug_manager/debug_manager.gd")


# Remove when Godot 4.x implements support for ImmediateGometry3D
class StubImmediateGeometry3D:
	extends MeshInstance3D

	var verts_array: PackedVector3Array = PackedVector3Array()
	var color_array: PackedColorArray = PackedColorArray()

	func clear():
		if not verts_array.is_empty():
			is_dirty = true
		verts_array = PackedVector3Array()
		color_array = PackedColorArray()

	var line_strip: int = 0
	var cur_color: Color = Color.WHITE
	var last_vert: Vector3 = Vector3.ZERO
	var is_dirty: bool = false

	func begin(mode):
		if mode == Mesh.PRIMITIVE_LINE_STRIP:
			line_strip = 1

	func end():
		is_dirty = true
		line_strip = 0

	func set_color(color: Color):
		cur_color = color

	func add_vertex(v: Vector3):
		if line_strip > 2:
			color_array.append(cur_color)
			verts_array.append(last_vert)
		color_array.append(cur_color)
		verts_array.append(v)
		last_vert = v
		if line_strip > 0:
			line_strip += 1

	func _commit_arraymesh():
		if is_dirty:
			if mesh == null:
				mesh = ArrayMesh.new()
			mesh.clear_surfaces()
			var arrays = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_COLOR] = color_array
			arrays[Mesh.ARRAY_VERTEX] = verts_array
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays, [], {})
			is_dirty = false


static func get_sphere_lines(p_position: Vector3, p_lats: int, p_lons: int, p_radius: float) -> PackedVector3Array:
	if p_lats < 2:
		p_lats = 2
	if p_lats < 4:
		p_lats = 4

	var verts = PackedVector3Array()
	verts.resize(p_lats * p_lons * 6)

	var total: int = 0
	for i in range(1, p_lats + 1):
		var lat0: float = PI * (-0.5 + float(i - 1) / p_lats)
		var z0: float = sin(lat0)
		var zr0: float = cos(lat0)

		var lat1: float = PI * (-0.5 + float(i) / p_lats)
		var z1: float = sin(lat1)
		var zr1: float = cos(lat1)

		for j in range(p_lons, 0, -1):
			var lng0: float = 2 * PI * (j - 1) / p_lons
			var x0: float = cos(lng0)
			var y0: float = sin(lng0)

			var lng1: float = 2 * PI * j / p_lons
			var x1: float = cos(lng1)
			var y1: float = sin(lng1)

			var v: Array = [
				Vector3(x1 * zr0, z0, y1 * zr0) * p_radius + p_position,
				Vector3(x1 * zr1, z1, y1 * zr1) * p_radius + p_position,
				Vector3(x0 * zr1, z1, y0 * zr1) * p_radius + p_position,
				Vector3(x0 * zr0, z0, y0 * zr0) * p_radius + p_position
			]

			verts[total] = v[0]
			total += 1
			verts[total] = v[1]
			total += 1
			verts[total] = v[2]
			total += 1

			verts[total] = v[2]
			total += 1
			verts[total] = v[3]
			total += 1
			verts[total] = v[0]
			total += 1

	return verts


func get_cached_sphere_lines(p_lats: int, p_lons: int) -> PackedVector3Array:
	if !cached_spheres.has([p_lats, p_lons]):
		cached_spheres[[p_lats, p_lons]] = debug_manager_const.get_sphere_lines(Vector3(), p_lats, p_lons, 1.0)

	return cached_spheres[[p_lats, p_lons]]


func clear(p_debug_object: StubImmediateGeometry3D) -> void:
	p_debug_object.clear()


func draw_line(p_debug_object: StubImmediateGeometry3D, p_start: Vector3, p_end: Vector3, p_color: Color, p_clear: bool) -> void:
	if p_debug_object.is_visible_in_tree():
		if p_clear:
			clear(p_debug_object)
		p_debug_object.begin(Mesh.PRIMITIVE_LINES)
		p_debug_object.set_color(p_color)
		p_debug_object.add_vertex(p_start)
		p_debug_object.add_vertex(p_end)
		p_debug_object.end()
		p_debug_object._commit_arraymesh()


func draw_lines(p_debug_object: StubImmediateGeometry3D, p_transform: Transform3D, p_lines: PackedVector3Array, p_color: Color, p_clear: bool) -> void:
	if p_debug_object.is_visible_in_tree():
		if p_clear:
			clear(p_debug_object)

		p_debug_object.begin(Mesh.PRIMITIVE_LINES)
		p_debug_object.set_color(p_color)
		for i in range(0, p_lines.size()):
			p_debug_object.add_vertex(p_transform * p_lines[i])
		p_debug_object.end()
		p_debug_object._commit_arraymesh()


func draw_line_strip(p_debug_object: StubImmediateGeometry3D, p_transform: Transform3D, p_lines: PackedVector3Array, p_color: Color, p_clear: bool) -> void:
	if p_debug_object.is_visible_in_tree():
		if p_clear:
			clear(p_debug_object)

		p_debug_object.begin(Mesh.PRIMITIVE_LINE_STRIP)
		p_debug_object.set_color(p_color)
		for i in range(0, p_lines.size()):
			p_debug_object.add_vertex(p_transform * p_lines[i])
		p_debug_object.end()
		p_debug_object._commit_arraymesh()


func draw_sphere(p_debug_object: StubImmediateGeometry3D, p_position: Vector3, p_lats: int, p_lons: int, p_radius: float, p_color: Color, p_clear: bool) -> void:
	if p_debug_object.is_visible_in_tree():
		var lines: PackedVector3Array = get_cached_sphere_lines(p_lats, p_lons)
		draw_lines(p_debug_object, Transform3D(Basis().scaled(Vector3(p_radius, p_radius, p_radius)), p_position), lines, p_color, p_clear)


##
## func draw_aabb(p_debug_object: ImmediateGeometry3D, p_aabb: AABB, p_color: Color, p_clear: bool) -> void:
## 	if p_debug_object.is_visible_in_tree():
## 		var lines: PackedVector3Array = get_aabb_lines(p_aabb)
## 		draw_lines(p_debug_object, Transform3D(), lines, p_color, p_clear)
##

###
###


func create_debug_object_for_layer(p_layer_name: String) -> StubImmediateGeometry3D:
	if !layers.has(p_layer_name):
		printerr("Could not create debug object for non-existant layer %s" % p_layer_name)
		return null

	var immediate_geometry = StubImmediateGeometry3D.new()
	immediate_geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tmp: Variant = debug_material
	immediate_geometry.material_override = tmp
	layers[p_layer_name].add_child(immediate_geometry, true)

	return immediate_geometry


func destroy_debug_object(p_debug_object: StubImmediateGeometry3D) -> void:
	if !p_debug_object:
		printerr("Could not destroy non-existent debug object!")
		return

	p_debug_object.queue_free()
	p_debug_object.get_parent().remove_child(p_debug_object)


func create_new_debug_layer(p_layer_name: String) -> void:
	if layers.has(p_layer_name):
		printerr("Already has layer %s" % p_layer_name)
		return

	var debug_layer: Node3D = Node3D.new()
	debug_layer.set_name(p_layer_name)

	layers[p_layer_name] = debug_layer

	add_child(debug_layer, true)


func _ready() -> void:
	debug_material = StandardMaterial3D.new()
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.no_depth_test = true
	debug_material.vertex_color_use_as_albedo = true

	create_new_debug_layer("GenericDebug")
