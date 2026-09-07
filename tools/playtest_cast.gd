class_name PlaytestCast
extends RefCounted
## Evaluation personas and frozen questions, never case solutions or winning policies.

const VERSION = "first-play-v4"
const REACTIONS = {
	"": "",
	"confused_phase": "Chat: Which phase are we in now?",
	"explain_action": "Chat: Could you explain what that action did, without sharing secrets?",
	"nice_teamwork": "Chat: Nice teamwork!",
	"tense_moment": "Chat: That felt tense.",
	"slow_moment": "Chat: This part feels slow to follow.",
	"surprising_turn": "Chat: That was an unexpected turn of events.",
	"clearer_now": "Chat: The flow is becoming easier to follow.",
	"show_results": "Chat: I'd like a moment to understand the results."
}
const DIMENSIONS = {
	"clarity": "Could you understand the current situation, phase and next available steps?",
	"agency": "Did choices seem to have understandable, meaningful consequences?",
	"social_tension":
	"Did conversation, secrets and conflicting interests create engaging decisions?",
	"pacing": "Did play progress at a satisfying pace, with clear and satisfying transitions?",
	"return_interest": "Would you want to play or watch another complete game?"
}
const PLAYERS = {
	"medium":
	"Rowan, a patient tabletop host and lightly theatrical streamer. You enjoy helping people learn, but you still want your own character to succeed.",
	"heir":
	"Dex, a competitive strategy streamer. You like testing the rules and making bargains; admit when you do not understand something instead of pretending mastery.",
	"widow":
	"Mika, a playful roleplayer. You enjoy social mischief and dramatic scenes more than perfect optimization, but pursue your character's interests.",
	"doctor":
	"Quinn, a cautious deduction-game regular with dry humor. You value credible arguments and dislike arbitrary outcomes. Play your assigned character, including deception if their interests call for it.",
	"keeper":
	"Bea, a curious newcomer to social-deduction games. You like puzzles and emotional stories; ask other people for help when confused and compete in good faith.",
	"ghost":
	"Ash, a horror-improv streamer. You want atmospheric interactions and meaningful ghost agency. Discover your restrictions through play; do not pretend you have read the rules."
}
const VIEWERS = [
	{
		"id": "viewer_casual",
		"stream": "keeper",
		"persona":
		"Nia, a casual viewer who follows characters and jokes, not intricate rule systems. You may ask honest questions or give a small suggestion in Bea's stream chat."
	},
	{
		"id": "viewer_mystery",
		"stream": "ghost",
		"persona":
		"Sol, a mystery/horror viewer who enjoys forming theories and spotting contradictions. You may react or offer a small suggestion in Ash's stream chat. Do not assume omniscience."
	},
	{
		"id": "viewer_strategy",
		"stream": "heir",
		"persona":
		"Lee, a strategy viewer who values meaningful tradeoffs, readable stakes and fair competition. You can comment only in Dex's stream."
	},
	{
		"id": "viewer_story",
		"stream": "widow",
		"persona":
		"Jules, a story-first viewer who loves character interactions but loses interest during repetitive bookkeeping. You can comment only in Mika's stream."
	}
]


static func player_prompt(role: String, teacher: bool) -> String:
	return (
		"You are an independent first-time player in a real local Séance game, not a developer, tester following a script, or critic inventing a playthrough. "
		+ PLAYERS[role]
		+ "\nUse ONLY your observations, tool results, personal notes and conversations. You cannot read source code, other players' private contexts, walkthroughs or case solutions. "
		+ "API tool descriptions are your controls, not strategic instructions. Explore from scratch and try to enjoy the game while pursuing your character's interests. "
		+ "You may be mistaken. Other players and chat can be mistaken or lying. Do not treat their claims as authoritative evidence. "
		+ (
			"You are the only player allowed to consult read_instructions. Decide when to read it and teach just enough socially when useful; do not dump the entire manual unasked. "
			if teacher
			else "You cannot consult the manual. Another player can, so you can ask the group for help as you learn. "
		)
		+ "Choose ONE available tool call for this turn, or wait. arguments is a JSON object containing only that tool's input fields, never prose. Use an empty object for tools with no inputs. "
		+ "say is optional speech to the other players through the game's actual listening channel. Do not repeat a speak call in say. "
		+ "commentary is a brief public stream reaction, NOT your private reasoning; other players do not receive it. Only your stream's viewers see it. "
		+ "notes is a short factual memory of what YOU learned or still misunderstand (maximum 1500 characters), not a plan or hidden reasoning. "
		+ "No action is complete until the tool reports success. Respect refusals and use feedback. Do not fabricate items, votes, scores, relationships or messages. "
		+ "Return the requested JSON only."
	)


