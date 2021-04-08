extends Node

var debug_material: SpatialMaterial = null
var layers: Dictionary = {}

var cached_spheres: Dictionary = {}

static func get_sphere_lines(p_position: Vector3, p_lats: int, p_lons: int, p_radius: float) -> PoolVector3Array:
	if (p_lats < 2):
		p_lats = 2
	if (p_lats < 4):
		p_lats = 4

	var verts = Array()
	verts.resize(p_lats * p_lons * 6)
	
	var total: int = 0
	for i in range(1, p_lats+1):
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

	
func get_cached_sphere_lines(p_lats: int, p_lons: int) -> PoolVector3Array:
	if !cached_spheres.has([p_lats, p_lons]):
		cached_spheres[[p_lats, p_lons]] = get_sphere_lines(Vector3(), p_lats, p_lons, 1.0)
		
	return cached_spheres[[p_lats, p_lons]]
	
func clear(p_debug_object: ImmediateGeometry) -> void:
	p_debug_object.clear()
	
func draw_line(p_debug_object: ImmediateGeometry, p_start: Vector3, p_end: Vector3, p_color: Color, p_clear: bool) -> void:
	if p_debug_object.is_visible_in_tree():
		if p_clear:
			clear(p_debug_object)
		p_debug_object.begin(Mesh.PRIMITIVE_LINES)
		p_debug_object.set_color(p_color)
		p_debug_object.add_vertex(p_start)
		p_debug_object.add_vertex(p_end)
		p_debug_object.end()
		
func draw_lines(p_debug_object: ImmediateGeometry, p_transform: Transform, p_lines: PoolVector3Array, p_color: Color, p_clear: bool) -> void:
	if p_debug_object.is_visible_in_tree():
		if p_clear:
			clear(p_debug_object)
		
		p_debug_object.begin(Mesh.PRIMITIVE_LINES)
		p_debug_object.set_color(p_color)
		for i in range(0, p_lines.size()):
			p_debug_object.add_vertex(p_transform * p_lines[i])
		p_debug_object.end()
		
func draw_line_strip(p_debug_object: ImmediateGeometry, p_transform: Transform, p_lines: PoolVector3Array, p_color: Color, p_clear: bool) -> void:
	if p_debug_object.is_visible_in_tree():
		if p_clear:
			clear(p_debug_object)
		
		p_debug_object.begin(Mesh.PRIMITIVE_LINE_STRIP)
		p_debug_object.set_color(p_color)
		for i in range(0, p_lines.size()):
			p_debug_object.add_vertex(p_transform * p_lines[i])
		p_debug_object.end()
	
func draw_sphere(p_debug_object: ImmediateGeometry, p_position: Vector3, p_lats: int, p_lons: int, p_radius: float, p_color: Color, p_clear: bool) -> void:
	if p_debug_object.is_visible_in_tree():
		var lines: PoolVector3Array = get_cached_sphere_lines(p_lats, p_lons)
		draw_lines(
			p_debug_object,
			Transform(Basis().scaled(Vector3(p_radius, p_radius, p_radius)), p_position),
			lines,
			p_color,
			p_clear)
		
"""
func draw_aabb(p_debug_object: ImmediateGeometry, p_aabb: AABB, p_color: Color, p_clear: bool) -> void:
	if p_debug_object.is_visible_in_tree():
		var lines: PoolVector3Array = get_aabb_lines(p_aabb)
		draw_lines(p_debug_object, Transform(), lines, p_color, p_clear)
"""
	
###
###
	
func create_debug_object_for_layer(p_layer_name: String) -> ImmediateGeometry:
	if !layers.has(p_layer_name):
		printerr("Could not create debug object for non-existant layer %s" % p_layer_name)
		return null
	
	var immediate_geometry: ImmediateGeometry = ImmediateGeometry.new()
	immediate_geometry.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	immediate_geometry.material_override = debug_material
	layers[p_layer_name].add_child(immediate_geometry)
	
	return immediate_geometry
	
func destroy_debug_object(p_debug_object: ImmediateGeometry) -> void:
	if !p_debug_object:
		printerr("Could not destroy non-existent debug object!")
		return
	
	p_debug_object.queue_free()
	p_debug_object.get_parent().remove_child(p_debug_object)
	
func create_new_debug_layer(p_layer_name: String) -> void:
	if layers.has(p_layer_name):
		printerr("Already has layer %s" % p_layer_name)
		return
		
	var debug_layer: Spatial = Spatial.new()
	debug_layer.set_name(p_layer_name)
	
	layers[p_layer_name] = debug_layer
	
	add_child(debug_layer)

func _ready() -> void:
	debug_material = SpatialMaterial.new()
	debug_material.flags_unshaded = true
	debug_material.flags_no_depth_test = true
	debug_material.vertex_color_use_as_albedo = true
	
	create_new_debug_layer("GenericDebug")
