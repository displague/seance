# Independent first-play trials and local MCP

This evaluation workflow is distinct from `tools/test-six-seats.ps1`, which runs
six scripted ENet clients. Here six separate local-model conversation sessions make
their own decisions through the real authoritative game rules. No canned winning
policy fills their turns. The reusable skill is
[seance-first-playtest](../.agents/skills/seance-first-playtest/SKILL.md).

## Run a trial

Keep LM Studio running on `http://127.0.0.1:1234/v1`, then:

```powershell
.\tools\test-agent-party.ps1 -Games 2 -CyclesPerPhase 4 -Viewers 2 -Teacher medium -Model granite-4.1-3b
```

`-Rounds` is an alias for `-Games`. A game is a complete three-sitting case, not one
investigation or séance phase. `-CyclesPerPhase` grants each of the six players that
many opportunities per phase; initiative rotates. Each opportunity permits one
model-selected tool action and optional permitted speech. The native phase clock
advances between cycles, so model inference speed does not consume another seat's
opportunity. This is a **turn-stepped text-adapter evaluation**, not a real-time,
rendered or physical-controller playtest.

Six roles have distinct player personas, individual histories and notes. Only the
designated teacher can read the manual. Others can ask them questions and learn
socially. Each persona carries its own learned notes into subsequent games. The same
authored mystery is reused, so improved outcomes may reflect memorized secrets rather
than improved onboarding. No host state, source code or solution is sent to the players.

Default viewers are a casual story follower watching Iris and a horror/mystery fan
watching Edmund. `-Viewers 0..4` adjusts the cast. Additional viewers watch Julian and
Lenore. Each sees only its assigned stream; free reviewer commentary stays in the
operator log. Only allowlisted neutral meta reactions can return to that one player.
Even a model that writes a secret in its commentary cannot forward that text to a
player or another stream. There is no shared backstage player chat bypassing the
Ghost/Medium, possession or silence rules.

## Ratings and receipts

Every player and viewer gives five integer ratings from 1 (very poor) to 5
(excellent): clarity, meaningful agency, social tension, pacing and desire to return.
Each needs a reason and observed example, plus friction points, a memorable moment
and learned notes. Invalid/missing ratings stay visible; no substitute is invented.

Every run creates a unique `artifacts/agent-party-<timestamp>-<id>/` with:

- `events.jsonl`: append-only configuration, source fingerprints, actual actor inputs,
  model outputs, actions, refusals, channel-scoped speech, viewer reactions and ratings.
- `report.md`: derived per-person/per-game scores, explanations, learning and caveats.
- `engine.log`: native process diagnostics and action progress.

Logs include private dossiers and case spoilers for the operator. They are not fed
back to active actors. The model's private reasoning channel is not published as
streamer commentary. A maximum of 600 requests is the default cap; change `-MaxCalls`
explicitly for longer experiments. Six invalid/model-failed turns stop the run with
an incomplete receipt. Failed turns are not replaced by scripted actions.

Inspect event receipts alongside ratings: models may describe actions they never
successfully performed, overrate an uneventful experience or misremember an event.
The report separates submitted ballots from the game's automatic timeout defaults.
Synthetic ratings are useful leads for human testing, not proof of entertainment,
visual quality, real-time pacing or commercial readiness.

The initial `first-play-v1` trial stopped after seven requests because a JSON-string
argument format elicited prose rather than executable fields. Its incomplete receipt
is preserved in `artifacts/agent-party-20260906-204450-fc696c91`. Protocol v2 uses a
schema-constrained nested argument object; it starts new sessions, not repaired v1
turns. This was an adapter failure, not a game-experience score.
The v2 pilot was also stopped and marked inconclusive: a merged schema dropped
tool-specific required fields, and some advertised actions were unavailable in the
current state. Its partial ledger and interruption note remain in
`artifacts/agent-party-20260906-204705-1a371207`. Protocol v3 preserves each tool's
required inputs and orders tool selection before argument decoding. Those pilot
failures are not discarded or counted as completed first-impression games.

Per-person context includes the current authorized channel transcript, own notes,
latest tool result and one previous model exchange; the full operator ledger is not
replayed into every prompt. Source fingerprints are compared again at the end, and
the run is incomplete if sources drift or any requested persona rating is missing.

The completed v3 trial and its independently checked negative findings are recorded
in [first-play findings](PLAYTEST_FINDINGS.md), including all 16 original five-axis
ratings. Current v4 adds receipt I/O and required-rating-field hardening after that
frozen run; no live v4 run replaces or repairs the v3 outcome.

For v4+, successful receipt completion also requires a final `receipt_finalized`
event whose SHA-256 matches `report.md`, and a successful runner exit. The preceding
`run_end` marks experiment completion with receipt status pending. Storage failures
stop further model/actions and return a nonzero exit; truncated or missing original
responses are not regenerated to fill the gap.

## Optional external MCP host

The regular game opens no MCP listener. For external agents, a separate explicitly
started native host can expose the same capability-scoped API on loopback port 8178.
It uses native real-time phase timers, all six seats marked human and no NPC policy.
Movement is still immediate at the adapter boundary: `walk` validates a route and
returns `travel_seconds`, but this host does not schedule/debit that travel time.
Consequently this mode cannot measure native movement speed or real-time action
economy. A future coordinator must schedule travel before claiming that equivalence.

Create a private local JSON configuration under ignored `artifacts/` containing
`seats` (each of `medium`, `heir`, `widow`, `doctor`, `keeper`, `ghost` mapped to a
distinct cryptographically random token of at least 24 characters), `teacher`, `port`,
`maximum_seconds` and optional `viewers` entries with `token` and `stream_role`.
Do not put this configuration in Git or share all tokens with any participant.

```powershell
.\tools\godot\Godot_console.exe --headless --path . --script res://tests/playtest_host.gd -- --serve-mcp --capabilities=C:/path/to/game/artifacts/mcp-capabilities.json
```

Clients send `Authorization: Bearer <their own token>` to
`http://127.0.0.1:8178/mcp`. Tokens never belong in URLs or printed launch arguments.
Give a blind external agent only its persona, one scoped token and the tool controls,
not repository history or this operator document. External subagent messages must
also respect game listening rules; use `speak` instead of an unrestricted group bus.

Supported MCP **2025-11-25 JSON-response subset**: `initialize`, notification
acknowledgment, `ping`, `tools/list`, `tools/call`. Tools are `observe`, `journal`,
`inspect`, `walk`, `act`, `speak` and teacher-only `read_instructions`. Viewers are
read-only and see either the public feed or one explicitly assigned perspective.
The host grants no shell, filesystem, network-management, score-setting or phase-skip
tools. All game actions retain normal authoritative validation.

The transport requires bounded JSON POST requests to `/mcp`, Bearer authorization,
valid localhost Host/Origin and a supported protocol version. GET returns 405; no SSE,
remote binding, general-purpose OAuth or claim of complete MCP conformance is made.
The process exits after its configured lifetime (at most two hours). It is an
experimental developer interface, not an authenticated public online game service.

The built-in local-model runner calls this same tool layer in-process. Its trial is
not evidence that six external MCP clients or six ENet clients participated. Separate
native tests cover actual authenticated HTTP calls and a standalone host process.

Protocol references: [MCP 2025-11-25 lifecycle](https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle)
and [Streamable HTTP transport](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports).
