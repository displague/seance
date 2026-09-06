# Séance: The Unquiet Will

A native Godot supernatural social-deduction game. Only the Medium hears the dead;
everyone has a different reason to tell the truth. A playable **0.1 vertical slice**,
not a finished AAA game or Steam release.

## Play

Double-click **PLAY.cmd** in this directory. In the portable `build` folder, use
its PLAY.cmd or Seance.exe; keep Seance.pck beside the executable.

The source launcher imports assets before starting, including on a fresh clone.
Install Godot first (see below); engine binaries and the portable bundle are not
in Git. Source-launch/import diagnostics are saved in `artifacts/source-*.log`
and `.err`. The first import takes longer than subsequent launches.

Alternatively import `project.godot` in Godot 4.6+ and press F6/F5. This checkout was
compiled and tested with Godot **4.7.stable.official.5b4e0cb0f**, using OpenGL
Compatibility. The game has no Python, API-key, Blender, or cloud runtime dependency.

Choose **Enter Ashwood → Medium → Begin the rehearsal** for a first visit. Read
your private dossier, then step inside. Explore before convening the first sitting;
the house's scripted guests bring their own evidence to the table.

The Windows development bundle contains the full Godot runtime/editor binary and
a compiled PCK. It is unsigned and larger than a release-template build. No engine
installation is needed for that bundle. It is not a retail installer.

## Controls

| Input | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Shift | Move faster |
| E | Inspect the object or speak to the guest under the crosshair |
| F | Toggle lantern |
| J | Journal, evidence, inheritance, private motives, estate guide |
| C | Séance circle / final testament |
| T | Text conversation with server-owned listening rules |
| G | Ghost manifestations, possession, and silence |
| M / hold V | Opt into microphone / push to talk |
| Escape | Close a panel or pause; releases the mouse |

Solo pauses while reading a panel. Multiplayer continues while menus are open.
Mouse sensitivity, master volume, fullscreen, and camera motion are configurable.
Preferences are saved locally; the current case is **not saved**.

## What's playable

- Six selectable roles: Ghost, Medium, eldest heir, widow, physician, housekeeper.
- An explorable 3D manor: séance parlour, library, conservatory, memorial chapel.
- Eight clues; privately collect, transfer, reveal, or destroy evidence.
- Three inheritance objects to claim and gift.
- Three ritual puzzles: radio tuning, candle symbols, and a sealed reliquary.
- Three investigation/séance rounds, followed by a final three-part ballot.
- Separate culprit, beneficiary, and spirit-fate outcomes; release, binding, banishment.
- Individual 2/3/5-point objectives plus up to three preparation points.
- A complete solo rehearsal with five **authored, scripted guests**, not conversational AI.
- Private ENet multiplayer with up to six human players; empty seats are scripted.
- Opt-in push-to-talk, ghost low-pass/echo/reverb, and permission-matched text.
- Sixty-second possession that opens a private channel without taking movement control.
- Temporary Speak No Evil, spirit-board signs, light changes, and spirit energy.
- Original procedural environment, sounds, UI, portrait, and two generated rigged character bases.

## Play together

1. On the host, choose **Host a private circle**, pick a role, and open the circle.
2. Other players choose **Join a circle**, entering the host's IP address. Port is UDP **27877**.
3. On one machine, use `127.0.0.1`. On a trusted LAN, use the host's LAN IPv4 address.
4. If Windows asks, allow Godot on the private network you intend to use.
5. The host begins the sitting. Taken roles are reassigned to a free seat.
6. Microphones begin **off**. M enables your microphone, then hold V to speak.

The Ghost reaches only the Medium during a séance, or the currently possessed guest.
Silenced living guests reach only the Ghost. The dead and living can all speak after
the ending. Text uses the same permissions during play, plus a copy to its sender.
Typing into a text field does not trigger push-to-talk. No audio is recorded.

This is direct-IP, trusted-peer multiplayer: no Steam relay, public matchmaking,
account authentication, encrypted transport, NAT traversal, or host migration.
Do not expose this prototype as a public internet service. A departing guest becomes
scripted; the host leaving ends the sitting for everyone. Joining an ongoing case
is not supported.

## Development

Keep all source files below 1,000 lines. GDScript is formatted/linted with
**gdtoolkit 4.5.0**. The actual Godot compiler, not just a parser, is part of QA.

```powershell
# Uses this checkout's engine and the sibling Sunrise venv read-only.
.\tools\check.ps1
.\tools\check.ps1 -Rendered
.\tools\test-network.ps1 -Address 127.0.0.1
.\tools\build.ps1
```

`check.ps1` accepts `-Engine` and `-LintBin` for another local installation. The
development requirements can be installed into a separate venv; they are not needed
to play. `-Rendered` exercises the real scene and saves viewport images in
`artifacts/qa_*.png`. The network test launches three independent processes and uses
synthetic PCM; it does not enable microphone capture. Logs are under `artifacts`.

The tested compiler harness is `tests/compile_test.gd`. Avoid
`--check-only --script res://ui/...` with this local engine: that mode caused native
access-violation popups during development. Import, compiler harness, gameplay tests,
and rendered startup have since completed without those crashes.

See [architecture](docs/ARCHITECTURE.md), [validation record](docs/VALIDATION.md),
[asset provenance](docs/ASSETS.md), and [production roadmap](docs/ROADMAP.md).

The project uses its own PNG boot splash. Its settings are under `[application]`
in `project.godot`; the source renderer is `tools/render_splash.gd`. The image is
checked into Git so a fresh checkout does not need to regenerate it.

The Git branch is `main`. Engine binaries, build outputs, local test receipts,
raw service responses, and credentials are intentionally excluded from Git.

## Current boundaries

This is one fixed case, not a procedural mystery generator. Bots use authored
testimony and predetermined voting heuristics; they cannot negotiate freely and
not every motive is achievable in solo rehearsal. Two character bases are shared
across six roles, with basic locomotion and a spectral override, not six finished
cinematic performances. Some generated clothing and hands need art cleanup.

There is no streamer spectator mix, Steam integration, save/rejoin, rebinding,
localization, gamepad support, or production anti-cheat. Actual microphone quality,
two-computer LAN play, WAN latency, and minimum-spec hardware remain unverified.

The packed case contains authored secrets, so extraction of game files can spoil
it. Per-recipient network redaction is not a claim of competitive security.
