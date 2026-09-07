# Reviewed prototype decisions

- 2026-09-07: Chapter unlocks and independent audit publication are authoritative;
  future prerequisites are disclosed from arrival. NPC ownership disclosure is
  listener-specific, and queued solo errands require actual physical arrival.
  Source: chapter code review and follow-up; ADR 0001 proposed addendum.
- 2026-09-07: Modal back/tab/scroll behavior belongs in presentation; reserving
  controller bumpers must not suppress keyboard push-to-talk or leak a held press
  across the journal boundary. Source: reviewed controller regression fixes.
- 2026-09-06: Local dialogue may propose only currently permitted native actions;
  private knowledge and explicit transfer consent remain authoritative. Native
  speech is optional and listening permission remains valid only while it holds.
  Source: second-checkpoint independent code review; ADR 0001 proposed addendum.
- 2026-09-06: Cosmetics replicate allowlisted appearance IDs, not gameplay benefits
  or paid entitlements. Remembrance remains local prototype progression.
  Source: second-checkpoint independent code review; ADR 0001 proposed addendum.
- 2026-09-06: First-play trials isolate player/viewer knowledge, preserve failed
  receipts and distinguish synthetic self-ratings from observed actions. External
  MCP travel timing is explicitly not native-movement equivalent.
  Source: second-checkpoint independent code review and frozen v3 audit;
  ADR 0001 proposed addendum, docs/PLAYTEST_FINDINGS.md.

These entries record review context, not human acceptance of the proposed ADR or
production release approval.
