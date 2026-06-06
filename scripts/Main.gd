extends Node3D

const IngredientFactoryScript = preload("res://scripts/IngredientFactory.gd")
const GameUIScene = preload("res://scenes/ui/GameUI.tscn")
const BurgerStackScript = preload("res://scripts/BurgerStack.gd")

const SAVE_FILE_PATH: String = "user://burger_stack_save.cfg"
const SAVE_SECTION: String = "player"
const UPGRADES_SAVE_PATH: String = "user://restaurant_upgrades.save"

var ingredient_factory: IngredientFactory = null
var game_ui: GameUI = null

enum GameState {
	SPLASH,
	MENU,
	PLAYING,
	GAME_OVER
}

enum GameMode {
	RESTAURANT,
	ENDLESS
}

var customer_order_pool: Array[String] = [
	"Patty",
	"Cheese",
	"Lettuce",
	"Tomato",
	"Onion",
	"Egg"
]

var customer_order_size: int = 5

var active_stack_names: Array[String] = ["A", "B"]

var customer_orders: Dictionary = {}
var customer_preferences: Dictionary = {}
var stack_ingredients: Dictionary = {}
var stack_style_bonuses: Dictionary = {}

var game_state: GameState = GameState.SPLASH
var current_game_mode: GameMode = GameMode.RESTAURANT
var endless_current_layers: int = 0
var endless_best_layers: int = 0
var splash_timer: float = 0.0
var splash_duration: float = 1.8

var shift_duration_seconds: float = 240.0
var shift_time_remaining: float = 240.0
var shift_timer_running: bool = false
var shift_has_ended: bool = false

var is_game_paused: bool = false
var gameplay_input_block_until_msec: int = 0

var current_stage: int = 1
var unlocked_stage: int = 1
var max_selectable_stage: int = 3

var base_customers_required: int = 5
var customers_required_increase_per_stage: int = 1
var customers_required_this_stage: int = 5
var customers_served_this_stage: int = 0
var stage_was_cleared: bool = false

var ingredient_x: float = 0.0
var ingredient_start_y: float = 4.5
var ingredient_speed: float = 2.2
var ingredient_range: float = 1.7
var time: float = 0.0

var active_ingredient: RigidBody3D = null
var can_drop: bool = true

var minimum_landing_time: float = 0.95
var maximum_landing_time: float = 2.80
var landing_elapsed: float = 0.0

var flip_available: bool = false
var flip_used: bool = false
var flip_direction: float = 1.0
var flip_strength: float = 8.0

var plate_a_x: float = -1.15
var plate_b_x: float = 1.15
var endless_plate_x: float = 0.0

var plate_a_body: StaticBody3D = null
var plate_b_body: StaticBody3D = null
var bottom_bun_a_body: StaticBody3D = null
var bottom_bun_b_body: StaticBody3D = null

var current_ingredient_name: String = "Cheese"
var current_ingredient_width: float = 0.85
var current_ingredient_height: float = 0.12
var current_ingredient_depth: float = 0.85
var current_ingredient_mass: float = 0.25
var current_ingredient_color: Color = Color(1.0, 0.80, 0.10)

var bottom_bun_width: float = 0.78
var bottom_bun_height: float = 0.20
var bottom_bun_y: float = 0.36

var burger_stacks: Array[BurgerStack] = []

var base_good_landing_score: int = 10
var base_unstable_landing_score: int = 4
var base_edge_landing_score: int = 2
var bad_landing_penalty: int = 3
var miss_penalty: int = 5
var trash_penalty: int = 0

var flip_bonus_score: int = 3
var height_bonus_per_extra_layer: int = 2
var combo_bonus_per_extra_combo: int = 2

var best_stack_height: int = 0

var fallen_layer_penalty: int = 8

var stack_fall_y_limit: float = 0.03
var max_distance_from_plate: float = 0.92
var max_detach_tilt_degrees: float = 72.0
var low_detach_y_limit: float = 1.10

var loose_ingredients: Array[Node3D] = []
var loose_cleanup_delay: float = 0.55
var loose_fall_y_limit: float = 0.15
var loose_max_distance_from_center: float = 2.40

var complete_order_base_money: int = 10
var money_per_required_ingredient: int = 3
var tip_per_extra_layer: int = 1
var exact_extra_layer_penalty: int = 2
var incomplete_order_money: int = 3

var flip_delivery_bonus_money: int = 3

var run_money: int = 0
var wallet_money: int = 0
var last_result: String = "Tap to drop"

var add_time_base_charges: int = 1
var add_time_charge_upgrade_level: int = 0
var add_time_max_charges: int = 1
var add_time_charges: int = 1
var add_time_charge_upgrade_base_cost: int = 100
var add_time_charge_upgrade_cost_increase: int = 75

func change_run_money(amount: int) -> void:
	run_money += amount

	if run_money < 0:
		run_money = 0

func load_wallet_money() -> void:
	var save_file: ConfigFile = ConfigFile.new()
	var load_error: int = save_file.load(SAVE_FILE_PATH)

	if load_error != OK:
		wallet_money = 0
		return

	wallet_money = int(save_file.get_value(SAVE_SECTION, "wallet_money", 0))
	unlocked_stage = int(save_file.get_value(SAVE_SECTION, "unlocked_stage", 1))

	if wallet_money < 0:
		wallet_money = 0

	if unlocked_stage < 1:
		unlocked_stage = 1

	if unlocked_stage > max_selectable_stage:
		unlocked_stage = max_selectable_stage

func load_restaurant_upgrades() -> void:
	if not FileAccess.file_exists(UPGRADES_SAVE_PATH):
		add_time_charge_upgrade_level = 0
		return

	var file: FileAccess = FileAccess.open(UPGRADES_SAVE_PATH, FileAccess.READ)

	if file == null:
		var load_error: Error = FileAccess.get_open_error()
		push_warning("Could not load restaurant upgrades. Error: " + str(load_error))
		add_time_charge_upgrade_level = 0
		return

	var save_data: Variant = file.get_var()
	file.close()

	if save_data is Dictionary:
		add_time_charge_upgrade_level = int(save_data.get("add_time_charge_upgrade_level", 0))
	else:
		add_time_charge_upgrade_level = 0

func save_wallet_money() -> void:
	var save_file: ConfigFile = ConfigFile.new()

	save_file.set_value(SAVE_SECTION, "wallet_money", wallet_money)
	save_file.set_value(SAVE_SECTION, "unlocked_stage", unlocked_stage)

	var save_error: int = save_file.save(SAVE_FILE_PATH)

	if save_error != OK:
		push_warning("Could not save wallet money. Error: " + str(save_error))

