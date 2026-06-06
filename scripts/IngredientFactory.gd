class_name IngredientFactory
extends Node

var normal_ingredients_since_top_bun: int = 0
var normal_spawns_while_order_ready: int = 0

var top_bun_min_normal_gap: int = 5
var top_bun_chance_when_no_order_ready: float = 0.05

var top_bun_chance_when_order_ready: float = 0.55
var top_bun_force_after_ready_spawns: int = 2

var missing_ingredient_bias_chance: float = 0.60

var normal_ingredient_names: Array[String] = [
	"Cheese",
	"Patty",
	"Lettuce",
	"Tomato",
	"Onion",
	"Egg"
]

var normal_ingredient_bag: Array[String] = []

func choose_random_ingredient() -> Dictionary:
	return choose_smart_ingredient([], false)

func choose_smart_ingredient(
	missing_ingredient_names: Array[String],
	has_ready_order: bool
) -> Dictionary:
	if should_spawn_top_bun(has_ready_order):
		normal_ingredients_since_top_bun = 0
		normal_spawns_while_order_ready = 0
		return get_ingredient_data("Top Bun")

	var ingredient_name: String = choose_normal_ingredient(missing_ingredient_names)

	normal_ingredients_since_top_bun += 1

	if has_ready_order:
		normal_spawns_while_order_ready += 1
	else:
		normal_spawns_while_order_ready = 0

	return get_ingredient_data(ingredient_name)

func should_spawn_top_bun(has_ready_order: bool) -> bool:
	if has_ready_order:
		if normal_spawns_while_order_ready >= top_bun_force_after_ready_spawns:
			return true

		return randf() < top_bun_chance_when_order_ready

	if normal_ingredients_since_top_bun < top_bun_min_normal_gap:
		return false

	return randf() < top_bun_chance_when_no_order_ready

func choose_normal_ingredient(missing_ingredient_names: Array[String]) -> String:
	var valid_missing_ingredients: Array[String] = get_valid_missing_ingredients(missing_ingredient_names)

	if valid_missing_ingredients.size() > 0:
		if randf() < missing_ingredient_bias_chance:
			var missing_index: int = randi_range(0, valid_missing_ingredients.size() - 1)
			return valid_missing_ingredients[missing_index]

	return take_ingredient_from_bag()

func get_valid_missing_ingredients(missing_ingredient_names: Array[String]) -> Array[String]:
	var valid_missing_ingredients: Array[String] = []

	for ingredient_name: String in missing_ingredient_names:
		if not normal_ingredient_names.has(ingredient_name):
			continue

		if valid_missing_ingredients.has(ingredient_name):
			continue

		valid_missing_ingredients.append(ingredient_name)

	return valid_missing_ingredients

func take_ingredient_from_bag() -> String:
	if normal_ingredient_bag.is_empty():
		refill_normal_ingredient_bag()

	var ingredient_name: String = normal_ingredient_bag.pop_back()

	if ingredient_name == "":
		return "Cheese"

	return ingredient_name

func refill_normal_ingredient_bag() -> void:
	normal_ingredient_bag = normal_ingredient_names.duplicate()
	normal_ingredient_bag.shuffle()

func reset_spawn_state() -> void:
	normal_ingredients_since_top_bun = 0
	normal_spawns_while_order_ready = 0
	normal_ingredient_bag.clear()
	refill_normal_ingredient_bag()

func get_ingredient_data(ingredient_name: String) -> Dictionary:
	var data: Dictionary = {}

	if ingredient_name == "Cheese":
		data["name"] = "Cheese"
		data["width"] = 0.85
		data["height"] = 0.12
		data["depth"] = 0.85
		data["mass"] = 0.25
		data["color"] = Color(1.0, 0.80, 0.10)

	elif ingredient_name == "Patty":
		data["name"] = "Patty"
		data["width"] = 0.78
		data["height"] = 0.20
		data["depth"] = 0.78
		data["mass"] = 0.65
		data["color"] = Color(0.22, 0.10, 0.04)

	elif ingredient_name == "Lettuce":
		data["name"] = "Lettuce"
		data["width"] = 0.95
		data["height"] = 0.09
		data["depth"] = 0.72
		data["mass"] = 0.18
		data["color"] = Color(0.25, 0.80, 0.25)

	elif ingredient_name == "Tomato":
		data["name"] = "Tomato"
		data["width"] = 0.70
		data["height"] = 0.12
		data["depth"] = 0.70
		data["mass"] = 0.35
		data["color"] = Color(0.90, 0.10, 0.08)

	elif ingredient_name == "Onion":
		data["name"] = "Onion"
		data["width"] = 0.78
		data["height"] = 0.10
		data["depth"] = 0.78
		data["mass"] = 0.22
		data["color"] = Color(0.92, 0.88, 1.0)

	elif ingredient_name == "Egg":
		data["name"] = "Egg"
		data["width"] = 0.80
		data["height"] = 0.11
		data["depth"] = 0.72
		data["mass"] = 0.30
		data["color"] = Color(1.0, 0.96, 0.82)

	else:
		data["name"] = "Top Bun"
		data["width"] = 0.82
		data["height"] = 0.18
		data["depth"] = 0.82
		data["mass"] = 0.40
		data["color"] = Color(0.98, 0.63, 0.25)

	return data

