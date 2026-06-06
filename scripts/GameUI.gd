class_name GameUI
extends CanvasLayer

const TRASH_ICON: Texture2D = preload("res://assets/ui/icons/trash_icon.png")

signal trash_pressed
signal play_pressed
signal restart_pressed
signal main_menu_pressed
signal upgrade_pressed
signal stage_selected(stage_number: int)
signal pause_pressed
signal resume_pressed
signal reset_stage_pressed
signal add_time_requested(seconds: float)
signal upgrade_menu_back_pressed
signal buy_add_time_charge_upgrade_pressed
signal endless_mode_pressed

@onready var splash_screen: Control = $SplashScreen
@onready var main_menu: Control = $MainMenu
@onready var gameplay_hud: Control = $GameplayHUD
@onready var game_over_screen: Control = $GameOverScreen

@onready var upgrade_menu: Control = $UpgradeMenu
@onready var add_time_charge_card: PanelContainer = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/UpgradeList/AddTimeChargeCard
@onready var rush_hour_card: PanelContainer = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/UpgradeList/RushHourCard
@onready var tip_boost_card: PanelContainer = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/UpgradeList/TipBoostCard
@onready var extra_plate_card: PanelContainer = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/UpgradeList/ExtraPlateCard
@onready var upgrade_wallet_label: Label = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/WalletLabel
@onready var upgrade_back_button: Button = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/BackButton

@onready var add_time_upgrade_level_label: Label = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/UpgradeList/AddTimeChargeCard/CardRow/TextColumn/LevelLabel
@onready var add_time_upgrade_current_effect_label: Label = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/UpgradeList/AddTimeChargeCard/CardRow/TextColumn/CurrentEffectLabel
@onready var add_time_upgrade_next_effect_label: Label = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/UpgradeList/AddTimeChargeCard/CardRow/TextColumn/NextEffectLabel
@onready var add_time_upgrade_cost_label: Label = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/UpgradeList/AddTimeChargeCard/CardRow/TextColumn/CostLabel
@onready var add_time_upgrade_buy_button: Button = $UpgradeMenu/BackgroundPanel/UpgradeContent/UpgradeVBox/UpgradeList/AddTimeChargeCard/CardRow/BuyButton

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

@onready var bottom_action_bar: PanelContainer = $GameplayHUD/BottomActionBar
@onready var trash_button: Button = $GameplayHUD/BottomActionBar/ActionButtonRow/TrashButton
@onready var rush_hour_button: Button = $GameplayHUD/BottomActionBar/ActionButtonRow/RushHourButton
@onready var tip_boost_button: Button = $GameplayHUD/BottomActionBar/ActionButtonRow/TipBoostButton

@onready var add_time_button: Button = $GameplayHUD/BottomActionBar/ActionButtonRow/AddTimeButton
@onready var add_time_charge_bubble: PanelContainer = $GameplayHUD/BottomActionBar/ActionButtonRow/AddTimeButton/AddTimeChargeBubble
@onready var add_time_charge_label: Label = $GameplayHUD/BottomActionBar/ActionButtonRow/AddTimeButton/AddTimeChargeBubble/CountLabel

@onready var shift_label: Label = $GameplayHUD/ShiftLabel
@onready var stage_goal_label: Label = $GameplayHUD/StageGoalLabel

@onready var endless_hud: Control = $GameplayHUD/EndlessHUD
@onready var endless_stats_label: Label = $GameplayHUD/EndlessHUD/EndlessStatsLabel
@onready var endless_hint_label: Label = $GameplayHUD/EndlessHUD/EndlessHintLabel
@onready var endless_result_label: Label = $GameplayHUD/EndlessHUD/EndlessResultLabel


@onready var pause_button: Button = $GameplayHUD/PauseButton

@onready var pause_menu: Control = $PauseMenu
@onready var resume_button: Button = $PauseMenu/ResumeButton
@onready var reset_stage_button: Button = $PauseMenu/ResetStageButton
@onready var pause_main_menu_button: Button = $PauseMenu/PauseMainMenuButton

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

var customer_money_preview_by_stack: Dictionary = {}

var money_popup_items: Array[Dictionary] = []
var money_popup_duration: float = 0.85
var money_popup_float_height: float = 48.0

