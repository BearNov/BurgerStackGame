extends PanelContainer


@onready var customer_name_label: Label = $ContentMargin/ContentVBox/CustomerNameLabel
@onready var order_ingredients_label: Label = $ContentMargin/ContentVBox/OrderIngredientsLabel
@onready var tip_label: Label = $ContentMargin/ContentVBox/TipLabel


var current_customer_name: String = "Customer"
var current_required_ingredients: Array[String] = []
var current_preference_type: String = "tip_lover"


func _ready() -> void:
	order_ingredients_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	order_ingredients_label.custom_minimum_size = Vector2(0, 48)
	tip_label.custom_minimum_size = Vector2(0, 46)


func setup_order(
	customer_name: String,
	required_ingredients: Array[String],
	preference_type: String = "tip_lover"
) -> void:
	current_customer_name = customer_name
	current_required_ingredients = required_ingredients.duplicate()
	current_preference_type = preference_type

	update_progress([])


func update_progress(
	current_burger_ingredients: Array[String],
	payout_preview_text: String = ""
) -> void:
	customer_name_label.text = current_customer_name
	order_ingredients_label.text = build_progress_text(current_burger_ingredients)
	tip_label.text = build_footer_text(current_burger_ingredients, payout_preview_text)


func build_progress_text(current_burger_ingredients: Array[String]) -> String:
	var progress_parts: Array[String] = []

	for required_ingredient: String in current_required_ingredients:
		if current_burger_ingredients.has(required_ingredient):
			progress_parts.append("✓ " + required_ingredient)
		else:
			progress_parts.append("□ " + required_ingredient)

	return split_text_parts_into_two_lines(progress_parts, 3)


func split_text_parts_into_two_lines(parts: Array[String], first_line_count: int) -> String:
	var first_line_parts: Array[String] = []
	var second_line_parts: Array[String] = []

	for index in range(parts.size()):
		if index < first_line_count:
			first_line_parts.append(parts[index])
		else:
			second_line_parts.append(parts[index])

	var result: String = ", ".join(first_line_parts)

	if second_line_parts.size() > 0:
		result += "\n" + ", ".join(second_line_parts)

	return result


func build_footer_text(
	current_burger_ingredients: Array[String],
	payout_preview_text: String
) -> String:
	var preference_text: String = get_preference_display_text()

	if payout_preview_text != "":
		return preference_text + "\n" + payout_preview_text

	var matched_required_count: int = get_matched_required_count(current_burger_ingredients)
	var extra_layer_count: int = current_burger_ingredients.size() - matched_required_count

	if extra_layer_count < 0:
		extra_layer_count = 0

	return preference_text + "\nExtra: " + str(extra_layer_count)


func get_matched_required_count(current_burger_ingredients: Array[String]) -> int:
	var matched_count: int = 0
	var remaining_burger_ingredients: Array[String] = current_burger_ingredients.duplicate()

	for required_ingredient: String in current_required_ingredients:
		var index: int = remaining_burger_ingredients.find(required_ingredient)

		if index != -1:
			matched_count += 1
			remaining_burger_ingredients.remove_at(index)

	return matched_count


func get_preference_display_text() -> String:
	if current_preference_type == "exact":
		return "Exact order only"

	if current_preference_type == "tip_lover":
		return "Bigger = better tip"

	return "Flexible"