func save_restaurant_upgrades() -> void:
	var save_data: Dictionary = {
		"add_time_charge_upgrade_level": add_time_charge_upgrade_level
	}

	var file: FileAccess = FileAccess.open(UPGRADES_SAVE_PATH, FileAccess.WRITE)

	if file == null:
		var save_error: Error = FileAccess.get_open_error()
		push_warning("Could not save restaurant upgrades. Error: " + str(save_error))
		return

	file.store_var(save_data)
	file.close()

func _ready() -> void:
	randomize()
	load_wallet_money()
	load_restaurant_upgrades()

	ingredient_factory = IngredientFactoryScript.new()
	add_child(ingredient_factory)

	game_ui = GameUIScene.instantiate() as GameUI
	add_child(game_ui)
	
	game_ui.update_wallet_money(wallet_money)
	update_stage_select_ui()
	
	game_ui.trash_pressed.connect(Callable(self, "trash_current_ingredient"))
	game_ui.add_time_requested.connect(Callable(self, "add_shift_time"))
	game_ui.stage_selected.connect(Callable(self, "start_restaurant_mode"))
	game_ui.endless_mode_pressed.connect(Callable(self, "start_endless_mode"))
	game_ui.restart_pressed.connect(Callable(self, "start_next_stage"))
	game_ui.main_menu_pressed.connect(Callable(self, "return_to_main_menu"))
	game_ui.upgrade_pressed.connect(Callable(self, "show_upgrade_placeholder"))
	game_ui.pause_pressed.connect(Callable(self, "pause_game"))
	game_ui.resume_pressed.connect(Callable(self, "resume_game"))
	game_ui.reset_stage_pressed.connect(Callable(self, "reset_current_stage"))
	game_ui.upgrade_menu_back_pressed.connect(Callable(self, "return_to_main_menu"))
	game_ui.buy_add_time_charge_upgrade_pressed.connect(Callable(self, "buy_add_time_charge_upgrade"))
	
	
	add_time_max_charges = calculate_add_time_max_charges()
	add_time_charges = add_time_max_charges
	update_ability_ui()
	
	setup_empty_stack_state()
	assign_customer_orders()

	create_static_scene_objects()
	
	game_state = GameState.SPLASH
	splash_timer = splash_duration
	last_result = "Press Play to start"
	update_ui()

func setup_empty_stack_state() -> void:
	for stack_name: String in active_stack_names:
		if not customer_orders.has(stack_name):
			customer_orders[stack_name] = []

		if not customer_preferences.has(stack_name):
			customer_preferences[stack_name] = "tip_lover"

		if not stack_ingredients.has(stack_name):
			stack_ingredients[stack_name] = []

		if not stack_style_bonuses.has(stack_name):
			stack_style_bonuses[stack_name] = 0

func setup_customer_ui() -> void:
	if game_ui == null:
		return

	game_ui.setup_customer_orders(
		get_customer_order_for_stack("A"),
		get_customer_order_for_stack("B"),
		get_customer_preference_for_stack("A"),
		get_customer_preference_for_stack("B")
	)

func refresh_all_customer_progress() -> void:
	for stack_name: String in active_stack_names:
		refresh_customer_progress(stack_name)

func update_stage_select_ui() -> void:
	if game_ui == null:
		return

	if game_ui.has_method("update_stage_buttons"):
		game_ui.update_stage_buttons(
			unlocked_stage,
			get_customers_required_for_stage(1),
			get_customers_required_for_stage(2),
			get_customers_required_for_stage(3)
		)

func generate_customer_preference() -> String:
	if randf() < 0.65:
		return "tip_lover"

	return "exact"

func generate_customer_order() -> Array[String]:
	var shuffled_pool: Array[String] = customer_order_pool.duplicate()
	shuffled_pool.shuffle()

	var new_order: Array[String] = []

	for i in range(customer_order_size):
		if i < shuffled_pool.size():
			new_order.append(shuffled_pool[i])

	return new_order

func assign_customer_orders() -> void:
	setup_empty_stack_state()

	for stack_name: String in active_stack_names:
		customer_orders[stack_name] = generate_customer_order()
		customer_preferences[stack_name] = generate_customer_preference()
		stack_ingredients[stack_name] = []
		stack_style_bonuses[stack_name] = 0

	setup_customer_ui()
	refresh_all_customer_progress()

func get_customers_required_for_stage(stage_number: int) -> int:
	var required_customers: int = base_customers_required
	required_customers += (stage_number - 1) * customers_required_increase_per_stage

	if required_customers < 1:
		required_customers = 1

	return required_customers

func setup_stage_goal(stage_number: int) -> void:
	current_stage = stage_number
	customers_required_this_stage = get_customers_required_for_stage(stage_number)
	customers_served_this_stage = 0
	stage_was_cleared = false

func block_gameplay_input_for(milliseconds: int) -> void:
	gameplay_input_block_until_msec = Time.get_ticks_msec() + milliseconds

func is_gameplay_input_blocked() -> bool:
	return Time.get_ticks_msec() < gameplay_input_block_until_msec

func pause_game() -> void:
	if game_state != GameState.PLAYING:
		return

	if is_game_paused:
		return

	block_gameplay_input_for(400)

	is_game_paused = true
	get_tree().paused = true

	if game_ui != null:
		game_ui.show_pause_menu()

func resume_game() -> void:
	if not is_game_paused:
		return

	block_gameplay_input_for(400)

	is_game_paused = false
	get_tree().paused = false

	if game_ui != null:
		game_ui.hide_pause_menu()

func reset_current_stage() -> void:
	is_game_paused = false
	get_tree().paused = false
	block_gameplay_input_for(400)

	if current_game_mode == GameMode.ENDLESS:
		reset_endless_run()
	else:
		reset_restaurant_stage()

func reset_restaurant_stage() -> void:
	start_stage(current_stage)

func reset_endless_run() -> void:
	start_endless_mode()

func start_endless_mode() -> void:
	current_game_mode = GameMode.ENDLESS
	game_state = GameState.PLAYING
	is_game_paused = false
	get_tree().paused = false
	
	setup_endless_layout()

	clear_current_run_objects()

	run_money = 0
	endless_current_layers = 0
	best_stack_height = 0

	shift_timer_running = false
	shift_has_ended = false
	shift_time_remaining = shift_duration_seconds

	last_result = "Endless Mode: stack as high as you can"

	setup_empty_stack_state()
	reset_ability_charges()

	if game_ui != null:
		game_ui.hide_pause_menu()
		game_ui.show_gameplay_hud()
		game_ui.update_endless_goal(endless_current_layers, endless_best_layers)

	spawn_ingredient()
	update_ui()

func start_restaurant_mode(stage_number: int) -> void:
	current_game_mode = GameMode.RESTAURANT
	start_stage(stage_number)

