class_name GameUI
extends CanvasLayer

const TRASH_ICON: Texture2D = preload("res://assets/ui/icons/trash_icon.png")

signal trash_pressed
signal play_pressed
signal restart_pressed
signal main_menu_pressed
signal upgrade_pressed
signal stage_selected(stage_number: int)

@onready var splash_screen: Control = $SplashScreen
@onready var main_menu: Control = $MainMenu
@onready var gameplay_hud: Control = $GameplayHUD
@onready var game_over_screen: Control = $GameOverScreen

@onready var stage_menu: Control = $StageMenu
@onready var stage_1_button: Button = $StageMenu/Stage1Button
@onready var stage_2_button: Button = $StageMenu/Stage2Button
@onready var stage_3_button: Button = $StageMenu/Stage3Button
@onready var stage_back_button: Button = $StageMenu/StageBackButton
@onready var main_upgrade_button: Button = get_node_or_null("MainMenu/MainUpgradeButton") as Button
@onready var endless_mode_button: Button = get_node_or_null("MainMenu/EndlessModeButton") as Button

@onready var score_label: Label = $GameplayHUD/ScoreLabel
@onready var ingredient_label: Label = $GameplayHUD/IngredientLabel
@onready var stacks_label: Label = $GameplayHUD/StacksLabel
@onready var info_label: Label = $GameplayHUD/InfoLabel
@onready var result_label: Label = $GameplayHUD/ResultLabel
@onready var combo_popup_label: Label = $GameplayHUD/ComboPopupLabel
@onready var trash_button: Button = $GameplayHUD/TrashButton
@onready var shift_label: Label = $GameplayHUD/ShiftLabel
@onready var stage_goal_label: Label = $GameplayHUD/StageGoalLabel

@onready var play_button: Button = $MainMenu/PlayButton
@onready var wallet_label: Label = $MainMenu/WalletLabel

@onready var game_over_label: Label = $GameOverScreen/GameOverLabel
@onready var final_score_label: Label = $GameOverScreen/FinalScoreLabel
@onready var restart_button: Button = $GameOverScreen/RestartButton
@onready var upgrade_button: Button = $GameOverScreen/UpgradeButton
@onready var main_menu_button: Button = $GameOverScreen/MainMenuButton

@onready var customer_slot_a = $GameplayHUD/CustomerSlotA
@onready var customer_slot_b = $GameplayHUD/CustomerSlotB

var customer_slots: Dictionary = {}

var combo_popup_timer: float = 0.0
var combo_popup_duration: float = 2.05
var combo_popup_first_milestone: int = 10
var combo_popup_step: int = 10
var combo_popup_float_distance: float = 18.0