func setup_mouse_filter_defaults() -> void:
	if gameplay_hud != null:
		gameplay_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if main_menu != null:
		main_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if stage_menu != null:
		stage_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if game_over_screen != null:
		game_over_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if pause_menu != null:
		pause_menu.mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	layer = 10
	
	setup_gameplay_input_blockers()
	setup_mouse_filter_defaults()
	setup_charge_bubble_style()
	setup_upgrade_card_styles()
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
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

	rush_hour_button.pressed.connect(_on_rush_hour_pressed)
	tip_boost_button.pressed.connect(_on_tip_boost_pressed)
	add_time_button.pressed.connect(_on_add_time_pressed)
	trash_button.pressed.connect(_on_trash_pressed)
	
	upgrade_back_button.pressed.connect(_on_upgrade_back_pressed)
	add_time_upgrade_buy_button.pressed.connect(_on_buy_add_time_charge_upgrade_pressed)
	
	play_button.pressed.connect(_on_play_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	resume_button.mouse_filter = Control.MOUSE_FILTER_STOP
	reset_stage_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_main_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_menu.mouse_filter = Control.MOUSE_FILTER_STOP

	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	reset_stage_button.pressed.connect(_on_reset_stage_pressed)
	pause_main_menu_button.pressed.connect(_on_pause_main_menu_pressed)

	stage_1_button.pressed.connect(_on_stage_1_pressed)
	stage_2_button.pressed.connect(_on_stage_2_pressed)
	stage_3_button.pressed.connect(_on_stage_3_pressed)
	stage_back_button.pressed.connect(_on_stage_back_pressed)

	if endless_mode_button != null:
		endless_mode_button.pressed.connect(_on_endless_mode_pressed)

	if main_upgrade_button != null:
		main_upgrade_button.pressed.connect(_on_upgrade_pressed)

	if endless_mode_button != null:
		endless_mode_button.pressed.connect(_on_endless_mode_pressed)

	

	setup_customer_slot_dictionary()
	
	setup()

func set_add_time_charges(current_charges: int, max_charges: int) -> void:
	if add_time_charge_label != null:
		add_time_charge_label.text = str(current_charges)

	if add_time_charge_bubble != null:
		add_time_charge_bubble.visible = max_charges > 0

	if add_time_button != null:
		add_time_button.disabled = current_charges <= 0

		if current_charges <= 0:
			add_time_button.modulate = Color(0.55, 0.55, 0.55, 1.0)
		else:
			add_time_button.modulate = Color.WHITE

func setup_charge_bubble_style() -> void:
	if add_time_charge_bubble == null:
		return

	var bubble_style: StyleBoxFlat = StyleBoxFlat.new()
	bubble_style.bg_color = Color(0.95, 0.18, 0.10)
	bubble_style.border_color = Color.WHITE
	bubble_style.border_width_left = 2
	bubble_style.border_width_top = 2
	bubble_style.border_width_right = 2
	bubble_style.border_width_bottom = 2
	bubble_style.corner_radius_top_left = 12
	bubble_style.corner_radius_top_right = 12
	bubble_style.corner_radius_bottom_left = 12
	bubble_style.corner_radius_bottom_right = 12

	add_time_charge_bubble.add_theme_stylebox_override("panel", bubble_style)

func setup_upgrade_card_styles() -> void:
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.075, 0.075, 0.075, 1.0)
	card_style.border_color = Color(0.14, 0.14, 0.14, 1.0)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.corner_radius_top_left = 4
	card_style.corner_radius_top_right = 4
	card_style.corner_radius_bottom_left = 4
	card_style.corner_radius_bottom_right = 4

	# Internal padding inside each card.
	card_style.set_content_margin(SIDE_LEFT, 12)
	card_style.set_content_margin(SIDE_TOP, 10)
	card_style.set_content_margin(SIDE_RIGHT, 12)
	card_style.set_content_margin(SIDE_BOTTOM, 10)

	var cards: Array[PanelContainer] = [
		add_time_charge_card,
		rush_hour_card,
		tip_boost_card,
		extra_plate_card
	]

	for card: PanelContainer in cards:
		if card != null:
			card.add_theme_stylebox_override("panel", card_style)

func setup_customer_orders(
	order_a: Array[String],
	order_b: Array[String],
	preference_a: String = "tip_lover",
	preference_b: String = "tip_lover"
) -> void:
	customer_money_preview_by_stack.clear()
	clear_money_popups()

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