func start_stage(stage_number: int) -> void:
	current_game_mode = GameMode.RESTAURANT
	setup_restaurant_layout()

	is_game_paused = false
	get_tree().paused = false
	
	if game_ui != null and game_ui.has_method("hide_pause_menu"):
		game_ui.hide_pause_menu()
		
	if stage_number > unlocked_stage:
		last_result = "Stage " + str(stage_number) + " is locked"
		return

	if stage_number > max_selectable_stage:
		stage_number = max_selectable_stage

	setup_stage_goal(stage_number)
	start_game()

func unlock_next_stage_after_clear() -> void:
	if current_stage >= max_selectable_stage:
		return

	var next_stage: int = current_stage + 1

	if next_stage > unlocked_stage:
		unlocked_stage = next_stage

func record_customer_served() -> void:
	customers_served_this_stage += 1

	if customers_served_this_stage > customers_required_this_stage:
		customers_served_this_stage = customers_required_this_stage

	if customers_served_this_stage >= customers_required_this_stage:
		end_shift(true)

func start_game() -> void:
	clear_current_run_objects()
	assign_customer_orders()

	if ingredient_factory != null and ingredient_factory.has_method("reset_spawn_state"):
		ingredient_factory.reset_spawn_state()

	game_state = GameState.PLAYING

	reset_ability_charges()

	run_money = 0
	best_stack_height = 0
	customers_required_this_stage = get_customers_required_for_stage(current_stage)
	customers_served_this_stage = 0
	stage_was_cleared = false
	shift_time_remaining = shift_duration_seconds
	shift_timer_running = true
	shift_has_ended = false
	last_result = "Tap to drop"

	if game_ui != null:
		game_ui.show_gameplay_hud()
		game_ui.update_wallet_money(wallet_money)
		refresh_customer_progress("A")
		refresh_customer_progress("B")

	spawn_ingredient()
	update_ui()

func restart_game() -> void:
	get_tree().reload_current_scene()

func clear_current_run_objects() -> void:
	if active_ingredient != null and is_instance_valid(active_ingredient):
		active_ingredient.queue_free()

	active_ingredient = null
	can_drop = false
	flip_available = false
	flip_used = false
	landing_elapsed = 0.0

	for stack: BurgerStack in burger_stacks:
		if stack != null and is_instance_valid(stack):
			stack.clear_ingredient_layers()
			stack.reset_combo()
	
	for stack_name: String in active_stack_names:
		stack_ingredients[stack_name] = []
		clear_stack_style_bonus(stack_name)

	for loose_ingredient: Node3D in loose_ingredients:
		if loose_ingredient != null and is_instance_valid(loose_ingredient):
			loose_ingredient.queue_free()

	loose_ingredients.clear()

	best_stack_height = 0
	hide_all_serve_prompts()

func has_next_stage_after_current() -> bool:
	return current_stage < max_selectable_stage

func start_next_stage() -> void:
	if stage_was_cleared:
		if has_next_stage_after_current():
			start_stage(current_stage + 1)
		else:
			return_to_stage_select()
	else:
		start_stage(current_stage)

func return_to_stage_select() -> void:
	clear_current_run_objects()

	run_money = 0
	shift_time_remaining = shift_duration_seconds
	shift_timer_running = false
	shift_has_ended = false
	game_state = GameState.MENU
	last_result = "Select a stage"

	if game_ui != null:
		game_ui.update_wallet_money(wallet_money)
		update_stage_select_ui()
		hide_all_serve_prompts()

		if game_ui.has_method("show_stage_menu"):
			game_ui.show_stage_menu()

func return_to_main_menu() -> void:
	is_game_paused = false
	get_tree().paused = false

	if game_ui != null and game_ui.has_method("hide_pause_menu"):
		game_ui.hide_pause_menu()
		
	clear_current_run_objects()

	run_money = 0
	shift_time_remaining = shift_duration_seconds
	shift_timer_running = false
	shift_has_ended = false
	game_state = GameState.MENU
	last_result = "Press Play to start"

	if game_ui != null:
		game_ui.update_wallet_money(wallet_money)
		update_stage_select_ui()
		hide_all_serve_prompts()
		game_ui.show_main_menu()

func show_upgrade_placeholder() -> void:
	if game_ui == null:
		return

	update_upgrade_menu_ui()
	game_ui.show_upgrade_menu()

func end_shift(stage_cleared: bool = false) -> void:
	if shift_has_ended:
		return

	shift_has_ended = true
	shift_timer_running = false
	stage_was_cleared = stage_cleared
	game_state = GameState.GAME_OVER

	if active_ingredient != null and is_instance_valid(active_ingredient):
		active_ingredient.queue_free()

	active_ingredient = null
	can_drop = false
	flip_available = false
	flip_used = false

	var added_money: int = run_money

	if added_money < 0:
		added_money = 0

	wallet_money += added_money
	
	if stage_cleared:
		unlock_next_stage_after_clear()
	
	save_wallet_money()
	update_stage_select_ui()

	if game_ui != null:
		game_ui.update_wallet_money(wallet_money)
		hide_all_serve_prompts()
		game_ui.show_shift_summary(
			run_money,
			wallet_money,
			added_money,
			current_stage,
			customers_served_this_stage,
			customers_required_this_stage,
			stage_was_cleared,
			has_next_stage_after_current()
		)

func create_static_scene_objects() -> void:
	ingredient_factory.create_static_box(
		self,
		"Counter",
		Vector3(0, 0, 0),
		Vector3(4.4, 0.25, 1.35),
		Color(0.55, 0.35, 0.20)
	)

	plate_a_body = ingredient_factory.create_static_box(
		self,
		"Plate A",
		Vector3(plate_a_x, 0.22, 0),
		Vector3(0.95, 0.07, 0.95),
		Color(0.85, 0.85, 0.85)
	)

	plate_b_body = ingredient_factory.create_static_box(
		self,
		"Plate B",
		Vector3(plate_b_x, 0.22, 0),
		Vector3(0.95, 0.07, 0.95),
		Color(0.85, 0.85, 0.85)
	)

	bottom_bun_a_body = ingredient_factory.create_static_box(
		self,
		"Bottom Bun A",
		Vector3(plate_a_x, bottom_bun_y, 0),
		Vector3(bottom_bun_width, bottom_bun_height, 0.78),
		Color(0.95, 0.58, 0.22)
	)

	bottom_bun_b_body = ingredient_factory.create_static_box(
		self,
		"Bottom Bun B",
		Vector3(plate_b_x, bottom_bun_y, 0),
		Vector3(bottom_bun_width, bottom_bun_height, 0.78),
		Color(0.95, 0.58, 0.22)
	)

	create_burger_stack("A", plate_a_x, bottom_bun_a_body)
	create_burger_stack("B", plate_b_x, bottom_bun_b_body)