var combo_popup_base_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = 10
	
	score_label.position = Vector2(24, 28)
	score_label.size = Vector2(390, 66)
	score_label.custom_minimum_size = Vector2(390, 66)
	score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	ingredient_label.position = Vector2(24, 108)
	stacks_label.position = Vector2(24, 138)

	info_label.visible = false

	result_label.position = Vector2(24, 168)
	result_label.size = Vector2(300, 48)
	result_label.custom_minimum_size = Vector2(300, 48)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	trash_button.text = ""
	trash_button.icon = TRASH_ICON
	trash_button.expand_icon = true

	trash_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	trash_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

	trash_button.position = Vector2(10, 900)
	trash_button.size = Vector2(80, 52)
	trash_button.custom_minimum_size = Vector2(80, 52)
	trash_button.z_index = 20

	stage_goal_label.position = Vector2(300, 106)
	stage_goal_label.size = Vector2(216, 28)
	stage_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage_goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_goal_label.text = "Stage 1 | Customers 0/5"
	
	final_score_label.size = Vector2(420, 150)
	final_score_label.custom_minimum_size = Vector2(420, 150)
	final_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	combo_popup_base_position = combo_popup_label.position
	combo_popup_label.visible = false
	combo_popup_label.pivot_offset = combo_popup_label.size / 2.0

	combo_popup_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35, 1.0))
	combo_popup_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	combo_popup_label.add_theme_constant_override("outline_size", 5)

	trash_button.pressed.connect(_on_trash_pressed)
	play_button.pressed.connect(_on_play_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	stage_1_button.pressed.connect(_on_stage_1_pressed)
	stage_2_button.pressed.connect(_on_stage_2_pressed)
	stage_3_button.pressed.connect(_on_stage_3_pressed)
	stage_back_button.pressed.connect(_on_stage_back_pressed)

	if main_upgrade_button != null:
		main_upgrade_button.pressed.connect(_on_upgrade_pressed)

	if endless_mode_button != null:
		endless_mode_button.pressed.connect(_on_endless_mode_pressed)

	setup_customer_slot_dictionary()
	
	setup()

func setup_customer_orders(
	order_a: Array[String],
	order_b: Array[String],
	preference_a: String = "tip_lover",
	preference_b: String = "tip_lover"
) -> void:
	setup_customer_order_for_stack("A", "Customer A", order_a, preference_a)
	setup_customer_order_for_stack("B", "Customer B", order_b, preference_b)

func setup_customer_order_for_stack(
	stack_name: String,
	customer_name: String,
	required_order: Array[String],
	preference_type: String = "tip_lover"
) -> void:
	var slot = get_customer_slot(stack_name)

	if slot != null and slot.has_method("setup_order"):
		slot.setup_order(customer_name, required_order, preference_type)

func update_customer_progress(
	stack_name: String,
	burger_ingredients: Array[String],
	payout_preview_text: String = ""
) -> void:
	var slot = get_customer_slot(stack_name)

	if slot != null and slot.has_method("update_progress"):
		slot.update_progress(burger_ingredients, payout_preview_text)

func update_serve_prompt(stack_name: String, should_show: bool) -> void:
	var slot = get_customer_slot(stack_name)

	if slot != null and slot.has_method("set_ready_to_serve"):
		slot.set_ready_to_serve(should_show)

func setup_customer_slot_dictionary() -> void:
	customer_slots.clear()

	customer_slots["A"] = customer_slot_a
	customer_slots["B"] = customer_slot_b

	for stack_name in customer_slots.keys():
		var slot = customer_slots[stack_name]

		if slot != null and slot.has_method("setup_slot"):
			slot.setup_slot(str(stack_name))

func get_customer_slot(stack_name: String):
	if customer_slots.has(stack_name):
		return customer_slots[stack_name]

	return null

func setup() -> void:
	show_splash_screen()

func _process(delta: float) -> void:
	update_combo_popup(delta)

func _on_trash_pressed() -> void:
	trash_pressed.emit()

func _on_play_pressed() -> void:
	show_stage_menu()

func _on_restart_pressed() -> void:
	restart_pressed.emit()

func _on_upgrade_pressed() -> void:
	upgrade_pressed.emit()

func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()

func _on_stage_1_pressed() -> void:
	stage_selected.emit(1)

func _on_stage_2_pressed() -> void:
	stage_selected.emit(2)


func _on_stage_3_pressed() -> void:
	stage_selected.emit(3)

func _on_stage_back_pressed() -> void:
	show_main_menu()


func _on_endless_mode_pressed() -> void:
	show_endless_placeholder()

func show_splash_screen() -> void:
	splash_screen.visible = true
	main_menu.visible = false
	gameplay_hud.visible = false
	game_over_screen.visible = false
	stage_menu.visible = false

func show_main_menu() -> void:
	splash_screen.visible = false
	main_menu.visible = true
	gameplay_hud.visible = false
	game_over_screen.visible = false
	stage_menu.visible = false

func update_stage_buttons(
	unlocked_stage: int,
	stage_1_required: int,
	stage_2_required: int,
	stage_3_required: int
) -> void:
	stage_1_button.text = "Stage 1 - Serve " + str(stage_1_required)
	stage_1_button.disabled = unlocked_stage < 1

	if unlocked_stage >= 2:
		stage_2_button.text = "Stage 2 - Serve " + str(stage_2_required)
		stage_2_button.disabled = false
	else:
		stage_2_button.text = "Stage 2 - Locked"
		stage_2_button.disabled = true

	if unlocked_stage >= 3:
		stage_3_button.text = "Stage 3 - Serve " + str(stage_3_required)
		stage_3_button.disabled = false
	else:
		stage_3_button.text = "Stage 3 - Locked"
		stage_3_button.disabled = true

func show_stage_menu() -> void:
	splash_screen.visible = false
	main_menu.visible = false
	gameplay_hud.visible = false
	game_over_screen.visible = false
	stage_menu.visible = true

func update_wallet_money(wallet_money: int) -> void:
	if wallet_label != null:
		wallet_label.text = "Wallet: $" + str(wallet_money)

func update_shift_time(time_remaining: float) -> void:
	if shift_label == null:
		return

	var total_seconds: int = int(ceil(time_remaining))

	if total_seconds < 0:
		total_seconds = 0

	var minutes: int = int(total_seconds / 60)
	var seconds: int = total_seconds % 60

	var seconds_text: String = str(seconds)

	if seconds < 10:
		seconds_text = "0" + seconds_text

	shift_label.text = "Shift: " + str(minutes) + ":" + seconds_text

func update_stage_goal(
	stage_number: int,
	customers_served: int,
	customers_required: int
) -> void:
	if stage_goal_label == null:
		return

	stage_goal_label.text = "Stage " + str(stage_number)
	stage_goal_label.text += " | Customers "
	stage_goal_label.text += str(customers_served) + "/" + str(customers_required)

func show_gameplay_hud() -> void:
	splash_screen.visible = false
	main_menu.visible = false
	gameplay_hud.visible = true
	game_over_screen.visible = false
	stage_menu.visible = false

func show_game_over(final_score: int) -> void:
	splash_screen.visible = false
	main_menu.visible = false
	gameplay_hud.visible = false
	game_over_screen.visible = true

	final_score_label.text = "Final Score: " + str(final_score)

func show_shift_summary(
	run_money: int,
	wallet_money: int,
	added_money: int,
	stage_number: int = 1,
	customers_served: int = 0,
	customers_required: int = 0,
	stage_cleared: bool = false
) -> void:
	splash_screen.visible = false
	main_menu.visible = false
	gameplay_hud.visible = false
	game_over_screen.visible = true
	stage_menu.visible = false

	game_over_label.position = Vector2(0, 250)
	game_over_label.size = Vector2(540, 70)

	final_score_label.position = Vector2(60, 340)
	final_score_label.size = Vector2(420, 190)
	final_score_label.custom_minimum_size = Vector2(420, 190)
	final_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	restart_button.position = Vector2(150, 570)
	upgrade_button.position = Vector2(150, 635)
	main_menu_button.position = Vector2(150, 700)

	if stage_cleared:
		game_over_label.text = "Stage Clear!"
		restart_button.text = "Next Stage"
	else:
		game_over_label.text = "Shift Over"
		restart_button.text = "Retry Stage"

	final_score_label.text = "Stage " + str(stage_number)
	final_score_label.text += "\nCustomers: " + str(customers_served) + "/" + str(customers_required)
	final_score_label.text += "\nRun Money: $" + str(run_money)
	final_score_label.text += "\nAdded to Wallet: $" + str(added_money)
	final_score_label.text += "\nWallet Total: $" + str(wallet_money)

	upgrade_button.text = "Upgrade Restaurant"
	main_menu_button.text = "Main Menu"

	upgrade_button.disabled = false
	main_menu_button.disabled = false
	restart_button.disabled = false

func show_upgrade_placeholder(wallet_money: int) -> void:
	splash_screen.visible = false
	main_menu.visible = false
	gameplay_hud.visible = false
	game_over_screen.visible = true
	stage_menu.visible = false

	game_over_label.text = "Upgrades"

	final_score_label.text = "Wallet: $" + str(wallet_money)
	final_score_label.text += "\nUpgrade screen coming soon."

	restart_button.text = "Next Stage"
	upgrade_button.text = "Upgrade Restaurant"
	main_menu_button.text = "Main Menu"

	upgrade_button.disabled = true
	main_menu_button.disabled = false
	restart_button.disabled = false

func show_endless_placeholder() -> void:
	splash_screen.visible = false
	main_menu.visible = false
	gameplay_hud.visible = false
	game_over_screen.visible = true
	stage_menu.visible = false

	game_over_label.text = "Endless Mode"
	final_score_label.text = "Endless stacking mode coming soon."

	restart_button.text = "Next Stage"
	upgrade_button.text = "Upgrade Restaurant"
	main_menu_button.text = "Main Menu"

	upgrade_button.disabled = false
	main_menu_button.disabled = false
	restart_button.disabled = false

func update_info(
	run_money: int,
	wallet_money: int,
	ingredient_name: String,
	stack_summary: String,
	result_text: String,
	trash_enabled: bool
) -> void:
	var after_shift_money: int = wallet_money + run_money

	score_label.text = "Run: $" + str(run_money) + " | Wallet: $" + str(wallet_money)
	score_label.text += "\nAfter shift: $" + str(after_shift_money)
	
	ingredient_label.text = "Ingredient: " + ingredient_name
	stacks_label.text = stack_summary
	result_label.text = result_text
	trash_button.disabled = not trash_enabled

func show_combo_popup(stack_name: String, combo_count: int) -> void:
	if combo_count < combo_popup_first_milestone:
		return

	if combo_count % combo_popup_step != 0:
		return

	combo_popup_label.text = get_combo_milestone_message(stack_name, combo_count)
	combo_popup_label.visible = true
	combo_popup_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	combo_popup_label.scale = Vector2(0.90, 0.90)
	combo_popup_label.position = combo_popup_base_position
	combo_popup_label.pivot_offset = combo_popup_label.size / 2.0

	combo_popup_timer = combo_popup_duration


func update_combo_popup(delta: float) -> void:
	if not combo_popup_label.visible:
		return

	combo_popup_timer -= delta

	if combo_popup_timer <= 0.0:
		combo_popup_label.visible = false
		combo_popup_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		combo_popup_label.scale = Vector2.ONE
		combo_popup_label.position = combo_popup_base_position
		return

	var elapsed: float = combo_popup_duration - combo_popup_timer

	var alpha: float = 1.0
	var fade_in_time: float = 0.10
	var fade_out_time: float = 0.50

	if elapsed < fade_in_time:
		alpha = elapsed / fade_in_time
	elif combo_popup_timer < fade_out_time:
		alpha = combo_popup_timer / fade_out_time
	else:
		alpha = 1.0

	alpha = clamp(alpha, 0.0, 1.0)

	var popup_color: Color = combo_popup_label.modulate
	popup_color.a = alpha
	combo_popup_label.modulate = popup_color

	var scale_value: float = 1.0

	if elapsed < 0.14:
		scale_value = lerpf(0.90, 1.04, elapsed / 0.14)
	elif elapsed < 0.28:
		scale_value = lerpf(1.04, 1.0, (elapsed - 0.14) / 0.14)
	else:
		scale_value = 1.0

	combo_popup_label.scale = Vector2(scale_value, scale_value)

	var float_progress: float = clamp(elapsed / combo_popup_duration, 0.0, 1.0)
	var float_offset: float = lerpf(0.0, -combo_popup_float_distance, float_progress)

	combo_popup_label.position = combo_popup_base_position + Vector2(0.0, float_offset)


func get_combo_milestone_message(stack_name: String, combo_count: int) -> String:
	var messages: Array[String] = [
		"Nice! Stack %s x%d",
		"Great! Stack %s x%d",
		"Keep going! Stack %s x%d",
		"On fire! Stack %s x%d",
		"Clean stack! Stack %s x%d"
	]

	var milestone_index: int = int(floor(float(combo_count) / float(combo_popup_step))) - 1

	if milestone_index < 0:
		milestone_index = 0

	var message_index: int = milestone_index % messages.size()

	return messages[message_index] % [stack_name, combo_count]


func is_pointer_over_ui(pointer_position: Vector2) -> bool:
	if splash_screen.visible:
		return true

	if main_menu.visible:
		return true

	if game_over_screen.visible:
		return true

	if trash_button.visible and trash_button.get_global_rect().has_point(pointer_position):
		return true

	return false