func setup_gameplay_input_blockers() -> void:
	var blocker_controls: Array[Control] = [
		trash_button,
		pause_button,
		rush_hour_button,
		tip_boost_button,
		add_time_button,
		play_button,
		restart_button,
		upgrade_button,
		main_menu_button,
		stage_1_button,
		stage_2_button,
		stage_3_button,
		stage_back_button,
		resume_button,
		reset_stage_button,
		pause_main_menu_button
	]

	if main_upgrade_button != null:
		blocker_controls.append(main_upgrade_button)

	if endless_mode_button != null:
		blocker_controls.append(endless_mode_button)

	for control: Control in blocker_controls:
		if control == null:
			continue

		if not control.is_in_group("blocks_gameplay_input"):
			control.add_to_group("blocks_gameplay_input")

		control.mouse_filter = Control.MOUSE_FILTER_STOP

func setup() -> void:
	show_splash_screen()

func _process(delta: float) -> void:
	update_combo_popup(delta)
	update_money_popups(delta)

func _on_trash_pressed() -> void:
	trash_pressed.emit()

func _on_rush_hour_pressed() -> void:
	show_gameplay_message("Rush Hour coming soon")

func _on_tip_boost_pressed() -> void:
	show_gameplay_message("Tip Boost coming soon")

func _on_add_time_pressed() -> void:
	add_time_requested.emit(5.0)

func _on_play_pressed() -> void:
	show_stage_menu()

func _on_endless_mode_pressed() -> void:
	endless_mode_pressed.emit()

func _on_restart_pressed() -> void:
	restart_pressed.emit()

func _on_upgrade_pressed() -> void:
	upgrade_pressed.emit()

func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()

func _on_upgrade_back_pressed() -> void:
	upgrade_menu_back_pressed.emit()

func _on_buy_add_time_charge_upgrade_pressed() -> void:
	buy_add_time_charge_upgrade_pressed.emit()

func _on_pause_pressed() -> void:
	pause_pressed.emit()

func _on_resume_pressed() -> void:
	resume_pressed.emit()

func _on_reset_stage_pressed() -> void:
	reset_stage_pressed.emit()

func _on_pause_main_menu_pressed() -> void:
	main_menu_pressed.emit()

func _on_stage_1_pressed() -> void:
	stage_selected.emit(1)

func _on_stage_2_pressed() -> void:
	stage_selected.emit(2)

func _on_stage_3_pressed() -> void:
	stage_selected.emit(3)

func _on_stage_back_pressed() -> void:
	show_main_menu()

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
	pause_menu.visible = false
	upgrade_menu.visible = false
	
	if endless_hud != null:
		endless_hud.visible = false

func show_upgrade_menu() -> void:
	splash_screen.visible = false
	main_menu.visible = false
	gameplay_hud.visible = false
	game_over_screen.visible = false
	stage_menu.visible = false
	pause_menu.visible = false
	upgrade_menu.visible = true

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
	pause_menu.visible = false
	upgrade_menu.visible = false
	
	if endless_hud != null:
		endless_hud.visible = false

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

func update_endless_goal(current_layers: int, best_layers: int) -> void:
	if endless_stats_label != null:
		endless_stats_label.text = "Endless | Layers " + str(current_layers) + " | Best " + str(best_layers)

func update_endless_result(result_text: String) -> void:
	if endless_result_label != null:
		endless_result_label.text = result_text

func set_customer_slots_visible(should_be_visible: bool) -> void:
	if customer_slot_a != null:
		customer_slot_a.visible = should_be_visible

	if customer_slot_b != null:
		customer_slot_b.visible = should_be_visible

func set_endless_hud_mode(is_endless: bool) -> void:
	if score_label != null:
		score_label.visible = not is_endless

	if ingredient_label != null:
		ingredient_label.visible = not is_endless

	if stacks_label != null:
		stacks_label.visible = not is_endless
		
	if result_label != null:
		result_label.visible = not is_endless

	if shift_label != null:
		shift_label.visible = not is_endless

	if stage_goal_label != null:
		stage_goal_label.visible = not is_endless

	if bottom_action_bar != null:
		bottom_action_bar.visible = not is_endless

	if endless_hud != null:
		endless_hud.visible = is_endless

	set_customer_slots_visible(not is_endless)