func create_burger_stack(stack_name: String, plate_x: float, bottom_layer: Node3D) -> void:
	var burger_stack: BurgerStack = BurgerStackScript.new()
	add_child(burger_stack)

	burger_stack.setup(
		stack_name,
		plate_x,
		bottom_layer,
		bottom_bun_width,
		bottom_bun_height,
		bottom_bun_y
	)

	burger_stacks.append(burger_stack)

func get_burger_stack_by_name(stack_name: String) -> BurgerStack:
	for stack: BurgerStack in burger_stacks:
		if stack == null:
			continue

		if not is_instance_valid(stack):
			continue

		if stack.get_stack_name() == stack_name:
			return stack

	return null

func set_static_body_collision_enabled(body: Node3D, enabled: bool) -> void:
	if body == null:
		return

	if not is_instance_valid(body):
		return

	if body is CollisionObject3D:
		var collision_body: CollisionObject3D = body as CollisionObject3D

		if enabled:
			collision_body.collision_layer = 1
			collision_body.collision_mask = 1
		else:
			collision_body.collision_layer = 0
			collision_body.collision_mask = 0

	for child: Node in body.get_children():
		var collision_shape: CollisionShape3D = child as CollisionShape3D

		if collision_shape != null:
			collision_shape.disabled = not enabled

func setup_restaurant_layout() -> void:
	active_stack_names = ["A", "B"]

	if plate_a_body != null and is_instance_valid(plate_a_body):
		plate_a_body.visible = true
		plate_a_body.position.x = plate_a_x
		set_static_body_collision_enabled(plate_a_body, true)

	if plate_b_body != null and is_instance_valid(plate_b_body):
		plate_b_body.visible = true
		plate_b_body.position.x = plate_b_x
		set_static_body_collision_enabled(plate_b_body, true)

	if bottom_bun_a_body != null and is_instance_valid(bottom_bun_a_body):
		bottom_bun_a_body.visible = true
		bottom_bun_a_body.position.x = plate_a_x
		set_static_body_collision_enabled(bottom_bun_a_body, true)

	if bottom_bun_b_body != null and is_instance_valid(bottom_bun_b_body):
		bottom_bun_b_body.visible = true
		bottom_bun_b_body.position.x = plate_b_x
		set_static_body_collision_enabled(bottom_bun_b_body, true)

	var stack_a: BurgerStack = get_burger_stack_by_name("A")
	if stack_a != null:
		stack_a.plate_x = plate_a_x

	var stack_b: BurgerStack = get_burger_stack_by_name("B")
	if stack_b != null:
		stack_b.plate_x = plate_b_x

	if game_ui != null:
		game_ui.set_endless_hud_mode(false)

func setup_endless_layout() -> void:
	active_stack_names = ["A"]

	if plate_a_body != null and is_instance_valid(plate_a_body):
		plate_a_body.visible = true
		plate_a_body.position.x = endless_plate_x
		set_static_body_collision_enabled(plate_a_body, true)

	if bottom_bun_a_body != null and is_instance_valid(bottom_bun_a_body):
		bottom_bun_a_body.visible = true
		bottom_bun_a_body.position.x = endless_plate_x
		set_static_body_collision_enabled(bottom_bun_a_body, true)

	if plate_b_body != null and is_instance_valid(plate_b_body):
		plate_b_body.visible = false
		set_static_body_collision_enabled(plate_b_body, false)

	if bottom_bun_b_body != null and is_instance_valid(bottom_bun_b_body):
		bottom_bun_b_body.visible = false
		set_static_body_collision_enabled(bottom_bun_b_body, false)

	var stack_a: BurgerStack = get_burger_stack_by_name("A")
	if stack_a != null:
		stack_a.plate_x = endless_plate_x

	var stack_b: BurgerStack = get_burger_stack_by_name("B")
	if stack_b != null:
		stack_b.clear_ingredient_layers()
		stack_b.reset_combo()

	if game_ui != null:
		game_ui.set_endless_hud_mode(true)

func _process(delta: float) -> void:
	if game_state == GameState.SPLASH:
		splash_timer -= delta

		if splash_timer <= 0.0:
			game_state = GameState.MENU

			if game_ui != null:
				game_ui.show_main_menu()

		return

	if game_state != GameState.PLAYING:
		return

	if shift_timer_running:
		shift_time_remaining -= delta

		if shift_time_remaining <= 0.0:
			shift_time_remaining = 0.0
			end_shift(false)
			return
	time += delta

	if active_ingredient != null and can_drop:
		ingredient_x = sin(time * ingredient_speed) * ingredient_range
		active_ingredient.position = Vector3(ingredient_x, ingredient_start_y, 0)

	if active_ingredient != null and not can_drop:
		landing_elapsed += delta

		var settled: bool = is_body_settled(active_ingredient)
		var can_evaluate: bool = landing_elapsed >= minimum_landing_time and settled
		var force_evaluate: bool = landing_elapsed >= maximum_landing_time

		if can_evaluate or force_evaluate:
			evaluate_landing(active_ingredient)
			
			if game_state != GameState.PLAYING:
				update_ui()
				return
			
			spawn_ingredient()

	check_detached_stack_layers(delta)
	check_loose_ingredients(delta)
	update_best_stack_height()
	update_ui()

func _input(event: InputEvent) -> void:
	if game_state != GameState.PLAYING:
		return

	if is_game_paused:
		return

	if is_gameplay_input_blocked():
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton

		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if game_ui != null and game_ui.is_pointer_over_ui(mouse_event.position):
				return

			handle_click_or_tap()

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey

		if key_event.pressed and key_event.keycode == KEY_R:
			get_tree().reload_current_scene()

func handle_click_or_tap() -> void:
	if can_drop:
		request_drop()
	else:
		request_flip()

func request_drop() -> void:
	if active_ingredient == null:
		return

	last_result = "Dropping " + current_ingredient_name + "..."

	active_ingredient.freeze = false
	active_ingredient.gravity_scale = 1.18
	active_ingredient.linear_velocity = Vector3.ZERO
	active_ingredient.angular_velocity = Vector3.ZERO

	can_drop = false
	flip_available = true
	flip_used = false
	landing_elapsed = 0.0

func request_flip() -> void:
	if active_ingredient == null:
		return

	if not flip_available:
		return

	if flip_used:
		return

	active_ingredient.angular_velocity += Vector3(0, 0, flip_direction * flip_strength)

	last_result = "Flip used - land it for bonus!"

	flip_used = true
	flip_available = false
	flip_direction *= -1.0

func add_shift_time(seconds: float) -> void:
	if game_state != GameState.PLAYING:
		return

	if is_game_paused:
		return

	if add_time_charges <= 0:
		last_result = "No +5 charges left"
		update_ui()
		update_ability_ui()
		return

	add_time_charges -= 1
	shift_time_remaining += seconds

	last_result = "Added +" + str(int(seconds)) + " seconds (" + str(add_time_charges) + " left)"

	update_ui()
	update_ability_ui()

