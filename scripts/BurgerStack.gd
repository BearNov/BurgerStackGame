class_name BurgerStack
extends Node

var stack_name: String = ""
var plate_x: float = 0.0

var bottom_bun_width: float = 0.78
var bottom_bun_height: float = 0.20
var bottom_bun_y: float = 0.36

var max_target_distance_from_plate: float = 1.15

var max_vertical_target_degrees: float = 78.0
var max_vertical_stuck_degrees: float = 75.0
var vertical_stuck_timer_start: float = 0.40

var detach_timer_start: float = 0.35
var fresh_layer_grace_start: float = 0.70

var min_support_overlap_ratio: float = 0.18
var max_support_vertical_gap: float = 0.24

var combo_count: int = 0

var layers: Array[Node3D] = []


func setup(
	new_stack_name: String,
	new_plate_x: float,
	bottom_layer: Node3D,
	new_bottom_bun_width: float,
	new_bottom_bun_height: float,
	new_bottom_bun_y: float
) -> void:
	stack_name = new_stack_name
	plate_x = new_plate_x
	bottom_bun_width = new_bottom_bun_width
	bottom_bun_height = new_bottom_bun_height
	bottom_bun_y = new_bottom_bun_y

	combo_count = 0
	layers.clear()

	if bottom_layer != null and is_instance_valid(bottom_layer):
		bottom_layer.set_meta("stack_width", bottom_bun_width)
		bottom_layer.set_meta("stack_height", bottom_bun_height)
		layers.append(bottom_layer)

func get_stack_name() -> String:
	return stack_name

func add_layer(body: Node3D) -> void:
	if body == null:
		return

	if not is_instance_valid(body):
		return

	if not layers.has(body):
		body.set_meta("detach_timer", detach_timer_start)
		body.set_meta("fresh_layer_grace", fresh_layer_grace_start)
		body.set_meta("vertical_stuck_timer", vertical_stuck_timer_start)
		layers.append(body)

func increase_combo() -> void:
	combo_count += 1

func reset_combo() -> void:
	combo_count = 0

func get_combo_count() -> int:
	return combo_count

func get_ingredient_layer_count() -> int:
	var count: int = 0
	var index: int = 1

	while index < layers.size():
		var layer: Node3D = layers[index]

		if layer != null and is_instance_valid(layer):
			count += 1

		index += 1

	return count

func clear_ingredient_layers() -> void:
	var index: int = layers.size() - 1

	while index >= 1:
		var layer: Node3D = layers[index]

		layers.remove_at(index)

		if layer != null and is_instance_valid(layer):
			layer.queue_free()

		index -= 1

	combo_count = 0

func get_support_ratio(x: float, body_width: float) -> float:
	if body_width <= 0.0:
		return 0.0

	var overlap: float = get_overlap(
		x,
		body_width,
		get_top_x(),
		get_top_width()
	)

	return overlap / body_width

# Kept as a function, but intentionally does nothing now.
# Manual upward correction caused the "lands again" twitch.
func correct_small_underlap(_body: RigidBody3D) -> void:
	return

func collect_detached_layers(
	delta: float,
	fall_y_limit: float,
	max_distance_from_plate: float,
	max_detach_tilt_degrees: float,
	low_detach_y_limit: float
) -> Array[Node3D]:
	var detached_layers: Array[Node3D] = []

	var index: int = layers.size() - 1

	while index >= 1:
		var layer: Node3D = layers[index]

		if layer == null or not is_instance_valid(layer):
			layers.remove_at(index)
			index -= 1
			continue

		if layer.position.y < fall_y_limit:
			layers.remove_at(index)
			detached_layers.append(layer)
			index -= 1
			continue

		var fresh_layer_grace: float = 0.0

		if layer.has_meta("fresh_layer_grace"):
			fresh_layer_grace = float(layer.get_meta("fresh_layer_grace"))

		if fresh_layer_grace > 0.0:
			fresh_layer_grace -= delta
			layer.set_meta("fresh_layer_grace", fresh_layer_grace)
			index -= 1
			continue

		if is_near_vertical(layer):
			var vertical_stuck_timer: float = vertical_stuck_timer_start

			if layer.has_meta("vertical_stuck_timer"):
				vertical_stuck_timer = float(layer.get_meta("vertical_stuck_timer"))

			vertical_stuck_timer -= delta
			layer.set_meta("vertical_stuck_timer", vertical_stuck_timer)

			if vertical_stuck_timer <= 0.0:
				layers.remove_at(index)
				detached_layers.append(layer)
				index -= 1
				continue
		else:
			layer.set_meta("vertical_stuck_timer", vertical_stuck_timer_start)

		var badly_supported: bool = is_layer_badly_supported(
			layer,
			max_distance_from_plate,
			max_detach_tilt_degrees,
			low_detach_y_limit
		)

		if badly_supported:
			var detach_timer: float = detach_timer_start

			if layer.has_meta("detach_timer"):
				detach_timer = float(layer.get_meta("detach_timer"))

			detach_timer -= delta
			layer.set_meta("detach_timer", detach_timer)

			if detach_timer <= 0.0:
				layers.remove_at(index)
				detached_layers.append(layer)

		else:
			layer.set_meta("detach_timer", detach_timer_start)

		index -= 1

	return detached_layers

