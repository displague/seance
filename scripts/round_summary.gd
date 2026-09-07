class_name RoundSummary
extends RefCounted
## Presentation-ready, server-owned progress. Hidden activity stays hidden until dawn.

const METRICS = ["revealed", "prepared", "gifts", "signs", "recovered", "destroyed"]
const AWARDS = {
	"revealed": ["Truth bearer", "evidence revealed"],
	"prepared": ["Threshold keeper", "ritual preparations"],
	"gifts": ["Changed hands", "inheritance gifts"],
	"signs": ["Voice beyond the veil", "spirit signs"],
	"recovered": ["Private investigator", "evidence recovered"],
	"destroyed": ["Buried secrets", "evidence destroyed"]
}
const WEIGHTS = [2, 3, 5]


static func initialize(state: Dictionary) -> void:
	state["activity"] = {}
	for role in CaseData.ROLES:
		state.activity[role] = {}
		for metric in METRICS:
			state.activity[role][metric] = 0
	state["activity_baseline"] = state.activity.duplicate(true)
	state["recap"] = {}
	state["recaps"] = []
	state["final_summary"] = {}


static func note(state: Dictionary, role: String, metric: String) -> void:
	state.activity[role][metric] += 1


static func record(state: Dictionary, role: String, action: String, id: String) -> void:
	var metric = {"reveal": "revealed", "task": "prepared", "manifest": "signs"}.get(action, "")
	if action == "collect" and CaseData.CLUES.has(id):
		metric = "recovered"
	elif action == "destroy":
		metric = "destroyed"
	elif action == "give" and CaseData.ITEMS.has(id):
		metric = "gifts"
	if metric != "":
		note(state, role, metric)


static func awards(activity: Dictionary, include_private: bool) -> Array:
	var earned = []
	for metric in METRICS:
		if not include_private and metric in ["recovered", "destroyed"]:
			continue
		var count = activity.get(metric, 0)
		if count > 0:
			earned.append(
				{"title": AWARDS[metric][0], "detail": "%d %s" % [count, AWARDS[metric][1]]}
			)
	return earned


static func capture(game) -> void:
	var state = game.state
	var rows = []
	for role in CaseData.ROLES:
		var activity = {}
		for metric in METRICS:
			activity[metric] = state.activity[role][metric] - state.activity_baseline[role][metric]
		var public_complete = game.completed_goals(role)[0]
		rows.append(
			{
				"role": role,
				"public_objective": CaseData.person(role).goals[0],
				"public_complete": public_complete,
				"public_points": 2 if public_complete else 0,
				"preparation_points": mini(3, state.task_points[role]),
				"awards": awards(activity, false)
			}
		)
	var phase_name = "Investigation" if state.phase == "investigation" else "Séance sitting"
	state.recap = {
		"id": state.recaps.size() + 1,
		"round": state.round,
		"phase": state.phase,
		"title": "%s %d of 3 complete" % [phase_name, state.round],
		"rows": rows,
		"prepared": game.preparations()
	}
	state.recaps.append(state.recap.duplicate(true))
	state.activity_baseline = state.activity.duplicate(true)


static func final(game) -> void:
	var rows = []
	var previous_points = -1
	var rank = 0
	for index in range(game.state.scores.size()):
		var score = game.state.scores[index]
		if score.points != previous_points:
			rank = index + 1
		previous_points = score.points
		var objectives = []
		for goal in range(3):
			objectives.append(
				{
					"category": ["Public objective", "Private objective", "Ulterior motive"][goal],
					"text": CaseData.person(score.role).goals[goal],
					"complete": score.goals[goal],
					"available": WEIGHTS[goal],
					"earned": WEIGHTS[goal] if score.goals[goal] else 0
				}
			)
		rows.append(
			{
				"role": score.role,
				"rank": rank,
				"points": score.points,
				"objectives": objectives,
				"bonus": score.bonus,
				"awards": awards(game.state.activity[score.role], true)
			}
		)
	game.state.final_summary = {
		"rows": rows, "sittings": game.state.round, "truth": CaseData.FINAL_TRUTH
	}


static func phase_info(state: Dictionary) -> Dictionary:
	var round_id = state.round
	match state.phase:
		"investigation":
			return {
				"label": "INVESTIGATION %d / 3" % round_id,
				"countdown": "UNTIL SÉANCE %d" % round_id,
				"next":
				"Explore, negotiate and prepare. The next bell starts a séance, not a new game.",
				"continue": "CONTINUE INVESTIGATION %d" % round_id
			}
		"seance":
			return {
				"label": "SÉANCE %d / 3" % round_id,
				"countdown":
				"UNTIL JUDGMENT" if round_id == 3 else "UNTIL INVESTIGATION %d" % (round_id + 1),
				"next":
				(
					"Séance %d of 3 starts now. " % round_id
					+ (
						"The third sitting ends in judgment. All six guests then seal a final testament."
						if round_id == 3
						else (
							"This is the same case. After discussion, investigation %d of 3 begins."
							% (round_id + 1)
						)
					)
				),
				"continue": "JOIN SÉANCE %d" % round_id
			}
		"judgment":
			return {
				"label": "FINAL JUDGMENT",
				"countdown": "UNTIL FINAL RESULTS",
				"next":
				"Three sittings are complete. Seal your choices; final scores follow the vote or dawn.",
				"continue": "OPEN THE FINAL TESTAMENT"
			}
	return {
		"label": "CASE COMPLETE",
		"countdown": "FINAL SCORES",
		"next": "The case is over. These results remain until you choose to leave Ashwood.",
		"continue": "VIEW FINAL RESULTS"
	}
