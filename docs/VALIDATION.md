# Validation record — 2026-09-07

## Gameplay-feedback follow-up: chapters and controller navigation

Current follow-up source checks cover staged evidence/preparations, listener-specific
ownership disclosures, first-person puzzle hints, continuing NPC movement, and real
widgets driven by synthetic SDL gamepad events. The final reviewed source candidate
passed `tools/check.ps1 -Rendered` with **1,487 distinct checks**, including the
133-check progression suite and 43-check navigation suite. Rendered repetitions are
not extra cases. Formatting/lint passed for 65 GDScript files; the source-limit gate
counted 80 files, largest 699 lines. Engine import and actual compilation passed.

| Suite | Checks |
| --- | ---: |
| Authoritative rules | 204 |
| NPC authority and consent | 99 |
| Chapter boundaries, anti-lockout audit, continued NPC movement and privacy | 133 |
| Phase recaps and final ranking UI | 85 |
| Scoped MCP API and affordance fidelity | 497 |
| Independent-session harness invariants (offline only) | 82 |
| Asset/rig/splash checks | 87 |
| Real scene, raycasts, keyboard, puzzles and all three chapters | 102 |
| Cosmetics, gamepad, haunting and music | 62 |
| Conversation and playback UI | 17 |
| B/Back, bumper tabs, stick panel scrolling, Stadia mappings and PTT isolation | 43 |
| Three-process ENet lifecycle and synthetic voice routing | 76 |

Godot 4.7 OpenGL Compatibility rendered navigation, round summaries, social panels,
full gameplay and feature checks successfully. Screenshots include
`artifacts/navigation-{conversation,schedule}.png` and updated `qa_*`, `social-*`,
`round-*`, `feature_*` frames. The main worker inspected the actual rendered panels.
Stadia was detected in rendered mode, but test inputs were injected: Bluetooth
reliability, physical button labels and felt rumble are not certified by these tests.
No microphone was opened, no new live LLM trial was run, and no model ratings were
replaced. The existing negative independent-party findings remain unchanged.

The separate six-peer chapter-aware exercise passed **91 checks** again on the
final candidate, with agreeing
replicated final outcomes and a public audit surviving ledger destruction. See
[scripted exercise](PLAYTEST.md). Its first attempt found a Godot compiler error in
a multiline test lambda despite gdtoolkit accepting it. That fixture now uses a
named callback, and the normal compiler harness also loads the six-seat/live-local
scripts. The negative receipt is `artifacts/party-chapter-parse-failure.err`.

Initial movement regression tests also exposed a chapel-threshold route that could
strand a guest. The route now exits through the actual doorway, and tests measure
movement after the initial goal pass in every chapter. These checks establish the
bounded authored policy's behavior, not human enjoyment or a general AI planner.

The final candidate also covers keyboard push-to-talk while journal bumpers are
reserved, scroll equivalence at simulated 60/1,000 FPS, physical guests in ordinary
solo without enabling the model, and a Ghost-requested audit errand. The errand
waits for chapter three, requires actual NPC arrival, refuses human-controlled
targets and cannot be promised after the final investigation has ended. Review
findings and deliberate performance deferrals are recorded in [REVIEW.md](REVIEW.md).

### Rebuilt chapter-aware Windows bundle

`tools/build.ps1 -SkipChecks` produced a **203,447,524-byte** `build/Seance.pck`
after the final source gate and review. SHA-256:
`b532fac43c59698a850ae47e7a1c7e62be61d9d60c9e312abc11fabfa0c985b3`.
From the build directory, the external native gameplay harness passed all **102
checks** against that PCK with no source project-path argument. A separate rendered
180-frame startup also passed. Logs: `artifacts/packed-chapters-runtime.log` and
`artifacts/packed-chapters-rendered.{log,err}`. These repeat existing coverage;
they are packaging evidence, not additional distinct test cases.