func calculate_add_time_max_charges() -> int:
	return add_time_base_charges + add_time_charge_upgrade_level

func calculate_add_time_charge_upgrade_cost() -> int:
	return add_time_charge_upgrade_base_cost + (add_time_charge_upgrade_level * add_time_charge_upgrade_cost_increase)

func reset_ability_charges() -> void:
	add_time_max_charges = calculate_add_time_max_charges()
	add_time_charges = add_time_max_charges
	update_ability_ui()

func update_ability_ui() -> void:
	if game_ui != null:
		game_ui.set_add_time_charges(add_time_charges, add_time_max_charges)

func update_upgrade_menu_ui() -> void:
	if game_ui == null:
		return

	game_ui.update_upgrade_menu(
		wallet_money,
		add_time_charge_upgrade_level,
		calculate_add_time_charge_upgrade_cost()
	)

func buy_add_time_charge_upgrade() -> void:
	var upgrade_cost: int = calculate_add_time_charge_upgrade_cost()

	if wallet_money < upgrade_cost:
		last_result = "Not enough money for Extra Time Charge upgrade ($" + str(upgrade_cost) + ")"
		update_ui()
		update_ability_ui()
		update_upgrade_menu_ui()
		return

	wallet_money -= upgrade_cost
	save_wallet_money()

	add_time_charge_upgrade_level += 1
	add_time_max_charges = calculate_add_time_max_charges()
	add_time_charges = add_time_max_charges

	save_restaurant_upgrades()

	last_result = "Bought Extra Time Charge Lv." + str(add_time_charge_upgrade_level) + " ($" + str(upgrade_cost) + ")"
	update_ui()
	update_ability_ui()
	update_upgrade_menu_ui()

func trash_current_ingredient() -> void:
	if active_ingredient == null:
		return

	if not can_drop:
		last_result = "Can't trash while ingredient is falling"
		return

	var trashed_name: String = current_ingredient_name

	active_ingredient.queue_free()
	active_ingredient = null
	
	last_result = trashed_name + " trashed"
	
	can_drop = true
	flip_available = false
	flip_used = false
	landing_elapsed = 0.0

	spawn_ingredient()

func get_missing_ingredients_for_active_orders() -> Array[String]:
	var missing_ingredient_names: Array[String] = []

	for stack_name: String in active_stack_names:
		var required_order: Array[String] = get_customer_order_for_stack(stack_name)
		var burger_ingredients: Array[String] = get_stack_ingredients(stack_name)
		var missing_for_stack: Array[String] = get_missing_ingredients(required_order, burger_ingredients)

		for ingredient_name: String in missing_for_stack:
			if not missing_ingredient_names.has(ingredient_name):
				missing_ingredient_names.append(ingredient_name)

	return missing_ingredient_names

func has_any_stack_ready_to_serve() -> bool:
	for stack_name: String in active_stack_names:
		if is_stack_order_ready_to_serve(stack_name):
			return true

	return false

func spawn_ingredient() -> void:
	var missing_ingredient_names: Array[String] = []
	var has_ready_order: bool = false
	
	if current_game_mode == GameMode.RESTAURANT:
		missing_ingredient_names = get_missing_ingredients_for_active_orders()
		has_ready_order = has_any_stack_ready_to_serve()

	var ingredient_data: Dictionary = ingredient_factory.choose_smart_ingredient(
		missing_ingredient_names,
		has_ready_order
	)
	current_ingredient_name = str(ingredient_data["name"])
	current_ingredient_width = float(ingredient_data["width"])
	current_ingredient_height = float(ingredient_data["height"])
	current_ingredient_depth = float(ingredient_data["depth"])
	current_ingredient_mass = float(ingredient_data["mass"])
	current_ingredient_color = ingredient_data["color"] as Color

	ingredient_x = sin(time * ingredient_speed) * ingredient_range

	active_ingredient = ingredient_factory.create_rigid_box(
		self,
		current_ingredient_name,
		Vector3(ingredient_x, ingredient_start_y, 0),
		Vector3(current_ingredient_width, current_ingredient_height, current_ingredient_depth),
		current_ingredient_color,
		current_ingredient_mass
	)

	active_ingredient.freeze = true
	can_drop = true
	flip_available = false
	flip_used = false
	landing_elapsed = 0.0

func evaluate_landing(body: RigidBody3D) -> void:
	if current_game_mode == GameMode.ENDLESS:
		evaluate_endless_landing(body)
	else:
		evaluate_restaurant_landing(body)

func evaluate_endless_landing(body: RigidBody3D) -> void:
	if body == null:
		return

	var final_x: float = body.position.x
	var body_width: float = get_body_projected_width(body)

	var target_stack: BurgerStack = get_target_stack(final_x, body_width)

	if target_stack == null:
		var missed_name: String = str(body.get_meta("ingredient_name"))
		last_result = missed_name + " missed the stack"
		add_loose_ingredient(body)
		active_ingredient = null
		update_endless_layer_score()
		return

	var support_ratio: float = target_stack.get_support_ratio(final_x, body_width)
	var ingredient_name: String = str(body.get_meta("ingredient_name"))

	if support_ratio >= 0.45:
		target_stack.add_layer(body)
		target_stack.increase_combo()

		update_endless_layer_score()

		last_result = "Layer " + str(endless_current_layers)

		if endless_current_layers >= endless_best_layers:
			last_result += " | New Best!"

	elif support_ratio >= 0.25:
		target_stack.add_layer(body)

		update_endless_layer_score()

		last_result = "Edge layer " + str(endless_current_layers)

		if endless_current_layers >= endless_best_layers:
			last_result += " | New Best!"

	else:
		target_stack.reset_combo()
		last_result = "Bad landing - keep the tower centered"
		add_loose_ingredient(body)

	active_ingredient = null

func update_endless_layer_score() -> void:
	var highest_layer_count: int = 0

	for stack: BurgerStack in burger_stacks:
		if stack == null:
			continue

		if not is_instance_valid(stack):
			continue
		
		if not active_stack_names.has(stack.get_stack_name()):
			continue
		
		var layer_count: int = stack.get_ingredient_layer_count()

		if layer_count > highest_layer_count:
			highest_layer_count = layer_count

	endless_current_layers = highest_layer_count

	if endless_current_layers > endless_best_layers:
		endless_best_layers = endless_current_layers

	if game_ui != null:
		game_ui.update_endless_goal(endless_current_layers, endless_best_layers)

