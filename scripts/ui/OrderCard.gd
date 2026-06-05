extends PanelContainer


var current_customer_name: String = "Customer"
var current_required_ingredients: Array[String] = []
var current_preference_type: String = "tip_lover"

var content_margin: MarginContainer = null
var strip_hbox: HBoxContainer = null
var profile_panel: PanelContainer = null
var profile_label: Label = null
var ingredient_row: HBoxContainer = null
var money_panel: PanelContainer = null
var money_label: Label = null


func _ready() -> void:
	build_compact_layout()
	update_progress([])


func build_compact_layout() -> void:
	clear_existing_children()

	custom_minimum_size = Vector2(230, 64)
	size = Vector2(230, 64)

	add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.10, 0.08, 0.06, 0.86),
			Color(0.95, 0.70, 0.22, 0.75),
			2
		)
	)

	content_margin = MarginContainer.new()
	content_margin.name = "ContentMargin"
	content_margin.add_theme_constant_override("margin_left", 6)
	content_margin.add_theme_constant_override("margin_right", 6)
	content_margin.add_theme_constant_override("margin_top", 5)
	content_margin.add_theme_constant_override("margin_bottom", 5)
	add_child(content_margin)

	strip_hbox = HBoxContainer.new()
	strip_hbox.name = "StripHBox"
	strip_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip_hbox.add_theme_constant_override("separation", 5)
	content_margin.add_child(strip_hbox)

	profile_panel = PanelContainer.new()
	profile_panel.name = "ProfilePanel"
	profile_panel.custom_minimum_size = Vector2(54, 52)
	strip_hbox.add_child(profile_panel)

	profile_label = Label.new()
	profile_label.name = "ProfileLabel"
	profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_label.add_theme_font_size_override("font_size", 12)
	profile_label.add_theme_color_override("font_color", Color.WHITE)
	profile_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	profile_label.add_theme_constant_override("outline_size", 2)
	profile_panel.add_child(profile_label)

	ingredient_row = HBoxContainer.new()
	ingredient_row.name = "IngredientRow"
	ingredient_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ingredient_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ingredient_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ingredient_row.add_theme_constant_override("separation", 3)
	strip_hbox.add_child(ingredient_row)

	money_panel = PanelContainer.new()
	money_panel.name = "MoneyPanel"
	money_panel.custom_minimum_size = Vector2(52, 52)
	money_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.08, 0.18, 0.09, 0.96),
			Color(0.55, 1.0, 0.35, 0.95),
			2
		)
	)
	strip_hbox.add_child(money_panel)

	money_label = Label.new()
	money_label.name = "MoneyLabel"
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_label.add_theme_font_size_override("font_size", 15)
	money_label.add_theme_color_override("font_color", Color.WHITE)
	money_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	money_label.add_theme_constant_override("outline_size", 2)
	money_panel.add_child(money_label)


func clear_existing_children() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()


func create_panel_style(
	background_color: Color,
	border_color: Color,
	border_width: int
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()

	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)

	return style


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
	var is_ready: bool = is_order_complete(current_burger_ingredients)

	update_card_ready_state(is_ready)
	update_profile()
	update_ingredient_icons(current_burger_ingredients)
	update_money(payout_preview_text)


func update_card_ready_state(is_ready: bool) -> void:
	if is_ready:
		add_theme_stylebox_override(
			"panel",
			create_panel_style(
				Color(0.08, 0.12, 0.06, 0.90),
				Color(0.50, 1.0, 0.25, 1.0),
				3
			)
		)
	else:
		add_theme_stylebox_override(
			"panel",
			create_panel_style(
				Color(0.10, 0.08, 0.06, 0.86),
				Color(0.95, 0.70, 0.22, 0.75),
				2
			)
		)


func update_profile() -> void:
	if profile_label == null:
		return

	var customer_short_name: String = get_customer_short_name()
	var preference_text: String = get_preference_short_text()

	profile_label.text = customer_short_name + "\n" + preference_text

	if current_preference_type == "exact":
		profile_panel.add_theme_stylebox_override(
			"panel",
			create_panel_style(
				Color(0.12, 0.12, 0.22, 0.96),
				Color(0.65, 0.75, 1.0, 0.95),
				2
			)
		)
	else:
		profile_panel.add_theme_stylebox_override(
			"panel",
			create_panel_style(
				Color(0.22, 0.13, 0.05, 0.96),
				Color(1.0, 0.78, 0.25, 0.95),
				2
			)
		)


func update_ingredient_icons(current_burger_ingredients: Array[String]) -> void:
	if ingredient_row == null:
		return

	for child: Node in ingredient_row.get_children():
		ingredient_row.remove_child(child)
		child.queue_free()

	var remaining_burger_ingredients: Array[String] = current_burger_ingredients.duplicate()

	for required_ingredient: String in current_required_ingredients:
		var is_added: bool = false
		var index: int = remaining_burger_ingredients.find(required_ingredient)

		if index != -1:
			is_added = true
			remaining_burger_ingredients.remove_at(index)

		var icon_tile: PanelContainer = create_ingredient_icon_tile(required_ingredient, is_added)
		ingredient_row.add_child(icon_tile)


