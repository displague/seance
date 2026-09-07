class_name CaseProgression
extends RefCounted
## Public case schedule and authoritative availability, independent of presentation.
## Future cases can author different chapters without changing networking or controls.

const UNLOCKS = {"will": 2, "birth": 2, "radio": 2, "ledger": 3, "audit": 3, "safe": 3}
const CHAPTERS = [
	{
		"title": "The Last Night",
		"focus":
		"Investigate the tonic, watch and relationships. Claim keepsakes and align the candles.",
		"opens": "Initial evidence, inheritance keepsakes and ritual candles."
	},
	{
		"title": "Blood and Inheritance",
		"focus":
		"The will and nursery register are unsealed. Establish the heir, negotiate gifts and tune the radio.",
		"opens": "Final will in the Library; nursery register in the Chapel; spirit radio."
	},
	{
		"title": "The Final Audit",
		"focus":
		"The ledger and a separate bank copy are available. Challenge the cover-up and open the reliquary before judgment.",
		"opens":
		"Physician's ledger in the Library; bank audit in the Conservatory; Chapel reliquary."
	}
]
const DEPENDENCIES = {
	"birth":
	"The register identifies the heir and gives the year for the round-three reliquary. Destroying it can obstruct those goals. The candles and radio remain an independent release path.",
	"will":
	"The final will supports the inheritance claim. Destroying it can prevent the house from accepting that claim.",
	"ledger":
	"An independent bank audit is available in investigation three even if this ledger is concealed or destroyed."
}


static func unlock_round(id: String) -> int:
	return UNLOCKS.get(id, 1)


static func locked(state: Dictionary, id: String) -> bool:
	return int(state.get("round", 1)) < unlock_round(id)


static func lock_message(id: String) -> String:
	return (
		"Sealed until investigation %d: %s"
		% [unlock_round(id), CHAPTERS[unlock_round(id) - 1].title]
	)


static func view_for(state: Dictionary) -> Dictionary:
	var round_id = clampi(int(state.round), 1, 3)
	var chapter: Dictionary = CHAPTERS[round_id - 1].duplicate(true)
	chapter["round"] = round_id
	chapter["schedule"] = []
	chapter["locked"] = {}
	chapter["dependencies"] = DEPENDENCIES.duplicate()
	for index in range(3):
		chapter.schedule.append(
			"%d · %s — %s" % [index + 1, CHAPTERS[index].title, CHAPTERS[index].opens]
		)
	for id in UNLOCKS:
		if locked(state, id):
			chapter.locked[id] = lock_message(id)
	return chapter


static func announce(game) -> void:
	var chapter = view_for(game.state)
	game.log_event("INVESTIGATION %d · %s. %s" % [chapter.round, chapter.title, chapter.focus])