The first packed gameplay run overlapped the six-peer host and could not bind its
localhost port, failing three host-lobby assertions. Its log is preserved as
`artifacts/packed-chapters-port-collision.log`. Once the six-peer run exited, the
same packed harness passed without code or criteria changes. Host-binding tests
must run serially, as must focus-sensitive rendered tests.

No gameplay changes followed the final source gate. This remains an unsigned
editor-runtime development bundle, not a Steam or AAA release.

Historical validation below describes the earlier build, not this follow-up's new
chapter rules or controller behavior.

## Solo AI, phase recaps and independent-agent infrastructure

The optional LM Studio path was exercised against the running local server with both
`lfm2.5-2.6b` and `granite-4.1-3b`: focused integration runs each passed **27
checks**. These generated six actual native Piper voice clips, transcribed generated
speech through whisper.cpp, obtained non-canned personal dialogue, negotiated a real
offer and transferred ownership only after explicit acceptance. The tests never
opened a physical microphone. Clips prove PCM synthesis, not actor performance quality.
These live runs preceded the final review's empty-reply and active-playback guards;
those guards were verified by the final offline/native gate below, not another live run.

Observed final six-role hint response times were **1.82–5.76s for LFM** and
**0.32–0.76s for Granite** on this machine; these tiny warm-server samples are not a
general model benchmark. Piper synthesis in those runs was roughly **0.39–0.69s** per
short line. Logs: `artifacts/solo-live-{lfm,granite}-final.log`.

Earlier negative results are retained: small reply budgets exhausted LFM's reasoning
tokens before a visible answer; model prose invented puzzle locations; one LFM run
selected an inheritance speech instead of proposing a trade. The implementation now
uses schema-constrained options, authored outcomes for actual actions, grounded named
puzzle routes and explicit object-request guidance. Free dialogue remains fallible.
The failing offer receipt is `artifacts/solo-live-lfm-offer-misselection.log`.

Recaps now distinguish the six phase transitions within one three-sitting case from
the final ending. Six-player public progress and phase activity awards do not expose
hidden motives; final rankings include all objective values and earned awards.
Screenshots `artifacts/round-{investigation,sitting,circle,judgment,results,details}.png`
were inspected. All six final score rows fit at 1440×810; objective details are
scrollable. Escape no longer leaves the final screen; an explicit leave action is
required. This changes presentation, not the underlying scoring balance.

Independent local-model first-play trials have their own [protocol and receipts](AGENT_PLAYTEST.md).
Do not count the earlier scripted six-seat network exercise as an autonomous party
or treat invalid adapter pilots as entertainment results. The first two pilot runs
were preserved as incomplete/inconclusive after command-schema defects. Corrected
trials use fresh actor histories and a separate fresh receipt auditor.

The completed v3 run made 380 local Granite requests with no model/format errors,
16 original five-axis ratings and unchanged source fingerprints. Neither of its two
matches had a player-submitted ballot; all 12 ballots defaulted. Game one had no
successful movement/inspection; game two had three walks and two inspections, but no
item, ritual or vote action. A fresh independent auditor verified action receipts and
found multiple rating examples describing events that did not happen. See the full
[tracked findings](PLAYTEST_FINDINGS.md). Technical completion is not evidence of
human enjoyment, working social teaching or an entertaining stream. The subsequent
v4 receipt/validation hardening has offline regression coverage, not a new live trial.

### Final reviewed source gate

`tools/check.ps1 -Rendered` passed on the final code candidate: **1,294 distinct
automated checks**, no failures. Rendered repetitions are not counted as extra cases.

| Suite | Checks |
| --- | ---: |
| Authoritative case rules | 204 |
| NPC knowledge, negotiation, consent and native dialogue boundaries | 96 |
| Public phase progress and final ranked breakdowns | 85 |
| Scoped playtest API, route validation and actual MCP HTTP | 495 |
| Independent-session schemas, ratings and receipt failure handling | 82 |
| Rigs, locomotion and splash assets | 87 |
| Native gameplay/input/UI | 90 |
| Appearance/controller/haunting/music | 62 |
| Conversation, clue discoverability and playback-permission UI | 17 |
| Three real localhost ENet processes | 76 |

