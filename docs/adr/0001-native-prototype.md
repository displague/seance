# 0001 — Native Godot prototype with host-owned rules

Status: proposed (records the user's existing project instructions; awaiting confirmation)
Date: 2026-09-06
Specification: [AGENTS.md](../../AGENTS.md), [architecture](../ARCHITECTURE.md)

## Context

Séance is a voice-led social-deduction game with a Ghost, a Medium, conflicting
individual motives, evidence, inheritance, rituals, and multiple endings. This
first checkout is a playable vertical slice, not a production AAA release.

The user selected Godot, permitted native GDScript instead of a hybrid runtime,
required maintainable source files below 1,000 lines, and provided an external
asset-generation credential source. There is no earlier Git history.

## Decision

- Keep the runtime native Godot 4.6+ / GDScript, without Python or cloud dependencies.
- Separate authored CaseData from pure authoritative GameRules; keep outcomes,
  ownership, scoring, and communication permissions out of UI code.
- Route ENet commands through the host and redact snapshots per recipient.
  Ghost voice and text consult the same server-owned listening rules.
- Keep UI, 3D presentation, voice, session lifecycle, and offline tools separate.
- Keep every source file below 1,000 lines after formatting.
- Use original assets with provenance and paid task IDs. Keep credentials,
  raw API responses, generated build outputs, and engine binaries out of Git.
- Treat direct-IP multiplayer as a trusted-party prototype, not public matchmaking
  or competitive anti-cheat. Test with the actual Godot compiler and rendered game.
- Use the game's own PNG boot splash, generated from its original branding.
  Preserve the engine and dependency notices in development bundles.

## Prototype expansion — 2026-09-06 (proposed)

This addendum records the user's subsequent requirements and the implemented
boundaries. It does not mark this decision record as human-accepted.

- Optional solo dialogue uses opt-in loopback LM Studio. Authored NPC personas,
  private knowledge, bargains, consent and actions remain native and host-owned.
  Model text is fallible dialogue, never evidence or an ownership/scoring oracle.
  Native Piper and whisper.cpp are separately installed optional helpers; voice
  capture is explicit and transcripts require review before sending. No Python
  runtime or voice weights enter the game package. See [solo AI](../SOLO_AI.md).
- Appearance preferences are per character and replicated as allowlisted cosmetic
  identifiers. Base characters and gameplay are free; prototype Remembrance is a
  local earned reward, not a paid entitlement or secure account balance. Future
  purchases need a separate service/licensing design. See [cosmetics](../COSMETICS.md).
- Public phase recaps and full final rankings are computed in authoritative rules.
  Private goals and hidden activity stay private until the final reveal; descriptive
  awards do not introduce hidden scoring in UI code.
- Reusable first-play evaluation uses six isolated local-model sessions and scoped
  read-only viewers. Only one seat can read the manual; all player speech follows
  the normal listening rules. Viewer-to-player messages are neutral allowlisted
  reactions, not arbitrary spoiler-bearing text. MCP is opt-in and loopback-only.
  Evaluation uses disclosed turn-stepped time and append-only raw receipts before
  derived ratings. Synthetic ratings do not establish human enjoyment or rendered
  usability. See [agent playtests](../AGENT_PLAYTEST.md).

The alternatives were unrestricted model-controlled game state, cloud-only NPCs,
shared omniscient player/chat context, and paid gameplay advantages. Those are not
used: they conflict with native authority, explicit local consent, useful blind
evaluation, or the user's cosmetic-only economy boundary.

## Consequences

Rules are testable without rendering. Solo and multiplayer share validation and
scoring. Native rendering and ENet lifecycle still require separate integration QA.
The current build needs further art, networking, accessibility, and production work;
documented limitations must not be presented as implemented features.

## Alternatives

A hybrid Python/Godot runtime was discussed by the user but is not used. External
asset services are offline tools only. Steam relays, public matchmaking, and larger
content production are deferred until the core social loop is playtested.
