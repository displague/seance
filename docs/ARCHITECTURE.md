# Architecture

Native Godot/GDScript. Python is restricted to offline asset generation.

| Responsibility | Files |
| --- | --- |
| Authored cast, clues, geometry positions, motives | `scripts/case_data.gd` |
| Authoritative actions, permissions, phases, scoring, redaction | `scripts/game_rules.gd` |
| ENet lifecycle, role assignment, validated commands, snapshots | `scripts/session.gd` |
| Opt-in microphone capture and permission-checked PCM routing | `scripts/voice.gd` |
| Original procedural sound | `scripts/sound.gd` |
| Scene composition and snapshot-driven presentation | `scripts/main.gd` |
| Manor shell, furniture, props, player, character rigs | `world/` |
| Menus, dossier, evidence, ritual inputs, results | `ui/` |
| Compiler, rules, native runtime, real network processes | `tests/` |

## State flow

Input → Session command → host GameRules validation → recipient-specific snapshot
→ UI/environment. The UI may display available choices but never owns outcomes.
Solo takes the same authoritative path without an ENet peer.

GameRules has no scene-tree, networking, input, rendering, or sound dependency.
An action returns an error string or succeeds; invalid actions preserve protected
state. Private ownership and messages, possession identity/timing, spirit energy,
and individual ballots are redacted before snapshots leave the host.

ENet reliable channel 0 carries commands, feedback, and snapshots. Channel 1 carries
unreliable ordered positions, checked for finite values, estate bounds, and a movement
budget. Channel 2 carries unreliable ordered fixed-size 16 kHz mono PCM packets.
The host resolves a sender from their registered peer ID, not client-supplied role
claims. Voice and text both consult GameRules.can_hear.

Movement remains locally responsive; the host verifies updates but does not run a
full authoritative physics simulation. This is appropriate only for trusted prototype
sessions. There is no packet encryption, transport identity, host migration, reconnect
token, predictive reconciliation, or robust hostile-network defense.

## Ownership and lifecycle

Session owns GameRules and one local view. Leaving closes the peer, stops microphone
capture/output, resets role/lobby state, and clears packet and movement counters.
Disconnected human roles become scripted guests. If all remaining humans have voted,
the host resolves judgment. Host loss returns clients to the menu.

The scene root owns the environment, player, characters, and UI. Menu/journal/ritual
helpers build controls; dialogs release previous controls. No GDScript file relies
on a Python process or an asset-generation service at runtime.

## Presentation

The manor is generated deterministically from native meshes and original ornament.
Floor planks use MultiMesh. Other props remain separable for iteration; static batching,
LOD, and occlusion need a dedicated production optimization pass.

CharacterMotion attaches Meshy's matching included walk/run animations to each
rigged base. Horizontal root motion is stripped because networked world movement
owns displacement. The idle pose is adapted from the base and locomotion clips.
Scripted guests change stage marks at phase boundaries; this is not navigation AI.

Compatibility rendering was chosen for a stable native baseline. No GDExtension,
engine fork, downloaded runtime script, or paid-service call is required to play.
