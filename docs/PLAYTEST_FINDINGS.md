# Frozen first-play findings — 2026-09-06

Operator report; contains case spoilers. Do not give this document to blind players.

Trial `agent-party-20260906-210314-4dfbe53a`, protocol `first-play-v3`, used
`granite-4.1-3b` through the user's loopback LM Studio server. Six independent player
histories, two separate viewer histories, Medium-only manual access, two complete
games and four six-seat cycles per phase were fixed before the run. The model made
380 requests with no provider/format errors. All 16 original ratings were retained.
Source fingerprints were unchanged at completion (event 1160); run end is event 1161.

The trial completed technically but **did not demonstrate a successful party
experience**. It used text tools and a turn-stepped clock, not rendered windows,
ENet clients, real microphones or controllers. A separate fresh read-only Luna agent
audited the receipts after the run; it was not a player, viewer or coach.

## What actually happened

| Observation | Game 1 | Game 2 |
| --- | ---: | ---: |
| Player-selected tool calls | 168 | 168 |
| Refused attempts to inspect an out-of-reach object | 127 | 99 |
| Successful inspections | 0 | 2 |
| Successful walks | 0 | 3 |
| Observe calls | 37 | 42 |
| Successful `speak` tool calls | 4 | 22 |
| Player-submitted ballots | 0/6 | 0/6 |

Optional accompanying speech is recorded separately from `speak` tool calls; these
counts are not the total number of spoken messages. No collect, exchange, ritual or
vote action was selected. The two successful inspections were events 645 and 654.
Both endings were timeout defaults: no culprit, Julian inherits, spirit banished
(events 556 and 1135). Those were not six players deliberately choosing an ending.

Only the Medium could request instructions, but it never chose to read them. Thus
this run exercised access isolation, not successful socially delivered teaching.
All 28 viewer turns stayed within the assigned Keeper/Ghost stream scopes; none
forwarded a chat reaction. This run therefore does not demonstrate engaging chat
participation, though offline tests exercise permitted/forbidden forwarding.

Some individuals learned to walk and inspect in game two. Most remained stuck
repeating rejected interactions, and none reached consequential item or ballot
actions. This is a model-plus-adapter discoverability failure worth investigating,
not evidence that a human would fail in the same way. Reusing the same case also
confounds learning with spoilers and memorization.

## Original self-reported ratings

Untrusted model opinions, not verified satisfaction measurements. Axes and the
integer 1–5 scale were fixed beforehand. No scores were repaired or averaged.

| Game | Persona | Clarity | Agency | Social tension | Pacing | Return interest | Event |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | Medium / Rowan | 4 | 3 | 5 | 3 | 4 | 559 |
| 1 | Heir / Dex | 3 | 2 | 5 | 3 | 4 | 562 |
| 1 | Widow / Mika | 4 | 3 | 5 | 2 | 4 | 565 |
| 1 | Doctor / Quinn | 4 | 3 | 5 | 3 | 4 | 568 |
| 1 | Keeper / Bea | 4 | 3 | 5 | 4 | 4 | 571 |
| 1 | Ghost / Ash | 3 | 2 | 4 | 3 | 3 | 574 |
| 1 | Casual viewer / Nia | 4 | 3 | 4 | 3 | 3 | 577 |
| 1 | Mystery viewer / Sol | 4 | 3 | 5 | 4 | 4 | 580 |
| 2 | Medium / Rowan | 4 | 3 | 5 | 4 | 4 | 1138 |
| 2 | Heir / Dex | 4 | 3 | 5 | 3 | 4 | 1141 |
| 2 | Widow / Mika | 4 | 3 | 4 | 3 | 2 | 1144 |
| 2 | Doctor / Quinn | 4 | 3 | 5 | 3 | 4 | 1147 |
| 2 | Keeper / Bea | 4 | 3 | 5 | 3 | 4 | 1150 |
| 2 | Ghost / Ash | 3 | 2 | 4 | 3 | 3 | 1153 |
| 2 | Casual viewer / Nia | 4 | 3 | 5 | 4 | 4 | 1156 |
| 2 | Mystery viewer / Sol | 3 | 2 | 4 | 3 | 4 | 1159 |

The high social scores substantially overstate demonstrated gameplay. For example,
the Heir's game-one explanation describes discovering an engraved cipher and making
a meaningful final vote (562), although it never successfully inspected or voted.
The Doctor describes manipulating watch hands (568); no such physical manipulation
occurred. The final mystery viewer describes a ticking stopped watch, gestures and
vocal delivery (1159); the interface supplied no rendered or voiced performance.
These are unsupported embellishments, not missing game features inferred from proof.

Phase/object labels were genuinely visible, repeated conversation did happen, and
some frustration about repetitive speculation is supported. Claims about meaningful
agency, rich evidence progression, audiovisual immersion and human replay interest
are not established. The ratings remain visible precisely so these discrepancies
can be audited rather than hidden behind an aggregate score.

## Next experiments, not retroactive fixes

- Test whether neutral control feedback makes `walk`/`collect` discoverable, without
  giving away clues or forcing a winning sequence.
- Separately test a designated teacher who actually elects to read and teach, and
  measure whether others use the shared instruction.
- Compare another model or blind external agents under a newly frozen protocol.
- Use human rendered sessions to judge atmosphere, pacing, voice and stream appeal.

The v1/v2 adapter failures remain in their original directories. Subsequent v4
hardening adds stricter rating-field and receipt-write validation, not altered score
axes, revised v3 ratings or a replacement successful game. No live v4 trial was
substituted for this result.

Full raw inputs/actions and per-person explanations remain in the local ignored
`artifacts/agent-party-20260906-210314-4dfbe53a/events.jsonl` and `report.md`.
Frozen ledger SHA-256:
`11fea5f46b16c319b0010c449bbd695f276331e93c8d775cdbfb975b0c2ae2af`.
See [the reusable workflow](AGENT_PLAYTEST.md) for scope and repetition controls.
