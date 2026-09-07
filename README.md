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
the house's native guests pursue their own objects and bring recovered evidence to the table.

Choose **Solo with local AI…** to add free-text conversation to those native guests.
LM Studio uses `http://127.0.0.1:1234/v1`; click **Check models**, select
LFM2.5-2.6B or Granite 4.1-3B, then choose your character. Both were exercised against
the real local server. NPCs have distinct histories and motives: show evidence,
request disclosures, bargain for objects, or arrange a transfer to another guest.
Open-ended dialogue is fallible and labelled separately from recovered evidence.

Optional native voices and reviewed push-to-talk transcripts are described in
[solo AI setup and limits](docs/SOLO_AI.md). No microphone opens automatically.
The normal rehearsal still works with no model server or speech helper installed.

The Windows development bundle contains the full Godot runtime/editor binary and
a compiled PCK. It is unsigned and larger than a release-template build. No engine
installation is needed for that bundle. It is not a retail installer.

## Controls

| Input | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Shift | Move faster |
| E | Inspect the object or speak to the guest under the crosshair |
| F | Toggle lantern (living only; the Ghost has its own glow) |
| J | Journal, evidence, inheritance, private motives, estate guide |
| C | Séance circle / final testament |
| T | Text conversation with server-owned listening rules |
| G | Ghost manifestations, possession, and silence |
| M / hold V | Opt into microphone / push to talk |
| Escape | Back to the journal from details; close top-level panels or pause |

Solo pauses while reading a panel. Multiplayer continues while menus are open.
Mouse sensitivity, master volume, fullscreen, and camera motion are configurable.
Preferences are saved locally; the current case is **not saved**.

Xbox, PlayStation and Stadia Bluetooth controllers use Godot's standard SDL mappings:
left/right stick move/look, south button interact, west journal, north circle.
Stadia ≡ opens the journal directly; … opens pause. Xbox/PlayStation Start/Options
opens pause and Back/Share opens journal. B/Circle returns details to their journal.
LB/RB (L1/R1) cycle journal tabs; right stick scrolls panels, with left/right selecting
the reading pane in conversations. D-pad up opens spirit powers, down transcript,
left opt-in mic, right lantern. Hold LB/L1 to talk outside journal tabs; keyboard V
can still speak while reading the journal (not while typing in a text field). Press left
stick to sprint. Settings include stick
deadzone, look speed and rumble. A Google Stadia Controller was detected with a known
SDL mapping during final validation; gameplay tests used synthetic events, not a
human-operated pad. Bluetooth transport and felt rumble still need a hands-on check.
Controller/headset audio can be selected
only if Windows exposes an output device; this switches the entire game mix.

Choose **Wardrobe** on the role screen to save each character's preferred look.
Your equipped model is replicated to other players and used in guest portraits.
Six distinct Ashwood characters are free; Medium/Physician also have a Heritage look.
Silver brooches are free; a gold brooch unlocks with gameplay-earned Remembrance.
No paid store is live. See [cosmetic economy boundaries](docs/COSMETICS.md).

The ghost can spend 20 energy on a room's spirit breeze or weeping walls. Lamps go
out temporarily; a living guest can inspect the affected wall to calm the cold spot.
Blood/slime and reduced-flash settings are free. The original adaptive instrumental
score has a separate volume slider and ducks under live speech.

## What's playable

- Six selectable roles: Ghost, Medium, eldest heir, widow, physician, housekeeper.
- An explorable 3D manor: séance parlour, library, conservatory, memorial chapel.
- Eight private clues plus a final, fixed public bank-audit reference.
- Three inheritance objects to claim and gift.
- Three ritual puzzles: radio tuning, candle symbols, and a sealed reliquary.
- Three distinct investigation chapters: initial evidence, will/lineage/radio,
  then financial audit/reliquary; each ends in a séance, followed by final judgment.
  The schedule and later dependencies are visible in your dossier and estate guide.
- Separate culprit, beneficiary, and spirit-fate outcomes; release, binding, banishment.
- Individual 2/3/5-point objectives plus up to three preparation points.
- Explicit phase recaps with six-player public progress and earned action awards;
  persistent final rankings with full objective breakdowns. No automatic new game.
- An authored solo rehearsal, plus optional local conversational AI with five goal-driven guests.
- Private follow-up conversations, evidence-based disclosures and voting, and explicit-consent trades.
- Private ENet multiplayer with up to six human players; empty seats are scripted.
- Opt-in push-to-talk, ghost low-pass/echo/reverb, and permission-matched text.
- Sixty-second possession that opens a private channel without taking movement control.
- Temporary Speak No Evil, spirit-board signs, light changes, and spirit energy.
- Original procedural environment, adaptive score and effects; six distinct generated characters plus two Heritage looks.

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
.\tools\test-six-seats.ps1
.\tools\test-agent-party.ps1 -Games 2 -Viewers 2 -Model granite-4.1-3b
.\tools\build.ps1
```

`check.ps1` accepts `-Engine` and `-LintBin` for another local installation. The
development requirements can be installed into a separate venv; they are not needed
to play. `-Rendered` exercises the real scene and saves viewport images in
`artifacts/qa_*.png`. The network test launches three independent processes and uses
synthetic PCM; it does not enable microphone capture. Logs are under `artifacts`.
The separate six-seat test runs six real local processes with scripted goal policies;
it is not a human playtest or six independently reasoning language models. Explicit
live-model/voice tests are documented separately and are not part of the offline gate.
The [independent agent trial](docs/AGENT_PLAYTEST.md) uses six isolated model sessions,
one teaching player and non-spoiling viewer reactions. Unlike the six-process script,
its players choose their own actions. It is a text-adapter experiment, not human QA.

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
knowledge, bounded bargaining rules and evidence-sensitive voting heuristics. Local
AI adds conversational interpretation, not an unrestricted planner. Active guests
walk authored routes; they cannot improvise arbitrary plans, lie convincingly about
every secret, or complete every motive in every solo role. Six distinct models have
basic locomotion, not cinematic performances or facial animation. Some generated
clothing and hands need art cleanup.

There is no streamer spectator mix, Steam integration, save/rejoin, rebinding,
localization, Twitch/YouTube integration, audience voting, operable doors, secret passages,
or production anti-cheat. See [six-seat findings and next gameplay work](docs/PLAYTEST.md).
An optional loopback-only developer MCP host is available for controlled experiments;
it is disabled during normal gameplay.
Actual microphone quality,
two-computer LAN play, WAN latency, and minimum-spec hardware remain unverified.

The packed case contains authored secrets, so extraction of game files can spoil
it. Per-recipient network redaction is not a claim of competitive security.
