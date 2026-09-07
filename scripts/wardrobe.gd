extends Node
## Local prototype progression, not a payment/entitlement authority.
## Paid cosmetics remain disabled until a verified account backend exists.

var choices: Dictionary = {}
var remembrance = 0
var gold_unlocked = false
var receipts: Array = []
var profile_path = "user://wardrobe.cfg"
var persistence = true
var last_award = 0


func _ready() -> void:
	persistence = (
		not OS.get_cmdline_args().has("--script") and not OS.get_cmdline_user_args().has("--qa")
	)
	choices = AppearanceData.preferences({})
	if persistence:
		load_profile()


func load_profile() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(profile_path) != OK:
		return
	choices = AppearanceData.preferences(cfg.get_value("wardrobe", "choices", {}))
	remembrance = clampi(int(cfg.get_value("wardrobe", "remembrance", 0)), 0, 1000000)
	gold_unlocked = bool(cfg.get_value("wardrobe", "gold_unlocked", false))
	var saved: Variant = cfg.get_value("wardrobe", "receipts", [])
	receipts = saved if saved is Array else []
	for role in choices:
		if choices[role].brooch == "gold" and not gold_unlocked:
			choices[role].brooch = "none"


func save_profile() -> Error:
	if not persistence:
		return OK
	var cfg = ConfigFile.new()
	cfg.set_value("wardrobe", "choices", choices)
	cfg.set_value("wardrobe", "remembrance", remembrance)
	cfg.set_value("wardrobe", "gold_unlocked", gold_unlocked)
	cfg.set_value("wardrobe", "receipts", receipts)
	# Save a new file first; a failed write leaves the current profile intact.
	var pending = profile_path + ".pending"
	var error = cfg.save(pending)
	if error != OK:
		return error
	return DirAccess.rename_absolute(pending, profile_path)


func equip(role: String, selected: Dictionary) -> Error:
	if not CaseData.ROLES.has(role):
		return ERR_INVALID_PARAMETER
	var choice = AppearanceData.normalize(role, selected)
	if choice.brooch == "gold" and not gold_unlocked:
		return ERR_UNAUTHORIZED
	var previous: Dictionary = choices[role]
	choices[role] = choice
	var error = save_profile()
	if error != OK:
		choices[role] = previous
	return error


func unlock_gold() -> Error:
	if gold_unlocked or remembrance < AppearanceData.GOLD_COST:
		return ERR_UNAUTHORIZED
	remembrance -= AppearanceData.GOLD_COST
	gold_unlocked = true
	var error = save_profile()
	if error != OK:
		remembrance += AppearanceData.GOLD_COST
		gold_unlocked = false
	return error


func award(snapshot: Dictionary, role: String) -> bool:
	var receipt = str(snapshot.get("sitting_id", ""))
	if snapshot.get("phase", "") != "ended" or receipt == "" or receipts.has(receipt):
		return false
	var points = -1
	for score in snapshot.get("scores", []):
		if score.role == role:
			points = int(score.points)
	if points < 0:
		return false
	var previous = remembrance
	var old_receipts = receipts.duplicate()
	remembrance = mini(1000000, remembrance + 20 + clampi(points, 0, 15) * 2)
	receipts.append(receipt)
	if receipts.size() > 256:
		receipts.pop_front()
	if save_profile() != OK:
		remembrance = previous
		receipts = old_receipts
		return false
	last_award = remembrance - previous
	return true