func create_ingredient_icon_tile(ingredient_name: String, is_added: bool) -> PanelContainer:
	var icon_tile: PanelContainer = PanelContainer.new()
	icon_tile.custom_minimum_size = Vector2(22, 34)

	var ingredient_color: Color = get_ingredient_color(ingredient_name)

	var background_color: Color = ingredient_color.darkened(0.62)
	var border_color: Color = ingredient_color.darkened(0.35)
	var text_color: Color = ingredient_color.lightened(0.20)
	var font_size: int = 14
	var border_width: int = 1

	background_color.a = 0.45
	border_color.a = 0.70
	text_color.a = 0.65

	if is_added:
		background_color = ingredient_color
		border_color = ingredient_color.lightened(0.35)
		text_color = get_text_color_for_ingredient(ingredient_name)
		font_size = 17
		border_width = 2

	icon_tile.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			background_color,
			border_color,
			border_width
		)
	)

	var icon_label: Label = Label.new()
	icon_label.text = get_ingredient_icon_text(ingredient_name)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", font_size)
	icon_label.add_theme_color_override("font_color", text_color)
	icon_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.90))
	icon_label.add_theme_constant_override("outline_size", 2)

	icon_tile.add_child(icon_label)

	return icon_tile


func update_money(payout_preview_text: String) -> void:
	if money_label == null:
		return

	var money_amount: int = extract_first_money_amount(payout_preview_text)

	money_label.text = "$" + str(money_amount)


func extract_first_money_amount(text: String) -> int:
	var dollar_index: int = text.find("$")

	if dollar_index == -1:
		return 0

	var index: int = dollar_index + 1
	var digits: String = ""

	while index < text.length():
		var character: String = text.substr(index, 1)

		if "0123456789".contains(character):
			digits += character
		else:
			break

		index += 1

	if digits == "":
		return 0

	return int(digits)


func is_order_complete(current_burger_ingredients: Array[String]) -> bool:
	var remaining_burger_ingredients: Array[String] = current_burger_ingredients.duplicate()

	for required_ingredient: String in current_required_ingredients:
		var index: int = remaining_burger_ingredients.find(required_ingredient)

		if index == -1:
			return false

		remaining_burger_ingredients.remove_at(index)

	return current_required_ingredients.size() > 0


func get_customer_short_name() -> String:
	if current_customer_name.ends_with("A"):
		return "A"

	if current_customer_name.ends_with("B"):
		return "B"

	if current_customer_name.length() > 0:
		return current_customer_name.substr(0, 1)

	return "?"


func get_preference_short_text() -> String:
	if current_preference_type == "exact":
		return "EXACT"

	if current_preference_type == "tip_lover":
		return "BIG TIP"

	return "FLEX"


func get_ingredient_icon_text(ingredient_name: String) -> String:
	if ingredient_name == "Patty":
		return "P"

	if ingredient_name == "Cheese":
		return "C"

	if ingredient_name == "Lettuce":
		return "L"

	if ingredient_name == "Tomato":
		return "T"

	if ingredient_name == "Onion":
		return "O"

	if ingredient_name == "Egg":
		return "E"

	if ingredient_name == "Top Bun":
		return "B"

	return "?"


func get_ingredient_color(ingredient_name: String) -> Color:
	if ingredient_name == "Patty":
		return Color(0.25, 0.10, 0.06, 1.0)

	if ingredient_name == "Cheese":
		return Color(1.0, 0.78, 0.12, 1.0)

	if ingredient_name == "Lettuce":
		return Color(0.16, 0.75, 0.20, 1.0)

	if ingredient_name == "Tomato":
		return Color(1.0, 0.12, 0.10, 1.0)

	if ingredient_name == "Onion":
		return Color(0.80, 0.72, 0.95, 1.0)

	if ingredient_name == "Egg":
		return Color(1.0, 0.95, 0.72, 1.0)

	return Color(0.90, 0.90, 0.90, 1.0)


func get_text_color_for_ingredient(ingredient_name: String) -> Color:
	if ingredient_name == "Cheese":
		return Color(0.20, 0.12, 0.00, 1.0)

	if ingredient_name == "Lettuce":
		return Color(0.02, 0.16, 0.02, 1.0)

	if ingredient_name == "Tomato":
		return Color.WHITE

	if ingredient_name == "Onion":
		return Color(0.10, 0.05, 0.18, 1.0)

	if ingredient_name == "Egg":
		return Color(0.22, 0.14, 0.00, 1.0)

	return Color.WHITE
