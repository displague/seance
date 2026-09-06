# Initial pre-commit review — 2026-09-06

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
