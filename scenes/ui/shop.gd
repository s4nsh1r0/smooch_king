extends PanelContainer
class_name Shop

signal close_pressed

@onready var title_label: Label = %TitleLabel
@onready var tab_container: TabContainer = %TabContainer
@onready var close_button: Button = %CloseButton

# Categories and which gifts belong to them
const CATEGORIES = {
	"Flowers & Cute": ["rose", "small_bouquet", "teddy", "balloon", "postcard", "keychain", "plush", "plant"],
	"Sweets":         ["chocolate", "candy", "cookie", "coffee", "mug"],
	"Fashion":        ["scarf", "handbag", "earrings", "necklace", "designer_scarf"],
	"Luxury":         ["watch", "ring", "luxury_perfume", "perfume", "lotion"],
	"Experiences":    ["spa_coupon", "massage", "dinner_voucher", "headphones", "photo_frame", "book", "candle"]
}

# Re-use the same gift data from GiftMenu
const GIFT_DATABASE = {
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
	_build_tabs()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	if PlayerData:
		PlayerData.player_money_changed.connect(_on_money_changed)

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
	add_theme_stylebox_override("panel", panel_style)
	
	if title_label:
		title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 1.0))
		title_label.add_theme_font_size_override("font_size", 26)
	
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

func _build_tabs() -> void:
	# Clear existing tabs
	for child in tab_container.get_children():
		child.queue_free()
	
	for category_name in CATEGORIES:
		var scroll = ScrollContainer.new()
		scroll.name = category_name
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		
		var list = VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 10)
		scroll.add_child(list)
		
		for gift_id in CATEGORIES[category_name]:
			if not GIFT_DATABASE.has(gift_id):
				continue
			var data = GIFT_DATABASE[gift_id]
			var btn = _create_buy_button(gift_id, data)
			list.add_child(btn)
		
		tab_container.add_child(scroll)
		tab_container.set_tab_title(tab_container.get_tab_count() - 1, category_name)

func _create_buy_button(gift_id: String, data: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 54)
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_meta("gift_id", gift_id)
	btn.set_meta("cost", data.cost)
	
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
	
	var disabled = normal.duplicate()
	disabled.bg_color = Color(0.3, 0.2, 0.35, 0.6)
	disabled.border_color = Color(0.5, 0.35, 0.55, 0.5)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 16)
	
	_update_button_text(btn, data)
	btn.pressed.connect(_on_buy_pressed.bind(gift_id, data.cost, data.name))
	return btn

func _update_button_text(btn: Button, data: Dictionary) -> void:
	var owned = 0
	if PlayerData:
		owned = PlayerData.get_item_count(btn.get_meta("gift_id"))
	
	btn.text = "%s  %s   $%d   (owned: %d)" % [data.emoji, data.name, data.cost, owned]
	
	if PlayerData:
		btn.disabled = not PlayerData.has_money(data.cost)

func _on_buy_pressed(gift_id: String, cost: float, gift_name: String) -> void:
	if not PlayerData:
		return
	
	if not PlayerData.has_money(cost):
		UIManager.show_notification("Not enough money!")
		return
	
	PlayerData.spend_money(cost)
	PlayerData.add_item(gift_id, 1)
	UIManager.show_notification("Bought %s!" % gift_name)
	_refresh_all_buttons()

func _refresh_all_buttons() -> void:
	for tab in tab_container.get_children():
		var list = tab.get_child(0) as VBoxContainer
		if not list:
			continue
		for btn in list.get_children():
			if btn.has_meta("gift_id"):
				var gift_id = btn.get_meta("gift_id")
				if GIFT_DATABASE.has(gift_id):
					_update_button_text(btn, GIFT_DATABASE[gift_id])

func _on_money_changed(_new_money: float) -> void:
	_refresh_all_buttons()

func _on_close_pressed() -> void:
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
