extends Control

const ROOM_COUNT := 100
const GRID_WIDTH := 10
const SEAL_ROOMS := [18, 57, 83]
const DIRECTIONS := ["North", "East", "South", "West"]
const WINGS := [
	"The West Wing", "The East Wing", "The Gallery Wing", "The Library Wing",
	"The Conservatory Wing", "The Servants' Wing", "The Tower Wing",
	"The Chapel Wing", "The Cellar Wing", "The East Annex"
]
const LOCATIONS := [
	"Grand Foyer", "Portrait Gallery", "Music Room", "Winter Garden",
	"Blue Parlour", "Clock Room", "Map Chamber", "Old Kitchen",
	"Family Study", "Moonlit Landing"
]
const HIDDEN_OBJECTS := [
	"silver thimble", "brass key", "velvet ribbon", "cracked pocket watch",
	"ivory comb", "glass butterfly", "copper bell", "porcelain bird",
	"black feather", "wax seal", "faded photograph", "amber brooch",
	"tiny compass", "lace glove", "blue marble", "golden locket",
	"folded letter", "music box", "carved rook", "crystal vial"
]
const OBJECT_CLUES := [
	"Something used for careful sewing, small enough to hide in a palm.",
	"A little piece of metal that opens what should stay locked.",
	"A soft strip of cloth, tied once and then forgotten.",
	"A timepiece that no longer keeps time.",
	"A pale grooming tool with a missing tooth.",
	"A delicate winged insect, made of glass instead of dust.",
	"A small metal instrument that calls someone from another room.",
	"A bird that cannot fly, painted in white and blue.",
	"A dark plume left behind by a visitor who never signed the book.",
	"A mark of red wax pressed with an unknown crest.",
	"A captured moment, worn at the edges by years of handling.",
	"A warm-colored ornament once pinned close to the heart.",
	"A guide that points the way even when the halls do not.",
	"A single hand covering for a formal occasion.",
	"A round piece of blue glass, smooth from being handled.",
	"A piece of jewelry that keeps a secret close to its owner.",
	"A message folded small enough to pass unnoticed.",
	"A little instrument that remembers a tune after its player is gone.",
	"A carved chess piece that moves in a crooked line.",
	"A small container holding a clear, unexplained liquid."
]
const RIDDLES = [
	{
		"question": "I speak without a mouth and answer without a mind. What am I?",
		"answer": "An echo",
		"wrong": ["A candle", "A key", "A portrait"]
	},
	{
		"question": "The more you take from me, the more you leave behind. What am I?",
		"answer": "Footsteps",
		"wrong": ["A secret", "A candle", "A mirror"]
	},
	{
		"question": "I have hands but cannot clap, and a face but no eyes. What am I?",
		"answer": "A clock",
		"wrong": ["A portrait", "A glove", "A book"]
	},
	{
		"question": "I am always ahead of you, yet can never be seen. What am I?",
		"answer": "The future",
		"wrong": ["A shadow", "A ghost", "The past"]
	},
	{
		"question": "What belongs to you, but is used more by everyone else?",
		"answer": "Your name",
		"wrong": ["Your shadow", "Your key", "Your home"]
	}
]

var randomizer := RandomNumberGenerator.new()
var passages: Array[Dictionary] = []
var visited: Array[bool] = []
var completed: Array[bool] = []
var current_room := 0
var found_seals: Array[int] = []
var case_solved := false
var feedback := ""
var stage: PanelContainer
var room_status: Label
var content: VBoxContainer


func _ready() -> void:
	randomizer.seed = 472
	_build_maze()
	visited.resize(ROOM_COUNT)
	visited.fill(false)
	completed.resize(ROOM_COUNT)
	completed.fill(false)
	visited[0] = true
	_build_interface()
	_show_title()


