# Evaluation protocol

## What is being evaluated

`tools/agent_playtest.gd` owns one real GameRules match with all six seats marked
human, so automatic NPC scripts do not substitute for model decisions. Six independent
message sessions call a local LM Studio model through `PlaytestModel`. This does not
require six separately loaded weight copies. Persona and knowledge histories are
isolated; the transport does not share prior responses between sessions.

Players discover room exits, nearby object controls, their own dossier and legal
actions through `PlaytestTools`. They can investigate, inspect, collect, reveal,
destroy, give, use apparatuses, manifest, possess, silence, speak and vote where the
ordinary authoritative rules permit. Movement follows small, validated path steps;
it is not a claim of rendered visual navigation or perfect physics equivalence.

The coordinator advances the native game clock between equal-opportunity six-seat
cycles, excluding inference latency. It rotates initiative each cycle. This prevents
a slower model request from consuming another player's turn but differs from realtime
play. `-CyclesPerPhase` sets opportunities, not seconds. A low count can itself produce
uninformative or rushed play; record it rather than concealing that limitation.

## Cast and exposure

Six player styles are fixed in `tools/playtest_cast.gd`: helpful tabletop host,
competitive strategist, playful roleplayer, cautious deduction regular, curious
newcomer and horror improviser. They share no backstage chat. The default teacher is
the Medium; change `-Teacher` explicitly to evaluate another social-teaching setup.
The teacher has access to a short gameplay manual, not a walkthrough or case solution.

Up to four viewer styles are available. Defaults are a casual viewer of Iris's stream
and a mystery viewer of the Ghost's stream. Additional strategy/story viewers watch
Julian/Lenore. A stream feed may contain the perspective character's secrets, just as
their screen can, but that does not authorize relaying them to players or other
streams. Viewer free text is retained only for operator review; forwarded chat comes
from a fixed list of non-spoiling meta reactions. This constrained chat is not a full
simulation of a live audience.

The operator can inspect the complete audit ledger after the trial; no actor can.
Reports and logs contain case spoilers and private-role observations. Do not paste
the operator transcript into an active player or viewer session.

## Frozen ratings

Every player and viewer rates these five dimensions from 1 (very poor) to 5
(excellent), with a reason and an observed example:

| Dimension | Question |
| --- | --- |
| Clarity | Could they understand the current situation, phase and next steps? |
| Agency | Did choices have understandable, meaningful consequences? |
| Social tension | Did conversation, secrets and conflicting interests create engaging decisions? |
| Pacing | Did the observed turn flow and transitions feel satisfying? |
| Return interest | Would they want to play or watch another complete match? |

For viewers, agency means the agency they observed the player having. Pacing excludes
rendered realtime latency in text trials. Do not convert model ratings to human NPS,
sales forecasts or release readiness. No average should hide a missing response.

Also retain each persona's friction list, memorable observed moment and learned notes.
The next match receives only that persona's own learned notes. The case is currently
fixed, so second-game improvements are confounded by revealed secrets and memorization.

## Receipt interpretation

- `configuration`: protocol version, model, counts, teacher, clock semantics and source hashes.
- `model_input` / `model_output`: the actor's exact visible message context and reply content.
  The model's private reasoning channel is neither requested as commentary nor published.
- `player_action`: authoritative outcome and communication result, including refusals.
- `viewer_reaction`: free reviewer text for the operator and the safe reaction actually relayed.
- `match_end`: score outcome, explicitly submitted ballots and timeout/default ballots.
- `rating`: original response plus validation flag, followed by derived report rows.
- `model_error` / `aborted`: preserved failures, not silent fallback policies.
- `run_end`: finished experiment state; v4 marks receipt finalization pending.
- `receipt_finalized` (v4+): written after verified report output; its report SHA-256
  must match the derived file and ledger-prefix SHA-256 must match all preceding
  raw ledger bytes (including their line endings). Require successful process exit
  and this marker before claiming a complete receipt set. Missing/truncated receipts are an infrastructure
  failure, not a replacement gameplay outcome. Do not retroactively apply a new
  protocol's completion rules to archived trials.

Check claims against these events. “I traded the ring” is not a trade unless the
authoritative result transferred ownership. A model may name a memorable moment
that never happened or give high ratings despite passivity. Report that discrepancy.
Keep native timer/gameplay defects separate from adapter affordance differences,
strict-schema decoding failures and absent audiovisual observation.

## External agent / MCP mode

`PlaytestBridge` implements a bounded HTTP MCP/JSON-RPC subset on loopback only,
using per-seat Bearer capabilities. Supported transport/protocol details and the
standalone host command are documented in `docs/AGENT_PLAYTEST.md` in the project.
It is not a general shell, source reader or Godot debug server.

An external Luna or other agent may be a blind player only if it receives a fresh
session with no inherited repository/task history, only its public persona and
one capability-scoped endpoint. Do not give it this operator skill, the case source,
other seat tokens or the shared audit ledger. If the tool environment cannot enforce
or reasonably maintain that separation, use the isolated local-model runner and
state the limitation. Outside-game messages must still use the seat's permitted
communication path. Viewer capabilities are read-only; instructions remain teacher-only.

A fresh reviewer agent can audit receipts after the game. That is useful independent
validation of the report, but is not another player or viewer first-impression score.
