class_name CaseData
extends RefCounted

const TITLE = "The Ashwood Inheritance"
const FINAL_TRUTH = "Blackwell poisoned the tonic to conceal his theft. Iris was Edmund's firstborn daughter. Whether the circle accepted those facts was up to you."
const ROLES = ["medium", "heir", "widow", "doctor", "keeper", "ghost"]
const PEOPLE = {
	"medium":
	{
		"name": "Vivienne Cross",
		"title": "The Medium",
		"color": "89b8b1",
		"initial": "V",
		"bio":
		"You have made a living speaking for the dead. Tonight, for the first time, one of them is speaking back.",
		"secret":
		"Edmund paid you to bind his spirit. You have since learned what binding really means.",
		"goals":
		[
			"Reveal the true cause of death.",
			"Complete at least two ritual preparations.",
			"Release Edmund's spirit."
		],
		"rumor": "Dr. Blackwell asked whether a dead man can remember pain."
	},
	"heir":
	{
		"name": "Julian Ashwood",
		"title": "The Eldest Heir",
		"color": "c29b70",
		"initial": "J",
		"bio":
		"The estate was supposed to be yours. Then your father changed his will. Some promises should survive the grave.",
		"secret":
		"You know the Binding imprisons your father. You also know a bound spirit cannot contest a will.",
		"goals":
		[
			"Reveal the final will.",
			"Keep the Ashwood signet ring.",
			"Have Edmund bound to the estate."
		],
		"rumor": "The housekeeper was alone in the nursery after the funeral."
	},
	"widow":
	{
		"name": "Lenore Ashwood",
		"title": "The Widow",
		"color": "b88996",
		"initial": "L",
		"bio":
		"A young widow is such a convenient suspect. Your grief is real. So is your need to leave this house behind.",
		"secret":
		"You loved the gardener. Edmund knew. You did not kill him, but someone would like the room to believe you did.",
		"goals":
		[
			"Reveal the love letter on your own terms.",
			"Give the mourning locket to Iris.",
			"Avoid being named the murderer."
		],
		"rumor": "Edmund's medicine smelled of bitter flowers on his final night."
	},
	"doctor":
	{
		"name": "Silas Blackwell",
		"title": "The Physician",
		"color": "9fa6ba",
		"initial": "S",
		"bio":
		"Forty years of service. One unforgivable decision. The living can be persuaded; the dead concern you.",
		"secret":
		"You poisoned Edmund's evening tonic to conceal years of embezzlement. The ledger can prove your motive.",
		"goals":
		[
			"Reveal the medicine report; appear cooperative.",
			"Keep the account ledger out of public view.",
			"Persuade the circle to accuse Lenore."
		],
		"rumor": "Lenore's locket contains a letter that isn't from her husband."
	},
	"keeper":
	{
		"name": "Iris Wren",
		"title": "The Housekeeper",
		"color": "a8ac7c",
		"initial": "I",
		"bio":
		"You know which floorboards creak, which doors lock, and which names were erased from the family Bible.",
		"secret":
		"You are Edmund's unacknowledged daughter. The nursery records can finally give you your name.",
		"goals":
		["Reveal the birth register.", "Keep the nursery key.", "Be named heir to Ashwood Manor."],
		"rumor": "The safe code is the year Edmund first became a father."
	},
	"ghost":
	{
		"name": "Edmund Ashwood",
		"title": "The Unquiet",
		"color": "9bcfc9",
		"initial": "E",
		"bio":
		"A bitter taste. A familiar hand. The clock striking eleven. Death has left you with fragments, and very little time.",
		"secret":
		"Iris is your daughter. You meant to tell her. Only the Medium can hear your voice, unless you invite another vessel.",
		"goals":
		[
			"Reveal both the medicine report and the ledger.",
			"Have Iris inherit the estate.",
			"Be released before dawn."
		],
		"rumor": "A silver chain. Bitter flowers. Someone said it was only medicine."
	}
}