Formatting and lint passed for 61 GDScript files; the source-limit gate counted 76
files, largest 676 lines. Engine import and the actual compiler passed. The three
new offline Python asset helpers passed Ruff check/format; the reusable playtest
skill passed its metadata validator. No live model call is part of this default gate.

Native rendered repeats passed for round summaries (85), social UI (17), gameplay
(90) and presentation/input features (62). Updated screenshots remain in `artifacts/`.
All final engine logs are clean of script errors, assertion failures and native
access-violation reports; this is not a claim that every engine crash is eliminated.

The final ENet run passed host 34 / Ghost 19 / heir 23. Earlier silenced-audio
failures are preserved in `artifacts/network-ghost-silenced-audio-failure.{log,err}`.
Tracing isolated adaptive unreliable-packet throttling under local inference load;
receiver barriers alone did not fix it. The test now emits a realistic 1.2-second
synthetic utterance at 30-ms cadence and waits for replicated silence permission.
No transport/permission rule or negative routing assertion was bypassed. Two focused
runs and the full gate then passed; real microphone, packet-loss and WAN QA remain open.

Independent follow-up code review found no remaining critical/high findings; see
[review dispositions](REVIEW.md). Historical sections below retain their original
scope and counts.

### Rebuilt Windows development bundle

After the complete source gate, `tools/build.ps1 -SkipChecks` produced the updated
`build/Seance.exe` and **203,384,928-byte** `Seance.pck`. PCK SHA-256:
`7c1ef406e5ae391a6b7e390cede788a45a534d78b55019e4f7a91b25c8732eda`.
The packed game passed the external 90-check gameplay harness headlessly from the
build directory, without a source project-path argument. It then passed a separate
180-frame rendered startup smoke check. Logs:
`artifacts/packed-runtime-final.log`, `artifacts/packed-rendered-final.log`.
Both exited successfully without engine errors. These repeat existing gameplay
coverage and add packaging evidence, not another 90 distinct cases.

This remains an unsigned editor-runtime development bundle, not a Steam release or
AAA-ready build. Optional native speech helpers/voice weights, credentials and raw
playtest logs are not bundled or committed. No gameplay changes followed the final
source gate; subsequent edits only completed documentation and skill guidance.

## Earlier appearance/controller/haunting pass

`tools/check.ps1 -Rendered`: **512 distinct checks**, all passing. Repeating the
runtime/feature tests with a rendered window is not counted as new coverage.

| Suite | Checks |
| --- | ---: |
| Authoritative case rules | 204 |
| Eight rigs, locomotion and splash assets | 87 |
| Native gameplay/input/UI | 88 |
| Appearance/profile/controller/environment/music features | 62 |
| Three real localhost ENet processes | 71 |

Formatting, GDScript lint, engine import and the actual compiler harness passed.
49 source files were counted; the largest is 564 lines, below the 1,000-line limit.
The three new offline Python asset helpers also pass Ruff.

New coverage includes per-role preference storage/reload/replacement, earned-cosmetic
gating and duplicate reward rejection, role reassignment using the assigned role's
cosmetics, public cosmetic sanitization/replication, ghost glow without a lantern,
analog movement/look, D-pad navigation and face-button menu activation, pause/back,
room-event ownership/energy/cooldown/expiry, local calming, synchronized public storm
state, reduced-flash lighting, aligned score stems, and matching guest portraits.

Native screenshots in `artifacts/feature_{roles,wardrobe,settings,guests,details,weeping}.png`
and `artifacts/roster-sheet.png` were inspected. Meshy geometry/materials, hands,
idle poses and trailing garments still need a production art/rigging pass.