func show_gameplay_message(message: String) -> void:
	if result_label != null:
		result_label.text = message

func show_gameplay_hud() -> void:
	splash_screen.visible = false
	main_menu.visible = false
	gameplay_hud.visible = true
	game_over_screen.visible = false
	stage_menu.visible = false
	pause_menu.visible = false
	upgrade_menu.visible = false

func show_pause_menu() -> void:
	pause_menu.visible = true
	pause_menu.move_to_front()

func hide_pause_menu() -> void:
	pause_menu.visible = false

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
	stage_cleared: bool = false,
	has_next_stage: bool = true
) -> void:
	splash_screen.visible = false
	main_menu.visible = false
	gameplay_hud.visible = false
	game_over_screen.visible = true
	stage_menu.visible = false
	pause_menu.visible = false
	upgrade_menu.visible = false
	
	if endless_hud != null:
		endless_hud.visible = false

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

		if has_next_stage:
			restart_button.text = "Next Stage"
		else:
			restart_button.text = "Stage Select"
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
	pause_menu.visible = false

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
	pause_menu.visible = false

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

func maybe_show_customer_money_change_popup(
	stack_name: String,
	payout_preview_text: String
) -> void:
	if not gameplay_hud.visible:
		return

	var new_money_value: int = extract_money_value_from_text(payout_preview_text)

	if not customer_money_preview_by_stack.has(stack_name):
		customer_money_preview_by_stack[stack_name] = new_money_value
		return

	var old_money_value: int = int(customer_money_preview_by_stack[stack_name])

	if new_money_value == old_money_value:
		return

	customer_money_preview_by_stack[stack_name] = new_money_value

	var money_delta: int = new_money_value - old_money_value

	if money_delta == 0:
		return

	var popup_text: String = get_money_change_popup_text(money_delta)
	show_customer_money_popup(stack_name, popup_text, money_delta)

func extract_money_value_from_text(text: String) -> int:
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

func get_money_change_popup_text(money_delta: int) -> String:
	if money_delta > 0:
		if result_label != null:
			var result_lower: String = result_label.text.to_lower()

			if result_lower.contains("style"):
				return "Style +$" + str(money_delta)

		return "Extra +$" + str(money_delta)

	return "Extra -$" + str(abs(money_delta))

func show_customer_money_feedback(
	stack_name: String,
	popup_text: String,
	money_delta: int
) -> void:
	if not gameplay_hud.visible:
		return

	show_customer_money_popup(stack_name, popup_text, money_delta)

func show_customer_money_popup(
	stack_name: String,
	popup_text: String,
	money_delta: int
) -> void:
	
	var target_position: Vector2 = get_customer_money_target_position(stack_name)

	var active_popup_count: int = get_active_money_popup_count_for_stack(stack_name)
	var lane_index: int = active_popup_count % 3
	var lane_offset: Vector2 = Vector2(0.0, -40.0 * float(lane_index))

	var start_position: Vector2 = target_position + Vector2(0.0, -money_popup_float_height) + lane_offset
	var adjusted_target_position: Vector2 = target_position + lane_offset
	
	var popup_label: Label = Label.new()
	
	popup_label.text = popup_text
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.size = Vector2(135, 30)
	popup_label.z_index = 40
	popup_label.add_theme_font_size_override("font_size", 19)
	popup_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	popup_label.add_theme_constant_override("outline_size", 5)

	if money_delta >= 0:
		popup_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.35, 1.0))
	else:
		popup_label.add_theme_color_override("font_color", Color(1.0, 0.30, 0.25, 1.0))

	var start_rect_position: Vector2 = clamp_money_popup_position(
		adjusted_target_position - Vector2(67.5, 15),
		popup_label.size
	)

	var target_rect_position: Vector2 = clamp_money_popup_position(
		target_position - Vector2(67.5, 15),
		popup_label.size
	)

	popup_label.position = start_rect_position

	gameplay_hud.add_child(popup_label)

	var popup_item: Dictionary = {
		"label": popup_label,
		"timer": money_popup_duration,
		"start_position": start_rect_position,
		"target_position": target_rect_position,
		"stack_name": stack_name
	}

	money_popup_items.append(popup_item)

