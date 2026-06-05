class_name IngredientFactory
extends Node

var normal_ingredients_since_top_bun: int = 0

var top_bun_min_normal_gap: int = 4
var top_bun_force_normal_gap: int = 8
var top_bun_chance_after_gap: float = 0.25

var normal_ingredient_names: Array[String] = [
	"Cheese",
	"Patty",
	"Lettuce",
	"Tomato",
	"Onion",
	"Egg"
]

func choose_random_ingredient() -> Dictionary:
	var should_spawn_top_bun: bool = false

	if normal_ingredients_since_top_bun >= top_bun_force_normal_gap:
		should_spawn_top_bun = true
	elif normal_ingredients_since_top_bun >= top_bun_min_normal_gap:
		should_spawn_top_bun = randf() < top_bun_chance_after_gap

	if should_spawn_top_bun:
		normal_ingredients_since_top_bun = 0
		return get_ingredient_data("Top Bun")

	var random_index: int = randi_range(0, normal_ingredient_names.size() - 1)
	var ingredient_name: String = normal_ingredient_names[random_index]

	normal_ingredients_since_top_bun += 1

	return get_ingredient_data(ingredient_name)

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
	else:
		add_default_ingredient_visual(body, size, color)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	parent.add_child(body)

	return body
