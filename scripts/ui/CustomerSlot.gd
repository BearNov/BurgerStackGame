extends Control


@onready var serve_prompt_label: Label = $ServePromptLabel
@onready var order_card = $OrderCard

var ready_prompt_visible: bool = false
var ready_prompt_pulse_time: float = 0.0

var current_stack_name: String = ""

func _ready() -> void:
	serve_prompt_label.text = "TOP BUN TO SERVE"
	serve_prompt_label.visible = false
	serve_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	serve_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	serve_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25))
	serve_prompt_label.add_theme_color_override("font_outline_color", Color(0.35, 0.20, 0.0))
	serve_prompt_label.add_theme_constant_override("outline_size", 5)
	serve_prompt_label.scale = Vector2.ONE
	serve_prompt_label.modulate = Color(1, 1, 1, 1)

func setup_slot(stack_name: String) -> void:
	current_stack_name = stack_name
	set_ready_to_serve(false)


func setup_order(
	customer_name: String,
	required_ingredients: Array[String],
	preference_type: String = "tip_lover"
) -> void:
	if order_card != null and order_card.has_method("setup_order"):
		order_card.setup_order(customer_name, required_ingredients, preference_type)

	set_ready_to_serve(false)


func update_progress(
	current_burger_ingredients: Array[String],
	payout_preview_text: String = ""
) -> void:
	if order_card != null and order_card.has_method("update_progress"):
		order_card.update_progress(current_burger_ingredients, payout_preview_text)

func set_ready_to_serve(should_show: bool) -> void:
	ready_prompt_visible = should_show
	serve_prompt_label.visible = should_show

	if should_show:
		ready_prompt_pulse_time = 0.0
		serve_prompt_label.text = "TOP BUN TO SERVE"
		serve_prompt_label.scale = Vector2.ONE
		serve_prompt_label.modulate = Color(1, 1, 1, 1)
	else:
		serve_prompt_label.scale = Vector2.ONE
		serve_prompt_label.modulate = Color(1, 1, 1, 1)

func reset_slot() -> void:
	set_ready_to_serve(false)

	if order_card != null and order_card.has_method("update_progress"):
		order_card.update_progress([])

func _process(delta: float) -> void:
	if not ready_prompt_visible:
		return

	ready_prompt_pulse_time += delta * 4.0

	var pulse: float = (sin(ready_prompt_pulse_time) + 1.0) * 0.5
	var alpha_value: float = lerp(0.72, 1.0, pulse)
	var scale_value: float = lerp(1.0, 1.08, pulse)

	serve_prompt_label.modulate = Color(1, 1, 1, alpha_value)
	serve_prompt_label.scale = Vector2(scale_value, scale_value)