func evaluate_restaurant_landing(body: RigidBody3D) -> void:
	if body == null:
		return

	var final_x: float = body.position.x
	var body_width: float = get_body_projected_width(body)

	var target_stack: BurgerStack = get_target_stack(final_x, body_width)

	if target_stack == null:
		var missed_name: String = str(body.get_meta("ingredient_name"))
		last_result = missed_name + " missed all burgers"
		change_run_money(-miss_penalty)
		add_loose_ingredient(body)
		active_ingredient = null
		return

	var support_ratio: float = target_stack.get_support_ratio(final_x, body_width)

	var flatness_angle_z: float = get_body_flatness_angle_z_degrees(body)
	var landed_flat: bool = flatness_angle_z < 28.0

	var ingredient_name: String = str(body.get_meta("ingredient_name"))
	var stack_name: String = target_stack.get_stack_name()

	if support_ratio >= 0.55:
		target_stack.add_layer(body)
		
		if ingredient_name == "Top Bun":
			deliver_stack_order(target_stack)
			active_ingredient = null
			return
		
		record_stack_ingredient(stack_name, ingredient_name)
		target_stack.increase_combo()
		
		if game_ui != null:
			game_ui.show_combo_popup(stack_name, target_stack.get_combo_count())
		update_best_stack_height()
		
		var combo_count: int = target_stack.get_combo_count()

		if landed_flat:
			last_result = "Good " + ingredient_name + " on " + stack_name
		else:
			last_result = "Unstable " + ingredient_name + " on " + stack_name

		last_result += " | Combo x" + str(combo_count)

		if flip_used:
			add_stack_style_bonus(stack_name, flip_delivery_bonus_money)
			last_result += " | Flip style +$" + str(flip_delivery_bonus_money)

	elif support_ratio >= 0.25:
		target_stack.add_layer(body)
		
		if ingredient_name == "Top Bun":
			deliver_stack_order(target_stack)
			active_ingredient = null
			return
		
		record_stack_ingredient(stack_name, ingredient_name)
		update_best_stack_height()

		last_result = "Edge landing on " + stack_name + " | Added to burger"

		if flip_used:
			add_stack_style_bonus(stack_name, flip_delivery_bonus_money)
			last_result += " | Flip style +$" + str(flip_delivery_bonus_money)


	else:
		target_stack.reset_combo()

		last_result = "Bad landing on " + stack_name + " -" + str(bad_landing_penalty)
		change_run_money(-bad_landing_penalty)
		add_loose_ingredient(body)

	active_ingredient = null

func get_height_bonus_for_stack(stack: BurgerStack) -> int:
	if stack == null:
		return 0

	if not is_instance_valid(stack):
		return 0

	var layer_count: int = stack.get_ingredient_layer_count()
	var extra_layers: int = layer_count - 1

	if extra_layers < 0:
		extra_layers = 0

	return extra_layers * height_bonus_per_extra_layer

func get_combo_bonus_for_stack(stack: BurgerStack) -> int:
	if stack == null:
		return 0

	if not is_instance_valid(stack):
		return 0

	var combo_count: int = stack.get_combo_count()
	var extra_combo: int = combo_count - 1

	if extra_combo < 0:
		extra_combo = 0

	return extra_combo * combo_bonus_per_extra_combo

func show_stack_money_feedback(
	stack_name: String,
	popup_text: String,
	money_delta: int
) -> void:
	if game_ui == null:
		return

	if game_ui.has_method("show_customer_money_feedback"):
		game_ui.show_customer_money_feedback(stack_name, popup_text, money_delta)

func count_ingredient_in_array(
	ingredient_names: Array[String],
	ingredient_name_to_count: String
) -> int:
	var count: int = 0

	for ingredient_name: String in ingredient_names:
		if ingredient_name == ingredient_name_to_count:
			count += 1

	return count

func is_extra_ingredient_for_stack(stack_name: String, ingredient_name: String) -> bool:
	var required_order: Array[String] = get_customer_order_for_stack(stack_name)
	var current_stack_ingredients: Array[String] = get_stack_ingredients(stack_name)

	var required_count: int = count_ingredient_in_array(required_order, ingredient_name)
	var current_count: int = count_ingredient_in_array(current_stack_ingredients, ingredient_name)

	return current_count >= required_count

func show_extra_layer_feedback_if_needed(stack_name: String, ingredient_name: String) -> void:
	if not is_extra_ingredient_for_stack(stack_name, ingredient_name):
		return

	var preference_type: String = get_customer_preference_for_stack(stack_name)

	if preference_type == "exact":
		show_stack_money_feedback(
			stack_name,
			"Extra -$" + str(exact_extra_layer_penalty),
			-exact_extra_layer_penalty
		)
	else:
		show_stack_money_feedback(
			stack_name,
			"Extra +$" + str(tip_per_extra_layer),
			tip_per_extra_layer
		)

func add_stack_style_bonus(stack_name: String, amount: int) -> void:
	var current_bonus: int = int(stack_style_bonuses.get(stack_name, 0))
	stack_style_bonuses[stack_name] = current_bonus + amount

	if amount > 0:
		show_stack_money_feedback(
			stack_name,
			"Style +$" + str(amount),
			amount
		)

	refresh_customer_progress(stack_name)

func get_stack_style_bonus(stack_name: String) -> int:
	return int(stack_style_bonuses.get(stack_name, 0))

func clear_stack_style_bonus(stack_name: String) -> void:
	stack_style_bonuses[stack_name] = 0

func get_customer_preference_for_stack(stack_name: String) -> String:
	return str(customer_preferences.get(stack_name, "tip_lover"))

func get_matched_required_count_for_order(
	required_order: Array[String],
	burger_ingredients: Array[String]
) -> int:
	var matched_count: int = 0
	var remaining_burger_ingredients: Array[String] = burger_ingredients.duplicate()

	for required_ingredient: String in required_order:
		var index: int = remaining_burger_ingredients.find(required_ingredient)

		if index != -1:
			matched_count += 1
			remaining_burger_ingredients.remove_at(index)

	return matched_count

