---
name: seance-first-playtest
description: Run and audit repeatable first-impression Séance playtests with isolated local-model players, a socially teaching rules-reader, non-spoiling stream viewers and five experience ratings. Use for gameplay evaluation, not ordinary unit tests or claims of human entertainment.
---

# Séance first-play evaluation

Use the game's native evaluation runner, not a scripted winning sequence disguised
as six players. Read [evaluation protocol](references/evaluation.md) before running
or interpreting a trial. The project root is three directories above this skill's directory;
keep receipts in the project's ignored `artifacts/` directory.

## Run

Check `AGENTS.md`, engine/compiler health and the already running loopback LM Studio
server first. Never start paid inference or change a user's model/server settings
without authority. This project's user has authorized the local server on port 1234.
Use the model explicitly selected for the experiment; availability is not permission
to silently switch to a larger model or a cloud provider.

```powershell
.\tools\test-agent-party.ps1 -Games 2 -CyclesPerPhase 4 -Viewers 2 -Teacher medium -Model granite-4.1-3b
```

`-Rounds` aliases `-Games`: these are complete matches, each containing three
investigation/séance sittings and judgment. Do not confuse repeated matches with
in-game sittings. Use the user's requested count; otherwise two complete matches
provide a first/second-exposure comparison. Confirm the bounded request budget
fits the count before starting. The runner intentionally makes no cloud calls,
opens no microphone, and uses no Python runtime.

The six actors have separate prompts, histories, notes, capabilities and tool views.
Only the teacher can read the manual. Other players learn socially. They may use
control schemas just as a person learns buttons; do not supply solutions, walkthroughs,
winning policies, host state or lessons from a previous unrelated evaluation.
Repeat matches retain each actor's own learned notes, not an omniscient summary.

Every request, observation, returned action, refusal, allowed message, commentary,
rating and configuration fingerprint is appended to `events.jsonl` before generating
`report.md`. Let a frozen run finish before changing prompts or game rules, unless a
concrete adapter/provider defect prevents a meaningful trial. In that case mark it
interrupted/inconclusive, preserve every partial receipt, and restart corrected
infrastructure with fresh actor histories. Do not stop merely for poor play or low
ratings. Never
delete a bad run, replace a failed action with a scripted success, silently repair
ratings, or count automatic timeout ballots as agent decisions.

## Communication boundaries

Player-to-player speech uses GameRules listening permissions, including Ghost,
Medium, possession and silence. Streamer commentary is not a second player chat bus.
Each viewer sees only its assigned stream. Free reviewer commentary stays in the
operator log; only allowlisted, neutral meta reaction text can return to a player.
Do not forward a viewer's inferred culprit, code, objective, private speech or other
secret through an out-of-game channel. For externally controlled sessions, apply
the same boundary to subagent messages and collaboration tools.

## Inspect and report

Read the machine receipts as well as the derived ratings. Attribute observations to
the correct persona, game and receipt. Separate game UX problems, adapter limitations,
model mistakes and imagined claims. Compare the same five dimensions and same personas
across repeated matches; keep missing/invalid ratings visible. One fixed case means
learning may be spoiler memorization rather than better onboarding.

For v4 and later, require the final `receipt_finalized` event and matching report
and ledger-prefix SHA-256 values as well as a successful runner exit. `run_end` alone
is pending receipt completion, not a finished receipt set. Preserve storage failures as incomplete;
never reconstruct missing original responses. Older frozen protocols retain their
original completion contract rather than being silently rescored under new rules.

State whether the run used the native text adapter, rendered controls, ENet clients,
real voices or human players. Text-adapter runs cannot rate actual visual quality,
physical controller comfort or real-time audiovisual pacing. Synthetic ratings are
signals for the next human playtest, not proof that the game is entertaining.

For independent audit, give a fresh subagent this skill and the receipt directory,
not your expected verdict. It may audit recorded behavior but must not be described
as a blind player that actually participated. If a genuinely new blind actor is
required, give it only its capability-scoped tools and persona, never this operator
skill or project source. See the protocol for external MCP transport boundaries.