func get_customer_money_target_position(stack_name: String) -> Vector2:
	var slot = get_customer_slot(stack_name)

	if slot != null and slot.has_method("get_money_target_global_position"):
		return slot.get_money_target_global_position()

	if slot != null:
		return slot.get_global_rect().get_center()

	return Vector2(270, 820)

func get_active_money_popup_count_for_stack(stack_name: String) -> int:
	var popup_count: int = 0

	for popup_item: Dictionary in money_popup_items:
		if not popup_item.has("stack_name"):
			continue

		if String(popup_item["stack_name"]) == stack_name:
			popup_count += 1

	return popup_count

func clamp_money_popup_position(raw_position: Vector2, popup_size: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var margin: float = 8.0

	var clamped_x: float = clamp(
		raw_position.x,
		margin,
		viewport_size.x - popup_size.x - margin
	)

	var clamped_y: float = clamp(
		raw_position.y,
		margin,
		viewport_size.y - popup_size.y - margin
	)

	return Vector2(clamped_x, clamped_y)

func update_money_popups(delta: float) -> void:
	for index in range(money_popup_items.size() - 1, -1, -1):
		var popup_item: Dictionary = money_popup_items[index]
		var popup_label: Label = popup_item["label"]

		if popup_label == null or not is_instance_valid(popup_label):
			money_popup_items.remove_at(index)
			continue

		var timer: float = float(popup_item["timer"])
		timer -= delta
		popup_item["timer"] = timer
		money_popup_items[index] = popup_item

		if timer <= 0.0:
			popup_label.queue_free()
			money_popup_items.remove_at(index)
			continue

		var progress: float = 1.0 - clamp(timer / money_popup_duration, 0.0, 1.0)
		var start_position: Vector2 = popup_item["start_position"]
		var target_position: Vector2 = popup_item["target_position"]

		var unclamped_position: Vector2 = start_position.lerp(target_position, progress)
		popup_label.position = clamp_money_popup_position(unclamped_position, popup_label.size)

		var popup_color: Color = popup_label.modulate
		popup_color.a = 1.0

		if progress > 0.55:
			popup_color.a = lerpf(1.0, 0.0, (progress - 0.55) / 0.45)

		popup_label.modulate = popup_color

		var scale_value: float = 1.0

		if progress < 0.18:
			scale_value = lerpf(0.85, 1.10, progress / 0.18)
		elif progress < 0.32:
			scale_value = lerpf(1.10, 1.0, (progress - 0.18) / 0.14)

		popup_label.scale = Vector2(scale_value, scale_value)

func clear_money_popups() -> void:
	for popup_item: Dictionary in money_popup_items:
		var popup_label: Label = popup_item["label"]

		if popup_label != null and is_instance_valid(popup_label):
			popup_label.queue_free()

	money_popup_items.clear()

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

func is_pointer_over_ui(screen_position: Vector2) -> bool:
	if pause_menu != null and pause_menu.is_visible_in_tree():
		return true

	for node: Node in get_tree().get_nodes_in_group("blocks_gameplay_input"):
		var control: Control = node as Control

		if control == null:
			continue

		if not control.is_visible_in_tree():
			continue

		if control.get_global_rect().has_point(screen_position):
			return true

	return false

func update_upgrade_menu(
	wallet_money: int,
	add_time_level: int,
	add_time_cost: int
) -> void:
	var current_uses: int = add_time_level + 1
	var next_uses: int = current_uses + 1

	if upgrade_wallet_label != null:
		upgrade_wallet_label.text = "Wallet: $" + str(wallet_money)

	if add_time_upgrade_level_label != null:
		add_time_upgrade_level_label.text = "Level: " + str(add_time_level)

	if add_time_upgrade_current_effect_label != null:
		add_time_upgrade_current_effect_label.text = "Current: " + str(current_uses) + " uses / shift"

	if add_time_upgrade_next_effect_label != null:
		add_time_upgrade_next_effect_label.text = "Next: " + str(next_uses) + " uses / shift"

	if add_time_upgrade_cost_label != null:
		add_time_upgrade_cost_label.text = "Cost: $" + str(add_time_cost)

	if add_time_upgrade_buy_button != null:
		add_time_upgrade_buy_button.disabled = wallet_money < add_time_cost

		if wallet_money < add_time_cost:
			add_time_upgrade_buy_button.text = "Need $" + str(add_time_cost - wallet_money)
		else:
			add_time_upgrade_buy_button.text = "Buy"
