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

## Consequences

Rules are testable without rendering. Solo and multiplayer share validation and
scoring. Native rendering and ENet lifecycle still require separate integration QA.
The current build needs further art, networking, accessibility, and production work;
documented limitations must not be presented as implemented features.

## Alternatives

A hybrid Python/Godot runtime was discussed by the user but is not used. External
asset services are offline tools only. Steam relays, public matchmaking, and larger
content production are deferred until the core social loop is playtested.
