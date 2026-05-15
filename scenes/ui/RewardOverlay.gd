extends CanvasLayer
class_name RewardOverlay

signal reward_selected(choice: Dictionary)

var title_label: Label
var status_label: Label
var cards_box: HBoxContainer
var buttons: Array[Button] = []
var choices: Array[Dictionary] = []
var selected_index := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	layer = 100
	_build_ui()

func show_choices(title: String, status: String, reward_choices: Array[Dictionary]) -> void:
	choices = reward_choices
	selected_index = 0
	title_label.text = title
	status_label.text = status
	_rebuild_cards()
	visible = true
	_update_selection()

func hide_overlay() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_A, KEY_W, KEY_LEFT, KEY_UP:
			_move_selection(-1)
			get_viewport().set_input_as_handled()
		KEY_D, KEY_S, KEY_RIGHT, KEY_DOWN:
			_move_selection(1)
			get_viewport().set_input_as_handled()
		KEY_SPACE, KEY_ENTER:
			_confirm_selection()
			get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 48
	center.offset_top = 48
	center.offset_right = -48
	center.offset_bottom = -48
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 360)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	box.add_child(title_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(status_label)

	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 16)
	box.add_child(cards_box)

	var hint := Label.new()
	hint.text = "WASD / 方向键选择，空格 / 回车确认"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

func _rebuild_cards() -> void:
	for child in cards_box.get_children():
		child.queue_free()
	buttons.clear()
	for i in range(choices.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(270, 190)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.focus_mode = Control.FOCUS_NONE
		button.text = String(choices[i].get("label", "奖励"))
		var index := i
		button.mouse_entered.connect(func() -> void:
			selected_index = index
			_update_selection()
		)
		button.pressed.connect(func() -> void:
			selected_index = index
			_confirm_selection_at(index)
		)
		cards_box.add_child(button)
		buttons.append(button)

func _move_selection(offset: int) -> void:
	if buttons.is_empty():
		return
	selected_index = wrapi(selected_index + offset, 0, buttons.size())
	_update_selection()

func _update_selection() -> void:
	for i in range(buttons.size()):
		var button := buttons[i]
		var label := String(choices[i].get("label", "奖励"))
		if i == selected_index:
			button.text = "▶\n%s" % label
			button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.45))
		else:
			button.text = label
			button.remove_theme_color_override("font_color")

func _confirm_selection() -> void:
	_confirm_selection_at(selected_index)

func _confirm_selection_at(index: int) -> void:
	selected_index = index
	if selected_index < 0 or selected_index >= choices.size():
		return
	reward_selected.emit(choices[selected_index].duplicate())
