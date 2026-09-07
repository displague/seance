# Six-seat exercise and next gameplay work

The section below records the earlier scripted network exercise, not the user's
requested independent first-impression trial. The latter now has a separate native
[local-model and MCP workflow](AGENT_PLAYTEST.md) with isolated actor histories,
one rules-reader, viewer boundaries, repeat games and five per-person ratings.

## Exercise completed — 2026-09-06

`tools/test-six-seats.ps1` launches six independent Godot ENet processes on one
machine. Each seat follows an explicit motive-oriented test policy, moves through
normal position messages, interacts with the authoritative game and submits a
ballot. Phase timing is accelerated for reproducibility. This is **not** six human
testers, six independently deliberating LLM agents, a 45-minute soak or an assessment
of how entertaining a real stream will be.

All **75 assertions passed**: Medium 19, heir 12, widow 13, physician 11,
housekeeper 12 and Ghost 8. Receipts are `artifacts/party-<role>.log` and `.err`.
The separate three-process suite checks more lifecycle/disconnection cases.

### Outcome spoilers

| Seat | Pursued strategy | Final score |
| --- | --- | ---: |
| Medium | Recover medical/botanical evidence, prepare rituals, expose the physician and release the spirit | 12 |
| Widow | Reveal her letter, pass the locket to Iris, support release | 10 |
| Housekeeper | Recover the register and key, establish her claim to the estate | 10 |
| Ghost | Use manifestations and the private Medium channel, seek truthful judgment | 8 |
| Heir | Secure signet/testament, campaign for binding | 5 |
| Physician | Destroy his ledger, redirect accusation | 5 |

All six clients agreed on physician as culprit, Iris as heir and release as spirit
fate. The Ghost's words reached the Medium but not ordinary living seats. The locket
actually changed hands; this was not just dialogue asserting that it happened.

## Design findings, not measured player satisfaction

The most promising dramatic beats are a private ghost statement conflicting with
the Medium's account, an heir demanding an object for testimony, and a recipient
accepting a cursed inheritance. Those create decisions an audience can understand.
The current fixed-case/policy exercise does not show that those beats occur often
enough in unscripted play.

The Medium has a comparatively reliable route to preparation and evidence points.
Julian and Blackwell depend more on persuading others; their low scores here identify
a balance question, not proof of a universal advantage from one scripted match.
Destroying the ledger can foreclose another role's objective. That consequence needs
clear feedback and alternative ways to stay competitive, without making secrets
meaningless. An independent multi-seed policy evaluation and human sessions are next.

The reported reliquary dead end was also a presentation problem: collecting a clue
closed its panel, and “the year that changed everything” did not identify what to
look for. Full pickup text, the explicit firstborn wording, a journal breadcrumb
and a request to Iris now supply a traversable clue chain. No test secretly grants
the player the answer as a reward.

## Gameplay directions and evaluation implementation status

1. **More spatial choices.** Add native door state with explicit interaction,
   collision/nav updates and host-owned replication. Connect library and chapel
   through a discoverable sliding-shelf passage. Require a clue/action to unlock it,
   and test both player collision and NPC rerouting; do not teleport NPCs through it.
2. **Witness-aware theft.** Define room/line-of-sight/light witnesses before adding
   steal or conceal actions. Current item-claim announcements can expose an action
   even during darkness, so the existing lighting effect alone is not stealth.
   Record private witness testimony and a redacted public incident, with sufficient
   counterplay to avoid an untraceable theft button.
3. **Opt-in audience director.** Host-controlled, rate-limited votes for cosmetic
   signs or bounded room outages. Give viewers a visible cooldown/energy budget;
   freeze disruptive effects during accessibility-sensitive or decisive ritual
   moments. No arbitrary commands, secret-state reads or paid gameplay advantage.
   Start with local synthetic votes; actual Twitch/YouTube integration needs explicit
   account connection, moderation and consent for the spectator information mix.
4. **Loopback agent/MCP adapter — experimental implementation added.** Per-seat
   observe, journal, inspect, walk, act and speech use scoped capability tokens.
   Instructions are teacher-only; viewers are read-only; there are no shell, source,
   score-setting or arbitrary debug tools. The listener starts only explicitly.
5. **Independent party evaluation — reusable runner added.** Six isolated local-model
   sessions and optional viewers provide decisions and five-dimension ratings. Source
   fingerprints, failures and actual outcomes are preserved. Repeat matches retain
   only each persona's own learned notes. This currently exercises one fixed case
   through text tools; independent case seeds, rendered agents and human comparisons
   remain future evaluation work.

Audience control, secret passages, opening/closing doors and theft under cover of
darkness remain design proposals, not currently available menu features. Developer
MCP and the model-party runner are explicitly launched tools, not a live stream
integration or public matchmaking service.