func calculate_order_result(stack_name: String) -> Dictionary:
	var required_order: Array[String] = get_customer_order_for_stack(stack_name)
	var burger_ingredients: Array[String] = get_stack_ingredients(stack_name)
	var preference_type: String = get_customer_preference_for_stack(stack_name)

	var required_count: int = required_order.size()
	var matched_count: int = get_matched_required_count_for_order(required_order, burger_ingredients)

	var missing_count: int = required_count - matched_count

	if missing_count < 0:
		missing_count = 0

	var extra_layer_count: int = burger_ingredients.size() - matched_count

	if extra_layer_count < 0:
		extra_layer_count = 0

	var base_complete_money: int = complete_order_base_money + (required_count * money_per_required_ingredient)
	var extra_adjustment_money: int = 0

	if preference_type == "exact":
		extra_adjustment_money = -(extra_layer_count * exact_extra_layer_penalty)
	else:
		extra_adjustment_money = extra_layer_count * tip_per_extra_layer

	var style_bonus: int = get_stack_style_bonus(stack_name)

	var complete_money: int = base_complete_money + extra_adjustment_money + style_bonus

	if complete_money < incomplete_order_money:
		complete_money = incomplete_order_money

	var is_complete: bool = missing_count <= 0

	var delivery_money: int = incomplete_order_money

	if is_complete:
		delivery_money = complete_money

	var result: Dictionary = {}
	result["stack_name"] = stack_name
	result["required_order"] = required_order
	result["burger_ingredients"] = burger_ingredients
	result["preference_type"] = preference_type
	result["required_count"] = required_count
	result["matched_count"] = matched_count
	result["missing_count"] = missing_count
	result["extra_layer_count"] = extra_layer_count
	result["base_complete_money"] = base_complete_money
	result["extra_adjustment_money"] = extra_adjustment_money
	result["style_bonus"] = style_bonus
	result["complete_money"] = complete_money
	result["delivery_money"] = delivery_money
	result["is_complete"] = is_complete

	return result

func build_payout_preview_text(stack_name: String) -> String:
	var result: Dictionary = calculate_order_result(stack_name)

	var missing_count: int = int(result["missing_count"])
	var extra_layer_count: int = int(result["extra_layer_count"])
	var preference_type: String = str(result["preference_type"])
	var complete_money: int = int(result["complete_money"])
	var delivery_money: int = int(result["delivery_money"])
	var style_bonus: int = int(result["style_bonus"])

	var adjustment_parts: Array[String] = []

	if extra_layer_count > 0:
		if preference_type == "exact":
			adjustment_parts.append("Extra -$" + str(extra_layer_count * exact_extra_layer_penalty))
		else:
			adjustment_parts.append("Extra +$" + str(extra_layer_count * tip_per_extra_layer))
	else:
		adjustment_parts.append("Extra 0")

	if style_bonus > 0:
		adjustment_parts.append("Style +$" + str(style_bonus))

	var adjustment_text: String = " | ".join(adjustment_parts)

	if missing_count > 0:
		return "Missing " + str(missing_count) + " -> $" + str(complete_money) + "\nEarly serve $" + str(delivery_money) + " | " + adjustment_text

	return "READY: $" + str(delivery_money) + "\n" + adjustment_text

func is_stack_order_ready_to_serve(stack_name: String) -> bool:
	var result: Dictionary = calculate_order_result(stack_name)

	var required_count: int = int(result["required_count"])

	if required_count <= 0:
		return false

	return bool(result["is_complete"])

func refresh_serve_prompt(stack_name: String) -> void:
	if game_ui == null:
		return

	var should_show: bool = false

	if game_state == GameState.PLAYING:
		should_show = is_stack_order_ready_to_serve(stack_name)

	game_ui.update_serve_prompt(stack_name, should_show)

func hide_all_serve_prompts() -> void:
	if game_ui == null:
		return

	for stack_name: String in active_stack_names:
		game_ui.update_serve_prompt(stack_name, false)

func refresh_customer_progress(stack_name: String) -> void:
	if game_ui == null:
		return

	game_ui.update_customer_progress(
		stack_name,
		get_stack_ingredients(stack_name),
		build_payout_preview_text(stack_name)
	)

	refresh_serve_prompt(stack_name)

func record_stack_ingredient(stack_name: String, ingredient_name: String) -> void:
	if ingredient_name == "Top Bun":
		return

	show_extra_layer_feedback_if_needed(stack_name, ingredient_name)

	var target_ingredients: Array = stack_ingredients.get(stack_name, [])
	target_ingredients.append(ingredient_name)
	stack_ingredients[stack_name] = target_ingredients

	refresh_customer_progress(stack_name)

func remove_stack_ingredient(stack_name: String, ingredient_name: String) -> void:
	if ingredient_name == "Top Bun":
		return

	if not stack_ingredients.has(stack_name):
		return

	var target_ingredients: Array = stack_ingredients[stack_name]
	var index: int = target_ingredients.size() - 1

	while index >= 0:
		if str(target_ingredients[index]) == ingredient_name:
			target_ingredients.remove_at(index)
			stack_ingredients[stack_name] = target_ingredients
			refresh_customer_progress(stack_name)
			return

		index -= 1

func get_stack_ingredients(stack_name: String) -> Array[String]:
	var typed_ingredients: Array[String] = []

	if not stack_ingredients.has(stack_name):
		return typed_ingredients

	var stored_ingredients: Array = stack_ingredients[stack_name]

	for ingredient_name in stored_ingredients:
		typed_ingredients.append(str(ingredient_name))

	return typed_ingredients

func get_customer_order_for_stack(stack_name: String) -> Array[String]:
	var typed_order: Array[String] = []

	if not customer_orders.has(stack_name):
		return typed_order

	var stored_order: Array = customer_orders[stack_name]

	for ingredient_name in stored_order:
		typed_order.append(str(ingredient_name))

	return typed_order

func get_missing_ingredients(required_order: Array[String], burger_ingredients: Array[String]) -> Array[String]:
	var missing: Array[String] = []

	for required_ingredient: String in required_order:
		if not burger_ingredients.has(required_ingredient):
			missing.append(required_ingredient)

	return missing

func assign_new_customer_order_for_stack(stack_name: String) -> void:
	customer_orders[stack_name] = generate_customer_order()
	customer_preferences[stack_name] = generate_customer_preference()

	setup_customer_ui()
	refresh_all_customer_progress()

func clear_tracked_stack_ingredients(stack_name: String) -> void:
	stack_ingredients[stack_name] = []

func deliver_stack_order(target_stack: BurgerStack) -> void:
	if target_stack == null:
		return

	var stack_name: String = target_stack.get_stack_name()
	var result: Dictionary = calculate_order_result(stack_name)

	var required_order: Array[String] = result["required_order"]
	var burger_ingredients: Array[String] = result["burger_ingredients"]
	var missing_ingredients: Array[String] = get_missing_ingredients(required_order, burger_ingredients)

	var is_complete: bool = bool(result["is_complete"])
	var delivery_money: int = int(result["delivery_money"])
	var extra_adjustment_money: int = int(result["extra_adjustment_money"])
	var style_bonus: int = int(result["style_bonus"])
	var preference_type: String = str(result["preference_type"])

	change_run_money(delivery_money)

	if is_complete:
		last_result = "Delivered order " + stack_name + " +$" + str(delivery_money)

		if preference_type == "exact" and extra_adjustment_money < 0:
			last_result += " | extra penalty -$" + str(abs(extra_adjustment_money))
		elif preference_type == "tip_lover" and extra_adjustment_money > 0:
			last_result += " | tip +$" + str(extra_adjustment_money)

		if style_bonus > 0:
			last_result += " | style +$" + str(style_bonus)
	else:
		last_result = "Early delivery " + stack_name + " +$" + str(delivery_money)

		if missing_ingredients.size() > 0:
			last_result += " | Missing: " + ", ".join(missing_ingredients)

	target_stack.clear_ingredient_layers()
	clear_tracked_stack_ingredients(stack_name)
	clear_stack_style_bonus(stack_name)

	if is_complete:
		record_customer_served()

	if game_state == GameState.PLAYING:
		assign_new_customer_order_for_stack(stack_name)
		update_best_stack_height()

