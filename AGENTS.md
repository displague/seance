# Séance: The Unquiet Will

Native Godot 4.6+ / GDScript game. Python is permitted only for offline asset tools,
never as a runtime dependency. Import `project.godot`, or run `PLAY.cmd` on Windows.

## Structure and limits

- Keep every source file below 1,000 lines, including after formatting. Split by responsibility.
- `scripts/case_data.gd`: authored case content; `game_rules.gd`: pure authoritative state.
- `session.gd`: ENet protocol and lifecycle; `voice.gd`: opt-in voice routing.
- `world/`: native 3D environment and characters; `ui/`: presentation and menus.
- Never put game outcomes, permissions, or scoring rules in UI code.
- No `.env` or API secrets in this repository. Asset tools accept an explicit external env path.
- Preserve the shared Sunrise checkout; its interpreter and engine may be reused read-only.

## Validation

- gdtoolkit 4.5.0: `gdformat` is the formatter; `gdlint` uses `gdlintrc`.
- Run `tools/check.ps1` for formatting, lint, file limits, engine import and rules tests.
- Godot's actual compiler is required in addition to the GDScript parser.
- Exercise the rendered game and multiplayer lifecycle for changes to those areas.
- Report what was actually tested. A playable prototype is not a AAA or Steam-ready release.

## Design

- Information is the resource; individual motives outweigh binary team victory.
- The ghost has agency; possession never takes away another player's controls.
- Ghost voice and text use the same server-owned listening rules.
- Use original assets, record provenance in `docs/ASSETS.md`, and keep paid task IDs.
- Add narrowly scoped skills only for repeatable project workflows that need them.

## Repeatable workflows

- `.agents/skills/seance-first-playtest/SKILL.md`: isolated model-player/viewer
  first-experience trials and receipt audits. Keep these distinct from scripted QA.