func create_physics_material() -> PhysicsMaterial:
	var physics_material: PhysicsMaterial = PhysicsMaterial.new()

	# High friction was causing sticky collision fighting.
	# This is still grippy, but less twitchy.
	physics_material.friction = 0.95
	physics_material.bounce = 0.0

	return physics_material

func create_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	return material

func create_patty_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()

	var albedo_texture: Texture2D = load("res://assets/materials/patty/patty_albedo.png")
	var normal_texture: Texture2D = load("res://assets/materials/patty/patty_normal.png")
	var roughness_texture: Texture2D = load("res://assets/materials/patty/patty_roughness.png")

	material.albedo_texture = albedo_texture
	material.albedo_color = Color.WHITE

	material.normal_enabled = true
	material.normal_texture = normal_texture
	material.normal_scale = 0.35

	material.roughness = 0.65
	material.roughness_texture = roughness_texture

	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX

	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	return material

func create_patty_side_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()

	var side_albedo_texture: Texture2D = load("res://assets/materials/patty/patty_side_strip_albedo.png")

	material.albedo_texture = side_albedo_texture
	material.albedo_color = Color(0.82, 0.72, 0.66, 1.0)

	material.roughness = 0.82
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	

	# No UV zoom for the side strip. The image already has the correct wide shape.
	material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	material.uv1_offset = Vector3(0.0, 0.0, 0.0)

	return material

func add_box_visual(
	parent: Node3D,
	visual_name: String,
	local_position: Vector3,
	size: Vector3,
	color: Color
) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = visual_name
	mesh_instance.position = local_position

	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = create_material(color)

	parent.add_child(mesh_instance)

	return mesh_instance

func add_default_ingredient_visual(parent: Node3D, size: Vector3, color: Color) -> void:
	add_box_visual(
		parent,
		"Visual",
		Vector3.ZERO,
		size,
		color
	)

func add_textured_patty_visual(parent: Node3D, size: Vector3) -> void:
	var patty_body_color: Color = Color(0.23, 0.085, 0.035)

	# Base body gives volume and keeps the patty readable.
	add_box_visual(
		parent,
		"PattyBody",
		Vector3(0.0, -size.y * 0.08, 0.0),
		Vector3(size.x, size.y * 0.78, size.z),
		patty_body_color
	)

	var body_center_y: float = -size.y * 0.08
	var body_height: float = size.y * 0.78
	var top_y: float = body_center_y + (body_height / 2.0) + 0.012
	var bottom_y: float = body_center_y - (body_height / 2.0) - 0.012
	var decal_offset: float = 0.008

	# Top grilled texture.
	var top_decal: MeshInstance3D = MeshInstance3D.new()
	top_decal.name = "PattyTopGrillTexture"

	var top_mesh: QuadMesh = QuadMesh.new()
	top_mesh.size = Vector2(size.x, size.z)
	top_decal.mesh = top_mesh

	top_decal.position = Vector3(0.0, top_y, 0.0)
	top_decal.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	top_decal.material_override = create_patty_material()
	parent.add_child(top_decal)

	# Bottom grilled texture, needed because ingredients can flip.
	var bottom_decal: MeshInstance3D = MeshInstance3D.new()
	bottom_decal.name = "PattyBottomGrillTexture"

	var bottom_mesh: QuadMesh = QuadMesh.new()
	bottom_mesh.size = Vector2(size.x, size.z)
	bottom_decal.mesh = bottom_mesh

	bottom_decal.position = Vector3(0.0, bottom_y, 0.0)
	bottom_decal.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	bottom_decal.material_override = create_patty_material()
	parent.add_child(bottom_decal)

	# Front meat texture.
	var front_decal: MeshInstance3D = MeshInstance3D.new()
	front_decal.name = "PattyFrontMeatTexture"

	var front_mesh: QuadMesh = QuadMesh.new()
	front_mesh.size = Vector2(size.x, body_height)
	front_decal.mesh = front_mesh

	front_decal.position = Vector3(0.0, body_center_y, -(size.z / 2.0) - decal_offset)
	front_decal.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	front_decal.material_override = create_patty_side_material()
	parent.add_child(front_decal)

	# Back meat texture.
	var back_decal: MeshInstance3D = MeshInstance3D.new()
	back_decal.name = "PattyBackMeatTexture"

	var back_mesh: QuadMesh = QuadMesh.new()
	back_mesh.size = Vector2(size.x, body_height)
	back_decal.mesh = back_mesh

	back_decal.position = Vector3(0.0, body_center_y, (size.z / 2.0) + decal_offset)
	back_decal.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	back_decal.material_override = create_patty_side_material()
	parent.add_child(back_decal)

	# Left meat texture.
	var left_decal: MeshInstance3D = MeshInstance3D.new()
	left_decal.name = "PattyLeftMeatTexture"

	var left_mesh: QuadMesh = QuadMesh.new()
	left_mesh.size = Vector2(size.z, body_height)
	left_decal.mesh = left_mesh

	left_decal.position = Vector3(-(size.x / 2.0) - decal_offset, body_center_y, 0.0)
	left_decal.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	left_decal.material_override = create_patty_side_material()
	parent.add_child(left_decal)

	# Right meat texture.
	var right_decal: MeshInstance3D = MeshInstance3D.new()
	right_decal.name = "PattyRightMeatTexture"

	var right_mesh: QuadMesh = QuadMesh.new()
	right_mesh.size = Vector2(size.z, body_height)
	right_decal.mesh = right_mesh

	right_decal.position = Vector3((size.x / 2.0) + decal_offset, body_center_y, 0.0)
	right_decal.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	right_decal.material_override = create_patty_side_material()
	parent.add_child(right_decal)

