# Pre-commit review — solo, presentation and independent playtests

The mandatory `code-review` skill was used for the second development checkpoint.
No standalone `/code-review` command tool was exposed in this session; two independent
read-only Codex reviewers used its checklist against the staged changes. One reviewed
authority, NPC consent, local inference, speech and networking; the other reviewed
presentation, cosmetic isolation, phase results and the evaluation/MCP boundary.
They did not run tests or make changes; the main worker verifies execution separately.

No critical or high code-level defect was confirmed. The ADR gate identified missing
decision coverage for local helpers, cosmetic rewards and isolated evaluation. The
existing [proposed ADR](adr/0001-native-prototype.md) now records these extensions and
links the detailed specifications; its status is not silently changed to accepted.

Medium findings and disposition:

- Empty no-choice model replies could replay the player's question as NPC speech:
  reject empty and whitespace-only replies; native regression assertions added.
- Completed TTS clips lacked a backend listening-permission recheck: track the
  speaker and cancel playback on permission loss. A synthetic playing-clip test
  covers expiry. Normal solo UI pause/cancellation already mitigated ordinary
  exposure; this was not a reproduced player-facing ghost-channel leak.
- External MCP movement returns travel duration but applies the position immediately:
  documented explicitly; neither external real-time movement equivalence nor
  rendered/controller usability is claimed by these trials.
- Rating validation accepted incomplete narratives: v4 requires the existing reason,
  example, memorable-moment and learning fields, and validates friction strings.
  Axes and score bounds are unchanged; frozen v3 ratings are not replaced.
- Receipt writes could fail without stopping the runner: sticky I/O errors now stop
  progress; writes, byte counts and readback hashes are checked. A finalization event
  follows verified report output. Closed, truncated, corrupted, reused and blocked
  receipt targets have offline regression coverage. This does not authenticate a
  hostile local filesystem or prove a model's narrative claims.

The integration gate also exposed an unreliable-audio test failure under concurrent
local inference. Tracing showed the host authorizing/relaying the silenced PCM while
ENet's adaptive outgoing throttle had fallen to 0/32 despite its 32/32 limit. Readiness
barriers alone did not fix that. Tests now synchronize receiver resets and send a
1.2-second synthetic utterance at the real 30-ms cadence, retaining the actual
unreliable transport and all negative/positive listening assertions. No gameplay
network throttle or permission rule was weakened. This does not establish resistance
to congestion or packet loss; sustained-load voice QA remains necessary.

Independent follow-up reviews confirmed the two dialogue/playback findings and the
two evaluator-validation/storage findings resolved, with no new critical/high
findings. The original presentation reviewer separately reviewed the receipt fix
implemented by the authority reviewer. Full native execution remains recorded in
[validation](VALIDATION.md), not inferred from reviewer inspection.

## Initial pre-commit review — 2026-09-06

The mandatory `code-review` skill was used before the first commit. The standalone
`/code-review` plugin and its referenced Codex-specific instruction file were not
installed, so the available Claude CLI performed an external read-only review using
the skill's checklist. It did not execute tests, modify files, or contact asset APIs.
The main worker ran the engine checks independently; see [validation](VALIDATION.md).

The initial whole-tree review reported **0 critical, 0 high, 3 medium** findings.
All three medium findings were addressed before committing:

- Source launcher: import an uncached or updated checkout before playing, wait on
  Windows process exit codes, and retain import/play diagnostics.
- Judgment: reset positions authoritatively and render the replicated positions.
  Fall recovery also returns to the last accepted position rather than a distant warp.
- Ballot: update the displayed sealed state when the server snapshot arrives; avoid
  rebuilding the editable form immediately after an asynchronous vote command.

Regression tests cover judgment positions, network replication, and ballot snapshot
refresh. A separate clean-cache source checkout exercises the actual launcher.
Main-worker network diagnosis additionally fixed the engine-specific ENet bandwidth
cap documented in validation; its regression is in the three-process test.

The external follow-up confirmed all original mediums fixed and again found
**0 critical, 0 high**. Its two new medium observations were dispositioned as follows:

- Concurrent launch log collision: fixed with per-launch timestamp/PID log names.
- Potential benign cold-import stderr rejection: not reproduced. The actual empty-cache
  staged checkout completed import and all 27 asset checks with clean stderr. Retained
  the fail-closed import diagnostic gate; monitor other engine versions/platforms.

The follow-up was code inspection, not execution; its suggestion that the clean-cache
path was untested was superseded by the main worker's launcher receipts.

A final single-pass launcher review again found **0 critical, 0 high**. Its PATH
discovery concern was fixed by accepting application executables only, excluding
PowerShell aliases/functions and batch shims. Its assumptions about missing GUI
stdout and literal ignored log names do not match the observed fallback test or
the repository-wide `artifacts/` ignore. Log retention, import timeout/serialization,
and console-window polish remain prototype follow-ups.

Low-priority follow-ups remain: per-instance floor grain/color, material sharing,
audio startup cost and zero-volume representation, optional locomotion-asset guards,
unused settings, departed voice-stream cleanup, and clearer late-join rejection.
The splash test now explicitly describes configuration coverage, not a captured boot
window. Source/test-count drift was corrected in the final validation record.

[ADR 0001](adr/0001-native-prototype.md) remains **proposed**. It records existing
user instructions; this review does not imply the user accepted the ADR.

Machine-readable review receipts are local ignored artifacts, not distributable
runtime files. This review is a prototype gate, not a security audit or release
certification.