const CLUES = {
	"will":
	{
		"name": "The Last Testament",
		"room": "Library",
		"pos": Vector3(-12.0, 1.09, -2.9),
		"kind": "document",
		"summary": "A final amendment, written three nights before the death.",
		"text":
		"I revoke all previous dispositions. Ashwood Manor and its grounds shall pass to my firstborn child, whose name is preserved in the nursery register.\n\nSigned, Edmund Ashwood. Witnessed by S. Blackwell.\n\nThe signature is steady. This was no delirium.",
		"tag": "INHERITANCE"
	},
	"ledger":
	{
		"name": "The Physician's Ledger",
		"room": "Library",
		"pos": Vector3(-13.5, 1.03, 2.8),
		"kind": "book",
		"summary": "Payments that never reached the hospital.",
		"text":
		"Blackwell's own handwriting records eight years of diverted charity payments. On the last page Edmund has written:\n\n‘Silas. Repay every penny by Friday, or I shall send this to the constable.’\n\nEdmund died on Thursday night.",
		"tag": "MOTIVE"
	},
	"vial":
	{
		"name": "The Evening Tonic",
		"room": "Conservatory",
		"pos": Vector3(12.0, 1.03, -2.8),
		"kind": "bottle",
		"summary": "Dried violet residue clings to the medicine glass.",
		"text":
		"A bitter, floral sediment remains in Edmund's prescribed tonic. The herbarium identifies it as belladonna: lethal in this concentration.\n\nOnly Dr. Blackwell prepared the evening dose. Lenore delivered the glass, but did not mix it.",
		"tag": "CAUSE OF DEATH"
	},
	"letter":
	{
		"name": "An Unsent Love Letter",
		"room": "Conservatory",
		"pos": Vector3(13.2, 0.86, 2.4),
		"kind": "document",
		"summary": "A letter from Lenore to the gardener.",
		"text":
		"‘Thomas — he knows. He has known for months. Yet yesterday he told me I would be free of this marriage without disgrace. I had never seen him so kind.\n\nMeet me when the roses bloom. — L.’\n\nThe date is two days before Edmund's death.",
		"tag": "RELATIONSHIP"
	},
	"birth":
	{
		"name": "The Nursery Register",
		"room": "Memorial Chapel",
		"pos": Vector3(-2.7, 1.05, -12.0),
		"kind": "book",
		"summary": "The first page has been carefully restored.",
		"text":
		"IRIS ASHWOOD — born 17 November 1913.\nFather: Edmund Ashwood.\nMother: Eleanor Wren.\n\nA note in Edmund's hand reads: ‘Forgive me for making you live as a servant in your own home.’\n\nIris is his firstborn child.",
		"tag": "LINEAGE"
	},
	"rite":
	{
		"name": "The Book of Departures",
		"room": "Memorial Chapel",
		"pos": Vector3(2.7, 1.05, -12.0),
		"kind": "book",
		"summary": "Three endings. Only one is a kindness.",
		"text":
		"RELEASE — a prepared circle opens the threshold. The spirit passes on in peace. Requires two completed preparations.\n\nBIND — the spirit remains chained to the estate, forever available to its owner.\n\nBANISH — the connection is severed. The dead become silence, and their unfinished business remains.",
		"tag": "RITUAL"
	},
	"clock":
	{
		"name": "The Stopped Watch",
		"room": "Séance Parlour",
		"pos": Vector3(5.8, 1.06, -5.3),
		"kind": "watch",
		"summary": "The hands stopped at eleven seventeen.",
		"text":
		"The cracked face shows 11:17. Blackwell told the police Edmund died at midnight.\n\nThe housekeeper heard the doctor leave the study at 11:20. The physician's account is at least forty minutes wrong.",
		"tag": "TIMELINE"
	},
	"flowers":
	{
		"name": "Pressed Belladonna",
		"room": "Conservatory",
		"pos": Vector3(10.3, 1.04, 0.0),
		"kind": "flower",
		"summary": "The gardener kept a careful inventory.",
		"text":
		"Three stems of belladonna were signed out to Dr. S. Blackwell on Thursday.\n\nUnderneath: ‘Medical research. Keep away from the family tea.’\n\nA dangerous plant is not a confession. Together with the tonic and ledger, it is a story.",
		"tag": "CORROBORATION"
	}
}

const ITEMS = {
	"ring":
	{
		"name": "Ashwood Signet",
		"room": "Library",
		"pos": Vector3(-10.2, 1.05, 0.0),
		"description": "The family seal. Julian believes blood gives him the right to it.",
		"cursed": false
	},
	"locket":
	{
		"name": "Mourning Locket",
		"room": "Conservatory",
		"pos": Vector3(12.0, 1.05, -1.5),
		"description":
		"Black pearls around a silver heart. Warm to the touch. Its bearer is susceptible to possession.",
		"cursed": true
	},
	"key":
	{
		"name": "Nursery Key",
		"room": "Memorial Chapel",
		"pos": Vector3(0.0, 1.05, -13.4),
		"description":
		"A little brass key, engraved with the initial I. Some doors were locked to keep a secret in.",
		"cursed": false
	}
}

const TASKS = {
	"radio":
	{
		"name": "Tune the Spirit Radio",
		"room": "Library",
		"pos": Vector3(-13.7, 1.10, -3.0),
		"description": "A pencilled note reads: ‘The dead speak at 88.7. Tune gently.’",
		"solution": "88.7"
	},
	"candles":
	{
		"name": "Align the Ritual Candles",
		"room": "Séance Parlour",
		"pos": Vector3(0.0, 1.02, 0.0),
		"description":
		"The inscription reads: ‘Night falls. The garden wakes. The door opens.’ Choose three symbols in order.",
		"solution": "MOON,THORN,KEY"
	},
	"safe":
	{
		"name": "Open the Reliquary",
		"room": "Memorial Chapel",
		"pos": Vector3(0.0, 1.2, -11.9),
		"description":
		"Four worn brass wheels. The inscription reads: ‘The year I first became a father.’ The nursery register is nearby.",
		"solution": "1913"
	}
}

const SEATS = {
	"medium": Vector3(0, 0, 3.4),
	"heir": Vector3(-3, 0, 1.7),
	"widow": Vector3(3, 0, 1.7),
	"doctor": Vector3(-3, 0, -1.7),
	"keeper": Vector3(3, 0, -1.7),
	"ghost": Vector3(0, 0, -3.4)
}


static func person(role: String) -> Dictionary:
	return PEOPLE.get(role, PEOPLE.medium)


static func spawn_at(role: String) -> Vector3:
	return SEATS[role] * 1.22


static func object_data(id: String) -> Dictionary:
	return CLUES.get(id, ITEMS.get(id, TASKS.get(id, {})))


static func is_walkable(p: Vector3) -> bool:
	if not p.is_finite():
		return false
	return (
		(absf(p.x) < 7.7 and p.z > -8.7 and p.z < 8.7)
		or (absf(p.x) < 15.7 and absf(p.x) > 7.2 and absf(p.z) < 4.7)
		or (absf(p.x) < 3.7 and p.z > -14.7 and p.z < -8.0)
	)


static func room_at(p: Vector3) -> String:
	if p.x < -8:
		return "Library"
	if p.x > 8:
		return "Conservatory"
	if p.z < -9:
		return "Memorial Chapel"
	return "Séance Parlour"