Early checks reported an empty controller list. The final rendered feature run
detected device 0; a subsequent native probe identified **Google Stadia Controller**,
with `Input.is_joy_known(0) == true` (see `artifacts/roster-render.log`).
Synthetic Godot joypad events prove the application bindings and UI behavior, **not**
human-operated input, Bluetooth transport, felt rumble or controller-speaker audio.
The rendered Windows audio driver exposed Realtek and virtual audio endpoints, not
a controller endpoint. Audio selection switches the entire mix; dedicated speakers
and adaptive triggers are not implemented. Microphones remained disabled during QA.
Human listening/comfort tests for the adaptive mix are still needed.

One earlier rendered-feature shutdown reported an ObjectDB/resource leak despite
all assertions passing. Explicit music/effect shutdown with an audio-thread drain
was added; the final full pass is clean. Earlier compiler/input/facing integration
failures were also fixed before the final pass. This is not evidence that all of the
previously observed engine access-violation paths are eliminated.
One table-collision check failed during overlapping validation/package work; the
position bounds and input criteria were not loosened. The final serialized full
suite passed. Window focus/load sensitivity remains a concern for GUI automation.

The updated 203,126,412-byte portable PCK passed the complete 88-case headless gameplay
harness from the build directory, using the external test script against the packed
game resources. It also passed a 180-frame rendered startup check. The other feature
and networking suites ran against source; they were not repeated against the package.
Latest logs: `artifacts/check-features.*`, `check-rendered-features.*`,
`network-{host,ghost,guest}.*`, `packed-runtime.log`, and `packed-features-rendered.log`.
The older clean-cache/LAN/review receipts below describe the initial build, not
independent retests of every new feature.

## Initial 0.1 validation (historical)

Environment: Windows, Godot `4.7.stable.official.5b4e0cb0f`, OpenGL Compatibility,
NVIDIA RTX 5080 Laptop GPU. Native GDScript runtime; gdtoolkit 4.5.0.

### Completed

`tools/check.ps1 -Rendered` passed:

| Check | Result |
| --- | --- |
| gdformat check / gdlint | Pass |
| Source-file limit | 32 checked files; largest 551 lines, all below 1,000 |
| Engine import and actual compiler harness | Pass |
| Authoritative rules | 204 checks, zero failures |
| Imported rigs, locomotion, PNG and splash configuration | 27 checks, zero failures |
| Native scene/input/physics/UI end-to-end test | 88 checks, zero failures |
| Same runtime test rendered on the GPU | 88 checks, zero failures (same cases, not additional coverage) |
| Three real ENet processes | 60 checks, zero failures |

379 distinct automated checks across the four test suites. Rendered playthroughs
and reruns are not counted as new tests. Engine logs contain no script errors or
native access-violation reports in these final runs.

The separately packaged `build/Seance.exe` + `Seance.pck` also passed headless and
120-frame rendered startup from the build directory, without a project-path argument.
Those are packaged startup smoke checks, not another full gameplay suite. The initial
relative parent-directory log path was rejected by the engine on Windows; rerunning
with absolute log paths succeeded without errors. The launcher does not use that path.

The rebuilt PCK contains the raw `assets/art/boot_splash.png`, as well as its imported
texture. The original 1600×900 splash PNG was visually inspected. Configuration
assertions do not independently prove the appearance of the short OS boot window.

A separate copy of the staged source tree, with no `.godot` cache and only the paired
engine binaries added, passed `tools/play.ps1 -Headless -Test assets_test`: first-run
import plus all 27 asset checks. This does not count as additional distinct cases.
The source launcher also passed with only the GUI executable available, and correctly
returned a nonzero exit code for an intentionally missing test script. Launch logs
use distinct timestamp/PID names so two instances do not contend for output files.
A concurrent-launch smoke check kept one headless game running while the second
source launcher imported and passed all 27 asset checks, using distinct logs. The
first test-owned process tree was then intentionally terminated; graceful network
shutdown is covered separately by the ENet suite.

The offline Meshy helper passed Ruff formatting/lint after its download-resume hardening.
It was not rerun against the paid API during final QA; no additional credits were spent.

