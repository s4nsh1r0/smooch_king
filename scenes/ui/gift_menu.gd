extends PanelContainer
class_name GiftMenu

signal gift_given(character_id: String, gift_id: String, points: int)
signal close_pressed

@onready var gift_list: VBoxContainer = %GiftList
@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton
@onready var empty_label: Label = %EmptyLabel

var character_id: String = ""

# cost = shop price only; points = relationship when given
const GIFT_DATABASE := {
	"rose":           {"name": "Rose",             "cost": 15,  "points": 3,  "emoji": "🌹"},
	"chocolate":      {"name": "Chocolate Box",    "cost": 25,  "points": 5,  "emoji": "🍫"},
	"candy":          {"name": "Candy Bag",        "cost": 12,  "points": 2,  "emoji": "🍬"},
	"coffee":         {"name": "Fancy Coffee",     "cost": 18,  "points": 4,  "emoji": "☕"},
	"teddy":          {"name": "Teddy Bear",       "cost": 40,  "points": 8,  "emoji": "🧸"},
	"balloon":        {"name": "Heart Balloon",    "cost": 10,  "points": 2,  "emoji": "🎈"},
	"postcard":       {"name": "Cute Postcard",    "cost": 8,   "points": 1,  "emoji": "💌"},
	"cookie":         {"name": "Homemade Cookies", "cost": 20,  "points": 4,  "emoji": "🍪"},
	"small_bouquet":  {"name": "Small Bouquet",    "cost": 30,  "points": 6,  "emoji": "💐"},
	"keychain":       {"name": "Cute Keychain",    "cost": 15,  "points": 3,  "emoji": "🔑"},
	"perfume":        {"name": "Perfume",          "cost": 80,  "points": 15, "emoji": "🌸"},
	"book":           {"name": "Romance Novel",    "cost": 45,  "points": 9,  "emoji": "📖"},
	"scarf":          {"name": "Soft Scarf",       "cost": 60,  "points": 12, "emoji": "🧣"},
	"candle":         {"name": "Scented Candle",   "cost": 35,  "points": 7,  "emoji": "🕯️"},
	"plush":          {"name": "Big Plushie",      "cost": 70,  "points": 14, "emoji": "🐰"},
	"mug":            {"name": "Custom Mug",       "cost": 28,  "points": 5,  "emoji": "☕"},
	"photo_frame":    {"name": "Photo Frame",      "cost": 50,  "points": 10, "emoji": "🖼️"},
	"lotion":         {"name": "Luxury Lotion",    "cost": 55,  "points": 11, "emoji": "🧴"},
	"plant":          {"name": "Cute Plant",       "cost": 40,  "points": 8,  "emoji": "🪴"},
	"headphones":     {"name": "Earbuds",          "cost": 90,  "points": 16, "emoji": "🎧"},
	"necklace":       {"name": "Necklace",         "cost": 200, "points": 30, "emoji": "💎"},
	"watch":          {"name": "Elegant Watch",    "cost": 350, "points": 45, "emoji": "⌚"},
	"earrings":       {"name": "Earrings",         "cost": 180, "points": 28, "emoji": "💫"},
	"handbag":        {"name": "Cute Handbag",     "cost": 280, "points": 38, "emoji": "👜"},
	"spa_coupon":     {"name": "Spa Coupon",       "cost": 220, "points": 32, "emoji": "💆"},
	"massage":        {"name": "Massage Coupon",   "cost": 250, "points": 35, "emoji": "🧖"},
	"dinner_voucher": {"name": "Fancy Dinner",     "cost": 300, "points": 40, "emoji": "🍽️"},
	"designer_scarf": {"name": "Designer Scarf",   "cost": 320, "points": 42, "emoji": "🎀"},
	"luxury_perfume": {"name": "Luxury Perfume",   "cost": 450, "points": 55, "emoji": "✨"},
	"ring":           {"name": "Promise Ring",     "cost": 600, "points": 70, "emoji": "💍"},
}

func _ready() -> void:
	_setup_modern_styling()

	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

	if PlayerData and not PlayerData.inventory_changed.is_connected(refresh_gift_list):
		PlayerData.inventory_changed.connect(refresh_gift_list)

	refresh_gift_list()

