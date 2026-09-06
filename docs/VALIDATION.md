# Validation record — 2026-09-06

Environment: Windows, Godot `4.7.stable.official.5b4e0cb0f`, OpenGL Compatibility,
NVIDIA RTX 5080 Laptop GPU. Native GDScript runtime; gdtoolkit 4.5.0.

## Completed

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