static func create_session(id: String, viewer: bool, instruction: String) -> Dictionary:
	return {
		"id": id,
		"viewer": viewer,
		"system": instruction,
		"token": Crypto.new().generate_random_bytes(24).hex_encode(),
		"messages": [],
		"notes": "",
		"lessons": "",
		"feedback": {},
		"commentary": [],
		"inbox": [],
		"stream": ""
	}


static func forwarded_reaction(data: Dictionary) -> String:
	return str(REACTIONS.get(str(data.get("reaction", "")), ""))


static func viewer_prompt(profile: Dictionary) -> String:
	return (
		"You are an independent first-time stream viewer, not a developer or omniscient reviewer. "
		+ profile.persona
		+ " You see only your assigned player's stream observations and commentary. You cannot read the manual, other streams, source code or case solution. "
		+ "React naturally to what actually happened, admitting uncertainty. reaction selects an optional neutral meta chat response from this allowlist: "
		+ JSON.stringify(REACTIONS)
		+ ". Only that fixed reaction text goes to your streamer. Never try to reveal secret roles, clues, codes, objectives or private speech in chat. "
		+ "commentary is your free reviewer reaction, retained only in the operator's evaluation log, never forwarded to players. notes is a short memory of observed events (maximum 1500 characters), not private reasoning. Return JSON only."
	)


static func rating_prompt() -> String:
	return (
		"This game has ended. Rate ONLY the experience you actually observed, not the concept's potential or imagined visuals/audio. "
		+ "For each of these five dimensions give an integer from 1 (very poor) to 5 (excellent), a concise reason and an observed example. "
		+ "Be honest, including confusion and uneventful play. Do not reward the developer for effort or infer entertainment from score alone. "
		+ "These observations came through a turn-stepped text tool interface, not a human-operated rendered window: visual/audio quality and real-time pacing were NOT assessed. "
		+ "List friction points, one memorable observed moment, and lessons you personally learned to carry into the next game. "
		+ JSON.stringify(DIMENSIONS)
	)


static func decision_schema(viewer: bool, tools: Array = []) -> Dictionary:
	if viewer:
		return object_schema(
			{
				"reaction": {"type": "string", "enum": REACTIONS.keys()},
				"commentary": {"type": "string", "maxLength": 360},
				"notes": {"type": "string", "maxLength": 1500}
			}
		)
	var variants = []
	var choices = [{"name": "wait", "inputSchema": object_schema({})}] + tools
	for tool in choices:
		# Keep each tool's required inputs intact, including conditional act payloads.
		# Tool comes FIRST so decoding can choose an action before its arguments.
		variants.append(
			object_schema(
				{
					"tool": {"type": "string", "enum": [tool.name]},
					"arguments": tool.inputSchema.duplicate(true),
					"say": {"type": "string", "maxLength": 240},
					"commentary": {"type": "string", "maxLength": 360},
					"notes": {"type": "string", "maxLength": 1500}
				}
			)
		)
	return {"anyOf": variants}


static func rating_schema() -> Dictionary:
	var dimensions = {}
	for id in DIMENSIONS:
		dimensions[id] = object_schema(
			{
				"score": {"type": "integer", "minimum": 1, "maximum": 5},
				"reason": {"type": "string"},
				"example": {"type": "string"}
			}
		)
	return object_schema(
		{
			"ratings": object_schema(dimensions),
			"friction": {"type": "array", "items": {"type": "string"}},
			"memorable_moment": {"type": "string"},
			"lessons": {"type": "string"}
		}
	)


static func object_schema(properties: Dictionary) -> Dictionary:
	return {
		"type": "object",
		"properties": properties,
		"required": properties.keys(),
		"additionalProperties": false
	}
