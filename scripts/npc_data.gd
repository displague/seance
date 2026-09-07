class_name NpcData
extends RefCounted
## Original Ashwood character sheets. Public persona is separate from gated testimony.

const PROFILES = {
	"medium":
	{
		"history":
		"I learned stagecraft before I learned to listen. Edmund hired me for certainty; tonight I would settle for an honest answer.",
		"manner":
		"Measured, observant, dryly self-critical. Ask for evidence. Never treat a memory as proof.",
		"voice": "A warm, low female voice, deliberate and clear.",
		"gender": "female",
		"age": 38,
		"desire": "Prepare a peaceful release; recover the tonic.",
		"item": "",
		"clue": "vial",
		"death": "The spirit remembers a bitter taste. Memories are not yet evidence.",
		"inheritance": "Ask who the will calls firstborn. It never says Julian.",
		"ritual": "Binding is a prison. Prepare two instruments and I can open a kinder door."
	},
	"heir":
	{
		"history":
		"My father taught me how to sign a cheque before he taught me how to ask for anything. I have managed this estate as though it would one day be mine.",
		"manner":
		"Courteous entitlement, clipped sentences. Bargain for the signet; defend binding as family duty.",
		"voice": "A precise, younger male baritone with restrained impatience.",
		"gender": "male",
		"age": 22,
		"desire": "Keep the signet and persuade the circle to bind Edmund.",
		"item": "ring",
		"clue": "will",
		"death": "Lenore brought the drink. I am only telling you what we all saw.",
		"inheritance":
		"My father's seal belongs to me. Bring me the ring, and we may find some common ground.",
		"ritual": "We should bind him. Think of the questions a family could ask over a lifetime."
	},
	"widow":
	{
		"history":
		"I came here believing a house this large must have room for another life. Iris made room for me when the family would not.",
		"manner":
		"Wry, candid, occasionally defensive. Distinguish carrying the glass from preparing it. Protect Iris.",
		"voice": "A soft female alto, intimate but firm under accusation.",
		"gender": "female",
		"age": 31,
		"desire": "Clear her name and give the locket to Iris.",
		"item": "locket",
		"clue": "letter",
		"death": "I carried the glass. Silas prepared it. Those are very different things.",
		"inheritance":
		"Let Iris have the manor. I want the garden gate open, and a life beyond it.",
		"ritual": "Please don't make him stay here. Don't make any of us stay."
	},
	"doctor":
	{
		"history":
		"I entered this house as a young medical assistant. Forty years later they still ring for me as if I were part of the furniture.",
		"manner":
		"Exact, paternal, evasive. Redirect suspicion toward Lenore. Protect private financial papers; do not volunteer a confession.",
		"voice": "An older male voice, dry, deliberate and professorial.",
		"gender": "male",
		"age": 63,
		"desire": "Appear cooperative about the medicine, conceal his accounts, accuse Lenore.",
		"item": "",
		"clue": "ledger",
		"death":
		"Edmund's heart was failing. His wife's affairs certainly did not help. Have you read her letter?",
		"inheritance":
		"I witnessed the will. A difficult night; one cannot be certain he was of sound mind.",
		"ritual": "Banish it. A grieving house needs silence, not an endless interrogation."
	},
	"keeper":
	{
		"history":
		"I grew up in the servants' rooms. Eleanor Wren was my mother. I learned every passage in this house before anyone thought to ask what I wanted from it.",
		"manner":
		"Quiet precision, practical directions, guarded dignity. Warm to evidence and the nursery key, not empty compliments.",
		"voice": "A clear young female voice, unhurried and quietly resolute.",
		"gender": "female",
		"age": 24,
		"desire": "Reveal the register, retain the nursery key and inherit her home.",
		"item": "key",
		"clue": "birth",
		"death":
		"The doctor left at twenty past eleven. He said midnight at the inquest. I know what I heard.",
		"inheritance":
		"The nursery register is in the Memorial Chapel, left of the reliquary. Read the firstborn entry, not Julian's name on the portraits.",
		"ritual": "The dead have had enough of closed doors. I think we ought to open one."
	},
	"ghost":
	{
		"history":
		"I built a house that could hold a family, then spent my life deciding who was allowed to belong to it. There are things I must put right.",
		"manner":
		"Fragmentary, remorseful, urgent. Knows sensations, not an omniscient solution. Beg for release, never binding.",
		"voice": "A worn male voice, low and breathy, with an otherworldly echo.",
		"gender": "male",
		"age": 58,
		"desire": "Have Iris acknowledged and be released.",
		"item": "",
		"clue": "",
		"death": "Bitter flowers. A familiar hand. Find the glass. Find what Silas wrote.",
		"inheritance":
		"Iris. My first child. Her name is in the nursery register. I should have told her.",
		"ritual": "Do not bind me. Moon, thorn, key. Prepare the circle, then let me go."
	}
}

const RESPONSES = {
	"vial":
	{
		"widow":
		"You see? I carried it; I did not prepare it. I will put my letter before the circle. Let them hear the whole story.",
		"doctor":
		"Residue establishes a substance, not an intention. Your conclusions outrun your training.",
		"medium":
		"Then the memory has a witness. Reveal this, and find a second piece that the circle can examine."
	},
	"ledger":
	{
		"doctor":
		"Those are private accounts. Hand them over and I will support your choice of heir. I will not pretend that I want them made public.",
		"keeper":
		"He threatened to expose Blackwell. Now the wrong hour in his testimony means something.",
		"widow": "There is your reason for a murder. It was never my letter."
	},
	"birth":
	{
		"keeper":
		"My mother's name. My father's hand. I will no longer let them call me merely the help.",
		"heir":
		"Firstborn. Not eldest son. I see exactly what those words are meant to take from me.",
		"ghost": "Iris. I should have said her name while I still had a voice."
	},
	"will":
	{
		"keeper":
		"If his firstborn is to inherit, the register matters. I will bring it to the circle if I have it.",
		"heir": "It is his signature. I will not deny that. But I still want my father's seal."
	},
	"rite":
	{
		"heir":
		"Yes, binding keeps him here. You call that imprisonment; I call it keeping the family together."
	}
}

const HINTS = {
	"safe":
	"The inscription asks when Edmund first became a father. In the Memorial Chapel, read the nursery register on the left of the reliquary. If Iris has it, ask her to reveal it. The firstborn entry supplies the year.",
	"radio":
	"The tuning card on the library radio gives the frequency. Move the dial in tenths, then hold that frequency.",
	"candles":
	"Read each image in order: night, a waking garden, an opening door. The symbols stand for those three things."
}