func update_best_stack_height() -> void:
	for stack: BurgerStack in burger_stacks:
		if stack == null:
			continue

		if not is_instance_valid(stack):
			continue

		var layer_count: int = stack.get_ingredient_layer_count()

		if layer_count > best_stack_height:
			best_stack_height = layer_count

func get_stack_summary_text() -> String:
	var result: String = "Stacks: "

	var index: int = 0

	while index < burger_stacks.size():
		var stack: BurgerStack = burger_stacks[index]

		if stack != null and is_instance_valid(stack):
			if index > 0:
				result += " | "

			result += stack.get_stack_name()
			result += " " + str(stack.get_ingredient_layer_count())
			result += " x" + str(stack.get_combo_count())

		index += 1

	result += " | Best " + str(best_stack_height)

	return result

func get_body_projected_width(body: Node3D) -> float:
	var width: float = get_body_stack_width(body)
	var height: float = get_body_stack_height(body)
	var angle: float = wrapf(body.rotation.z, -PI, PI)

	var projected_width: float = abs(cos(angle)) * width + abs(sin(angle)) * height

	if projected_width < 0.05:
		return 0.05

	return projected_width

func get_body_flatness_angle_z_degrees(body: Node3D) -> float:
	var raw_angle: float = abs(rad_to_deg(wrapf(body.rotation.z, -PI, PI)))

	if raw_angle > 90.0:
		return 180.0 - raw_angle

	return raw_angle

func get_target_stack(x: float, body_width: float) -> BurgerStack:
	var best_stack: BurgerStack = null
	var best_support_ratio: float = 0.0

	for stack: BurgerStack in burger_stacks:
		if stack == null:
			continue

		if not is_instance_valid(stack):
			continue
		
		if not active_stack_names.has(stack.get_stack_name()):
			continue
		
		var support_ratio: float = stack.get_support_ratio(x, body_width)

		if support_ratio > best_support_ratio:
			best_support_ratio = support_ratio
			best_stack = stack

	if best_support_ratio >= 0.15:
		return best_stack

	return null

func add_loose_ingredient(body: Node3D) -> void:
	if body == null:
		return

	if not is_instance_valid(body):
		return

	if not loose_ingredients.has(body):
		body.set_meta("cleanup_timer", loose_cleanup_delay)
		loose_ingredients.append(body)

func check_loose_ingredients(delta: float) -> void:
	var index: int = loose_ingredients.size() - 1

	while index >= 0:
		var body: Node3D = loose_ingredients[index]

		if body == null or not is_instance_valid(body):
			loose_ingredients.remove_at(index)
			index -= 1
			continue

		var timer: float = loose_cleanup_delay

		if body.has_meta("cleanup_timer"):
			timer = float(body.get_meta("cleanup_timer"))

		timer -= delta
		body.set_meta("cleanup_timer", timer)

		var should_remove: bool = false

		if timer <= 0.0:
			should_remove = true

		if body.position.y < loose_fall_y_limit:
			should_remove = true

		if abs(body.position.x) > loose_max_distance_from_center:
			should_remove = true

		if should_remove:
			loose_ingredients.remove_at(index)
			body.queue_free()

		index -= 1

func check_detached_stack_layers(delta: float) -> void:
	for stack: BurgerStack in burger_stacks:
		if stack == null:
			continue

		if not is_instance_valid(stack):
			continue

		var detached_layers: Array[Node3D] = stack.collect_detached_layers(
			delta,
			stack_fall_y_limit,
			max_distance_from_plate,
			max_detach_tilt_degrees,
			low_detach_y_limit
		)

		if detached_layers.size() <= 0:
			continue

		stack.reset_combo()
		
		var penalty: int = detached_layers.size() * fallen_layer_penalty

		if current_game_mode != GameMode.ENDLESS:
			change_run_money(-penalty)

		for detached_layer: Node3D in detached_layers:
			if detached_layer != null and is_instance_valid(detached_layer):
				if detached_layer.has_meta("ingredient_name"):
					var detached_ingredient_name: String = str(detached_layer.get_meta("ingredient_name"))
					remove_stack_ingredient(stack.get_stack_name(), detached_ingredient_name)

				add_loose_ingredient(detached_layer)
			

		if current_game_mode == GameMode.ENDLESS:
			if detached_layers.size() == 1:
				last_result = "A layer fell from the tower"
			else:
				last_result = str(detached_layers.size()) + " layers fell from the tower"

			update_endless_layer_score()
		else:
			if detached_layers.size() == 1:
				last_result = "A stacked ingredient fell from " + stack.get_stack_name() + " -" + str(penalty)
			else:
				last_result = str(detached_layers.size()) + " ingredients fell from " + stack.get_stack_name() + " -" + str(penalty)

func is_body_settled(body: RigidBody3D) -> bool:
	if body == null:
		return false

	var linear_speed: float = body.linear_velocity.length()
	var angular_speed: float = abs(body.angular_velocity.z)

	if body.position.y < -1.0:
		return true

	return linear_speed < 0.14 and angular_speed < 0.38

func get_body_stack_width(body: Node3D) -> float:
	if body.has_meta("stack_width"):
		return float(body.get_meta("stack_width"))

	return current_ingredient_width

func get_body_stack_height(body: Node3D) -> float:
	if body.has_meta("stack_height"):
		return float(body.get_meta("stack_height"))

	return current_ingredient_height

func update_ui() -> void:
	if game_ui == null:
		return

	game_ui.update_wallet_money(wallet_money)
	
	if current_game_mode != GameMode.ENDLESS:
		game_ui.update_shift_time(shift_time_remaining)	
		
	if current_game_mode == GameMode.ENDLESS:
		game_ui.update_endless_goal(endless_current_layers, endless_best_layers)
	else:
		game_ui.update_stage_goal(
			current_stage,
			customers_served_this_stage,
			customers_required_this_stage
		)

	var trash_enabled: bool = active_ingredient != null and can_drop

	if current_game_mode == GameMode.ENDLESS:
		game_ui.update_endless_result(last_result)
	else:
		game_ui.update_info(
			run_money,
			wallet_money,
			current_ingredient_name,
			get_stack_summary_text(),
			last_result,
			trash_enabled
		)