The rendered test walks into the séance table, crosses the library doorway,
raycasts and collects evidence, reveals it, claims/gifts inheritance, completes all
three apparatus puzzles through UI handlers, asks the Ghost a question, advances
three sittings, seals a ballot, renders scores, and returns to the menu. All six
role cards/dossiers are exercised, as is opening and starting a host lobby.

Separate host, Ghost, and heir processes verified registration, snapshots, initial
movement, unauthorized manifestation rejection, ghost/medium text and PCM routing,
possession, silence, ritual prerequisites, ballots, final scores, guest loss,
host loss, port reuse, and returning from online play to solo.

Regression coverage now includes authoritative judgment seating and replication,
snapshot-driven sealed-ballot UI refresh, an ENet bandwidth-cap check, and reliable
test-stage acknowledgements (PCM itself remains unreliable).

Networking passed through both `127.0.0.1:27877` and this machine's Wi-Fi LAN address
`10.0.0.27:27877`. All three processes ran on the same physical PC. The LAN address
is a test receipt, not a permanent configuration value. The Windows network-access
prompt was acknowledged by the user and the tests were rerun afterward.

All network audio was generated synthetic PCM. No microphone was enabled by QA.

## Evidence

- `artifacts/check-{import,compile,rules,assets,runtime,rendered}.{log,err}`.
- `artifacts/network-{host,ghost,guest}.{log,err}` (latest networking run).
- `artifacts/qa_{transcript,judgment,results,spirit}.png` from the actual rendered viewport.
- `artifacts/capture_00.png` through `capture_09.png`: native-render menu/manor tour.
- `artifacts/export.log`: PCK export.
- `artifacts/packed-{headless,rendered}.log`: independent packaged startup checks.
- `artifacts/fresh-launch.{log,err}`: clean-cache source launcher asset test.
- `artifacts/{initial,followup}-review.json`: external read-only code-review receipts.

The native tour used additional camera placements to inspect rooms. Those captures
alone are not movement or gameplay tests; the runtime suite supplies that coverage.
Screenshots were inspected for layout, text visibility, and native 3D presentation.

## Known limitations and negative results

- Pre-commit reruns repeatedly lost early Ghost PCM packets. Added stage barriers
  alone did not fix it. Tracing found a client ENet throttle limit of 1/32: this
  engine's `create_server(..., max_channels=3)` forwards the channel count plus two
  as incoming bandwidth (5 bytes/s). Using the default host channel negotiation
  restored a 32/32 limit and passing loopback/LAN audio tests. Client channels remain
  explicitly configured. See the [exact engine source](https://github.com/godotengine/godot/blob/5b4e0cb0f/modules/enet/enet_multiplayer_peer.cpp#L61).
- An initial fresh-cache launcher test completed import but falsely reported failure
  because the GUI executable did not populate PowerShell's `LASTEXITCODE`. The launcher
  now waits on process handles, checks their exit codes, prefers the console wrapper,
  and preserves output in explicit log files. A new empty-cache test passed afterward.
- Early `--check-only --script` calls on UI scripts produced three native access
  violations. The project now uses an import step plus a SceneTree script-loading
  compiler harness. This avoids that observed failure path; it does not establish
  that every engine crash scenario is fixed.
- The computer-use automation backend failed before executing its JavaScript due
  to a sandbox metadata error. QA instead used native Godot input events, button
  signals, physics queries, rendering, and independent ENet processes.
- Human speech quality/latency, actual capture-device compatibility, two-computer
  LAN play, WAN operation, packet-loss behavior, and six-client soak are not tested.
- Rendered FPS readings on this GPU are not a minimum-spec benchmark. The manor
  still issues thousands of draw calls and needs a production optimization pass.
- Tests inspect the evaluated rig for scale; an initial static-source mesh bounds
  check was invalid for these skinned GLBs because it omitted bind transforms.
- One fixed case, scripted bot behavior, shared character bases, and unfinished
  art/animation are intentional prototype limits, not evidence of AAA readiness.