func is_near_vertical(layer: Node3D) -> bool:
	var flatness_angle: float = get_layer_flatness_angle_z_degrees(layer)
	return flatness_angle >= max_vertical_stuck_degrees

func is_layer_badly_supported(
	layer: Node3D,
	max_distance_from_plate: float,
	max_detach_tilt_degrees: float,
	low_detach_y_limit: float
) -> bool:
	if layer.position.y >= low_detach_y_limit:
		return false

	if abs(layer.position.x - plate_x) > max_distance_from_plate:
		return true

	var flatness_angle: float = get_layer_flatness_angle_z_degrees(layer)

	if flatness_angle > max_detach_tilt_degrees and not has_sufficient_support_below(layer):
		return true

	if not has_sufficient_support_below(layer):
		return true

	return false

func has_sufficient_support_below(layer: Node3D) -> bool:
	if layer == null:
		return false

	if not is_instance_valid(layer):
		return false

	var layer_width: float = get_body_projected_width(layer)
	var layer_height: float = get_body_projected_height(layer)
	var layer_bottom_y: float = layer.position.y - layer_height / 2.0

	for candidate: Node3D in layers:
		if candidate == null:
			continue

		if not is_instance_valid(candidate):
			continue

		if candidate == layer:
			continue

		if candidate.position.y >= layer.position.y:
			continue

		var candidate_width: float = get_body_projected_width(candidate)
		var candidate_height: float = get_body_projected_height(candidate)
		var candidate_top_y: float = candidate.position.y + candidate_height / 2.0

		var vertical_gap: float = abs(layer_bottom_y - candidate_top_y)

		if vertical_gap > max_support_vertical_gap:
			continue

		var overlap: float = get_overlap(
			layer.position.x,
			layer_width,
			candidate.position.x,
			candidate_width
		)

		var overlap_ratio: float = overlap / layer_width

		if overlap_ratio >= min_support_overlap_ratio:
			return true

	return false

func get_top_node() -> Node3D:
	var top_node: Node3D = null
	var top_surface_y: float = -9999.0

	for layer: Node3D in layers:
		if layer == null:
			continue

		if not is_instance_valid(layer):
			continue

		if not is_valid_target_layer(layer):
			continue

		var layer_height: float = get_body_projected_height(layer)
		var surface_y: float = layer.position.y + layer_height / 2.0

		if surface_y > top_surface_y:
			top_surface_y = surface_y
			top_node = layer

	return top_node

func is_valid_target_layer(layer: Node3D) -> bool:
	if layer == null:
		return false

	if not is_instance_valid(layer):
		return false

	if layers.size() > 0 and layer == layers[0]:
		return true

	if abs(layer.position.x - plate_x) > max_target_distance_from_plate:
		return false

	if layer.position.y < bottom_bun_y - 0.10:
		return false

	var flatness_angle: float = get_layer_flatness_angle_z_degrees(layer)

	if flatness_angle >= max_vertical_target_degrees:
		return false

	return true

func get_layer_flatness_angle_z_degrees(layer: Node3D) -> float:
	var raw_angle: float = abs(rad_to_deg(wrapf(layer.rotation.z, -PI, PI)))

	if raw_angle > 90.0:
		return 180.0 - raw_angle

	return raw_angle

func get_top_x() -> float:
	var top_node: Node3D = get_top_node()

	if top_node == null:
		return plate_x

	return top_node.position.x

func get_top_width() -> float:
	var top_node: Node3D = get_top_node()

	if top_node == null:
		return bottom_bun_width

	return get_body_projected_width(top_node)

func get_surface_y() -> float:
	var top_node: Node3D = get_top_node()

	if top_node == null:
		return bottom_bun_y + bottom_bun_height / 2.0

	var layer_height: float = get_body_projected_height(top_node)
	return top_node.position.y + layer_height / 2.0

func get_body_projected_width(body: Node3D) -> float:
	var width: float = get_body_stack_width(body)
	var height: float = get_body_stack_height(body)
	var angle: float = wrapf(body.rotation.z, -PI, PI)

	var projected_width: float = abs(cos(angle)) * width + abs(sin(angle)) * height

	if projected_width < 0.05:
		return 0.05

	return projected_width

func get_body_projected_height(body: Node3D) -> float:
	var width: float = get_body_stack_width(body)
	var height: float = get_body_stack_height(body)
	var angle: float = wrapf(body.rotation.z, -PI, PI)

	var projected_height: float = abs(sin(angle)) * width + abs(cos(angle)) * height

	if projected_height < 0.05:
		return 0.05

	return projected_height

func get_body_stack_width(body: Node3D) -> float:
	if body != null and body.has_meta("stack_width"):
		return float(body.get_meta("stack_width"))

	return bottom_bun_width

func get_body_stack_height(body: Node3D) -> float:
	if body != null and body.has_meta("stack_height"):
		return float(body.get_meta("stack_height"))

	return bottom_bun_height

func get_overlap(center_a: float, width_a: float, center_b: float, width_b: float) -> float:
	var left_a: float = center_a - width_a / 2.0
	var right_a: float = center_a + width_a / 2.0

	var left_b: float = center_b - width_b / 2.0
	var right_b: float = center_b + width_b / 2.0

	var overlap: float = min(right_a, right_b) - max(left_a, left_b)

	if overlap < 0.0:
		return 0.0

	return overlap
