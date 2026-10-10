class_name GarageScreen
extends Control

const TITLE_SCENE := "res://scenes/menu/title.tscn"
const ROWS: Array[String] = ["motor", "tope", "nitro"]
const NAMES := {"motor": "Motor", "tope": "Tope", "nitro": "Nitro"}

var auto_change_scene := true
var closed := false
var selection := 0
var progress := Progress.new()
var _rows: Array[Label] = []

@onready var _money_label: Label = %MoneyLabel


func _ready() -> void:
	theme = preload("res://ui/rushline_theme.tres")
	_rows = [%RowMotor, %RowTope, %RowNitro]
	progress = Progress.load_state()
	for index in _rows.size():
		var row := _rows[index]
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_row_click.bind(index))
		row.mouse_entered.connect(_on_row_hover.bind(index))
	refresh()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_up"):
		selection = posmod(selection - 1, ROWS.size())
		refresh()
	elif Input.is_action_just_pressed("ui_down"):
		selection = posmod(selection + 1, ROWS.size())
		refresh()
	elif Input.is_action_just_pressed("ui_accept"):
		buy_selected()
	elif Input.is_action_just_pressed("ui_cancel"):
		close()


func buy_selected() -> bool:
	var bought := progress.buy(ROWS[selection])
	refresh()
	return bought


func _on_row_hover(index: int) -> void:
	selection = index
	refresh()


func _on_row_click(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selection = index
		buy_selected()


func close() -> void:
	if closed:
		return
	closed = true
	if auto_change_scene:
		get_tree().change_scene_to_file(TITLE_SCENE)


func refresh() -> void:
	_money_label.text = "Dinero %d cr" % progress.money
	for index in ROWS.size():
		var upgrade_id := ROWS[index]
		var price := progress.cost_for(upgrade_id)
		var price_text := "al máximo" if price < 0 else "%d cr" % price
		var mark := "▸ " if index == selection else "  "
		_rows[index].text = "%s%s  %d/%d  %s" % [mark, NAMES[upgrade_id], progress.level(upgrade_id), Progress.MAX_LEVEL, price_text]
		_rows[index].modulate = Color(0.74, 0.96, 1) if index == selection else Color(0.95, 0.94, 0.9)