func _build_maze() -> void:
	passages.clear()
	for _room in ROOM_COUNT:
		passages.append({"North": -1, "East": -1, "South": -1, "West": -1})

	var carved: Array[bool] = []
	carved.resize(ROOM_COUNT)
	carved.fill(false)
	var stack: Array[int] = [0]
	carved[0] = true

	while not stack.is_empty():
		var room: int = stack[-1]
		var x := room % GRID_WIDTH
		var y := int(room / GRID_WIDTH)
		var options: Array[Dictionary] = []
		if y > 0 and not carved[room - GRID_WIDTH]:
			options.append({"room": room - GRID_WIDTH, "out": "North", "back": "South"})
		if x < GRID_WIDTH - 1 and not carved[room + 1]:
			options.append({"room": room + 1, "out": "East", "back": "West"})
		if y < GRID_WIDTH - 1 and not carved[room + GRID_WIDTH]:
			options.append({"room": room + GRID_WIDTH, "out": "South", "back": "North"})
		if x > 0 and not carved[room - 1]:
			options.append({"room": room - 1, "out": "West", "back": "East"})

		if options.is_empty():
			stack.pop_back()
			continue

		var passage: Dictionary = options[randomizer.randi_range(0, options.size() - 1)]
		var next_room: int = passage["room"]
		passages[room][passage["out"]] = next_room
		passages[next_room][passage["back"]] = room
		carved[next_room] = true
		stack.append(next_room)

	for room in ROOM_COUNT:
		var x := room % GRID_WIDTH
		var y := int(room / GRID_WIDTH)
		if x < GRID_WIDTH - 1 and passages[room]["East"] == -1 and randomizer.randf() < 0.12:
			passages[room]["East"] = room + 1
			passages[room + 1]["West"] = room
		if y < GRID_WIDTH - 1 and passages[room]["South"] == -1 and randomizer.randf() < 0.12:
			passages[room]["South"] = room + GRID_WIDTH
			passages[room + GRID_WIDTH]["North"] = room


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#101414")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var wordmark := _label("B L A C K T H O R N   M A N O R", 16, Color("#c9b47c"))
	wordmark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(wordmark)
	room_status = _label("A CASE OF VANISHING", 13, Color("#9aaba4"))
	room_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(room_status)

	stage = PanelContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", _panel_style())
	layout.add_child(stage)

	var footer := _label("A mystery adventure  ·  100 rooms  ·  Explore with the passage buttons", 12, Color("#788780"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(footer)


func _show_title() -> void:
	room_status.text = "A CASE OF VANISHING"
	_clear_stage()
	content.add_child(_label("A HOUSE THAT\nREMEMBERS", 42, Color("#eee6d1")))
	content.add_child(_label("THE VANISHING AT BLACKTHORN MANOR", 14, Color("#c9b47c")))
	content.add_child(_spacer(18))
	content.add_child(_label(
		"On a rain-soaked October night, every clock in Blackthorn Manor stopped at 11:17. "
		+ "By morning, the master of the house had vanished—and so had the key to the front door.",
		19, Color("#c3cbc3")
	))
	content.add_child(_label(
		"Search forgotten rooms for hidden evidence, solve the riddles left by the household, "
		+ "and find your way through a shifting maze of corridors. Three seals stand between "
		+ "you and the manor's locked archive.",
		16, Color("#9aaba4")
	))
	content.add_child(_spacer(10))
	var begin := _button("ENTER THE MANOR", _begin_game, true)
	begin.custom_minimum_size = Vector2(300, 56)
	content.add_child(begin)
	content.add_child(_label("Choose a passage to move through the manor.", 13, Color("#788780")))


func _begin_game() -> void:
	_render_room()


func _render_room() -> void:
	room_status.text = "%d / %d ROOMS DISCOVERED   ·   %d / 3 SEALS" % [
		_count_true(visited), ROOM_COUNT, found_seals.size()
	]
	_clear_stage()
	var title := _label(_room_title(current_room), 30, Color("#eee6d1"))
	content.add_child(title)
	content.add_child(_label(
		"%s   ·   ROOM %02d" % [_room_type_label(current_room), current_room + 1],
		13, Color("#c9b47c")
	))
	content.add_child(_label(_room_description(current_room), 16, Color("#b2beb5")))

	var separator := HSeparator.new()
	content.add_child(separator)

	if case_solved:
		_show_ending()
	elif current_room == ROOM_COUNT - 1:
		_show_archive()
	else:
		_show_room_activity()

	content.add_child(_spacer(4))
	content.add_child(_label("PASSAGES", 13, Color("#c9b47c")))
	var passage_row := GridContainer.new()
	passage_row.columns = 2
	passage_row.add_theme_constant_override("separation", 10)
	content.add_child(passage_row)
	for direction in DIRECTIONS:
		var destination: int = passages[current_room][direction]
		if destination < 0:
			continue
		var destination_text := "%s  →  %s" % [direction.to_upper(), _short_room_title(destination)]
		var navigation := _button(destination_text, _travel.bind(destination))
		navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		passage_row.add_child(navigation)

	var return_button := _button("CASE NOTES", _show_title)
	return_button.custom_minimum_size = Vector2(150, 44)
	content.add_child(return_button)


func _show_room_activity() -> void:
	if completed[current_room]:
		content.add_child(_label(
			"You have searched this room and recorded its evidence. Its silence feels less hostile now.",
			16, Color("#92b69e")
		))
		return

	if SEAL_ROOMS.has(current_room):
		_show_seal_puzzle()
	elif current_room % 5 == 0:
		content.add_child(_label(
			"The corridor turns back on itself. Only the passages below are safe; listen for the draft before choosing.",
			16, Color("#c3cbc3")
		))
		_mark_complete(current_room)
	elif current_room % 4 == 0:
		_show_riddle()
	else:
		_show_hidden_object()


func _show_hidden_object() -> void:
	var object_index := (current_room * 7 + 3) % HIDDEN_OBJECTS.size()
	content.add_child(_label("HIDDEN OBJECT SEARCH", 18, Color("#eee6d1")))
	content.add_child(_label("Clue: " + OBJECT_CLUES[object_index], 16, Color("#c3cbc3")))
	content.add_child(_label("Which object belongs in the case notes?", 14, Color("#9aaba4")))

	var choices: Array[String] = [HIDDEN_OBJECTS[object_index]]
	for offset in [4, 9, 13]:
		choices.append(HIDDEN_OBJECTS[(object_index + offset) % HIDDEN_OBJECTS.size()])
	choices.shuffle()
	for object_name in choices:
		var find_button := _button("Search for the %s" % object_name, _search_for.bind(object_name, HIDDEN_OBJECTS[object_index]))
		find_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(find_button)
	_show_feedback()


func _show_riddle() -> void:
	var riddle: Dictionary = RIDDLES[int(current_room / 4) % RIDDLES.size()]
	content.add_child(_label("THE HOUSEHOLD'S RIDDLE", 18, Color("#eee6d1")))
	content.add_child(_label(riddle["question"], 17, Color("#c3cbc3")))
	var choices: Array[String] = [riddle["answer"]]
	for wrong_answer in riddle["wrong"]:
		choices.append(wrong_answer)
	choices.shuffle()
	for answer in choices:
		var answer_button := _button(answer, _answer_riddle.bind(answer, riddle["answer"]))
		answer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(answer_button)
	_show_feedback()


func _show_seal_puzzle() -> void:
	var seal_index := SEAL_ROOMS.find(current_room)
	var riddle: Dictionary = RIDDLES[seal_index % RIDDLES.size()]
	content.add_child(_label("A SEAL OF THE MANOR", 18, Color("#eee6d1")))
	content.add_child(_label(
		"A brass seal guards a page from the missing master's journal. Answer the inscription to claim it.",
		16, Color("#c3cbc3")
	))
	content.add_child(_label(riddle["question"], 16, Color("#c9b47c")))
	var choices: Array[String] = [riddle["answer"]]
	for wrong_answer in riddle["wrong"]:
		choices.append(wrong_answer)
	choices.shuffle()
	for answer in choices:
		var answer_button := _button(answer, _answer_seal.bind(answer, riddle["answer"]))
		answer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(answer_button)
	_show_feedback()


func _show_archive() -> void:
	content.add_child(_label("THE LOCKED ARCHIVE", 18, Color("#eee6d1")))
	if found_seals.size() < SEAL_ROOMS.size():
		content.add_child(_label(
			"The archive door bears three empty impressions. Recover all three seals before attempting to enter.",
			16, Color("#c3cbc3")
		))
		content.add_child(_label("Seals recovered: %d / 3" % found_seals.size(), 14, Color("#c9b47c")))
		return

	content.add_child(_label(
		"The three seals turn in their sockets. Inside, a letter reveals that the master staged his disappearance "
		+ "to expose the person who had been secretly altering the manor's clocks.",
		17, Color("#c3cbc3")
	))
	var finish := _button("READ THE FINAL PAGE", _solve_case, true)
	finish.custom_minimum_size = Vector2(300, 54)
	content.add_child(finish)


func _show_ending() -> void:
	content.add_child(_label("THE CASE IS CLOSED", 22, Color("#c9b47c")))
	content.add_child(_label(
		"You found the master alive in the old bell tower. He confesses to the deception, "
		+ "and Blackthorn Manor's clocks begin to tick again.",
		18, Color("#c3cbc3")
	))
	content.add_child(_label(
		"Rooms explored: %d / %d   ·   Evidence recorded: %d" % [
			_count_true(visited), ROOM_COUNT, _count_true(completed)
		],
		14, Color("#9aaba4")
	))


func _search_for(selected: String, target: String) -> void:
	if selected != target:
		feedback = "Not this time. Re-read the clue and search among the remaining objects."
		_render_room()
		return
	_mark_complete(current_room)
	feedback = "Found: %s. The evidence has been added to your case notes." % target
	_render_room()


func _answer_riddle(selected: String, target: String) -> void:
	if selected != target:
		feedback = "The inscription stays dark. Consider the riddle once more."
		_render_room()
		return
	_mark_complete(current_room)
	feedback = "The answer is accepted. You have recorded a piece of the household's history."
	_render_room()


func _answer_seal(selected: String, target: String) -> void:
	if selected != target:
		feedback = "The seal remains shut. Try another answer."
		_render_room()
		return
	if not found_seals.has(current_room):
		found_seals.append(current_room)
	_mark_complete(current_room)
	feedback = "The brass seal is yours. One more page of the journal is yours to keep."
	_render_room()


func _travel(destination: int) -> void:
	current_room = destination
	visited[current_room] = true
	feedback = ""
	_render_room()


func _solve_case() -> void:
	case_solved = true
	_mark_complete(ROOM_COUNT - 1)
	_render_room()


func _mark_complete(room: int) -> void:
	completed[room] = true


func _room_title(room: int) -> String:
	return "%s — %s" % [WINGS[int(room / GRID_WIDTH)], LOCATIONS[room % GRID_WIDTH]]


func _short_room_title(room: int) -> String:
	return LOCATIONS[room % GRID_WIDTH]


func _room_type_label(room: int) -> String:
	if room == ROOM_COUNT - 1:
		return "THE FINAL CHAMBER"
	if SEAL_ROOMS.has(room):
		return "JOURNAL SEAL"
	if room % 5 == 0:
		return "LABYRINTH PASSAGE"
	if room % 4 == 0:
		return "HOUSEHOLD PUZZLE"
	return "HIDDEN OBJECTS"


func _room_description(room: int) -> String:
	if room % 5 == 0:
		return "A narrow, shifting passage divides the manor. The air carries a faint smell of rain and extinguished candles."
	if room % 4 == 0 or SEAL_ROOMS.has(room):
		return "Dust lies undisturbed except for a single fresh line leading to an inscription on the wall."
	return "The room is frozen in the instant its last occupant left. Something small has been overlooked among the furnishings."


func _show_feedback() -> void:
	if not feedback.is_empty():
		content.add_child(_label(feedback, 14, Color("#d7bd82")))


func _clear_stage() -> void:
	for child in stage.get_children():
		stage.remove_child(child)
		child.free()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	stage.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)


func _label(text: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result


func _button(text: String, callback: Callable, primary := false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(0, 46)
	result.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	result.add_theme_font_size_override("font_size", 14)
	var base_color := Color("#85744c") if primary else Color("#29332f")
	result.add_theme_stylebox_override("normal", _button_style(base_color))
	result.add_theme_stylebox_override("hover", _button_style(base_color.lightened(0.16)))
	result.add_theme_stylebox_override("pressed", _button_style(base_color.darkened(0.14)))
	result.add_theme_stylebox_override("focus", _button_style(Color("#c9b47c")))
	result.add_theme_color_override("font_color", Color("#eee6d1"))
	result.add_theme_color_override("font_hover_color", Color("#ffffff"))
	result.pressed.connect(callback)
	return result


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#536159")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1b2421")
	style.border_color = Color("#39453f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _spacer(height: int) -> Control:
	var result := Control.new()
	result.custom_minimum_size.y = height
	return result


func _count_true(values: Array[bool]) -> int:
	var total := 0
	for value in values:
		if value:
			total += 1
	return total
