class_name AppearanceData
extends RefCounted
## Cosmetic allowlist only. Never imported by scoring or listening rules.

const HEIGHTS = {
	"ghost": 1.83, "medium": 1.70, "heir": 1.81, "widow": 1.74, "doctor": 1.78, "keeper": 1.65
}
const GOLD_COST = 60


static func normalize(role: String, value: Variant) -> Dictionary:
	var choice: Dictionary = value if value is Dictionary else {}
	var outfit = str(choice.get("outfit", "ashwood"))
	if outfit != "heritage" or role not in ["medium", "doctor"]:
		outfit = "ashwood"
	var brooch = str(choice.get("brooch", "none"))
	if brooch not in ["none", "silver", "gold"]:
		brooch = "none"
	return {"outfit": outfit, "brooch": brooch}


static func preferences(value: Variant) -> Dictionary:
	var supplied: Dictionary = value if value is Dictionary else {}
	var result = {}
	for role in CaseData.ROLES:
		result[role] = normalize(role, supplied.get(role, {}))
	return result


static func model(role: String, choice: Dictionary) -> String:
	if not CaseData.ROLES.has(role):
		return ""
	if normalize(role, choice).outfit == "heritage":
		return "medium" if role == "medium" else "physician"
	return "roster/" + role
