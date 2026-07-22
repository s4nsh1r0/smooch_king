extends PanelContainer
class_name GiftMenu

signal gift_selected(character_id: String, points: int, cost: float)
signal close_pressed

@onready var small_gift_button: Button = %SmallGiftButton
@onready var medium_gift_button: Button = %MediumGiftButton
@onready var large_gift_button: Button = %LargeGiftButton
@onready var fancy_gift_button: Button = %FancyGiftButton
@onready var luxury_gift_button: Button = %LuxuryGiftButton
@onready var extravagant_gift_button: Button = %ExtravagantGiftButton
@onready var close_button: Button = %CloseButton

var character_id: String = ""

const GIFT_DATA = {
	"Small": {"points": 1, "cost": 10.0},
	"Medium": {"points": 5, "cost": 50.0},
	"Large": {"points": 10, "cost": 100.0},
	"Fancy": {"points": 25, "cost": 250.0},
	"Luxury": {"points": 50, "cost": 500.0},
	"Extravagant": {"points": 100, "cost": 1000.0}
}

func _ready():
	# Ensure unique names
	small_gift_button.set_unique_name_in_owner(true)
	medium_gift_button.set_unique_name_in_owner(true)
	large_gift_button.set_unique_name_in_owner(true)
	fancy_gift_button.set_unique_name_in_owner(true)
	luxury_gift_button.set_unique_name_in_owner(true)
	extravagant_gift_button.set_unique_name_in_owner(true)
	close_button.set_unique_name_in_owner(true)

	# Connect button signals
	small_gift_button.pressed.connect(_on_gift_button_pressed.bind("Small"))
	medium_gift_button.pressed.connect(_on_gift_button_pressed.bind("Medium"))
	large_gift_button.pressed.connect(_on_gift_button_pressed.bind("Large"))
	fancy_gift_button.pressed.connect(_on_gift_button_pressed.bind("Fancy"))
	luxury_gift_button.pressed.connect(_on_gift_button_pressed.bind("Luxury"))
	extravagant_gift_button.pressed.connect(_on_gift_button_pressed.bind("Extravagant"))
	close_button.pressed.connect(_on_close_button_pressed)

	update_gift_button_availability()

func set_character_id(id: String):
	character_id = id
	update_gift_button_availability()

func update_gift_button_availability():
	if not is_instance_valid(PlayerData):
		printerr("GiftMenu: Player singleton not found!")
		return

	var buttons = {
		"SmallGiftButton": GIFT_DATA["Small"].cost,
		"MediumGiftButton": GIFT_DATA["Medium"].cost,
		"LargeGiftButton": GIFT_DATA["Large"].cost,
		"FancyGiftButton": GIFT_DATA["Fancy"].cost,
		"LuxuryGiftButton": GIFT_DATA["Luxury"].cost,
		"ExtravagantGiftButton": GIFT_DATA["Extravagant"].cost
	}

	for button_name in buttons:
		var button = get_node_or_null("%" + button_name)
		if button:
			var gift_type = button_name.replace("GiftButton", "")
			var cost = buttons[button_name]
			var has_money = PlayerData.has_money(cost)
			button.disabled = not has_money
			button.text = "%s Gift (+%d, %.0f coins)" % [
				gift_type,
				GIFT_DATA[gift_type].points,
				cost
			]
			button.tooltip_text = "%s Gift\nMoney: %.2f (Need %.2f)" % [
				gift_type,
				PlayerData.money if PlayerData else 0.0,
				cost
			] if not has_money else ""
		else:
			printerr("GiftMenu: Button %s not found!" % button_name)

func _on_gift_button_pressed(gift_type: String):
	if not PlayerData or not GIFT_DATA.has(gift_type):
		printerr("GiftMenu: PlayerData or gift type %s not found!" % gift_type)
		return
	var config = GIFT_DATA[gift_type]
	if PlayerData.has_money(config.cost):
		gift_selected.emit(character_id, config.points, config.cost)
		update_gift_button_availability()
	else:
		UIManager.show_notification("Not enough money for %s Gift!" % gift_type)

func _on_close_button_pressed():
	close_pressed.emit()

func show_panel_animated() -> void:
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, UIManager.FADE_DURATION).set_trans(UIManager.FADE_TRANS).set_ease(UIManager.FADE_EASE)

func hide_panel_animated() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, UIManager.FADE_DURATION).set_trans(UIManager.FADE_TRANS).set_ease(UIManager.FADE_EASE)
	await tween.finished
	visible = false
	queue_free()

func get_fade_tween() -> Tween:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, UIManager.FADE_DURATION).set_trans(UIManager.FADE_TRANS).set_ease(UIManager.FADE_EASE)
	return tween