func _exit_tree() -> void:
	if PlayerData and PlayerData.inventory_changed.is_connected(refresh_gift_list):
		PlayerData.inventory_changed.disconnect(refresh_gift_list)

func _setup_modern_styling() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.32, 0.18, 0.42, 0.92)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.95, 0.7, 1.0, 0.9)
	panel_style.set_corner_radius_all(22)
	panel_style.shadow_color = Color(0.5, 0.2, 0.7, 0.5)
	panel_style.shadow_size = 16
	panel_style.shadow_offset = Vector2(0, 6)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", panel_style)

	if title_label:
		title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 1.0))
		title_label.add_theme_font_size_override("font_size", 24)

	if close_button:
		var close_style = StyleBoxFlat.new()
		close_style.bg_color = Color(0.75, 0.3, 0.45, 0.95)
		close_style.set_corner_radius_all(14)
		close_style.border_width_left = 2
		close_style.border_width_top = 2
		close_style.border_width_right = 2
		close_style.border_width_bottom = 2
		close_style.border_color = Color(1.0, 0.55, 0.7, 0.85)

		var close_hover = close_style.duplicate()
		close_hover.bg_color = Color(0.9, 0.4, 0.55, 1.0)

		close_button.add_theme_stylebox_override("normal", close_style)
		close_button.add_theme_stylebox_override("hover", close_hover)
		close_button.add_theme_color_override("font_color", Color.WHITE)

func set_character_id(id: String) -> void:
	character_id = id
	if title_label and not id.is_empty():
		title_label.text = "Gifts"
	refresh_gift_list()

func refresh_gift_list() -> void:
	if not is_instance_valid(gift_list):
		return

	for child in gift_list.get_children():
		child.queue_free()

	if not PlayerData:
		if empty_label:
			empty_label.visible = true
		return

	var inv = PlayerData.get_inventory()
	var has_any := false

	var sorted_ids: Array = inv.keys()
	sorted_ids.sort_custom(func(a, b):
		return int(GIFT_DATABASE.get(a, {}).get("points", 0)) < int(GIFT_DATABASE.get(b, {}).get("points", 0))
	)

	for gift_id in sorted_ids:
		var amount = int(inv[gift_id])
		if amount <= 0 or not GIFT_DATABASE.has(gift_id):
			continue
		has_any = true
		gift_list.add_child(_create_gift_button(str(gift_id), GIFT_DATABASE[gift_id], amount))

	if empty_label:
		empty_label.visible = not has_any

func _create_gift_button(gift_id: String, data: Dictionary, amount: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 52)
	btn.focus_mode = Control.FOCUS_NONE

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.55, 0.3, 0.7, 0.92)
	normal.set_corner_radius_all(14)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.95, 0.7, 1.0, 0.8)

	var hover = normal.duplicate()
	hover.bg_color = Color(0.65, 0.38, 0.8, 1.0)
	hover.border_color = Color(1.0, 0.8, 1.0, 1.0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 16)

	btn.text = "%s  %s  ×%d   (+%d pts)" % [data.emoji, data.name, amount, data.points]
	btn.tooltip_text = "Give %s\n+%d relationship points" % [data.name, data.points]
	btn.pressed.connect(_on_gift_pressed.bind(gift_id))
	return btn

func _on_gift_pressed(gift_id: String) -> void:
	if character_id.is_empty():
		return
	if not PlayerData or not GIFT_DATABASE.has(gift_id):
		return
	if not PlayerData.has_item(gift_id):
		UIManager.show_notification("You don't have this gift!")
		return

	var data: Dictionary = GIFT_DATABASE[gift_id]
	if not PlayerData.remove_item(gift_id, 1):
		UIManager.show_notification("You don't have this gift!")
		return

	var points = int(data.points)
	PlayerData.add_relationship_points(character_id, points)
	gift_given.emit(character_id, gift_id, points)
	UIManager.show_notification("You gave a %s! (+%d points)" % [data.name, points])
	refresh_gift_list()

func _on_close_button_pressed() -> void:
	close_pressed.emit()

func show_panel_animated() -> void:
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func hide_panel_animated() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
	queue_free()

func get_fade_tween() -> Tween:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	return tween