func add_egg_visual(parent: Node3D, size: Vector3) -> void:
	var egg_white_color: Color = Color(1.0, 0.96, 0.86)
	var yolk_color: Color = Color(1.0, 0.78, 0.08)

	# Main egg white.
	add_box_visual(
		parent,
		"EggWhite",
		Vector3.ZERO,
		size,
		egg_white_color
	)

	# Small yolk block on top, centered.
	var yolk_size: Vector3 = Vector3(size.x * 0.34, 0.035, size.z * 0.34)
	var yolk_y: float = (size.y / 2.0) + (yolk_size.y / 2.0) + 0.004

	add_box_visual(
		parent,
		"EggYolk",
		Vector3(0.0, yolk_y, 0.0),
		yolk_size,
		yolk_color
	)

func add_onion_visual(parent: Node3D, size: Vector3) -> void:
	var onion_color: Color = Color(0.94, 0.90, 1.0)
	var border_thickness: float = 0.13

	var horizontal_bar_size: Vector3 = Vector3(
		size.x,
		size.y,
		border_thickness
	)

	var vertical_bar_size: Vector3 = Vector3(
		border_thickness,
		size.y,
		size.z
	)

	var front_z: float = (size.z / 2.0) - (border_thickness / 2.0)
	var back_z: float = -(size.z / 2.0) + (border_thickness / 2.0)
	var right_x: float = (size.x / 2.0) - (border_thickness / 2.0)
	var left_x: float = -(size.x / 2.0) + (border_thickness / 2.0)

	# Four bars make a visible onion ring/border.
	# The collision is still one simple rectangle for stable stacking.
	add_box_visual(
		parent,
		"OnionFrontBorder",
		Vector3(0.0, 0.0, front_z),
		horizontal_bar_size,
		onion_color
	)

	add_box_visual(
		parent,
		"OnionBackBorder",
		Vector3(0.0, 0.0, back_z),
		horizontal_bar_size,
		onion_color
	)

	add_box_visual(
		parent,
		"OnionLeftBorder",
		Vector3(left_x, 0.0, 0.0),
		vertical_bar_size,
		onion_color
	)

	add_box_visual(
		parent,
		"OnionRightBorder",
		Vector3(right_x, 0.0, 0.0),
		vertical_bar_size,
		onion_color
	)

func create_static_box(parent: Node3D, object_name: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = object_name
	body.position = pos
	body.physics_material_override = create_physics_material()

	body.set_meta("stack_width", size.x)
	body.set_meta("stack_height", size.y)

	add_default_ingredient_visual(body, size, color)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	parent.add_child(body)

	return body

func create_rigid_box(parent: Node3D, object_name: String, pos: Vector3, size: Vector3, color: Color, mass: float) -> RigidBody3D:
	var body: RigidBody3D = RigidBody3D.new()
	body.name = object_name
	body.position = pos
	body.mass = mass
	body.physics_material_override = create_physics_material()

	body.set_meta("stack_width", size.x)
	body.set_meta("stack_height", size.y)
	body.set_meta("ingredient_name", object_name)

	body.continuous_cd = true
	body.can_sleep = true

	# Higher damping reduces tiny solver jitter, but still allows wobble/collapse.
	body.linear_damp = 0.65
	body.angular_damp = 0.90

	# 2.5D physics:
	# X = left/right, Y = up/down, Z = depth.
	body.axis_lock_linear_z = true
	body.axis_lock_angular_x = true
	body.axis_lock_angular_y = true

	if object_name == "Egg":
		add_egg_visual(body, size)
	elif object_name == "Onion":
		add_onion_visual(body, size)
	elif object_name == "Patty":
		add_textured_patty_visual(body, size)
	else:
		add_default_ingredient_visual(body, size, color)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	parent.add_child(body)

	return body
